# One-off migration from Terragrunt, which ran the module as the root module.
# These blocks move the existing state into `module.dns_zone`. Delete this file
# once the configuration has been applied.

moved {
  from = aws_route53_zone.zone
  to   = module.dns_zone.aws_route53_zone.zone
}
