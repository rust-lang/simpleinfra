// The instance role is intentionally limited to Systems Manager. Workload
// access to rustc-perf storage or secrets should be added separately and with
// narrower policies once the collectors are enrolled.
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
