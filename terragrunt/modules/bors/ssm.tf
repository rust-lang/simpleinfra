resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/bors/db-endpoint"
  type  = "SecureString"
  value = "postgres://${aws_db_instance.primary.username}:${aws_db_instance.primary.password}@${aws_db_instance.primary.endpoint}/bors"
}

data "aws_ssm_parameter" "webhook_secret" {
  name            = "/bors/webhook-secret"
  with_decryption = false
}

data "aws_ssm_parameter" "app_key" {
  name            = "/bors/app-private-key"
  with_decryption = false
}

data "aws_ssm_parameter" "oauth_client_secret" {
  name            = "/bors/oauth-client-secret"
  with_decryption = false
}
