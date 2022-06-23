resource "aws_cloudfront_response_headers_policy" "cache-immutable" {
  name = "cache-immutable"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      override = true
      value    = "immutable, max-age=9999999"
    }
  }
}
