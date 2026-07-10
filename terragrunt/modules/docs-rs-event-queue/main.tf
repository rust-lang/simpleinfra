data "aws_iam_user" "producer" {
  # Same IAM user used in the crates-io-logs module.
  user_name = "crates-io-heroku-access"
  provider  = aws.us-east-1
}

resource "aws_sqs_queue" "index_changes" {
  provider = aws.us-east-1
  name     = "crates-io-index-events.fifo"

  # Preserve the ordering of registry events, including deletes, recreations,
  # yanks, and unyanks. The producer should use one MessageGroupId for all
  # events to retain total ordering.
  fifo_queue = true

  # Let crates.io assign a stable event ID as MessageDeduplicationId instead of
  # deriving it from the message body. SendMessage fails if the ID is omitted.
  # If set to true, the queue silently discards distinct events with identical bodies.
  # This is not acceptable because crates.io may send the same event multiple times.
  # E.g. if someone yanks, unyank, and yanks again, the second yank is a distinct event
  # that must be delivered to docs.rs.
  content_based_deduplication = false

  # Keep events for seven days so docs.rs can recover from a prolonged outage.
  # Default: 4 days.
  message_retention_seconds = 7 * 24 * 60 * 60

  # Use the maximum long-poll duration to reduce empty ReceiveMessage calls.
  # The default is 0 seconds, which means that HTTP calls return immediately if the queue is empty.
  # This can cause a lot of empty calls and wasted resources.
  # By setting this value, HTTP calls wait up to 20 seconds for a message to arrive before returning.
  # The consumer can override this queue-level value by supplying
  # WaitTimeSeconds in each ReceiveMessage call.
  # Note: ensure the client’s HTTP timeout is longer than 20 seconds.
  receive_wait_time_seconds = 20

  # Give the consumer (docs-rs in this case) five minutes to handle an event.
  # After the consumer receives an event, SQS hides it for five minutes.
  # If the consumer deletes it, processing is complete. Otherwise, it becomes visible for retry.
  # Messages are idempotent, so it's safe to retry.
  # The consumer must extend this with ChangeMessageVisibility when processing takes longer.
  # Default: 30 seconds.
  visibility_timeout_seconds = 300

  # Encrypt messages at rest without requiring a customer-managed KMS key.
  # This is the default, and it is set to true to detect drifts.
  sqs_managed_sse_enabled = true
}

data "aws_iam_policy_document" "producer" {
  provider = aws.us-east-1

  statement {
    sid    = "SendCratesIoIndexEvents"
    effect = "Allow"

    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:SendMessage",
    ]
    resources = [aws_sqs_queue.index_changes.arn]
  }
}

resource "aws_iam_user_policy" "producer" {
  provider = aws.us-east-1
  name     = "crates-io-index-events-producer"
  user     = data.aws_iam_user.producer.user_name
  policy   = data.aws_iam_policy_document.producer.json
}

data "aws_iam_policy_document" "consumer" {
  count    = length(var.consumer_principal_arns) > 0 ? 1 : 0
  provider = aws.us-east-1

  statement {
    sid    = "ConsumeCratesIoIndexEvents"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.consumer_principal_arns
    }

    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
      "sqs:GetQueueUrl",
    ]
    resources = [aws_sqs_queue.index_changes.arn]
  }
}

resource "aws_sqs_queue_policy" "consumer" {
  count    = length(var.consumer_principal_arns) > 0 ? 1 : 0
  provider = aws.us-east-1

  queue_url = aws_sqs_queue.index_changes.url
  policy    = data.aws_iam_policy_document.consumer[0].json
}
