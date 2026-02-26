resource "aws_ecs_cluster" "primary" {
  name = "bors"
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.bors.name
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "bors" {
  name              = "bors"
  retention_in_days = 14
}

resource "aws_ecs_cluster_capacity_providers" "fargate" {
  cluster_name = aws_ecs_cluster.primary.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_service" "bors" {
  name             = "bors"
  cluster          = aws_ecs_cluster.primary.id
  task_definition  = aws_ecs_task_definition.bors.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  enable_ecs_managed_tags = true

  load_balancer {
    target_group_arn = aws_lb_target_group.primary.arn
    container_name   = "bors"
    container_port   = 8080
  }

  network_configuration {
    subnets         = data.aws_subnets.public.ids
    security_groups = [aws_security_group.ecs.id]
    // TODO: We assign a public IP address so that the service communicate
    // to all the services it needs (e.g., SSM and ECR). Eventually, we'd
    // like to shut down public access to the ecs service, but the work
    // around is tediuous.
    assign_public_ip = true
  }
}

resource "aws_security_group" "ecs" {
  name        = "ecs-task-network"
  description = "Allow necessary communication for bors ECS tasks"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "ingress_lb" {
  for_each          = toset(data.aws_subnets.public.ids)
  security_group_id = aws_security_group.ecs.id

  cidr_ipv4   = data.aws_subnet.public[each.value].cidr_block
  from_port   = 0
  ip_protocol = "TCP"
  to_port     = 8080
}

resource "aws_vpc_security_group_egress_rule" "egress_anywhere_v4" {
  security_group_id = aws_security_group.ecs.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = -1
  ip_protocol = -1
  to_port     = -1
}

resource "aws_vpc_security_group_egress_rule" "egress_anywhere_v6" {
  security_group_id = aws_security_group.ecs.id

  cidr_ipv6   = "::/0"
  from_port   = -1
  ip_protocol = -1
  to_port     = -1
}

resource "aws_ecs_task_definition" "bors" {
  family                   = "bors"
  cpu                      = var.cpu
  memory                   = var.memory
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  task_role_arn      = aws_iam_role.runtime.arn
  execution_role_arn = aws_iam_role.runtime.arn

  container_definitions = jsonencode([
    {
      name      = "bors"
      image     = aws_ecr_repository.primary.repository_url
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.bors.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "bors"
        }
      }

      portMappings = [{
        protocol      = "tcp"
        containerPort = 8080
        hostPort      = 8080
      }]

      environment = [
        {
          name  = "APP_ID"
          value = "${var.gh_app_id}"
        },
        {
          name  = "RUST_LOG"
          value = "bors=trace"
        },
        {
          name  = "CMD_PREFIX",
          value = "@bors"
        },
        {
          name  = "WEB_URL",
          value = "https://${var.public_url}"
        },
        {
          name  = "OAUTH_CLIENT_ID",
          value = "${var.oauth_client_id}"
        }
      ]

      secrets = [
        {
          name      = "WEBHOOK_SECRET"
          valueFrom = data.aws_ssm_parameter.webhook_secret.arn
        },
        {
          name      = "PRIVATE_KEY"
          valueFrom = data.aws_ssm_parameter.app_key.arn
        },
        {
          name      = "DATABASE_URL"
          valueFrom = aws_ssm_parameter.db_endpoint.arn
        },
        {
          name      = "OAUTH_CLIENT_SECRET"
          valueFrom = data.aws_ssm_parameter.oauth_client_secret.arn
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
        timeout     = 10
        startPeriod = 10
      }
    }
  ])
}
