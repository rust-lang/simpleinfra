variable "crates_io_aws_access_key_id" {
  type = string
}

variable "static_rust_lang_org_aws_access_key_id" {
  type = string
}

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
      aws_access_key_id = var.crates_io_aws_access_key_id
    }
    static-rust-lang-org = {
      bucket_name = "dev-static-rust-lang-org"
      # cloudfront-dev-static.rust-lang.org
      cloudfront_id     = "d29bglnmyg6h72"
      description       = "Development Rust releases"
      aws_access_key_id = var.static_rust_lang_org_aws_access_key_id
    }
  }
}