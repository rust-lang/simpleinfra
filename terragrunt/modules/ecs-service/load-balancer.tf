resource "aws_lb_listener_rule" "service" {
  listener_arn = var.cluster_config.lb_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service.arn
  }

  condition {
    host_header {
      values = var.domains
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

  health_check {
    enabled             = true
    path                = var.health_check_path
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}
