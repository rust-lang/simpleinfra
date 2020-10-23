// Resources used to deploy bors to production.

// Storage for the SQLite database used by bors.

module "efs" {
  source        = "../shared/modules/efs-filesystem"
  name          = "prod--bors"
  allow_subnets = data.terraform_remote_state.shared.outputs.prod_vpc.private_subnets
}

// AWS IAM Role used during the execution of bors, with access to the EFS
// filesystem created earlier.

resource "aws_iam_role" "bors" {
  name = "bors"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECS"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "use_efs" {
  role       = aws_iam_role.bors.name
  policy_arn = module.efs.root_policy_arn
}

// Deployment of the container on ECS

data "aws_ssm_parameter" "bors" {
  for_each = toset([
    "github-token",
    "github-client-id",
    "github-client-secret",
    "ssh-key",
  ])
  name = "/prod/ecs/bors/${each.value}"
}

module "ecs_task" {
  source = "../shared/modules/ecs-task"

  name   = "bors"
  cpu    = 1024
  memory = 2048

  log_retention_days = 7
  ecr_repositories_arns = [
    module.ecr.arn,
  ]

  task_role_arn = aws_iam_role.bors.arn

  containers = jsonencode([
    {
      name      = "app"
      image     = module.ecr.url
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/bors"
          "awslogs-region"        = "us-west-1"
          "awslogs-stream-prefix" = "app"
        }
      }

      secrets = concat(
        [
          {
            name      = "GITHUB_TOKEN"
            valueFrom = data.aws_ssm_parameter.bors["github-token"].arn
          },
          {
            name      = "GITHUB_CLIENT_ID"
            valueFrom = data.aws_ssm_parameter.bors["github-client-id"].arn
          },
          {
            name      = "GITHUB_CLIENT_SECRET"
            valueFrom = data.aws_ssm_parameter.bors["github-client-secret"].arn
          },
          {
            name      = "HOMU_SSH_KEY"
            valueFrom = data.aws_ssm_parameter.bors["ssh-key"].arn
          },
        ],
        [
          for repo in keys(var.repositories) : {
            name      = "HOMU_WEBHOOK_SECRET_${upper(replace(repo, "-", "_"))}"
            valueFrom = aws_ssm_parameter.webhook_secrets[repo].arn
          }
        ]
      )

      mountPoints = [
        {
          sourceVolume  = "efs"
          containerPath = "/efs"
          readOnly      = false
        }
      ]
    }
  ])

  volumes = [
    {
      name           = "efs"
      file_system_id = module.efs.id
      iam            = true
    }
  ]
}

module "ecs_service" {
  source           = "../shared/modules/ecs-service"
  cluster_config   = data.terraform_remote_state.shared.outputs.ecs_cluster_config
  platform_version = "1.4.0"

  name        = "bors"
  task_arn    = module.ecs_task.arn
  tasks_count = 1

  http_container        = "app"
  http_port             = 80
  health_check_path     = "/health"
  health_check_interval = 60
  health_check_timeout  = 50

  domains = concat([var.domain_name], var.legacy_domain_names)
}
