data "aws_route53_zone" "rust_lang_org" {
  name = "rust-lang.org"
}

resource "aws_route53_record" "ipv4" {
  for_each = var.instances

  zone_id = data.aws_route53_zone.rust_lang_org.id
  name    = "${each.key}.infra.rust-lang.org"
  type    = "A"
  records = [azurerm_public_ip.v4[each.key].ip_address]
  ttl     = 60
}
