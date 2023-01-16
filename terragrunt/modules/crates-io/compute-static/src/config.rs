use fastly::ConfigStore;

// Name of the dictionary. Must match the dictionary in `fastly-static.tf`.
const DICTIONARY_NAME: &str = "compute_static";

// Name of the dictionary item with the name of the primary host.
const PRIMARY_HOST: &str = "s3-primary-host";

// Name of the dictionary item with the name of the fallback host.
const FALLBACK_HOST: &str = "s3-fallback-host";

// Name of the dictionary item with the TTL for the static bucket
const STATIC_TTL: &str = "static-ttl";

#[derive(Debug)]
pub struct Config {
    pub primary_host: String,
    pub fallback_host: String,
    pub static_ttl: u32,
}

impl Config {
    pub fn from_dictionary() -> Self {
        let dictionary = ConfigStore::open(DICTIONARY_NAME);

        // Lookup S3 hosts for current environment
        let primary_host = dictionary
            .get(PRIMARY_HOST)
            .expect("failed to get S3 primary host from dictionary");
        let fallback_host = dictionary
            .get(FALLBACK_HOST)
            .expect("failed to get S3 fallback host from dictionary");
        let static_ttl = dictionary
            .get(STATIC_TTL)
            .expect("failed to get TTL for the static bucket from dictionary")
            .parse()
            .expect("failed to parse TTL for the static bucket");

        Self {
            primary_host,
            fallback_host,
            static_ttl,
        }
    }
}
