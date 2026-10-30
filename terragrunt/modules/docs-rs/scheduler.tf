resource "aws_scheduler_schedule_group" "docs_rs" {
  name = "docs-rs"
}

resource "aws_iam_role" "scheduler" {
  name = "docs-rs-scheduler"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "scheduler.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = local.account_id
          "aws:SourceArn"     = aws_scheduler_schedule_group.docs_rs.arn
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "scheduler" {
  name = "run-docs-rs-tasks"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecs:RunTask"]
        Resource = "arn:${data.aws_partition.builder.partition}:ecs:${data.aws_region.builder.region}:${local.account_id}:task-definition/docs-rs-*:*"
        Condition = {
          ArnEquals = {
            "ecs:cluster" = var.cluster_config.cluster_id
          }
        }
      },
      {
        Effect = "Allow"
        Action = ["iam:PassRole"]
        # Match the task and execution role names created by the ecs-task module.
        Resource = [
          "arn:${data.aws_partition.builder.partition}:iam::${local.account_id}:role/docs-rs-*",
          "arn:${data.aws_partition.builder.partition}:iam::${local.account_id}:role/ecs-task-execution--docs-rs-*",
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      },
    ]
  })
}

resource "aws_scheduler_schedule" "consistency_check" {
  name        = "docs-rs-consistency-check"
  group_name  = aws_scheduler_schedule_group.docs_rs.name
  description = "Synchronize the docs.rs database with the registry"

  schedule_expression          = "cron(0 0 * * ? *)"
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode                      = "FLEXIBLE"
    maximum_window_in_minutes = 60
  }

  target {
    arn      = var.cluster_config.cluster_id
    role_arn = aws_iam_role.scheduler.arn

    ecs_parameters {
      task_definition_arn = module.watcher.task_arn
      launch_type         = "FARGATE"
      platform_version    = "1.4.0"
      task_count          = 1
      group               = "docs-rs-consistency-check"

      network_configuration {
        subnets          = var.cluster_config.subnet_ids
        security_groups  = [aws_security_group.watcher.id]
        assign_public_ip = true
      }
    }

    input = jsonencode({
      containerOverrides = [{
        name    = "app"
        command = ["database", "synchronize"]
      }]
    })

    # Retry launch failures for up to an hour, without carrying them into the next day.
    # Scheduler does not monitor or retry the container's eventual exit status.
    retry_policy {
      maximum_event_age_in_seconds = 3600
      maximum_retry_attempts       = 3
    }
  }

  depends_on = [aws_iam_role_policy.scheduler]
}
