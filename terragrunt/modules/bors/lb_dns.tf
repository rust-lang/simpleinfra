resource "aws_lb_target_group" "primary" {
  name_prefix = "bors"
  port        = 8080
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  # How many seconds to stay in the deregistering (or deactivating) state.
  # In this state, the load balancer sends no requests to the target.
  # So this delay should be long enough to allow in-flight connections to
  # complete.
  # After this delay, the ECS task enters the stopping state, and ECS
  # sends the SIGTERM signal to the container, so that it can shutdown gracefully.
  # See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-lifecycle-explanation.html
  deregistration_delay = 30

  health_check {
    # delay between each health check attempt
    interval            = 10
    unhealthy_threshold = 2
    protocol            = "TCP"
    healthy_threshold   = 3
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "primary" {
  name               = "bors"
  internal           = false
  load_balancer_type = "network"
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = true
}

resource "aws_lb_listener" "primary" {
  load_balancer_arn = aws_lb.primary.arn
  port              = "443"
  protocol          = "TLS"
  certificate_arn   = aws_acm_certificate.primary.arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  alpn_policy       = "HTTP2Preferred"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.primary.arn
  }
}

resource "aws_acm_certificate" "primary" {
  domain_name = var.domain
  # Allow the load balancer to accept HTTPS connections for bors.rust-lang.org
  subject_alternative_names = var.domain == "bors-prod.rust-lang.net" ? [local.bors_rust_lang_org] : []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "net" {
  name         = var.domain
  private_zone = false
}

# Don't create Route53 record for bors.rust-lang.org because it is managed in the legacy AWS account.
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.primary.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    } if dvo.domain_name != local.bors_rust_lang_org
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.net.zone_id
}

resource "aws_acm_certificate_validation" "primary" {
  certificate_arn = aws_acm_certificate.primary.arn
  # Include both Terraform-managed FQDNs and manually-managed ones (e.g., bors.rust-lang.org in the legacy account)
  validation_record_fqdns = [for dvo in aws_acm_certificate.primary.domain_validation_options : dvo.resource_record_name]
}

resource "aws_route53_record" "lb" {
  zone_id = data.aws_route53_zone.net.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_lb.primary.dns_name
    zone_id                = aws_lb.primary.zone_id
    evaluate_target_health = true
  }

  allow_overwrite = true
}
