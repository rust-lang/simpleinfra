data "aws_iam_role" "cloudfront_lambda" {
  name = "cloudfront-lambda"
}

data "aws_route53_zone" "static" {
  // Convert foo.bar.baz into bar.baz
  name = join(".", reverse(slice(reverse(split(".", var.static_domain_name)), 0, 2)))
}

data "aws_s3_bucket" "static" {
  bucket = var.static_bucket
}

data "aws_s3_bucket" "logs" {
  bucket = var.log_bucket
}

data "aws_ssm_parameter" "datadog_api_key" {
  name            = "/${var.environment}/promote-release/datadog-api-key"
}

data "aws_ssm_parameter" "fastly_customer_id" {
  name            = "/${var.environment}/promote-release/fastly-customer-id"
  with_decryption = false
}
