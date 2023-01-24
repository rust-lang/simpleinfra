use std::net::IpAddr;

use derive_builder::Builder;
use serde::Serialize;
use time::{Date, Time};

#[derive(Debug, Serialize)]
#[serde(tag = "version")]
pub enum LogLine {
    #[serde(rename = "1")]
    V1(LogLineV1),
}

#[derive(Debug, Builder, Serialize)]
pub struct LogLineV1 {
    date: Date,
    time: Time,
    url: String,
    bytes: Option<usize>,
    ip: Option<IpAddr>,
    method: Option<String>,
    status: Option<u16>,
}
