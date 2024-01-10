resource "aws_sqs_queue" "cdn_log_event_queue" {
  name                      = "cdn-log-event-queue"
  receive_wait_time_seconds = 20
}

resource "aws_sqs_queue_policy" "s3_push" {
  queue_url = aws_sqs_queue.cdn_log_event_queue.id
  policy    = data.aws_iam_policy_document.s3_push_to_queue.json
}

data "aws_iam_policy_document" "s3_push_to_queue" {
  statement {
    sid    = "AllowS3ToPushEvents"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sqs:SendMessage"]

    resources = [aws_sqs_queue.cdn_log_event_queue.arn]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [var.bucket_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.bucket_account]
    }
  }
}

resource "aws_iam_user" "heroku_access" {
  name = "crates-io-heroku-access"
}

resource "aws_iam_access_key" "crates_io" {
  user = aws_iam_user.heroku_access.name
}

resource "aws_iam_user_policy" "sqs_read" {
  name   = "heroku-access"
  user   = aws_iam_user.heroku_access.name
  policy = data.aws_iam_policy_document.heroku_access.json
}

data "aws_iam_policy_document" "heroku_access" {
  statement {
    sid    = "AllowAccessToSQS"
    effect = "Allow"

    actions = [
      "sqs:GetQueueAttributes",
      "sqs:DeleteMessage",
      "sqs:DeleteMessageBatch",
      "sqs:ReceiveMessage",
    ]

    resources = [aws_sqs_queue.cdn_log_event_queue.arn]
  }
}
