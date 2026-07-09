locals {
  queue_name           = "crates-io-docs-rs-events.fifo"
  ssm_parameter_prefix = "/crates-io/docs-rs-event-queue"

  producer_actions = [
    "sqs:SendMessage",
    "sqs:GetQueueAttributes",
    "sqs:GetQueueUrl",
  ]

  consumer_actions = [
    "sqs:ReceiveMessage",
    "sqs:DeleteMessage",
    "sqs:ChangeMessageVisibility",
    "sqs:GetQueueAttributes",
    "sqs:GetQueueUrl",
  ]

  tags = {
    Name       = local.queue_name
    component  = "crates-io-events"
    env        = var.env
    queue_name = local.queue_name
    service    = "docs-rs"
  }
}

resource "aws_sqs_queue" "docs_rs_events" {
  name                        = local.queue_name
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = 604800 # 7 days
  receive_wait_time_seconds   = 20
  visibility_timeout_seconds  = var.visibility_timeout_seconds

  tags = local.tags
}

resource "aws_sqs_queue_policy" "docs_rs_events" {
  queue_url = aws_sqs_queue.docs_rs_events.id
  policy    = data.aws_iam_policy_document.docs_rs_events.json
}

data "aws_iam_policy_document" "docs_rs_events" {
  statement {
    sid    = "AllowCratesIoToPublishEvents"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.producer_principal_arns
    }

    actions   = local.producer_actions
    resources = [aws_sqs_queue.docs_rs_events.arn]
  }

  statement {
    sid    = "AllowDocsRsToConsumeEvents"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.consumer_principal_arns
    }

    actions   = local.consumer_actions
    resources = [aws_sqs_queue.docs_rs_events.arn]
  }
}

resource "aws_ssm_parameter" "queue" {
  for_each = {
    arn  = aws_sqs_queue.docs_rs_events.arn
    name = aws_sqs_queue.docs_rs_events.name
    url  = aws_sqs_queue.docs_rs_events.id
  }

  name  = "${local.ssm_parameter_prefix}/${each.key}"
  type  = "String"
  value = each.value

  tags = local.tags
}
