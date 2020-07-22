// Resources used to deploy RLA to production.

module "efs" {
  source        = "../shared/modules/efs-filesystem"
  name          = "prod--rust-log-analyzer"
  allow_subnets = data.terraform_remote_state.shared.outputs.prod_vpc.private_subnets
}

data "aws_ssm_parameter" "rla" {
  for_each = toset([
    "github-token",
    "webhook-secret",
  ])
  name = "/prod/ecs/rust-log-analyzer/${each.value}"
}

resource "aws_iam_role" "rla" {
  name = "rust-log-analyzer"

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
  role       = aws_iam_role.rla.name
  policy_arn = module.efs.root_policy_arn
}

module "ecs_task" {
  source = "../shared/modules/ecs-task"

  name   = "rust-log-analyzer"
  cpu    = 256
  memory = 512

  log_retention_days = 7
  ecr_repositories_arns = [
    module.ecr.arn,
  ]

  task_role_arn = aws_iam_role.rla.arn

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
          "awslogs-group"         = "/ecs/rust-log-analyzer"
          "awslogs-region"        = "us-west-1"
          "awslogs-stream-prefix" = "app"
        }
      }

      environment = [
        {
          name  = "CI_REPO"
          value = "rust-lang/rust"
        },
        {
          name  = "CI_PROVIDER"
          value = "actions"
        },
        {
          name  = "EXTRA_ARGS"
          value = "--secondary-repo rust-lang-ci/rust"
        },
        {
          name  = "GITHUB_USER"
          value = "rust-log-analyzer"
        },
        {
          name  = "INDEX_FILE"
          value = "/opt/rla/rust-lang/rust/actions.idx"
        },
        {
          name  = "RLA_LOG"
          value = "rla_server=trace,rust_log_analyzer=trace"
        },
      ]

      secrets = [
        {
          name      = "GITHUB_TOKEN"
          valueFrom = data.aws_ssm_parameter.rla["github-token"].arn
        },
        {
          name      = "GITHUB_WEBHOOK_SECRET"
          valueFrom = data.aws_ssm_parameter.rla["webhook-secret"].arn
        },
      ]

      mountPoints = [
        {
          sourceVolume  = "efs"
          containerPath = "/opt/rla"
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

  name        = "rust-log-analyzer"
  task_arn    = module.ecs_task.arn
  tasks_count = 1

  http_container = "app"
  http_port      = 80

  domains = [
    "rla.infra.rust-lang.org",
  ]
}
