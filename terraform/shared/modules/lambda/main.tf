terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      // Allow both 4.x and 5.x while we upgrade everything to 5.x.
      version = ">= 4.20, < 6"
    }
  }
}

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
  timeout       = var.timeout_seconds
  publish       = true

  source_code_hash = data.external.source_zip.result.base64sha256

  dynamic "environment" {
    for_each = length(var.environment) == 0 ? toset([]) : toset([true])
    content {
      variables = var.environment
    }
  }
}
