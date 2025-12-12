use std::env::var;
use std::net::IpAddr;

use crate::config::Config;
use crate::http_version_to_string;
use derive_builder::Builder;
use fastly::{Error, Request, Response};
use serde::Serialize;
use time::OffsetDateTime;

const DATADOG_APP: &str = "crates.io";
const DATADOG_SERVICE: &str = "static.crates.io";

#[derive(Debug, Serialize)]
#[serde(tag = "version")]
pub enum LogLine {
    #[serde(rename = "1")]
    V1(LogLineV1),
}

// `ddsource`, `ddtags`, and `service` are reserved log attributes on Datadog that have a special
// meaning. See https://docs.datadoghq.com/logs/log_configuration/attributes_naming_convention.
#[derive(Debug, Builder, Serialize)]
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
}

impl LogLineV1 {
    /// Collect data for the logs from the request
    pub fn collect_request(config: &Config, request: &Request) -> LogLineV1Builder {
        let http_details = HttpDetailsBuilder::default()
            .protocol(http_version_to_string(request.get_version()))
            .referer(
                request
                    .get_header("Referer")
                    .and_then(|s| s.to_str().ok())
                    .map(|s| s.to_string()),
            )
            .useragent(
                request
                    .get_header("User-Agent")
                    .and_then(|s| s.to_str().ok())
                    .map(|s| s.to_string()),
            )
            .build()
            .ok();

        let tls_details = TlsDetailsBuilder::default()
            .cipher(request.get_tls_cipher_openssl_name())
            .protocol(request.get_tls_protocol())
            .build()
            .ok();

        let log_line = LogLineV1Builder::default()
            .ddtags(format!("app:{},env:{}", DATADOG_APP, config.datadog_env))
            .service(DATADOG_SERVICE)
            .date_time(OffsetDateTime::now_utc())
            .edge_location(var("FASTLY_POP").ok())
            .host(request.get_url().host().map(|s| s.to_string()))
            .http(http_details)
            .ip(request.get_client_ip_addr())
            .method(Some(request.get_method().to_string()))
            .url(request.get_url_str().into())
            .tls(tls_details)
            .to_owned();

        log_line
    }

    /// Collect data for the logs from the response
    pub fn collect_response(
        log_line: &mut LogLineV1Builder,
        response: &Result<Response, Error>,
    ) -> LogLineV1Builder {
        if let Ok(response) = response {
            log_line
                .bytes(response.get_content_length())
                .content_type(response.get_content_type().map(|s| s.to_string()))
                .status(Some(response.get_status().as_u16()))
                .to_owned()
        } else {
            log_line.status(Some(500)).to_owned()
        }
    }
}

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
    cipher: Option<&'static str>,
    protocol: Option<&'static str>,
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Verifies whether the log collector can correctly build a log line from a request/response pair.
    #[test]
    fn test_log_collector() {
        let client_req = Request::get("https://crates.io/crates/syn"); // Arbitrary crate with no meaning
        let config = Config {
            primary_host: "test_backend".to_string(),
            fallback_host: "fallback_host".to_string(),
            static_ttl: 0,
            cloudfront_url: "cloudfront_url".to_string(),
            datadog_env: "datadog_env".to_string(),
            datadog_host: "datadog_host".to_string(),
            datadog_request_logs_endpoint: "datadog_request_logs_endpoint".to_string(),
            s3_request_logs_endpoint: "s3_request_logs_endpoint".to_string(),
            s3_service_logs_endpoint: "s3_service_logs_endpoint".to_string(),
        };
        let mut log = LogLineV1::collect_request(&config, &client_req);
        let log = LogLineV1::collect_response(
            &mut log,
            &Ok(Response::temporary_redirect("https://crates.io/")),
        );
        let log = log.build().unwrap();
        assert_eq!(log.ddsource, "fastly");
        assert_eq!(
            log.ddtags,
            format!("app:crates.io,env:{}", config.datadog_env)
        );
        assert_eq!(log.service, "static.crates.io");
        assert_eq!(
            log.host,
            Some(client_req.get_url().host().unwrap().to_string())
        );
        assert_eq!(log.url, client_req.get_url_str());
        assert_eq!(log.method, Some(client_req.get_method().to_string()));
    }
}
