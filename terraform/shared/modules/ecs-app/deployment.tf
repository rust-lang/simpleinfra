// IAM Role used during the execution of the application, granting all
// permissions needed at runtime.

resource "aws_iam_role" "task" {
  name = var.name
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

// IAM Role used during the startup of the application, granting all
// permissions needed while creating the task.

resource "aws_iam_role" "task_execution" {
  name = "ecs-task-execution--${var.name}"
  assume_role_policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = "ECS"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "task_execution" {
  role = aws_iam_role.task_execution.name
  name = "permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      // Access to SSM Parameter Store
      {
        Sid    = "AllowParameterStore"
        Effect = "Allow"
        Action = "ssm:GetParameters"

        Resource = concat(
          values(data.aws_ssm_parameter.task).*.arn,
          values(var.computed_secrets),
        )
      },

      // Access to CloudWatch Logs
      {
        Sid    = "AllowLogs"
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
        ]
        Resource = "${aws_cloudwatch_log_group.task.arn}:*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_ecr_pull" {
  role       = aws_iam_role.task_execution.name
  policy_arn = module.ecr.policy_pull_arn
}

// EFS filesystem used for persistent storage across tasks. The filesystem is
// created only if it's meant to be mounted inside the tasks.

module "efs" {
  for_each = var.mount_efs == null ? toset([]) : toset([var.name])
  source   = "../efs-filesystem"

  name          = "${var.env}--${var.name}"
  allow_subnets = var.cluster_config.subnet_ids
}

resource "aws_iam_role_policy_attachment" "use_efs" {
  for_each = var.mount_efs == null ? toset([]) : toset([var.name])

  role       = aws_iam_role.task.name
  policy_arn = module.efs[var.name].root_policy_arn
}

// Task definition of the application, which specifies which containers should
// be part of the task and which settings do they have.

data "aws_ssm_parameter" "task" {
  for_each = toset(values(var.secrets))
  name     = each.value
}

resource "aws_cloudwatch_log_group" "task" {
  name              = "/${var.env}/${var.name}"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "task" {
  family       = var.name
  cpu          = var.cpu
  memory       = var.memory
  network_mode = "awsvpc"

  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.task_execution.arn
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = module.ecr.url
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.task.name
          "awslogs-region"        = "us-west-1"
          "awslogs-stream-prefix" = "app"
        }
      }

      environment = [
        for name, value in var.environment :
        {
          name  = name
          value = value
        }
      ]

      secrets = concat(
        [
          for name, param in var.secrets :
          {
            name      = name
            valueFrom = data.aws_ssm_parameter.task[param].arn
          }
        ],
        [
          for name, param in var.computed_secrets :
          {
            name      = name
            valueFrom = param
          }
        ],
      )

      portMappings = var.expose_http == null ? [] : [
        {
          containerPort = var.expose_http.container_port
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      mountPoints = var.mount_efs == null ? [] : [
        {
          sourceVolume  = "efs"
          containerPath = var.mount_efs
          readOnly      = false
        }
      ]

      dockerLabels = var.expose_http == null || var.expose_http.prometheus == null ? {} : {
        PROMETHEUS_EXPORTER_PORT     = 80
        PROMETHEUS_EXPORTER_PATH     = var.expose_http.prometheus
        PROMETHEUS_EXPORTER_JOB_NAME = "ecs-${var.name}"
      }
    }
  ])

  dynamic "volume" {
    for_each = module.efs
    content {
      name = "efs"
      efs_volume_configuration {
        file_system_id     = volume.value.id
        root_directory     = "/"
        transit_encryption = "ENABLED"

        authorization_config {
          iam = "ENABLED"
        }
      }
    }
  }
}

// Service of the application, which schedules the application to run on the
// cluster.

module "ecs_service" {
  source           = "../ecs-service"
  cluster_config   = var.cluster_config
  platform_version = var.platform_version

  name        = var.name
  task_arn    = aws_ecs_task_definition.task.arn
  tasks_count = var.tasks_count

  http_container = "app"
  http_port      = 80
  domains        = var.expose_http.domains

  health_check_path     = var.expose_http.health_check_path
  health_check_interval = var.expose_http.health_check_interval
  health_check_timeout  = var.expose_http.health_check_timeout

  additional_security_group_ids = var.additional_security_group_ids
}
