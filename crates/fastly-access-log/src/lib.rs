use derive_builder::Builder;
use fastly::{Error, Request, Response, http::Version};
use serde::Serialize;
use std::{env::var, net::IpAddr};
use time::OffsetDateTime;

#[derive(Debug, Serialize)]
#[serde(tag = "version")]
pub enum LogLine {
    #[serde(rename = "1")]
    V1(LogLineV1),
}

impl LogLine {
    pub fn to_json(self) -> String {
        serde_json::to_string(&self).expect("failed to serialize request log")
    }
}

// `ddsource`, `ddtags`, and `service` are reserved Datadog log attributes.
#[derive(Debug, Builder, Serialize)]
#[builder(build_fn(private, name = "build_internal"))]
pub struct LogLineV1 {
    #[builder(default = "default_source()")]
    ddsource: &'static str,
    ddtags: String,
    service: &'static str,
    bytes: Option<usize>,
    content_type: Option<String>,
    #[serde(with = "time::serde::rfc3339")]
    date_time: OffsetDateTime,
    edge_location: Option<String>,
    host: Option<String>,
    http: Option<HttpDetails>,
    ip: Option<IpAddr>,
    method: Option<String>,
    status: Option<u16>,
    tls: Option<TlsDetails>,
    url: String,
    cache_hit: bool,
    #[builder(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    on_shield: Option<bool>,
    #[builder(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    request_id: Option<String>,
}

impl LogLineV1Builder {
    pub fn build(self) -> Result<LogLine, LogLineV1BuilderError> {
        Ok(LogLine::V1(self.build_internal()?))
    }
}

/// return default source for usage with datadog.
///
/// We have custom input parsers in datadog that
/// handle exactly this access log format.
///
/// These are bound to this source identifier.
fn default_source() -> &'static str {
    "fastly"
}

#[derive(Clone, Debug, Builder, Serialize)]
pub struct HttpDetails {
    protocol: Option<String>,
    referer: Option<String>,
    useragent: Option<String>,
}

#[derive(Clone, Debug, Builder, Serialize)]
pub struct TlsDetails {
    cipher: Option<String>,
    protocol: Option<String>,
}

/// Collect access-log fields available before the request is sent to a backend.
pub fn collect_request(
    request: &Request,
    service: &'static str,
    app: &str,
    env: &str,
    host: Option<String>,
) -> LogLineV1Builder {
    let http_details = HttpDetailsBuilder::default()
        .protocol(http_version_to_string(request.get_version()))
        .referer(
            request
                .get_header("Referer")
                .and_then(|s| s.to_str().ok())
                .map(str::to_owned),
        )
        .useragent(
            request
                .get_header("User-Agent")
                .and_then(|s| s.to_str().ok())
                .map(str::to_owned),
        )
        .build()
        .ok();

    let tls_details = TlsDetailsBuilder::default()
        .cipher(
            request
                .get_tls_cipher_openssl_name()
                .ok()
                .flatten()
                .map(str::to_owned),
        )
        .protocol(request.get_tls_protocol().ok().flatten().map(str::to_owned))
        .build()
        .ok();

    LogLineV1Builder::default()
        .ddtags(format!("app:{},env:{}", app, env))
        .service(service)
        .date_time(OffsetDateTime::now_utc())
        .edge_location(var("FASTLY_POP").ok())
        .host(host)
        .http(http_details)
        .ip(request.get_client_ip_addr())
        .method(Some(request.get_method().to_string()))
        .url(request.get_url_str().into())
        .tls(tls_details)
        .to_owned()
}

/// Add fields available after the backend response is received.
pub fn collect_response(
    log_line: &mut LogLineV1Builder,
    response: &Result<Response, Error>,
) -> LogLineV1Builder {
    if let Ok(response) = response {
        log_line
            .bytes(response.get_content_length())
            .content_type(
                response
                    .get_content_type()
                    .map(|content_type| content_type.to_string()),
            )
            .status(Some(response.get_status().as_u16()))
            .cache_hit(response_is_cache_hit(response))
            .to_owned()
    } else {
        collect_error_response(log_line)
    }
}

fn collect_error_response(log_line: &mut LogLineV1Builder) -> LogLineV1Builder {
    // No response was received, so this cannot have been a cache hit.
    log_line.status(Some(500)).cache_hit(false).to_owned()
}

/// Determine whether the cache lookup at this POP was a hit.
///
/// Fastly appends an `X-Cache` value at every cache layer. Earlier values can
/// describe an upstream shield, while the final value describes this POP.
/// Synthetic responses do not carry this header and are not cache hits.
///
/// See
/// https://www.fastly.com/documentation/guides/concepts/shielding/#debugging
fn response_is_cache_hit(response: &Response) -> bool {
    is_cache_hit(
        response
            .get_header("X-Cache")
            .and_then(|value| value.to_str().ok()),
    )
}

fn is_cache_hit(x_cache: Option<&str>) -> bool {
    x_cache
        .and_then(|value| value.rsplit(',').next())
        .is_some_and(|value| value.trim().eq_ignore_ascii_case("HIT"))
}

fn http_version_to_string(version: Version) -> Option<String> {
    match version {
        Version::HTTP_09 => Some("HTTP/0.9".into()),
        Version::HTTP_10 => Some("HTTP/1.0".into()),
        Version::HTTP_11 => Some("HTTP/1.1".into()),
        Version::HTTP_2 => Some("HTTP/2".into()),
        Version::HTTP_3 => Some("HTTP/3".into()),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::Value;

    fn minimal_log_builder() -> LogLineV1Builder {
        LogLineV1Builder::default()
            .ddtags("app:test,env:test".into())
            .service("test")
            .bytes(None)
            .content_type(None)
            .date_time(OffsetDateTime::UNIX_EPOCH)
            .edge_location(None)
            .host(None)
            .http(None)
            .ip(None)
            .method(None)
            .status(None)
            .tls(None)
            .url("https://example.test/".into())
            .cache_hit(false)
            .to_owned()
    }

    #[test]
    fn serialized_log_has_the_expected_access_log_contract() {
        let serialized = minimal_log_builder().build().unwrap().to_json();
        let value: Value = serde_json::from_str(&serialized).unwrap();

        assert_eq!(value["version"], Value::String("1".into()));
        assert_eq!(value["cache_hit"], Value::Bool(false));
        assert!(value["status"].is_null());
        assert!(value.get("on_shield").is_none());
        assert!(value.get("request_id").is_none());
    }

    #[test]
    fn serialized_log_preserves_optional_request_fields() {
        for on_shield in [true, false] {
            let log = minimal_log_builder()
                .on_shield(Some(on_shield))
                .request_id(Some("request-123".into()))
                .to_owned()
                .build()
                .unwrap();
            let value: Value = serde_json::from_str(&log.to_json()).unwrap();

            assert_eq!(value["on_shield"], Value::Bool(on_shield));
            assert_eq!(value["request_id"], Value::String("request-123".into()));
        }
    }

    // Response accessors require Fastly hostcalls supplied by Viceroy.
    #[cfg(target_arch = "wasm32")]
    #[test]
    fn collected_responses_serialize_their_cache_status() {
        for (x_cache, expected) in [
            (Some("MISS, HIT"), true),
            (Some("HIT, MISS"), false),
            (None, false),
        ] {
            let mut response = Response::new()
                .with_status(201)
                .with_header("Content-Length", "42")
                .with_header("Content-Type", "text/plain");
            if let Some(x_cache) = x_cache {
                response.set_header("X-Cache", x_cache);
            }
            let log = collect_response(&mut minimal_log_builder(), &Ok(response))
                .build()
                .unwrap();
            let value: Value = serde_json::from_str(&log.to_json()).unwrap();

            assert_eq!(value["cache_hit"], Value::Bool(expected), "{x_cache:?}");
            assert_eq!(value["status"], Value::from(201));
            assert_eq!(value["bytes"], Value::from(42));
            assert_eq!(value["content_type"], Value::String("text/plain".into()));
        }
    }

    #[test]
    fn cache_hit_uses_the_final_x_cache_value() {
        for (x_cache, expected) in [
            (None, false),
            (Some(""), false),
            (Some("MISS"), false),
            (Some("HIT"), true),
            (Some(" hit "), true),
            (Some("HIT, MISS"), false),
            (Some("MISS, HIT"), true),
            (Some("MISS, HIT, MISS"), false),
            (Some("unknown"), false),
        ] {
            assert_eq!(is_cache_hit(x_cache), expected, "{x_cache:?}");
        }
    }

    #[test]
    fn error_responses_are_logged_as_uncached_500s() {
        let mut builder = minimal_log_builder();
        builder.cache_hit(true);
        let log = collect_error_response(&mut builder).build().unwrap();
        let value: Value = serde_json::from_str(&log.to_json()).unwrap();

        assert_eq!(value["status"], Value::from(500));
        assert_eq!(value["cache_hit"], Value::Bool(false));
    }

    // Linking collect_response also pulls in hostcalls from its success path.
    #[cfg(target_arch = "wasm32")]
    #[test]
    fn collected_errors_reset_cache_hits() {
        let mut builder = minimal_log_builder();
        builder.cache_hit(true);
        let response = Err(Error::msg("backend unavailable"));
        let log = collect_response(&mut builder, &response).build().unwrap();
        let value: Value = serde_json::from_str(&log.to_json()).unwrap();

        assert_eq!(value["status"], Value::from(500));
        assert_eq!(value["cache_hit"], Value::Bool(false));
    }
}
