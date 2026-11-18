use fastly::log::Endpoint;
use log::{Level, LevelFilter, Log, Metadata, Record};
use serde::Serialize;
use std::env::var;
use std::io::Write;
use time::OffsetDateTime;

const MAX_LEVEL: LevelFilter = LevelFilter::Debug;

/// Writes service logs, i.e. the records of the `log` macros, to Datadog as JSON lines
///
/// Fastly sends the lines to Datadog unchanged, so they have to contain the reserved Datadog
/// attributes themselves. The fields follow the default log format of the Fastly VCL services.
pub struct ServiceLogger {
    endpoint: Endpoint,
    service: &'static str,
    ddtags: String,
    host: String,
    server_datacenter: Option<String>,
    request_id: Option<String>,
}

impl ServiceLogger {
    /// Creates a logger for the request with the given request ID
    ///
    /// Each sandbox handles a single request, so the request ID is the same for all records.
    pub fn new(
        endpoint: &str,
        service: &'static str,
        app: &str,
        env: &str,
        host: String,
        request_id: Option<String>,
    ) -> Self {
        Self {
            endpoint: Endpoint::from_name(endpoint),
            service,
            ddtags: format!("app:{app},env:{env}"),
            host,
            server_datacenter: var("FASTLY_POP").ok(),
            request_id,
        }
    }

    /// Installs the logger as the global logger of the `log` crate
    pub fn init(self) {
        log::set_boxed_logger(Box::new(self)).expect("failed to initialize logger");
        log::set_max_level(MAX_LEVEL);
    }

    fn line(&self, record: &Record, date: OffsetDateTime) -> serde_json::Result<String> {
        let line = ServiceLogLine {
            ddsource: "fastly",
            service: self.service,
            ddtags: &self.ddtags,
            host: &self.host,
            server_datacenter: self.server_datacenter.as_deref(),
            request_id: self.request_id.as_deref(),
            date,
            status: datadog_status(record.level()),
            message: record.args().to_string(),
        };

        serde_json::to_string(&line)
    }
}

impl Log for ServiceLogger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= MAX_LEVEL
    }

    fn log(&self, record: &Record) {
        if !self.enabled(record.metadata()) {
            return;
        }

        match self.line(record, OffsetDateTime::now_utc()) {
            Ok(line) => {
                let _ = self.endpoint.clone().write(line.as_bytes());
            }
            Err(error) => eprintln!("failed to serialize service log: {error}"),
        }
        // Show service logs in `fastly log-tail`
        println!("{}", record.args());
    }

    fn flush(&self) {}
}

#[derive(Serialize)]
struct ServiceLogLine<'a> {
    ddsource: &'static str,
    service: &'static str,
    ddtags: &'a str,
    host: &'a str,
    server_datacenter: Option<&'a str>,
    #[serde(skip_serializing_if = "Option::is_none")]
    request_id: Option<&'a str>,
    #[serde(with = "time::serde::rfc3339")]
    date: OffsetDateTime,
    status: &'static str,
    message: String,
}

/// Datadog has no `trace` status, so trace records are reported as `debug`.
fn datadog_status(level: Level) -> &'static str {
    match level {
        Level::Error => "error",
        Level::Warn => "warn",
        Level::Info => "info",
        Level::Debug | Level::Trace => "debug",
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use log::Level;
    use serde_json::{json, Value};
    use time::macros::datetime;

    /// Serialize a warning with a logger that has the given request ID
    fn line(request_id: Option<&str>) -> Value {
        let logger = ServiceLogger {
            endpoint: Endpoint::from_name("datadog-service-logs"),
            service: "static.crates.io",
            ddtags: "app:crates.io,env:prod".into(),
            host: "static.crates.io".into(),
            server_datacenter: Some("FRA".into()),
            request_id: request_id.map(Into::into),
        };

        let record = Record::builder()
            .level(Level::Warn)
            .args(format_args!("S3 returned status code 503"))
            .build();

        let date = datetime!(2026-11-11 14:13:20.231373 UTC);
        serde_json::from_str(&logger.line(&record, date).unwrap()).unwrap()
    }

    #[test]
    fn test_line() {
        assert_eq!(
            line(Some("7b1e3e4f2c5d4a6b")),
            json!({
                "ddsource": "fastly",
                "service": "static.crates.io",
                "ddtags": "app:crates.io,env:prod",
                "host": "static.crates.io",
                "server_datacenter": "FRA",
                "request_id": "7b1e3e4f2c5d4a6b",
                "date": "2026-11-11T14:13:20.231373Z",
                "status": "warn",
                "message": "S3 returned status code 503",
            })
        );
    }

    #[test]
    fn test_line_without_request_id() {
        assert!(line(None).get("request_id").is_none());
    }
}
