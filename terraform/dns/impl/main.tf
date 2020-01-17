// A Route53 zone is the container for all the DNS records of a domain. We
// create one for the domain managed by this module, allowing us to add records
// to it later in the file.

resource "aws_route53_zone" "zone" {
  name    = var.domain
  comment = "[terraform] ${var.comment}"
}

// Each record requested in the module variables is then added to the zone
// previously created. If you need to add a kind of record not currently
// supported you'll need to both create a resource here and a variable in
// `variables.tf`.

resource "aws_route53_record" "a" {
  for_each = var.A

  zone_id = aws_route53_zone.zone.id
  name    = each.key == "@" ? "${var.domain}." : "${each.key}.${var.domain}."
  type    = "A"
  ttl     = var.ttl
  records = each.value
}

resource "aws_route53_record" "cname" {
  for_each = var.CNAME

  zone_id = aws_route53_zone.zone.id
  name    = each.key == "@" ? "${var.domain}." : "${each.key}.${var.domain}."
  type    = "CNAME"
  ttl     = var.ttl
  records = each.value
}

resource "aws_route53_record" "txt" {
  for_each = var.TXT

  zone_id = aws_route53_zone.zone.id
  name    = each.key == "@" ? "${var.domain}." : "${each.key}.${var.domain}."
  type    = "TXT"
  ttl     = var.ttl
  records = each.value
}

resource "aws_route53_record" "mx" {
  for_each = var.MX

  zone_id = aws_route53_zone.zone.id
  name    = each.key == "@" ? "${var.domain}." : "${each.key}.${var.domain}."
  type    = "MX"
  ttl     = var.ttl
  records = each.value
}
