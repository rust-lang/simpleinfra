module "backup" {
  source     = "../shared/modules/assets-backup"
  project_id = "concrete-racer-468119-m7"
  region     = "europe-west1"
  providers = {
    google = google
  }
  environment = "dev"

  # Source buckets to backup - staging AWS S3 buckets
  source_buckets = {
    crates-io = {
      bucket_name = "staging-crates-io"
      # cloudfront-static.staging.crates.io
      cloudfront_id     = "d23cyymnjtuccx"
      description       = "Staging crates for testing"
      aws_access_key_id = "AKIA46X5W6CZBSN3RGGN"
    }
    static-rust-lang-org = {
      bucket_name = "dev-static-rust-lang-org"
      # dev-static.rust-lang.org
      cloudfront_id     = "d29bglnmyg6h72"
      description       = "Development Rust releases"
      aws_access_key_id = "AKIA46X5W6CZC6PEZ36Z"
    }
  }
}
