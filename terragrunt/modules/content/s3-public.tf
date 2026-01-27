locals {
  rust_content_public  = "rust-content-public"
  cloudfront_origin_id = "content"
}

# S3 bucket to store public content, such as podcast episodes.
resource "aws_s3_bucket" "public" {
  bucket = local.rust_content_public
}

# Block all public access paths so S3 is not directly reachable.
resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.public.id

  # Prevent public ACLs from granting access.
  block_public_acls = true
  # Prevent public bucket policies from granting access.
  block_public_policy = true
  # Ignore any public ACLs that might be applied.
  ignore_public_acls = true
  # Restrict public bucket policies.
  restrict_public_buckets = true
}

# Origin access control allowing CloudFront to access S3 privately.
resource "aws_cloudfront_origin_access_control" "public" {
  name                              = local.rust_content_public
  origin_access_control_origin_type = "s3"
  # Require CloudFront to sign all requests.
  signing_behavior = "always"
  # Use SigV4 signing for S3 requests.
  signing_protocol = "sigv4"
}

# Cache policy defining how CloudFront caches responses.
resource "aws_cloudfront_cache_policy" "public" {
  name = local.rust_content_public

  # Allow cached objects to live for at least zero seconds.
  min_ttl = 0
  # Set default cache duration of one day. (seconds)
  default_ttl = 86400
  # Cap cache duration at one year. (seconds)
  max_ttl = 31536000

  # Configure which request values are included in the cache key.
  parameters_in_cache_key_and_forwarded_to_origin {
    # Do not include cookies in the cache key or forward them.
    cookies_config {
      cookie_behavior = "none"
    }

    # Do not include headers except Origin for CORS variance.
    headers_config {
      # Allowlist specific headers in the cache key.
      header_behavior = "whitelist"
      # Include Origin so CORS responses are cached correctly.
      headers {
        items = ["Origin"]
      }
    }

    # Do not include query strings in the cache key or forward them.
    query_strings_config {
      query_string_behavior = "none"
    }

    # Allow Brotli and Gzip in the cache key for compression.
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

# CloudFront distribution that serves content.rust-lang.org.
resource "aws_cloudfront_distribution" "public" {
  comment = local.domain_name

  # Enable the distribution so it serves traffic.
  enabled = true
  # Enable IPv6 for clients that support it.
  is_ipv6_enabled = true
  # Use all edge locations for global performance.
  price_class = "PriceClass_All"

  # Map the custom domain name to this distribution.
  aliases = [local.domain_name]

  # Configure the TLS certificate for the custom domain.
  viewer_certificate {
    # Reference the ACM certificate for content.rust-lang.org.
    acm_certificate_arn = module.certificate.arn
    ssl_support_method  = "sni-only"
    # Enforce a modern TLS minimum version.
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Set the default caching behavior for content requests.
  default_cache_behavior {
    # Route requests to the content origin.
    target_origin_id = local.cloudfront_origin_id
    # Allow only safe read methods.
    allowed_methods = ["GET", "HEAD"]
    # Cache only safe read methods.
    cached_methods = ["GET", "HEAD"]
    # Enable compression to reduce bandwidth.
    compress = true
    # Redirect HTTP requests to HTTPS.
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = aws_cloudfront_cache_policy.public.id
  }

  # Define the S3 origin backed by the private bucket.
  origin {
    # Set a stable origin identifier.
    origin_id   = local.cloudfront_origin_id
    domain_name = aws_s3_bucket.public.bucket_regional_domain_name
    # Attach the OAC so CloudFront can read from S3.
    origin_access_control_id = aws_cloudfront_origin_access_control.public.id
  }

  # Disable geo restrictions to serve globally.
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# Allow only this CloudFront distribution to read from S3.
resource "aws_s3_bucket_policy" "public_cloudfront" {
  bucket = aws_s3_bucket.public.id

  policy = jsonencode({
    Version = "2012-10-17"
    # Define a single read-only statement.
    Statement = [
      {
        Sid = "AllowCloudFrontReadOnlyAccess"
        # Allow the specified principal.
        Effect = "Allow"
        # Restrict access to CloudFront service.
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        # Allow CloudFront to read objects.
        Action = ["s3:GetObject"]
        # Scope access to objects in this bucket.
        Resource = ["${aws_s3_bucket.public.arn}/*"]
        Condition = {
          # Require the request to come from this distribution.
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.public.arn
          }
        }
      }
    ]
  })
}

module "certificate" {
  source = "../acm-certificate"
  providers = {
    aws = aws.us-east-1
  }
  domains = [local.domain_name]
  # Use the subdomain zone managed in this account.
  legacy = false
  # Bypass Route 53 lookups by providing the hosted zone ID directly.
  zone_ids = {
    (local.domain_name) = aws_route53_zone.zone.id
  }
}
