use fastly::{
    Error, Request, Response,
    http::{Method, StatusCode},
};

const ONE_YEAR_IN_SECONDS: u32 = 31536000;
// Should match the backend name in terraform
const DOCS_RS_BACKEND: &str = "docs_rs_origin";

#[fastly::main]
fn main(mut req: Request) -> Result<Response, Error> {
    match req.get_method() {
        &Method::GET | &Method::HEAD | &Method::OPTIONS => {
            // Both Cloudfront and Fastly should have a TTL of one year
            req.set_ttl(ONE_YEAR_IN_SECONDS);
        }
        &Method::PUT | &Method::POST | &Method::PATCH | &Method::DELETE => {
            // Do not cache other methods
            req.set_pass(true);
        }
        _ => {
            return Ok(Response::from_status(StatusCode::METHOD_NOT_ALLOWED));
        }
    }

    // Send request to backend
    let mut resp = req.send(DOCS_RS_BACKEND)?;

    // Prevent indexing by search engines
    // TODO: remove this when we are ready to go live with fastly
    resp.set_header("X-Robots-Tag", "noindex, nofollow");

    Ok(resp)
}
