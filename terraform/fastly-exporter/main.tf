# ECS Express migration for fastly-exporter
# This simplifies the configuration by using aws_ecs_express_gateway_service
# which automatically manages load balancing, networking, and scaling.

locals {
  name = "fastly-exporter"
}

data "aws_ssm_parameter" "fastly_api_token" {
  name = "/prod/fastly-exporter/fastly/api-token"
}

# CloudWatch log group for the service
resource "aws_cloudwatch_log_group" "fastly_exporter" {
  name              = "/ecs/${local.name}"
  retention_in_days = 7
}

# IAM role for ECS task execution (pulling images, writing logs, accessing secrets)
resource "aws_iam_role" "execution" {
  name = "ecs-express-execution--${local.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "execution" {
  role = aws_iam_role.execution.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowParameterStore"
        Effect = "Allow"
        Action = "ssm:GetParameters"
        Resource = data.aws_ssm_parameter.fastly_api_token.arn
      },
      {
        Sid    = "AllowLogs"
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ]
        Resource = "${aws_cloudwatch_log_group.fastly_exporter.arn}:*"
      },
      {
        Sid    = "ECRAuthentication"
        Effect = "Allow"
        Action = "ecr:GetAuthorizationToken"
        Resource = "*"
      }
    ]
  })
}

# IAM role for ECS Express infrastructure management (ALB, target groups, scaling)
resource "aws_iam_role" "infrastructure" {
  name = "ecs-express-infrastructure--${local.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "infrastructure" {
  role       = aws_iam_role.infrastructure.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRolePolicyForVolumes"
}

# Wait for IAM roles to propagate
resource "time_sleep" "wait_for_iam" {
  depends_on = [
    aws_iam_role_policy.execution,
    aws_iam_role_policy_attachment.infrastructure
  ]
  create_duration = "10s"
}

# Security group for the service
resource "aws_security_group" "fastly_exporter" {
  name        = "ecs-express-fastly-exporter"
  description = "Allow Prometheus to scrape the fastly-exporter via ECS Express"
  vpc_id      = data.terraform_remote_state.shared.outputs.ecs_cluster_config.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["52.9.166.219/32"]
    description = "Elastic IP of the monitoring server"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

# ECS Express Gateway Service
resource "aws_ecs_express_gateway_service" "fastly_exporter" {
  service_name            = local.name
  execution_role_arn      = aws_iam_role.execution.arn
  infrastructure_role_arn = aws_iam_role.infrastructure.arn

  primary_container {
    image          = "ghcr.io/fastly/fastly-exporter:v7.4.0"
    container_port = 8080

    aws_logs_configuration {
      log_group = aws_cloudwatch_log_group.fastly_exporter.name
    }

    secrets {
      name       = "FASTLY_API_TOKEN"
      value_from = data.aws_ssm_parameter.fastly_api_token.arn
    }
  }

  network_configuration {
    subnets         = data.terraform_remote_state.shared.outputs.ecs_cluster_config.subnet_ids
    security_groups = [aws_security_group.fastly_exporter.id]
  }

  scaling_target {
    min_task_count            = 1
    max_task_count            = 2
    auto_scaling_metric       = "CPU"
    auto_scaling_target_value = 70
  }

  depends_on = [time_sleep.wait_for_iam]
}
