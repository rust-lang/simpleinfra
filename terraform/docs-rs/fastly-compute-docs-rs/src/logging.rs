use fastly::log::Endpoint;
use serde::Serialize;
use serde_json::{Map, Value};
use std::{
    io::{self, Write},
    sync::Mutex,
};
use time::OffsetDateTime;
use tracing::{
    Event, Subscriber,
    span::{Attributes, Id, Record},
};
use tracing_serde::fields::AsMap;
use tracing_subscriber::{
    filter::LevelFilter,
    fmt,
    layer::{Context, Layer, SubscriberExt},
    registry::LookupSpan,
    util::SubscriberInitExt,
};

// Must match the logging endpoint name in Terraform.
const APPLICATION_LOG_ENDPOINT: &str = "application_logs";

// About `ddsource`
// This corresponds to the integration name, the technology
// from which the log originated. When it matches an integration
// name, Datadog automatically installs the corresponding parsers
// and facets. For example, nginx, postgresql, and so on.
const LOG_SOURCE_FORMAT: &str = "docs-rs-fastly-wasm";

pub(crate) fn setup() {
    let application_logs = Endpoint::from_name(APPLICATION_LOG_ENDPOINT);

    tracing_subscriber::registry()
        .with(
            // Print to stderr for `fastly log-tail`.
            fmt::layer()
                .compact()
                .with_ansi(false)
                .with_writer(io::stderr)
                .with_filter(LevelFilter::INFO),
        )
        // emit NDJSON in datadog format to logging endpoint
        .with(DatadogLayer::new(application_logs).with_filter(LevelFilter::INFO))
        .init();
}

/// tracing layer for datadog.
///
/// * collects all fields from spans
/// * emits a json log record following the datadog convention
/// * includes event fields & span fields
struct DatadogLayer<W> {
    writer: Mutex<W>,
}

impl<W> DatadogLayer<W> {
    fn new(writer: W) -> Self {
        Self {
            writer: Mutex::new(writer),
        }
    }
}

/// To collect span fields so we have them when we emit the log
/// records inside a span.
#[derive(Default)]
struct SpanFields(Map<String, Value>);

impl<S, W> Layer<S> for DatadogLayer<W>
where
    S: Subscriber + for<'lookup> LookupSpan<'lookup>,
    W: Write + Send + 'static,
{
    /// called when a new span is created.
    fn on_new_span(&self, attrs: &Attributes<'_>, id: &Id, ctx: Context<'_, S>) {
        let Ok(fields) = json_fields(attrs.field_map()) else {
            return;
        };

        if let Some(span) = ctx.span(id) {
            span.extensions_mut().insert(SpanFields(fields));
        }
    }

    /// called when people do `span.record` ( = add fields to the span later)
    fn on_record(&self, id: &Id, values: &Record<'_>, ctx: Context<'_, S>) {
        let Ok(fields) = json_fields(values.field_map()) else {
            return;
        };

        if let Some(span) = ctx.span(id) {
            let mut extensions = span.extensions_mut();
            if let Some(span_fields) = extensions.get_mut::<SpanFields>() {
                span_fields.0.extend(fields);
            } else {
                extensions.insert(SpanFields(fields));
            }
        }
    }

    /// called on each log event
    fn on_event(&self, event: &Event<'_>, ctx: Context<'_, S>) {
        let event_fields = json_fields(event.field_map()).unwrap_or_else(|error| {
            eprintln!("failed to serialize tracing event fields: {error}");
            Map::new()
        });

        let mut fields = Map::new();
        if let Some(scope) = ctx.event_scope(event) {
            // collect all the fields from all the surrounding spans.
            //
            // We start at the outermost span, and overwrite fields
            // with new values from inner spans.
            for span in scope.from_root() {
                if let Some(span_fields) = span.extensions().get::<SpanFields>() {
                    fields.extend(span_fields.0.clone());
                }
            }
        }
        // Event fields override those inherited from spans.
        fields.extend(event_fields);

        let message = match fields.remove("message") {
            Some(Value::String(message)) => Some(message),
            _ => None,
        };

        let row = TraceLog {
            ddsource: LOG_SOURCE_FORMAT,
            ddtags: "env:production",
            hostname: fastly::compute_runtime::hostname(),
            timestamp: OffsetDateTime::now_utc(),
            message: message.as_deref().unwrap_or_default(),
            service: "docs.rs fastly WASM",
            status: level_name(*event.metadata().level()),
            target: event.metadata().target(),
            fields,
        };

        // A Fastly endpoint turns each `write` into one log line. Do not use
        // `write_all`, which may turn a partial write into multiple log lines.
        if let Ok(json) = serde_json::to_vec(&row)
            && let Ok(mut writer) = self.writer.lock()
        {
            let _ = writer.write(&json);
        }
    }
}

fn json_fields(fields: impl Serialize) -> Result<Map<String, Value>, serde_json::Error> {
    match serde_json::to_value(fields)? {
        Value::Object(fields) => Ok(fields),
        // AsMap is sealed and implemented only for Event, Attributes, and Record.
        // Their Serialize implementations all call serializer.serialize_map(...)
        // before recording fields. With serde_json::to_value, that necessarily
        // produces Value::Object.
        _ => unreachable!("tracing-serde field maps always serialize as JSON objects"),
    }
}

fn level_name(level: tracing::Level) -> &'static str {
    match level {
        tracing::Level::ERROR => "error",
        tracing::Level::WARN => "warn",
        tracing::Level::INFO => "info",
        tracing::Level::DEBUG | tracing::Level::TRACE => "debug",
    }
}

/// Datadog-compatible JSON emitted to Fastly's real-time logging endpoint.
#[derive(Serialize)]
struct TraceLog<'a> {
    ddsource: &'static str,
    ddtags: &'static str,
    hostname: &'static str,
    #[serde(with = "time::serde::rfc3339")]
    timestamp: OffsetDateTime,
    message: &'a str,
    service: &'static str,
    /// Normalized tracing level.
    status: &'static str,
    /// The tracing target, normally the Rust module containing the event.
    target: &'a str,
    /// Additional `tracing` event fields.
    fields: Map<String, Value>,
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    use std::{
        str,
        sync::{Arc, Mutex},
    };
    use time::macros::datetime;

    #[derive(Clone, Debug, Default)]
    struct CapturedOutput {
        bytes: Vec<u8>,
        writes: usize,
    }

    #[derive(Clone)]
    struct TestWriter(Arc<Mutex<CapturedOutput>>);

    impl io::Write for TestWriter {
        fn write(&mut self, bytes: &[u8]) -> io::Result<usize> {
            let mut output = self.0.lock().unwrap();
            output.bytes.extend_from_slice(bytes);
            // Fastly turns every write into an individual log line. Mimic that
            // behavior so the test can split the captured records.
            output.bytes.push(b'\n');
            output.writes += 1;
            Ok(bytes.len())
        }

        fn flush(&mut self) -> io::Result<()> {
            Ok(())
        }
    }

    fn capture_logs(log: impl FnOnce()) -> CapturedOutput {
        let output = Arc::new(Mutex::new(CapturedOutput::default()));
        let make_writer = {
            let output = Arc::clone(&output);
            move || TestWriter(Arc::clone(&output))
        };
        let subscriber = tracing_subscriber::registry().with(DatadogLayer::new(make_writer()));

        tracing::subscriber::with_default(subscriber, log);
        output.lock().unwrap().clone()
    }

    fn json_lines(output: &CapturedOutput) -> Vec<Value> {
        str::from_utf8(&output.bytes)
            .unwrap()
            .lines()
            .map(|line| serde_json::from_str(line).unwrap())
            .collect()
    }

    #[test]
    fn trace_log_serializes_to_datadog_json() {
        let timestamp = datetime!(2026-09-04 06:07:42 UTC);

        let row = TraceLog {
            ddsource: LOG_SOURCE_FORMAT,
            ddtags: "env:production",
            hostname: "docs.rs-fastly",
            timestamp,
            message: "handled request",
            service: "docs.rs fastly WASM",
            status: "info",
            target: "docs_rs_fastly::ngwaf",
            fields: Map::from_iter([("status_code".into(), json!(200))]),
        };

        assert_eq!(
            serde_json::to_value(row).unwrap(),
            json!({
                "ddsource": LOG_SOURCE_FORMAT,
                "ddtags": "env:production",
                "hostname": "docs.rs-fastly",
                "timestamp": "2026-09-04T06:07:42Z",
                "message": "handled request",
                "service": "docs.rs fastly WASM",
                "status": "info",
                "target": "docs_rs_fastly::ngwaf",
                "fields": { "status_code": 200 },
            })
        );
    }

    #[test]
    fn formatter_preserves_typed_fields_and_request_span() {
        let output = capture_logs(|| {
            let span = tracing::info_span!("request", request_id = "request-123");
            let _entered = span.enter();
            tracing::info!(status_code = 200, cache_hit = true, "handled request");
        });

        assert_eq!(output.writes, 1);
        let log = json_lines(&output).pop().unwrap();
        assert_eq!(log["message"], "handled request");
        assert_eq!(log["fields"]["request_id"], "request-123");
        assert_eq!(log["fields"]["status_code"], 200);
        assert_eq!(log["fields"]["cache_hit"], true);
    }

    #[test]
    fn formatter_includes_request_id_after_it_is_recorded() {
        let output = capture_logs(|| {
            let span = tracing::info_span!("request", request_id = tracing::field::Empty);
            let _entered = span.enter();

            tracing::info!("before request ID");
            span.record("request_id", "request-123");
            tracing::info!("after request ID");
        });

        let logs = json_lines(&output);
        assert_eq!(output.writes, 2);
        assert!(logs[0]["fields"].get("request_id").is_none());
        assert_eq!(logs[1]["fields"]["request_id"], "request-123");
    }

    #[test]
    fn formatter_prefers_event_fields_over_inner_and_outer_spans() {
        let output = capture_logs(|| {
            let request =
                tracing::info_span!("request", request_id = "request-123", backend = "edge");
            let _request_entered = request.enter();
            let operation = tracing::info_span!("operation", backend = "origin");
            let _operation_entered = operation.enter();

            tracing::info!(backend = "override", "sending request");
        });

        let log = json_lines(&output).pop().unwrap();
        assert_eq!(log["fields"]["request_id"], "request-123");
        assert_eq!(log["fields"]["backend"], "override");
    }

    #[test]
    fn formatter_prefers_inner_span_fields_over_root_span_fields() {
        let output = capture_logs(|| {
            let request = tracing::info_span!("request", backend = "edge");
            let _request_entered = request.enter();
            let operation = tracing::info_span!("operation", backend = "origin");
            let _operation_entered = operation.enter();

            tracing::info!("sending request");
        });

        let log = json_lines(&output).pop().unwrap();
        assert_eq!(log["fields"]["backend"], "origin");
    }

    #[test]
    fn formatter_preserves_message_with_a_debug_error_field() {
        #[derive(Debug)]
        struct InspectError;

        let output = capture_logs(|| {
            let request = tracing::info_span!("request", request_id = "request-123");
            let _entered = request.enter();
            let error = InspectError;

            tracing::error!(
                target: "docs_rs_fastly::ngwaf",
                error = ?error,
                "error inspecting request"
            );
        });

        let log = json_lines(&output).pop().unwrap();
        assert_eq!(log["message"], "error inspecting request");
        assert_eq!(log["status"], "error");
        assert_eq!(log["target"], "docs_rs_fastly::ngwaf");
        assert_eq!(log["fields"]["error"], "InspectError");
        assert_eq!(log["fields"]["request_id"], "request-123");
    }
}
