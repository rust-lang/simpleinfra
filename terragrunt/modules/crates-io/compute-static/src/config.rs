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

// Name of the directory item with the Datadog environment tag
const DATADOG_ENV: &str = "datadog-env";

// Name of the directory item with the Datadog host tag
const DATADOG_HOST: &str = "datadog-host";

// Name of the directory item with the Datadog logging endpoint for requests
const DATADOG_REQUEST_LOGS_ENDPOINT: &str = "datadog-request-logs-endpoint";

// Name of the directory item with the S3 logging endpoint for requests
const S3_REQUEST_LOGS_ENDPOINT: &str = "s3-request-logs-endpoint";

// Name of the directory item with the S3 logging endpoint for the worker
const S3_SERVICE_LOGS_ENDPOINT: &str = "s3-service-logs-endpoint";

#[derive(Debug)]
pub struct Config {
    pub primary_host: String,
    pub fallback_host: String,
    pub static_ttl: u32,
    pub cloudfront_url: String,
    pub datadog_env: String,
    pub datadog_host: String,
    pub datadog_request_logs_endpoint: String,
    pub s3_request_logs_endpoint: String,
    pub s3_service_logs_endpoint: String,
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
        let datadog_request_logs_endpoint = dictionary
            .get(DATADOG_REQUEST_LOGS_ENDPOINT)
            .expect("failed to get endpoint for request logs from dictionary");
        let s3_request_logs_endpoint = dictionary
            .get(S3_REQUEST_LOGS_ENDPOINT)
            .expect("failed to get endpoint for request logs from dictionary");
        let s3_service_logs_endpoint = dictionary
            .get(S3_SERVICE_LOGS_ENDPOINT)
            .expect("failed to get endpoint for service logs from dictionary");

        // Look up the tags for Datadog
        let datadog_env = dictionary
            .get(DATADOG_ENV)
            .expect("failed to get Datadog environment tag from dictionary");
        let datadog_host = dictionary
            .get(DATADOG_HOST)
            .expect("failed to get Datadog host tag from dictionary");

        Self {
            primary_host,
            fallback_host,
            static_ttl,
            cloudfront_url,
            datadog_env,
            datadog_host,
            datadog_request_logs_endpoint,
            s3_request_logs_endpoint,
            s3_service_logs_endpoint,
        }
    }
}
