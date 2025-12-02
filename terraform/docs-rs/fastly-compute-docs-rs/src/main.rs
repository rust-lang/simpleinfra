use fastly::{
    Backend, ConfigStore, Error, Request, Response, SecretStore,
    error::anyhow,
    http::{
        HeaderName, Method, StatusCode,
        header::{CACHE_CONTROL, EXPIRES, STRICT_TRANSPORT_SECURITY},
    },
    shielding::Shield,
};

// Should match the backend name in terraform
const DOCS_RS_BACKEND: &str = "docs_rs_origin";

// Should match the secret store name in terraform
const DOCS_RS_SECRET_STORE: &str = "docs_rs_secrets";
// Should match the secret item key in terraform
const ORIGIN_AUTH_KEY: &str = "origin-auth";

// Should match the dictionary name in terraform
const DOCS_RS_CONFIG: &str = "docs_rs_config";
const SHIELD_POP_KEY: &str = "shield_pop";
const HSTS_MAX_AGE_KEY: &str = "hsts_max_age";

const FASTLY_CLIENT_IP: HeaderName = HeaderName::from_static("fastly-client-ip");
const SURROGATE_CONTROL: HeaderName = HeaderName::from_static("surrogate-control");
const X_ORIGIN_AUTH: HeaderName = HeaderName::from_static("x-origin-auth");
const X_COMPRESS_HINT: HeaderName = HeaderName::from_static("x-compress-hint");
const X_FORWARDED_HOST: HeaderName = HeaderName::from_static("x-forwarded-host");

#[fastly::main]
fn main(mut req: Request) -> Result<Response, Error> {
    let config = ConfigStore::open(DOCS_RS_CONFIG);

    let shield_pop = config.get(SHIELD_POP_KEY);
    let shield: Option<Shield> = shield_pop.as_ref().and_then(|pop| match Shield::new(pop) {
        Ok(shield) => Some(shield),
        Err(e) => {
            eprintln!(
                "Could not find shield '{}', Disabling the origin shielding.\n {:?}",
                pop, e
            );
            None
        }
    });

    // default "settings" for this handler, just the client, the edge POP and
    // direct requests to the origin.
    let mut origin_backend = Backend::from_name(DOCS_RS_BACKEND)
        .expect("we know the name is valid, and ::from_name just validates that");
    let mut target_is_origin = true;
    let mut response_is_for_client = true;

    // for now this is very defensive logic around the origin shield.
    // We might simplify it later.
    if let Some(ref shield) = shield {
        // shielding is configured with a valid shield
        if shield.running_on() {
            // and we're running on the shield POP node.
            // -> our client is the fastly edge POP node.
            // -> our target for the request is the origin
            target_is_origin = true;
            response_is_for_client = false;
        } else {
            // we're running on an edge POP node, so the request should go to the shield node.
            // -> our client is the user
            // -> our target is the shield POP
            match shield.encrypted_backend() {
                Ok(shield_backend) => {
                    origin_backend = shield_backend;
                    target_is_origin = false;
                    response_is_for_client = true;
                }
                Err(e) => {
                    // not sure when this can happen. In any case, fall back to a direct request
                    // to the origin.
                    eprintln!(
                        "Could not create backend for shield pop '{:?}'.\n {:?}",
                        shield_pop, e
                    );
                }
            }
        }
    }

    match req.get_method() {
        &Method::GET | &Method::HEAD | &Method::OPTIONS => {
            // for GET/HEAD/OPTIONS request, follow what the backend sends in the headers.
            // Don't apply any default when there are no headers.
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

    if target_is_origin {
        let secrets = SecretStore::open(DOCS_RS_SECRET_STORE).expect("failed to open secret store");
        let origin_auth = secrets
            .get(ORIGIN_AUTH_KEY)
            .expect("failed to get origin auth from secret store")
            .plaintext();

        req.set_header(X_ORIGIN_AUTH, origin_auth.as_ref());
    }

    if req.get_header(X_FORWARDED_HOST).is_none() {
        // when the request doesn't have an X-Forwarded-Host header,
        // set one.
        // When this is a request on a shield POP, we should already
        // get the header from the edge POP, so just pass it on.
        // THe forwarded host (= subdomain) will be needed
        req.set_header(
            X_FORWARDED_HOST,
            req.get_url()
                .host_str()
                .ok_or_else(|| anyhow!("missing hostname in request URL"))?
                .to_owned(),
        );
    }

    if req.get_header(FASTLY_CLIENT_IP).is_none() {
        // when the request doesn't have an Fastly-Client-Ip header, set one.
        // When this is a request on a shield POP, we should already
        // get the header from the edge POP, and just pass it on.
        //
        // https://www.fastly.com/documentation/reference/http/http-headers/Fastly-Client-IP/
        // We intentionally choose this simple header instead of X-Forwarded-For, because we only
        // need the client IP, and not all in between.
        req.set_header(
            FASTLY_CLIENT_IP,
            req.get_client_ip_addr()
                .ok_or_else(|| anyhow!("this is the client request, it should have an IP address"))?
                .to_string(),
        );
    }

    // Send request to backend, shield POP or origin
    let mut resp = req.send(origin_backend)?;

    // set HSTS header
    if response_is_for_client {
        let ttl: u32 = config
            .get(HSTS_MAX_AGE_KEY)
            .and_then(|ttl| ttl.parse().ok())
            .unwrap_or(31_557_600);

        resp.set_header(STRICT_TRANSPORT_SECURITY, format!("max-age={ttl}"));
    }

    // enable dynamic compression at the edge
    // https://www.fastly.com/documentation/guides/concepts/compression/#dynamic-compression
    //
    // We always set this header, assuming it can also help optimizing the transfer between
    // the edge & shield POPs.
    resp.set_header(X_COMPRESS_HINT, "on");

    Ok(resp)
}
