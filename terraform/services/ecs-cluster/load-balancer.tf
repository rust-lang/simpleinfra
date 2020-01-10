// The ECS cluster uses an Application Load Balancer to forward requests to the
// containers in the cluster. We use a load balancer as that gets us HTTPS,
// redirects from HTTP and the ability to have multiple containers serving the
// same application.

resource "aws_lb" "lb" {
  name               = var.cluster_name
  load_balancer_type = "application"
  subnets            = var.load_balancer_subnet_ids
  security_groups    = [aws_security_group.lb.id]
  ip_address_type    = "dualstack"

  tags = {
    Name = var.cluster_name
  }
}

data "aws_route53_zone" "zone" {
  // Convert foo.bar.baz into bar.baz
  name = join(".", reverse(slice(reverse(split(".", var.load_balancer_domain)), 0, 2)))
}

resource "aws_route53_record" "lb" {
  zone_id = data.aws_route53_zone.zone.id
  name    = var.load_balancer_domain
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.lb.dns_name]
}

resource "aws_security_group" "lb" {
  name        = "${var.cluster_name}-load-balancer"
  description = "Allow incoming traffic for the load balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.cluster_name}-load-balancer"
  }
}

// The behavior for HTTP requests is to forward to the same host and path, but
// with the HTTPS protocol.

resource "aws_lb_listener" "lb_http" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

// The default behavior for HTTPS requests is to return a plaintext 404 page,
// as containers will add their own listening rules in separate files.
//
// Unfortunately the load balancer requires a default TLS certificate to be
// configured, even if all the routes point to other hosts with their own
// certificates. Because of that we create a certificate for the "load balancer
// domain": that domain will always serve the 404 page when visited.

module "default_lb_certificate" {
  source = "../../modules/acm-certificate"

  domains = [
    var.load_balancer_domain,
  ]
}

resource "aws_lb_listener" "lb_https" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-1-2017-01" // TLSv1.1
  certificate_arn   = module.default_lb_certificate.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "There is no backend configured for this route.\n"
      status_code  = "404"
    }
  }
}

