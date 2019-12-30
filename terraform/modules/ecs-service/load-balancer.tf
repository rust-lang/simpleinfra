module "certificate" {
  source  = "../acm-certificate"
  domains = var.domains
}

resource "aws_lb_listener_certificate" "service" {
  listener_arn    = var.cluster_config.lb_listener_arn
  certificate_arn = module.certificate.arn
}

resource "aws_lb_listener_rule" "service" {
  listener_arn = var.cluster_config.lb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service.arn
  }

  condition {
    host_header {
      values = keys(var.domains)
    }
  }
}

resource "aws_lb_target_group" "service" {
  name        = var.name
  vpc_id      = var.cluster_config.vpc_id
  target_type = "ip"

  port     = var.http_port
  protocol = "HTTP"

  deregistration_delay = 30
}

resource "aws_route53_record" "service" {
  for_each = var.domains

  zone_id = each.value
  name    = each.key
  type    = "CNAME"
  ttl     = 300
  records = [var.cluster_config.lb_dns_name]
}
