// Configure all static websites hosted in our AWS account.

module "static_website_ci_mirrors" {
  source = "./modules/static-website"
  providers = {
    aws = "aws.east1"
  }

  domain_name        = "ci-mirrors.rust-lang.org"
  dns_zone           = aws_route53_zone.rust_lang_org.id
  origin_domain_name = aws_s3_bucket.rust_lang_ci_mirrors.bucket_regional_domain_name
}
