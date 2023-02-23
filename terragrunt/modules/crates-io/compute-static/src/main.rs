use fastly::http::{Method, StatusCode};
use fastly::{Error, Request, Response};
use log::warn;

use crate::config::Config;

mod config;

#[fastly::main]
fn main(mut request: Request) -> Result<Response, Error> {
    let config = Config::from_dictionary();

    if let Some(response) = limit_http_methods(&request) {
        return Ok(response);
    }

    set_ttl(&config, &mut request);

    // Database dump is too big to cache on Fastly
    if request.get_url_str().ends_with("db-dump.tar.gz") {
        redirect_db_dump_to_cloudfront(&config)
    } else {
        send_request_to_s3(&config, &request)
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
