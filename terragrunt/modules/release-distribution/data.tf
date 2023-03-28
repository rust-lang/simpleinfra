data "aws_iam_role" "cloudfront_lambda" {
  name = "cloudfront-lambda"
}

data "aws_s3_bucket" "static" {
  bucket = var.static_bucket
}

data "aws_s3_bucket" "logs" {
  bucket = var.log_bucket
}
