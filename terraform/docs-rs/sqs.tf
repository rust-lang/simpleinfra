locals {
  crates_io_index_events_queue_arn = "arn:aws:sqs:us-east-1:365596307002:crates-io-index-events.fifo"
}

# This role is attached to the legacy EC2 instance currently running docs.rs:
# i-0208c7ee11cc4e0db in us-west-1.
data "aws_iam_role" "docs_rs_ec2" {
  name = "docs-rs"
}

data "aws_iam_policy_document" "index_events_consumer" {
  statement {
    sid    = "ConsumeCratesIoIndexEvents"
    effect = "Allow"

    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
      "sqs:GetQueueUrl",
    ]
    resources = [local.crates_io_index_events_queue_arn]
  }
}

resource "aws_iam_role_policy" "index_events_consumer" {
  name   = "crates-io-index-events-consumer"
  role   = data.aws_iam_role.docs_rs_ec2.name
  policy = data.aws_iam_policy_document.index_events_consumer.json
}
