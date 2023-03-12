locals {
  domain = "confirmation.sync-team-prod.rust-lang.net"
}

data "aws_ssm_parameter" "confirmation_parameters" {
  for_each = toset([
    "/prod/sync-team-confirmation/github-oauth-client-id",
    "/prod/sync-team-confirmation/github-oauth-client-secret",
  ])

  name = each.value
  // We don't need the actual value, just their ARNs:
  with_decryption = false
}

module "lambda_confirmation" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "sync-team-confirmation"
  description   = "Out-of-band confirmation before applying sync-team changes."
  handler       = "index.handler"
  runtime       = "python3.9"
  publish       = true

  source_path = "lambdas/sync-team-confirmation"

  create_lambda_function_url = true

  // While the module supports attaching an inline policy here, in practice we
  // cannot attach it here as it'd create a circular dependency between the
  // CodeBuild build and the Lambda policy.
}

resource "aws_iam_policy" "lambda_confirmation" {
  name        = "sync-team-confirmation"
  description = "Policy for the sync-team-confirmation Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "codebuild:StartBuild"
        Resource = aws_codebuild_project.sync_team.arn
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters"],
        Resource = [for p in data.aws_ssm_parameter.confirmation_parameters : p.arn]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_confirmation" {
  role       = module.lambda_confirmation.lambda_role_name
  policy_arn = aws_iam_policy.lambda_confirmation.arn
}

module "confirmation_certificate" {
  source  = "../acm-certificate"
  providers = {
    aws = aws.us-east-1
  }
  domains = [local.domain]
  legacy  = false
}

resource "aws_cloudfront_distribution" "confirmation" {
  comment = local.domain

  enabled             = true
  wait_for_deployment = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  http_version        = "http2and3"

  aliases = [local.domain]
  viewer_certificate {
    acm_certificate_arn      = module.confirmation_certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  default_cache_behavior {
    target_origin_id       = "lambda"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    default_ttl = 0
    max_ttl     = 0

    forwarded_values {
      headers      = []
      query_string = true
      cookies {
        forward = "none"
      }
    }
  }

  origin {
    origin_id   = "lambda"
    domain_name = trimsuffix(trimprefix(module.lambda_confirmation.lambda_function_url, "https://"), "/")
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

data "aws_route53_zone" "confirmation_zone" {
  name = "sync-team-prod.rust-lang.net"
}

resource "aws_route53_record" "confirmation_record" {
  zone_id = data.aws_route53_zone.confirmation_zone.id
  name    = "confirmation"
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.confirmation.domain_name]
}
