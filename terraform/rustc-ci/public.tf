module "public" {
  source = "./impl"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  iam_prefix = "ci--rust-lang--rust"
  repo       = "rust-lang-ci/rust"

  caches_bucket    = "rust-lang-ci-sccache2"
  caches_domain    = "ci-caches.rust-lang.org"
  artifacts_bucket = "rust-lang-ci2"
  artifacts_domain = "ci-artifacts.rust-lang.org"

  buckets_public_access = true

  delete_caches_after_days    = 90
  delete_artifacts_after_days = 168
}
