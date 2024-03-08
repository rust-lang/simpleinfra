use std::net::IpAddr;

use derive_builder::Builder;
use serde::Serialize;
use time::OffsetDateTime;

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
    service: String,
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
