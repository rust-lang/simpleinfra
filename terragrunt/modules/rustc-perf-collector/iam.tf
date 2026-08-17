// The instance role is intentionally limited to Systems Manager. Workload
// access to rustc-perf storage or secrets should be added separately and with
// narrower policies once the collector is enrolled.
resource "aws_iam_role" "collector" {
  name = "rustc-perf-collector"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  // This managed policy lets the *agent* establish its outbound SSM control
  // channel. Human permission to start a session comes from Identity Center.
  role       = aws_iam_role.collector.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

// EC2 receives IAM roles through an instance-profile wrapper rather than by
// attaching aws_iam_role directly to aws_instance.
resource "aws_iam_instance_profile" "collector" {
  name = "rustc-perf-collector"
  role = aws_iam_role.collector.name
}

// SSM documents are account-and-region-local configuration consumed by
// Systems Manager. This one defines the default interactive shell used by
// `aws ssm start-session`; it is not a startup script for the instance.
// Managing it here makes the no-SSH access path available without a manual
// console step, runs operators as Ubuntu's normal sudo-capable user, and puts
// finite idle and total limits on forgotten sessions.
resource "aws_ssm_document" "session_preferences" {
  name            = "SSM-SessionManagerRunShell"
  document_format = "JSON"
  document_type   = "Session"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Regional Session Manager settings for rustc-perf-prod"
    sessionType   = "Standard_Stream"
    inputs = {
      // There is no account-local log destination yet, so session contents are
      // not streamed. Session API activity is still captured by CloudTrail.
      s3BucketName                = ""
      s3KeyPrefix                 = ""
      s3EncryptionEnabled         = true
      cloudWatchLogGroupName      = ""
      cloudWatchEncryptionEnabled = true
      cloudWatchStreamingEnabled  = false
      kmsKeyId                    = ""
      runAsEnabled                = true
      runAsDefaultUser            = "ubuntu"
      idleSessionTimeout          = "20"
      maxSessionDuration          = "240"
      shellProfile = {
        windows = ""
        linux   = "cd /home/ubuntu"
      }
    }
  })
}
