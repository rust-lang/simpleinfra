terraform {
  source = "../../../../modules//crates-io"
  # Marco removed the deployed ref because too annoying. If you need it, feel free to add it back
  # source = "git::../../../../..//terragrunt/modules/crates-io?ref=${trimspace(file("../deployed-ref"))}"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  env = "prod"

  webapp_domain_name = "crates.io"
  static_domain_name = "static.crates.io"
  index_domain_name  = "index.crates.io"
  dns_apex           = true

  static_bucket_name     = "crates-io"
  index_bucket_name      = "crates-io-index"

  static_ttl = 31536000 // 1 year

  webapp_origin_domain = "crates-io.herokuapp.com"

  iam_prefix = "crates-io"

  strict_security_headers = true

  static_cloudfront_weight = 0
  static_fastly_weight = 255

  index_cloudfront_weight = 1
  index_fastly_weight = 255

  webapp_cloudfront_weight = 50
  webapp_fastly_weight = 50

  cdn_log_event_queue_arn = "arn:aws:sqs:us-west-1:365596307002:cdn-log-event-queue"
}
