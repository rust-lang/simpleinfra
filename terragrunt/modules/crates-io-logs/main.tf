resource "aws_sqs_queue" "log_event_queue" {
  name                      = "cdn-log-queue"
  receive_wait_time_seconds = 20
}

resource "aws_sqs_queue_policy" "s3_push" {
  queue_url = aws_sqs_queue.log_event_queue.id
  policy    = data.aws_iam_policy_document.s3_push_to_queue.json
}

data "aws_iam_policy_document" "s3_push_to_queue" {
  statement {
    sid    = "allow-s3-to-push-events"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sqs:SendMessage"]

    resources = [aws_sqs_queue.log_event_queue.arn]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [data.aws_arn.src_bucket.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_arn.src_bucket.account]
    }
  }
}

data "aws_arn" "src_bucket" {
  arn = var.src_log_bucket_arn
}

variable "src_log_bucket_arn" {
  type        = string
  description = "Bucket ARN which will send events to the SQS queue"
}

resource "aws_iam_user" "heroku_access" {
  name = "crates-io-heroku-access"
}

resource "aws_iam_access_key" "crates_io" {
  user = aws_iam_user.heroku_access
}

resouce "aws_iam_user_policy" "sqs_read" {
  name = "heroku-access"
  user = aws_iam_user.heroku_access.name
}

data "aws_iam_policy_document" "heroku_access" {
  statement {
    sid    = "allow-sqs"
    effect = "Allow"

    actions = [
      "sqs:GetQueueAttributes",
      "sqs:DeleteMessage",
      "sqs:DeleteMessageBatch",
      "sqs:ReceiveMessage",
    ]

    resources = [aws_sqs_queue.log_event_queue.arn]
  }
}
