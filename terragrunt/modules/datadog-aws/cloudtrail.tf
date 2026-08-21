module "organization_cloudtrail" {
  count  = var.cloudtrail_datadog_api_key_secret_name == null ? 0 : 1
  source = "./cloudtrail"

  datadog_api_key_secret_name = var.cloudtrail_datadog_api_key_secret_name
}
