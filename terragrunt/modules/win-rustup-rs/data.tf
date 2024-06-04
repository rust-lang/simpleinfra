data "aws_iam_role" "cloudfront_lambda" {
  name = "cloudfront-lambda"
}

data "aws_route53_zone" "rustup" {
  // Convert {dev-win,win}.rustup.rs into rustup.rs
  name = join(".", reverse(slice(reverse(split(".", var.domain_name)), 0, 2)))
}

data "aws_s3_bucket" "static" {
  bucket = var.static_bucket
}
