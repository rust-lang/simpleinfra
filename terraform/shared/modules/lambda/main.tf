provider "external" {}

data "aws_region" "current" {}

data "external" "source_zip" {
  program = ["${path.module}/pack.py"]
  query = {
    source_dir  = var.source_dir,
    destination = "${path.module}/packages/${data.aws_region.current.name}/${var.name}.zip"
  }
}

resource "aws_lambda_function" "lambda" {
  filename      = data.external.source_zip.result.path
  function_name = var.name
  handler       = var.handler
  role          = var.role_arn
  runtime       = var.runtime
  publish       = true

  source_code_hash = data.external.source_zip.result.base64sha256
}
