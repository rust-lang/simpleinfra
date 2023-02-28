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

#[derive(Debug, Builder, Serialize)]
pub struct LogLineV1 {
    #[serde(with = "time::serde::rfc3339")]
    date_time: OffsetDateTime,
    url: String,
    bytes: Option<usize>,
    ip: Option<IpAddr>,
    method: Option<String>,
    status: Option<u16>,
}
