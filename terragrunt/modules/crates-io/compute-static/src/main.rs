use fastly::http::{Method, StatusCode, Version};
use fastly::{Error, Request, Response};
use log::{info, warn, LevelFilter};
use log_fastly::Logger;
use once_cell::sync::Lazy;
use regex::Regex;
use serde_json::json;

use crate::config::Config;
use crate::log_line::{LogLine, LogLineV1, LogLineV1Builder};

mod config;
mod log_line;

const VERSION_DOWNLOADS: &str = "/archive/version-downloads";

#[fastly::main]
fn main(request: Request) -> Result<Response, Error> {
    let config = Config::from_dictionary();

    // Forward purge requests immediately to a backend
    // https://developer.fastly.com/learning/concepts/purging/#forwarding-purge-requests
    if request.get_method() == "PURGE" {
        return send_request_to_s3(&config, &request);
    }

    init_logging(&config);
    let mut log = LogLineV1::collect_request(&config, &request);

    let has_origin_header = request.get_header("Origin").is_some();
    let mut response = handle_request(&config, request);

    if has_origin_header {
        add_cors_headers(&mut response);
    }

    let log = LogLineV1::collect_response(&mut log, &response);
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
        .endpoint(config.datadog_request_logs_endpoint.clone())
        .endpoint(config.s3_request_logs_endpoint.clone())
        .default_endpoint(config.s3_service_logs_endpoint.clone())
        .echo_stdout(true)
        .init();
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

    rewrite_request(config, &mut request);

    // Database dump is too big to cache on Fastly
    if request.get_url_str().ends_with("db-dump.tar.gz") {
        redirect_to_cloudfront(config, "db-dump.tar.gz")
    } else if request.get_url_str().ends_with("db-dump.zip") {
        redirect_to_cloudfront(config, "db-dump.zip")
    } else {
        send_request_to_s3(config, &request)
    }
}

/// Applies required modifications on the request
fn rewrite_request(config: &Config, request: &mut Request) {
    set_ttl(config, request);
    rewrite_urls_with_plus_character(request);
    rewrite_download_urls(request);
    rewrite_version_downloads_urls(request);
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

/// Rewrite URLs with a plus character
///
/// An issue was reported for crates.io where URLs that encoded the `+` character in a crate's
/// version as `%2B` were not working correctly. As a backwards-compatible fix, we are transparently
/// rewriting URLs that contain the `+` character to use `%2B` instead. This ensures that crates in
/// Amazon S3 are accessed in a consistent way across all clients and Content Delivery Networks.
///
/// See more: https://github.com/rust-lang/crates.io/issues/4891
fn rewrite_urls_with_plus_character(request: &mut Request) {
    let url = request.get_url_mut();
    let path = url.path();

    if path.contains('+') {
        let new_path = path.replace('+', "%2B");
        url.set_path(&new_path);
    }
}

/// Rewrite `/archive/version-downloads/` URLs to `/archive/version-downloads/index.html`
///
/// In this way, users can see what files are available for download.
fn rewrite_version_downloads_urls(request: &mut Request) {
    let url = request.get_url_mut();
    let path = url.path().trim_end_matches('/');

    if path == VERSION_DOWNLOADS {
        let new_path = format!("{path}/index.html");
        url.set_path(&new_path);
    }
}

/// Rewrite `/crates/{crate}/{version}/download` URLs to
/// `/crates/{crate}/{crate}-{version}.crate`
///
/// cargo versions before 1.24 don't support placeholders in the `dl` field
/// of the index, so we need to rewrite the download URL to point to the
/// crate file instead.
fn rewrite_download_urls(request: &mut Request) {
    static RE: Lazy<Regex> = Lazy::new(|| {
        Regex::new(r"^/crates/(?P<crate>[^/]+)/(?P<version>[^/]+)/download$").unwrap()
    });

    let url = request.get_url_mut();
    let path = url.path();

    if let Some(captures) = RE.captures(path) {
        let krate = captures.name("crate").unwrap().as_str();
        let version = captures.name("version").unwrap().as_str();
        let new_path = format!("/crates/{krate}/{krate}-{version}.crate");
        url.set_path(&new_path);
    }
}

/// Redirect request to CloudFront
///
/// As of early 2023, certain files are too large to be served through Fastly. One of those is the
/// database dump, which gets redirected to CloudFront.
fn redirect_to_cloudfront(config: &Config, path: &str) -> Result<Response, Error> {
    let url = format!("https://{}/{path}", config.cloudfront_url);
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

/// Add CORS headers to response
///
/// We are explicitly adding the three CORS headers to requests that include an `Origin` header to
/// match functionality with CloudFront.
fn add_cors_headers(response: &mut Result<Response, Error>) {
    if let Ok(response) = response {
        response.set_header("Access-Control-Allow-Origin", "*");
        response.set_header("Access-Control-Allow-Methods", "GET");
        response.set_header("Access-Control-Max-Age", "3000");
    }
}


/// Finalize the builder and log the line
fn build_and_send_log(log_line: LogLineV1Builder, config: &Config) {
    match log_line.build() {
        Ok(log) => {
            let versioned_log = LogLine::V1(log);

            [
                &config.datadog_request_logs_endpoint,
                &config.s3_request_logs_endpoint,
            ]
            .iter()
            .for_each(|endpoint| {
                info!(target: endpoint, "{}", json!(versioned_log).to_string());
            });
        }
        Err(error) => {
            warn!("failed to serialize request log: {error}");
        }
    };
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

    fn new_test_config() -> Config {
        Config {
            primary_host: "test_backend".to_string(),
            fallback_host: "fallback_host".to_string(),
            static_ttl: 0,
            cloudfront_url: "cloudfront_url".to_string(),
            datadog_env: "datadog_env".to_string(),
            datadog_host: "datadog_host".to_string(),
            datadog_request_logs_endpoint: "datadog_request_logs_endpoint".to_string(),
            s3_request_logs_endpoint: "s3_request_logs_endpoint".to_string(),
            s3_service_logs_endpoint: "s3_service_logs_endpoint".to_string(),
        }
    }

    #[test]
    fn test_rewrite_download_urls() {
        fn test(url: &str, expected: &str) {
            let mut request = Request::get(url);
            rewrite_download_urls(&mut request);
            assert_eq!(request.get_url_str(), expected);
        }

        test(
            "https://static.crates.io/unrelated",
            "https://static.crates.io/unrelated",
        );
        test(
            "https://static.crates.io/crates/serde/serde-1.0.0.crate",
            "https://static.crates.io/crates/serde/serde-1.0.0.crate",
        );
        test(
            "https://static.crates.io/crates/serde/1.0.0/download",
            "https://static.crates.io/crates/serde/serde-1.0.0.crate",
        );
        test(
            "https://static.crates.io/crates/serde/1.0.0-alpha.1+foo-bar/download",
            "https://static.crates.io/crates/serde/serde-1.0.0-alpha.1+foo-bar.crate",
        );
    }

    /// Ensure plus symbols in crates versions are properly URL encoded (see https://github.com/rust-lang/simpleinfra/pull/313)
    #[test]
    fn test_plus_encoding() {
        // Example taken from the GitHub issue above
        let mut client_req = Request::get("https://static.crates.io/crates/libgit2-sys/libgit2-sys-0.12.25+1.3.0.crate");
        let config = new_test_config();

        rewrite_request(&config, &mut client_req);
        assert_eq!(client_req.get_path(), "/crates/libgit2-sys/libgit2-sys-0.12.25%2B1.3.0.crate");
    }

    /// Ensures visiting version-downloads with and without a trailing slash properly redirects to the index.html
    #[test]
    fn test_version_download_url() {
        let mut client_req = Request::get("https://static.crates.io/archive/version-downloads/");
        let config = new_test_config();
        rewrite_request(&config, &mut client_req);
        assert_eq!(client_req.get_path(), "/archive/version-downloads/index.html");

        let mut client_req = Request::get("https://static.crates.io/archive/version-downloads");
        rewrite_request(&config, &mut client_req);
        assert_eq!(client_req.get_path(), "/archive/version-downloads/index.html");
    }
}
