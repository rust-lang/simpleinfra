use compute_static::compression::is_compressible_content_type;
use fastly::convert::ToHeaderValue;
use fastly::http::{header, Method, StatusCode};
use fastly::log::Endpoint;
use fastly::{Error, Request, Response};
use fastly_access_log::{collect_request, collect_response};
use log::{warn, LevelFilter};
use log_fastly::Logger;

use crate::config::Config;

mod config;

const DATADOG_APP: &str = "crates.io";
const DATADOG_SERVICE: &str = "static.crates.io";
const VERSION_DOWNLOADS: &str = "/archive/version-downloads/";
const VERSION_DOWNLOADS_INDEX: &str = "/archive/version-downloads/index.html";
const X_COMPRESS_HINT: &str = "X-Compress-Hint";

#[fastly::main]
fn main(request: Request) -> Result<Response, Error> {
    let config = Config::from_dictionary();

    // Forward purge requests immediately to a backend
    // https://developer.fastly.com/learning/concepts/purging/#forwarding-purge-requests
    if request.get_method() == "PURGE" {
        return send_request_to_s3(&config, &request);
    }

    init_logging(&config);
    let mut log = collect_request(
        &request,
        DATADOG_SERVICE,
        DATADOG_APP,
        &config.datadog_env,
        Some(config.datadog_host.clone()),
    );

    let has_origin_header = request.get_header("Origin").is_some();
    let mut response = handle_request(&config, request);

    if has_origin_header {
        add_cors_headers(&mut response);
    }

    let log = collect_response(&mut log, &response);
    if let Err(err) = fastly_access_log::build_and_send_log(
        log,
        [
            Endpoint::from_name(&config.datadog_request_logs_endpoint),
            Endpoint::from_name(&config.s3_request_logs_endpoint),
        ],
    ) {
        warn!("error emitting access logs: \n{err}");
    }

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

    if request.get_url().path() == "/archive/version-downloads" {
        let mut destination = request.get_url().clone();
        destination.set_path(VERSION_DOWNLOADS);

        return Ok(permanent_redirect(destination));
    }

    set_ttl(config, &mut request);
    set_surrogate_keys(&mut request);
    rewrite_urls_with_plus_character(&mut request);
    rewrite_download_urls(&mut request);
    rewrite_version_downloads_urls(&mut request);

    // Database dump is too big to cache on Fastly
    let url = request.get_url_str();
    if url.ends_with("db-dump.tar.gz") {
        redirect_to_cloudfront(config, "db-dump.tar.gz")
    } else if url.ends_with("db-dump.zip") {
        redirect_to_cloudfront(config, "db-dump.zip")
    } else {
        send_request_to_s3(config, &request)
    }
}

fn permanent_redirect(destination: impl ToHeaderValue) -> Response {
    Response::new()
        .with_status(StatusCode::PERMANENT_REDIRECT)
        .with_header(header::LOCATION, destination)
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

/// Set the surrogate keys
///
/// The crates.io backend attaches a comma-separated list of cache tags (e.g.
/// `crate:serde,release:serde@1.0.0`) to the S3 objects as `cache-tags` metadata, which S3
/// surfaces as the `x-amz-meta-cache-tags` response header. A callback is registered to read the
/// header before the response is cached and translate it into surrogate keys, so that e.g. all
/// cached files of a crate can be purged with a single request. The header is removed from the
/// response in the process, since it is an origin-internal detail.
fn set_surrogate_keys(request: &mut Request) {
    request.set_after_send(|candidate| {
        if candidate.get_status().is_success() {
            if let Some(tags) = candidate.remove_header_str("x-amz-meta-cache-tags") {
                candidate.set_surrogate_keys(parse_cache_tags(&tags));
            }
        }
        Ok(())
    });
}

/// Split a comma-separated `cache-tags` metadata value into individual cache tags
fn parse_cache_tags(tags: &str) -> impl Iterator<Item = &str> {
    tags.split(',').map(str::trim).filter(|tag| !tag.is_empty())
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
    let mut url = request.get_url_mut();
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
    let mut url = request.get_url_mut();
    let path = url.path();

    if path == VERSION_DOWNLOADS {
        url.set_path(VERSION_DOWNLOADS_INDEX);
    }
}

/// Rewrite `/crates/{crate}/{version}/download` URLs to
/// `/crates/{crate}/{crate}-{version}.crate`
///
/// cargo versions before 1.24 don't support placeholders in the `dl` field
/// of the index, so we need to rewrite the download URL to point to the
/// crate file instead.
fn rewrite_download_urls(request: &mut Request) {
    let mut url = request.get_url_mut();
    let path = url.path();

    if let Some(crates_path) = path.strip_prefix("/crates/") {
        // crates_path = "{crate}/{version}/download"
        let Some((krate, rest)) = crates_path.split_once('/') else {
            return;
        };

        // krate = "{crate}"
        // rest = "{version}/download"
        let Some(version) = rest.strip_suffix("/download") else {
            return;
        };

        // version = "{version}"
        if krate.is_empty() || version.is_empty() || version.contains('/') {
            return;
        }

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

    if let Some(response) = unsatisfiable_range_response(&response) {
        return Ok(response);
    }

    enable_dynamic_compression(request, &mut response);

    // Automatic framing derives downstream framing from the response body and
    // discards S3's Content-Length. This is normally necessary because downstream
    // transformations such as client-negotiated compression can change the
    // representation. For HEAD, preserve the origin length only when the
    // equivalent GET is ineligible for dynamic compression.
    if should_preserve_framing_headers(request, &response) {
        response.set_framing_headers_mode(fastly::http::FramingHeadersMode::ManuallyFromHeaders);
    }

    Ok(response)
}

/// Return an empty 416 response when a partial response starts at or beyond EOF.
///
/// Fastly's Compute cache can return a reversed byte range and the complete body for such requests.
/// See https://github.com/rust-lang/crates.io/issues/13159.
fn unsatisfiable_range_response(response: &Response) -> Option<Response> {
    if response.get_status() != StatusCode::PARTIAL_CONTENT {
        return None;
    }

    let content_range = response.get_header(header::CONTENT_RANGE)?.to_str().ok()?;
    let (range, length) = content_range.strip_prefix("bytes ")?.split_once('/')?;
    let (start, end) = range.split_once('-')?;
    let start = start.parse::<u64>().ok()?;
    end.parse::<u64>().ok()?;
    let length = length.parse::<u64>().ok()?;

    if start < length {
        return None;
    }

    Some(
        Response::new()
            .with_status(StatusCode::RANGE_NOT_SATISFIABLE)
            .with_header(header::CONTENT_RANGE, format!("bytes */{length}")),
    )
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

fn enable_dynamic_compression(request: &Request, response: &mut Response) {
    if request.get_method() != Method::GET
        || !is_eligible_for_dynamic_compression(request, response)
    {
        return;
    }

    response.set_header(X_COMPRESS_HINT, "on");
    response.append_header(header::VARY, "Accept-Encoding");
}

/// Whether a HEAD response can preserve the origin's framing headers.
///
/// Preserve S3's `Content-Length` only when the equivalent GET is structurally ineligible for
/// dynamic compression. Intentionally do not inspect `Accept-Encoding`: Fastly owns that automatic
/// negotiation. Omitting `Content-Length` for eligible HEAD responses is valid and safer
/// than forwarding a potentially stale value.
fn should_preserve_framing_headers(request: &Request, response: &Response) -> bool {
    request.get_method() == Method::HEAD && !is_eligible_for_dynamic_compression(request, response)
}

fn is_eligible_for_dynamic_compression(request: &Request, response: &Response) -> bool {
    if request.contains_header(header::RANGE)
        || response.get_status() != StatusCode::OK
        || response.contains_header(header::CONTENT_ENCODING)
    {
        return false;
    }

    let Some(content_type) = response.get_content_type() else {
        return false;
    };

    is_compressible_content_type(&content_type)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_unsatisfiable_range_response() {
        for content_range in [
            "bytes 278076-278075/278076",
            "bytes 278077-278075/278076",
            "bytes 18446744073709551615-278075/278076",
        ] {
            let response = Response::from_body("complete archive")
                .with_status(StatusCode::PARTIAL_CONTENT)
                .with_header(header::CONTENT_RANGE, content_range)
                .with_header(header::CONTENT_LENGTH, "278076")
                .with_header(header::CACHE_CONTROL, "public,max-age=31536000,immutable");

            let mut response = unsatisfiable_range_response(&response).unwrap();
            assert_eq!(response.get_status(), StatusCode::RANGE_NOT_SATISFIABLE);
            assert_eq!(
                response.get_header_str(header::CONTENT_RANGE),
                Some("bytes */278076")
            );
            assert!(response.take_body().into_bytes().is_empty());
            assert!(response.get_header(header::CONTENT_LENGTH).is_none());
            assert!(response.get_header(header::CACHE_CONTROL).is_none());
        }
    }

    #[test]
    fn test_unsatisfiable_range_response_preserves_other_responses() {
        for content_range in [
            None,
            Some("bytes 278075-278075/278076"),
            Some("bytes 0-0/278076"),
            Some("bytes 278076-278075/*"),
            Some("bytes */278076"),
            Some("bytes 278076-invalid/278076"),
            Some("bytes 18446744073709551616-278075/278076"),
            Some("bytes 278076-278075/18446744073709551616"),
            Some("items 278076-278075/278076"),
        ] {
            let mut response = Response::from_body("partial archive")
                .with_status(StatusCode::PARTIAL_CONTENT)
                .with_header(header::CONTENT_LENGTH, "1");
            if let Some(content_range) = content_range {
                response.set_header(header::CONTENT_RANGE, content_range);
            }

            assert!(unsatisfiable_range_response(&response).is_none());
            assert_eq!(response.take_body().into_string(), "partial archive");
        }

        let content_range = b"bytes 278076-278075/\xff".as_slice();
        let response = Response::new()
            .with_status(StatusCode::PARTIAL_CONTENT)
            .with_header(header::CONTENT_RANGE, content_range);
        assert!(unsatisfiable_range_response(&response).is_none());

        for status in [
            StatusCode::OK,
            StatusCode::RANGE_NOT_SATISFIABLE,
            StatusCode::INTERNAL_SERVER_ERROR,
        ] {
            let response = Response::new()
                .with_status(status)
                .with_header(header::CONTENT_RANGE, "bytes 278076-278075/278076");
            assert!(unsatisfiable_range_response(&response).is_none());
        }
    }

    #[test]
    fn test_parse_cache_tags() {
        fn test(input: &str, expected: &[&str]) {
            assert_eq!(parse_cache_tags(input).collect::<Vec<_>>(), expected);
        }

        test(
            "crate:serde,release:serde@1.0.0",
            &["crate:serde", "release:serde@1.0.0"],
        );
        test("crate:serde", &["crate:serde"]);
        test(
            " crate:serde , release:serde@1.0.0 ",
            &["crate:serde", "release:serde@1.0.0"],
        );
        test("", &[]);
        test(" , ", &[]);
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
        test(
            "https://static.crates.io/crates/serde//download",
            "https://static.crates.io/crates/serde//download",
        );
        test(
            "https://static.crates.io/crates/serde/1.0.0/download/extra",
            "https://static.crates.io/crates/serde/1.0.0/download/extra",
        );
        test(
            "https://static.crates.io/crates/serde/1.0.0/extra/download",
            "https://static.crates.io/crates/serde/1.0.0/extra/download",
        );
    }
}
