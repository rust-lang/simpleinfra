module "dns_zone" {
  source = "../../../../terragrunt/modules/dns-zone"

  name = "bors-prod.rust-lang.net"
}
