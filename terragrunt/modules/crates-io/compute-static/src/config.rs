use fastly::ConfigStore;

// Name of the dictionary. Must match the dictionary in `fastly-static.tf`.
const DICTIONARY_NAME: &str = "compute_static";

// Name of the dictionary item with the CloudFront URL
const CLOUDFRONT_URL: &str = "cloudfront-url";

// Name of the dictionary item with the name of the primary host.
const PRIMARY_HOST: &str = "s3-primary-host";

// Name of the dictionary item with the name of the fallback host.
const FALLBACK_HOST: &str = "s3-fallback-host";

// Name of the dictionary item with the TTL for the static bucket
const STATIC_TTL: &str = "static-ttl";

// Name of the directory item with the logging endpoint for requests
const REQUEST_LOGS_ENDPOINT: &str = "request-logs-endpoint";

// Name of the directory item with the logging endpoint for the worker
const SERVICE_LOGS_ENDPOINT: &str = "service-logs-endpoint";

#[derive(Debug)]
pub struct Config {
    pub primary_host: String,
    pub fallback_host: String,
    pub static_ttl: u32,
    pub cloudfront_url: String,
    pub request_logs_endpoint: String,
    pub service_logs_endpoint: String,
}

impl Config {
    pub fn from_dictionary() -> Self {
        let dictionary = ConfigStore::open(DICTIONARY_NAME);

        // Look up S3 hosts for current environment
        let primary_host = dictionary
            .get(PRIMARY_HOST)
            .expect("failed to get S3 primary host from dictionary");
        let fallback_host = dictionary
            .get(FALLBACK_HOST)
            .expect("failed to get S3 fallback host from dictionary");

        // Look up time to cache crates
        let static_ttl = dictionary
            .get(STATIC_TTL)
            .expect("failed to get TTL for the static bucket from dictionary")
            .parse()
            .expect("failed to parse TTL for the static bucket");
        let cloudfront_url = dictionary
            .get(CLOUDFRONT_URL)
            .expect("failed to get CloudFront URL from dictionary");

        // Look up the endpoints for logging
        let request_logs_endpoint = dictionary
            .get(REQUEST_LOGS_ENDPOINT)
            .expect("failed to get endpoint for request logs from dictionary");
        let service_logs_endpoint = dictionary
            .get(SERVICE_LOGS_ENDPOINT)
            .expect("failed to get endpoint for service logs from dictionary");

        Self {
            primary_host,
            fallback_host,
            static_ttl,
            cloudfront_url,
            request_logs_endpoint,
            service_logs_endpoint,
        }
    }
}
