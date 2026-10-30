data "aws_ssm_parameter" "docsrs_authorization_token" {
  name            = "/${var.env}/crates-io/webapp/docsrs-auth-token"
  with_decryption = true
}
