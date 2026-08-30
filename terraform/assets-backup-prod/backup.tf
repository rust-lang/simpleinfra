variable "aws_access_key_id_crates_io" {
  description = "AWS Access Key ID for crates-io bucket"
  type        = string
}
variable "aws_access_key_id_static_rust_lang_org" {
  description = "AWS Access Key ID for static-rust-lang-org bucket"
  type        = string
}

module "backup" {
  source     = "../shared/modules/assets-backup"
  project_id = "rust-asset-backup-production"
  region     = "europe-west1"
  providers = {
    google = google
  }
  environment = "prod"

  # Source buckets to backup - production AWS S3 buckets
  source_buckets = {
    crates-io = {
      bucket_name = "crates-io"
      # cloudfront-static.crates.io
      cloudfront_id     = "d19xqa3lc3clo8"
      description       = "Production crates-io bucket"
      aws_access_key_id = var.aws_access_key_id_crates_io
    }
    static-rust-lang-org = {
      bucket_name = "static-rust-lang-org"
      # cloudfront-static.rust-lang.org
      cloudfront_id     = "d3ah34wvbudrdd"
      description       = "Production Rust releases"
      aws_access_key_id = var.aws_access_key_id_static_rust_lang_org
    }
  }
}