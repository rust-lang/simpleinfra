resource "aws_cloudfront_response_headers_policy" "mdbook" {
  name    = "MdbookSitePolicy"
  comment = "Policy for hosted mdbook-style websites"

  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    xss_protection {
      protection = true
      mode_block = true
      override   = true
    }
    referrer_policy {
      referrer_policy = "no-referrer"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = 63072000
      override                   = true
    }
  }
}
