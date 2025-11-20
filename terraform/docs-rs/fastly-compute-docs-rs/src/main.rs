use fastly::{
    Error, Request, Response, SecretStore,
    http::{
        HeaderName, Method, StatusCode,
        header::{CACHE_CONTROL, EXPIRES},
    },
};

// Should match the backend name in terraform
const DOCS_RS_BACKEND: &str = "docs_rs_origin";
// Should match the secret store name in terraform
const DOCS_RS_SECRET_STORE: &str = "docs_rs_secrets";
// Should match the secret item key in terraform
const ORIGIN_AUTH_KEY: &str = "origin-auth";

const SURROGATE_CONTROL: HeaderName = HeaderName::from_static("surrogate-control");
const X_ROBOTS_TAG: HeaderName = HeaderName::from_static("x-robots-tag");
const X_ORIGIN_AUTH: HeaderName = HeaderName::from_static("x-origin-auth");

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

    // Send request to backend
    let mut resp = req.send(DOCS_RS_BACKEND)?;

    // Prevent indexing by search engines
    // TODO: remove this when we are ready to go live with fastly
    resp.set_header(X_ROBOTS_TAG, "noindex, nofollow");

    Ok(resp)
}
