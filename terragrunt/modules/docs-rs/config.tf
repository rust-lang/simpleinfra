locals {
  # Shared defaults for docs.rs containers. Tasks can merge in their own
  # environment settings or override these defaults as needed.
  common_environment = {
    DOCSRS_PREFIX          = "/tmp"
    DOCSRS_STORAGE_BACKEND = "s3"
    DOCSRS_S3_BUCKET       = aws_s3_bucket.storage.id
    S3_REGION              = aws_s3_bucket.storage.region
    DOCSRS_LOG             = "info"
    DOCSRS_LOG_FORMAT      = "json"
    RUST_BACKTRACE         = "1"
  }

  common_computed_secrets = {
    DOCSRS_DATABASE_URL = aws_ssm_parameter.connection_url.arn
  }
}

resource "aws_ssm_parameter" "connection_url" {
  name  = "/docs-rs/database-url"
  type  = "SecureString"
  value = "postgres://${local.docs_rs_username}:${random_password.db.result}@${aws_db_instance.db.address}/${local.docs_rs_db_name}?sslmode=require"
}
