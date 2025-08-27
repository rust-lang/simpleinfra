terraform {
  source = "../../../modules//rust-assets-backup"
}

include {
  path = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  project_id  = "concrete-racer-468119-m7"
  region      = "europe-west1"

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

  # TODO: add the rest of the infra admins
  # infra admins can have admin access to staging for testing/development
  admins = [
    "jandavidnose@rustfoundation.org",
    "joelmarcey@rustfoundation.org",
    "marcoieni@rustfoundation.org",
    "walterpearce@rustfoundation.org"
  ]

  viewers = [
  ]
}
