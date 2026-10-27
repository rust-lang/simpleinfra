locals {
  # Existing token shared by the registry watcher and builders.
  github_token_parameter = "/docs-rs/github-access-token"
  github_token_arn       = data.aws_ssm_parameter.github_token.arn
  sentry_dsn_parameter   = "/docs-rs/sentry-dsn"

  # Shared defaults for docs.rs containers. Tasks can merge in their own
  # environment settings or override these defaults as needed.
  common_environment = {
    DOCSRS_PREFIX             = "/tmp"
    DOCSRS_STORAGE_BACKEND    = "s3"
    DOCSRS_S3_BUCKET          = aws_s3_bucket.storage.id
    S3_REGION                 = aws_s3_bucket.storage.region
    DOCSRS_LOG                = "info"
    DOCSRS_LOG_FORMAT         = "json"
    RUST_BACKTRACE            = "1"
    SENTRY_ENVIRONMENT        = var.sentry_environment
    SENTRY_TRACES_SAMPLE_RATE = tostring(var.sentry_traces_sample_rate)
  }

  common_computed_secrets = {
    DOCSRS_DATABASE_URL = aws_ssm_parameter.connection_url.arn
    SENTRY_DSN          = data.aws_ssm_parameter.sentry_dsn.arn
  }
}

resource "aws_ssm_parameter" "connection_url" {
  name  = "/docs-rs/database-url"
  type  = "SecureString"
  value = "postgres://${local.docs_rs_username}:${random_password.db.result}@${aws_db_instance.db.address}/${local.docs_rs_db_name}?sslmode=require"
}

# Only the ARN is needed; do not decrypt the token during Terraform runs.
data "aws_ssm_parameter" "github_token" {
  name            = local.github_token_parameter
  with_decryption = false
}

# Supply the DSN in each account's Parameter Store, outside Terraform.
data "aws_ssm_parameter" "sentry_dsn" {
  name            = local.sentry_dsn_parameter
  with_decryption = false
}
