resource "aws_route53_zone" "zone" {
  name    = var.domain
  comment = "[terraform] ${var.comment}"
}

resource "aws_route53_record" "a" {
  for_each = var.A

  zone_id = aws_route53_zone.zone.id
  name    = each.key
  type    = "A"
  ttl     = var.ttl
  records = each.value
}

resource "aws_route53_record" "cname" {
  for_each = var.CNAME

  zone_id = aws_route53_zone.zone.id
  name    = each.key
  type    = "CNAME"
  ttl     = var.ttl
  records = each.value
}

resource "aws_route53_record" "txt" {
  for_each = var.TXT

  zone_id = aws_route53_zone.zone.id
  name    = each.key
  type    = "TXT"
  ttl     = var.ttl
  records = each.value
}

resource "aws_route53_record" "mx" {
  for_each = var.MX

  zone_id = aws_route53_zone.zone.id
  name    = each.key
  type    = "MX"
  ttl     = var.ttl
  records = each.value
}
