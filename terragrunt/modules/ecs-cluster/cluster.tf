locals {
  // Each service is configured through a separate instance of the "./service"
  // module, and each instance needs access to a bunch of variables. To avoid
  // repeating ourselves, all those variables are grouped in this local
  // variable, which is passed as a whole to the module.
  cluster_config = {
    cluster_id                = aws_ecs_cluster.cluster.id
    lb_listener_arn           = aws_lb_listener.lb_https.arn
    lb_dns_name               = aws_lb.lb.dns_name
    service_security_group_id = aws_security_group.service.id
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_ecs_cluster_capacity_providers" "provider" {
  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
  }
}

// This security group is used by all the services hosted on the cluster: it
// only allows ingress HTTP connections from members of the load balancer
// security group, and allows any egress.
resource "aws_security_group" "service" {
  name        = "${var.cluster_name}-service"
  description = "Allow HTTP requests from the load balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
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
