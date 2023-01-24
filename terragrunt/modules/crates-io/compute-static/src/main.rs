use fastly::http::{Method, StatusCode};
use fastly::{Error, Request, Response};
use log::{info, warn, LevelFilter};
use log_fastly::Logger;
use serde_json::json;
use time::OffsetDateTime;

use crate::config::Config;
use crate::log_line::{LogLine, LogLineV1Builder};

mod config;
mod log_line;

#[fastly::main]
fn main(request: Request) -> Result<Response, Error> {
    let config = Config::from_dictionary();
    init_logging(&config);

    let mut log = collect_request(&request);

    let response = handle_request(&config, request);

    let log = collect_response(&mut log, &response);
    build_and_send_log(log, &config);

    response
}

/// Initialize the logger
///
/// Fastly provides its own logger implementation that streams logs to pre-configured endpoints. We
/// have created one endpoint for request logs and one for service logs.
///
/// Logs are echoed to stdout as well to enable tailing the logs with the Fastly CLI.
fn init_logging(config: &Config) {
    Logger::builder()
        .max_level(LevelFilter::Debug)
        .endpoint(config.request_logs_endpoint.clone())
        .default_endpoint(config.service_logs_endpoint.clone())
        .echo_stdout(true)
        .init();
}

/// Collect data for the logs from the request
fn collect_request(request: &Request) -> LogLineV1Builder {
    let datetime = OffsetDateTime::now_utc();

    LogLineV1Builder::default()
        .date(datetime.date())
        .time(datetime.time())
        .url(request.get_url_str().into())
        .ip(request.get_client_ip_addr())
        .method(Some(request.get_method().to_string()))
        .to_owned()
}

/// Handle the request
///
/// This method handles the incoming request and returns a response for the client. It first ensures
/// that the request uses whitelisted request methods, then sets a TTL to cache the response, before
/// finally forwarding the request to S3.
fn handle_request(config: &Config, mut request: Request) -> Result<Response, Error> {
    if let Some(response) = limit_http_methods(&request) {
        return Ok(response);
    }

    set_ttl(config, &mut request);

    // Database dump is too big to cache on Fastly
    if request.get_url_str().ends_with("db-dump.tar.gz") {
        redirect_db_dump_to_cloudfront(config)
    } else {
        send_request_to_s3(config, &request)
    }
}

/// Limit HTTP methods
///
/// Clients are only allowed to request resources using GET and HEAD requests. If any other HTTP
/// method is received, HTTP 403 Unauthorized is returned.
///
/// We don't return HTTP 405 Method Not Allowed to maintain parity with CloudFront.
fn limit_http_methods(request: &Request) -> Option<Response> {
    let method = request.get_method();

    if method != Method::GET && method != Method::HEAD {
        return Some(
            Response::from_body("Method not allowed").with_status(StatusCode::UNAUTHORIZED),
        );
    }

    None
}

/// Set the TTL
///
/// A TTL header is added to the request to ensure that the content is cached for the given amount
/// of time.
fn set_ttl(config: &Config, request: &mut Request) {
    request.set_ttl(config.static_ttl);
}

/// Redirect request to CloudFront
///
/// As of early 2023, certain files are too large to be served through Fastly. One of those is the
/// database dump, which gets redirected to CloudFront.
fn redirect_db_dump_to_cloudfront(config: &Config) -> Result<Response, Error> {
    let url = format!("https://{}/db-dump.tar.gz", config.cloudfront_url);
    Ok(Response::temporary_redirect(url))
}

/// Forward client request to S3
///
/// The request that was received by the client is forwarded to S3. First, the primary bucket is
/// queried. If the response indicates a server issue (status code >= 500), the request is sent to
/// a fallback bucket in a different geographical region.
fn send_request_to_s3(config: &Config, request: &Request) -> Result<Response, Error> {
    let primary_request = request.clone_without_body();

    let mut response = primary_request.send(&config.primary_host)?;
    let status_code = response.get_status().as_u16();

    if status_code >= 500 {
        warn!(
            "Request to host {} returned status code {}",
            config.primary_host, status_code
        );

        let fallback_request = request.clone_without_body();
        response = fallback_request.send(&config.fallback_host)?;
    }

    Ok(response)
}

/// Collect data for the logs from the response
fn collect_response(
    log_line: &mut LogLineV1Builder,
    response: &Result<Response, Error>,
) -> LogLineV1Builder {
    if let Ok(response) = response {
        log_line
            .bytes(response.get_content_length())
            .status(Some(response.get_status().as_u16()))
            .to_owned()
    } else {
        log_line.status(Some(500)).to_owned()
    }
}

/// Finalize the builder and log the line
fn build_and_send_log(log_line: LogLineV1Builder, config: &Config) {
    match log_line.build() {
        Ok(log) => {
            let versioned_log = LogLine::V1(log);
            info!(target: &config.request_logs_endpoint, "{}", json!(versioned_log).to_string())
        }
        Err(error) => {
            warn!("failed to serialize request log: {error}");
        }
    };
}
