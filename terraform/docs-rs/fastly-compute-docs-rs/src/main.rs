use fastly::{
    ConfigStore, Error, Request, Response, SecretStore,
    http::{Method, StatusCode},
};

// Should match the backend name in terraform
const DOCS_RS_BACKEND: &str = "docs_rs_origin";
// Should match the secret store name in terraform
const DOCS_RS_SECRET_STORE: &str = "docs_rs_secrets";
// Should match the dictionary name in terraform
const DOCS_RS_DICTIONARY: &str = "docs_rs_config";
// Should match the secret item key in terraform
const ORIGIN_AUTH_KEY: &str = "origin-auth";

#[fastly::main]
fn main(mut req: Request) -> Result<Response, Error> {
    let config = ConfigStore::open(DOCS_RS_DICTIONARY);
    let ttl: u32 = config
        .get("ttl")
        .expect("failed to get TTL from config store")
        .parse::<u32>()
        .expect("invalid TTL in config store (expected unsigned integer)");
    let secrets = SecretStore::open(DOCS_RS_SECRET_STORE).expect("failed to open secret store");
    let origin_auth = secrets
        .get(ORIGIN_AUTH_KEY)
        .expect("failed to get origin auth from secret store")
        .plaintext();

    match req.get_method() {
        &Method::GET | &Method::HEAD | &Method::OPTIONS => {
            // Both Cloudfront and Fastly should have a TTL of one year
            req.set_ttl(ttl);
        }
        &Method::PUT | &Method::POST | &Method::PATCH | &Method::DELETE => {
            // Do not cache other methods
            req.set_pass(true);
        }
        _ => {
            return Ok(Response::from_status(StatusCode::METHOD_NOT_ALLOWED));
        }
    }

    req.set_header("X-Origin-Auth", origin_auth.as_ref());

    // Send request to backend
    let mut resp = req.send(DOCS_RS_BACKEND)?;

    // Prevent indexing by search engines
    // TODO: remove this when we are ready to go live with fastly
    resp.set_header("X-Robots-Tag", "noindex, nofollow");

    Ok(resp)
}
