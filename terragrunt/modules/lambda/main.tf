# Package the Lambda source directory into a deterministic zip file
data "external" "source_zip" {
  program = ["${path.module}/pack.py"]
  query = {
    source_dir  = var.source_dir,
    destination = var.destination
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 14
}

resource "aws_lambda_function" "this" {
  filename      = data.external.source_zip.result.path
  function_name = var.name
  # For Rust, the handler is not used, but AWS requires a value.
  handler = "bootstrap"
  role    = aws_iam_role.lambda.arn
  # We use an OS-only Runtime (amazon linux)
  runtime          = "provided.al2023"
  architectures    = ["arm64"]
  timeout          = var.lambda_timeout
  publish          = true
  source_code_hash = data.external.source_zip.result.base64sha256

  dynamic "environment" {
    for_each = length(var.environment) == 0 ? toset([]) : toset([true])
    content {
      variables = var.environment
    }
  }
}
