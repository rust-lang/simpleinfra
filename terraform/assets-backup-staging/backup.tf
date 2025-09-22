module "backup" {
  source     = "../shared/modules/assets-backup"
  project_id = "concrete-racer-468119-m7"
  region     = "europe-west1"
  providers = {
    google = google
  }

  # Source buckets to backup - staging AWS S3 buckets
  source_buckets = {
    crates-io = {
      bucket_name       = "staging-crates-io"
      cloudfront_domain = "cloudfront-static.staging.crates.io"
      description       = "Staging crates for testing"
    }
    static-rust-lang-org = {
      bucket_name       = "dev-static-rust-lang-org"
      cloudfront_domain = "cloudfront-dev-static.rust-lang.org"
      description       = "Development Rust releases"
    }
  }
}
