locals {
  crates_io_event_queue_configured = (
    var.crates_io_event_queue_arn != null &&
    var.crates_io_event_queue_name != null &&
    var.crates_io_event_queue_url != null
  )

  crates_io_event_queue_environment = local.crates_io_event_queue_configured ? {
    DOCSRS_CRATES_IO_EVENT_QUEUE_ARN  = var.crates_io_event_queue_arn
    DOCSRS_CRATES_IO_EVENT_QUEUE_NAME = var.crates_io_event_queue_name
    DOCSRS_CRATES_IO_EVENT_QUEUE_URL  = var.crates_io_event_queue_url
  } : {}

  crates_io_event_queue_consumer_actions = [
    "sqs:ReceiveMessage",
    "sqs:DeleteMessage",
    "sqs:ChangeMessageVisibility",
    "sqs:GetQueueAttributes",
    "sqs:GetQueueUrl",
  ]
}

resource "aws_iam_role_policy" "web_crates_io_event_queue" {
  count = local.crates_io_event_queue_configured ? 1 : 0

  role = module.web.role_id
  name = "crates_io_event_queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "CratesIoEventQueueConsumer"
        Effect   = "Allow"
        Action   = local.crates_io_event_queue_consumer_actions
        Resource = var.crates_io_event_queue_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "builder_crates_io_event_queue" {
  count = local.crates_io_event_queue_configured ? 1 : 0

  role = aws_iam_role.builder.name
  name = "crates_io_event_queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "CratesIoEventQueueConsumer"
        Effect   = "Allow"
        Action   = local.crates_io_event_queue_consumer_actions
        Resource = var.crates_io_event_queue_arn
      }
    ]
  })
}
