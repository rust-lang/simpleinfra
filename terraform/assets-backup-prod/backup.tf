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
      cloudfront_id     = "d1e8qr2bsg2yo9"
      description       = "Production crates-io bucket"
      aws_access_key_id = "AKIA46X5W6CZJH2GD7UE"
    }
    static-rust-lang-org = {
      bucket_name = "static-rust-lang-org"
      # cloudfront-static.rust-lang.org
      cloudfront_id     = "d3ah34wvbudrdd"
      description       = "Production Rust releases"
      aws_access_key_id = "AKIA46X5W6CZK2NZZU4U"
    }
  }
}
