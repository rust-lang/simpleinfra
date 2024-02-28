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

// `source` and `service` are reserved log attributes on Datadog that have a special meaning.
// https://docs.datadoghq.com/logs/log_configuration/attributes_naming_convention
#[derive(Debug, Builder, Serialize)]
pub struct LogLineV1 {
    #[builder(default = "default_source()")]
    ddsource: &'static str,
    ddtags: String,
    service: String,
    hostname: String,
    #[serde(with = "time::serde::rfc3339")]
    date_time: OffsetDateTime,
    url: String,
    bytes: Option<usize>,
    ip: Option<IpAddr>,
    method: Option<String>,
    status: Option<u16>,
}

fn default_source() -> &'static str {
    "fastly"
}
