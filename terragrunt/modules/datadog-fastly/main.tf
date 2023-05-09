data "aws_ssm_parameter" "fastly_api_key" {
  name            = "/prod/datadog-fastly/fastly-api-key"
  with_decryption = false
}

resource "datadog_integration_fastly_account" "account" {
  name    = "Rust Foundation"
  api_key = data.aws_ssm_parameter.fastly_api_key.value
}

resource "datadog_integration_fastly_service" "service" {
  for_each = var.services

  account_id = datadog_integration_fastly_account.account.id
  service_id = each.key

  tags = [
    "env:${each.value.env}"
  ]
}
