use fastly::{
    Error, Request, Response, SecretStore,
    http::{
        HeaderName, Method, StatusCode,
        header::{CACHE_CONTROL, EXPIRES, STRICT_TRANSPORT_SECURITY},
    },
};

// Should match the backend name in terraform
const DOCS_RS_BACKEND: &str = "docs_rs_origin";
// Should match the secret store name in terraform
const DOCS_RS_SECRET_STORE: &str = "docs_rs_secrets";
// Should match the secret item key in terraform
const ORIGIN_AUTH_KEY: &str = "origin-auth";

const SURROGATE_CONTROL: HeaderName = HeaderName::from_static("surrogate-control");
const X_ORIGIN_AUTH: HeaderName = HeaderName::from_static("x-origin-auth");
const X_COMPRESS_HINT: HeaderName = HeaderName::from_static("x-compress-hint");

const X_RLNG_SOURCE_CDN: HeaderName = HeaderName::from_static("x-rlng-source-cdn");

#[fastly::main]
fn main(mut req: Request) -> Result<Response, Error> {
    let secrets = SecretStore::open(DOCS_RS_SECRET_STORE).expect("failed to open secret store");
    let origin_auth = secrets
        .get(ORIGIN_AUTH_KEY)
        .expect("failed to get origin auth from secret store")
        .plaintext();

    match req.get_method() {
        &Method::GET | &Method::HEAD | &Method::OPTIONS => {
            req.set_after_send(|response_candidate| {
                // By design, fastly caching happens _before_ the response ends up back in our code here.
                // (below, at `let mut response = req.send(backend)?`).
                //
                // In the case that the origin/backend doesnt contain any caching headers,
                // fastly will apply a default TTL.
                //
                // We don't want this.
                //
                // So we will check if the backend response has any caching header, and if it doesn't,
                // set the response to be uncacheable.
                //
                // If any backend wants anything to be cached, it has to set the appropriate caching
                // headers.
                //
                // Related docs:
                // https://www.fastly.com/documentation/guides/concepts/edge-state/cache/#controlling-cache-behavior-based-on-backend-response
                let has_any_cache_headers = [CACHE_CONTROL, SURROGATE_CONTROL, EXPIRES]
                    .iter()
                    .any(|header| response_candidate.contains_header(header));

                if !has_any_cache_headers {
                    response_candidate.set_uncacheable(
                        // `true` here means that we want to prevent request collapsing until we
                        // get the next cacheable response.
                        // About request collapsing:
                        // https://www.fastly.com/documentation/guides/concepts/edge-state/cache/request-collapsing/
                        true,
                    );
                }
                Ok(())
            });
        }
        &Method::PUT | &Method::POST | &Method::PATCH | &Method::DELETE => {
            // Do not cache other methods
            req.set_pass(true);
        }
        _ => {
            return Ok(Response::from_status(StatusCode::METHOD_NOT_ALLOWED));
        }
    }

    req.set_header(X_ORIGIN_AUTH, origin_auth.as_ref());
    req.set_header(X_RLNG_SOURCE_CDN, "fastly");

    // Send request to backend
    let mut resp = req.send(DOCS_RS_BACKEND)?;

    // set HSTS header
    resp.set_header(
        STRICT_TRANSPORT_SECURITY,
        // FIXME: this should be made configurable for test environments
        "max-age=31557600",
    );

    // enable dynamic compression at the edge
    // https://www.fastly.com/documentation/guides/concepts/compression/#dynamic-compression
    resp.set_header(X_COMPRESS_HINT, "on");

    Ok(resp)
}
