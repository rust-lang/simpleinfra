module "dns_zone" {
  source = "../../../../terragrunt/modules/dns-zone"

  name = "bors-staging.rust-lang.net"
}
