// This terraform module imports all the services from the services/ directory,
// and configures them.

module "prod" {
  source = "./impl"
  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
    aws.eu-west-1 = aws.eu-west-1
  }

  webapp_domain_name = "crates.io"
  static_domain_name = "static.crates.io"
  index_domain_name  = "index.crates.io"
  dns_apex           = true

  static_bucket_name     = "crates-io"
  index_bucket_name      = "crates-io-index"
  inventories_bucket_arn = data.terraform_remote_state.shared.outputs.inventories_bucket_arn

  webapp_origin_domain = "crates-io.herokuapp.com"

  iam_prefix = "crates-io"

  strict_security_headers = true
}

module "staging" {
  source = "./impl"
  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
    aws.eu-west-1 = aws.eu-west-1
  }

  webapp_domain_name = "staging.crates.io"
  static_domain_name = "static.staging.crates.io"
  index_domain_name  = "index.staging.crates.io"

  static_bucket_name     = "staging-crates-io"
  index_bucket_name      = "staging-crates-io-index"
  inventories_bucket_arn = data.terraform_remote_state.shared.outputs.inventories_bucket_arn

  webapp_origin_domain = "staging-crates-io.herokuapp.com"

  iam_prefix = "staging-crates-io"

  strict_security_headers = true
}
