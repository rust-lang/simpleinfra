locals {
  bors_rust_lang_org = "bors.rust-lang.org"
}

resource "aws_ecr_repository" "primary" {
  name                 = "bors"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository_policy" "policy" {
  repository = aws_ecr_repository.primary.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.gha.arn
        }
        Action = [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "policy" {
  repository = aws_ecr_repository.primary.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Delete 14 days after untagged"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_iam_openid_connect_provider" "gh_oidc" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  // Not actually used today, AWS has its own store of allowed certs
  thumbprint_list = ["1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

resource "aws_iam_role" "gha" {
  name = "gha-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = aws_iam_openid_connect_provider.gh_oidc.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : "${var.trusted_sub}"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  inline_policy {
    name = "allow-ecr-push"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "GetAuthorizationToken"
          Effect = "Allow"
          Action = [
            "ecr:GetAuthorizationToken",
            "ecs:UpdateService",
            # Used to wait until the service is stable
            "ecs:DescribeServices"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

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

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
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

resource "aws_iam_role" "runtime" {
  name = "bors-app"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
          StringEquals = {
            "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_ssm" {
  role       = aws_iam_role.runtime.name
  policy_arn = aws_iam_policy.ssm_access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_ecr" {
  role       = aws_iam_role.runtime.name
  policy_arn = data.aws_iam_policy.AmazonECSTaskExecutionRolePolicy.arn
}

data "aws_iam_policy" "AmazonECSTaskExecutionRolePolicy" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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

resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/bors/db-endpoint"
  type  = "SecureString"
  value = "postgres://${aws_db_instance.primary.username}:${aws_db_instance.primary.password}@${aws_db_instance.primary.endpoint}/bors"
}

data "aws_ssm_parameter" "webhook_secret" {
  name            = "/bors/webhook-secret"
  with_decryption = false
}

data "aws_ssm_parameter" "app_key" {
  name            = "/bors/app-private-key"
  with_decryption = false
}

data "aws_ssm_parameter" "oauth_client_secret" {
  name            = "/bors/oauth-client-secret"
  with_decryption = false
}

resource "aws_iam_policy" "ssm_access" {
  name        = "ecs_ssm_access"
  path        = "/"
  description = "Access to SSM secrets for ECS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "ssm:GetParameters"
        Effect = "Allow"
        Resource = [
          data.aws_ssm_parameter.app_key.arn,
          data.aws_ssm_parameter.webhook_secret.arn,
          aws_ssm_parameter.db_endpoint.arn,
          data.aws_ssm_parameter.oauth_client_secret.arn
        ]
      }
    ]

  })
}


resource "aws_lb_target_group" "primary" {
  name_prefix = "bors"
  port        = 8080
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

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
  alpn_policy       = "HTTP1Only"

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

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_db_instance" "primary" {
  db_name                 = "bors"
  engine                  = "postgres"
  engine_version          = "16.9"
  instance_class          = "db.t4g.micro"
  backup_retention_period = 7

  allow_major_version_upgrade = true

  # Make the instance accessible from outside the VPC.
  # This is needed because bastion is in the legacy AWS account.
  publicly_accessible = true

  vpc_security_group_ids = [aws_security_group.rds.id]

  username = "bors"
  password = random_password.db.result

  allocated_storage = 30
  storage_type      = "gp3"
}

resource "random_password" "db" {
  length  = 32
  special = false
}

resource "aws_security_group" "rds" {
  name        = "rds"
  description = "Allow necessary communication for rds database"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "bastion" {
  security_group_id = aws_security_group.rds.id

  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"
  # Bastion is in the legacy AWS account, so we hardcode its IP address.
  cidr_ipv4   = "13.57.121.61/32"
  description = "Connections from the bastion"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_ecs" {
  security_group_id = aws_security_group.rds.id

  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 0
  ip_protocol                  = "TCP"
  to_port                      = 5432
}

resource "aws_vpc_security_group_egress_rule" "rds_egress_anywhere_v4" {
  security_group_id = aws_security_group.rds.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = -1
  ip_protocol = -1
  to_port     = -1
}

resource "aws_vpc_security_group_egress_rule" "rds_egress_anywhere_v6" {
  security_group_id = aws_security_group.rds.id

  cidr_ipv6   = "::/0"
  from_port   = -1
  ip_protocol = -1
  to_port     = -1
}

variable "domain" {
  description = "domain to use"
}

variable "gh_app_id" {
  description = "GitHub App ID"
}

variable "trusted_sub" {
  description = "GitHub OIDC claim"
}

variable "oauth_client_id" {
  description = "OAuth client ID"
}

variable "public_url" {
  description = "Public URL for the bors instance. Used in GitHub comments."
}

variable "cpu" {
  description = "How much CPU should be allocated to the bors instance."
}

variable "memory" {
  description = "How much memory should be allocated to the bors instance."
}
