provider "archive" {}

locals {
  zip_name = "modules/lambda/packages/${var.name}.zip"
}

data "archive_file" "source" {
  type        = "zip"
  output_path = local.zip_name
  source_dir  = var.source_dir
}

resource "aws_lambda_function" "lambda" {
  filename      = local.zip_name
  function_name = var.name
  handler       = var.handler
  role          = var.role_arn
  runtime       = var.runtime
  publish       = true

  source_code_hash = data.archive_file.source.output_base64sha256
}
