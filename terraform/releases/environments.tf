// Definition of the dev and production environments.
//
// The environments are completly separate, with no configuration shared
// between them. This reduces the chances of compromise between them.

resource "aws_s3_bucket" "logs" {
  bucket = "rust-release-logs"
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "yearly-delete"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    expiration {
      days = 330
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "dev" {
  source = "./impl"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  name = "dev"

  bucket             = "dev-static-rust-lang-org"
  static_domain_name = "dev-static.rust-lang.org"

  cloudfront_static_id = "E30AO2GXMDY230"
  cloudfront_doc_id    = "E3BB4EZOGX5YED"

  inventories_bucket_arn   = data.terraform_remote_state.shared.outputs.inventories_bucket_arn
  promote_release_ecr_repo = module.promote_release_ecr
  release_keys_bucket_arn  = aws_s3_bucket.release_keys.arn

  extra_environment_variables = toset([
    {
      name  = "PROMOTE_RELEASE_DISCOURSE_API_USER"
      value = "system"
      type  = "PLAINTEXT"
    },
    {
      name  = "PROMOTE_RELEASE_DISCOURSE_API_KEY"
      value = "/prod/promote-release/discourse-api-key"
      type  = "PARAMETER_STORE"
    }
  ])

  promote_release_cron = {}
}

module "prod" {
  source = "./impl"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  name = "prod"

  bucket             = "static-rust-lang-org"
  static_domain_name = "static.rust-lang.org"

  cloudfront_static_id = "E3NZU1LCBHH4A4"
  cloudfront_doc_id    = "ECO8GQQ6UCG66"

  inventories_bucket_arn   = data.terraform_remote_state.shared.outputs.inventories_bucket_arn
  promote_release_ecr_repo = module.promote_release_ecr
  release_keys_bucket_arn  = aws_s3_bucket.release_keys.arn

  extra_environment_variables = toset([
    // Setting this enables tagging of releases, so we only do it for the production
    // bucket. dev releases shouldn't create tags.
    {
      name  = "PROMOTE_RELEASE_RUSTC_TAG_REPOSITORY"
      value = "rust-lang/rust"
      type  = "PLAINTEXT"
    },
    {
      name  = "PROMOTE_RELEASE_DISCOURSE_API_USER"
      value = "system"
      type  = "PLAINTEXT"
    },
    {
      name  = "PROMOTE_RELEASE_DISCOURSE_API_KEY"
      value = "/prod/promote-release/users-discourse-api-key"
      type  = "PARAMETER_STORE"
    }
  ])

  promote_release_cron = {
    "nightly" = "cron(0 0 * * ? *)"
    "beta"    = "cron(0 0 * * ? *)"
  }
}
