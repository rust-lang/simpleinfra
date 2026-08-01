// Grant CodeBuild project IAM role access to use the connection, as documented in
// https://docs.aws.amazon.com/codebuild/latest/userguide/connections-github-app.html#connections-github-role-access
data "aws_iam_policy_document" "codebuild_policy_doc" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild-github-runner-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_policy_doc.json
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "codebuild-github-runner-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codeconnections:GetConnectionToken",
          "codeconnections:GetConnection"
        ]
        Resource = [aws_codeconnections_connection.github_connection.arn]
      }
    ]
  })
}

resource "aws_iam_role" "executor" {
  name = "gha-runner-management"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "AllowBors"
        Principal = {
          AWS = var.executor_account_id
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "executor" {
  name = "gha-runner-management"
  role = aws_iam_role.executor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        // The management service (bors) needs to be able to find and terminate
        // instances that have leaked (e.g. because our on-host software failed
        // to terminate them properly after the GitHub Actions runner exited).
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:TerminateInstances",
        ]
        Resource = ["*"]
      },
      {
        // Used to resolve the AMI used.
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
        ]
        Resource = ["arn:aws:ssm:*::parameter/aws/service/canonical/ubuntu/*"]
      },
      // The management service (bors) needs to be able to start new instances.
      //
      // This uses the examples given in the AWS docs (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ExamplePolicies_EC2.html#iam-example-launch-templates).
      //
      // The effect is that the launch template we specify is used, and no
      // properties in the launch template can be overriden by the run
      // instances call.
      //
      // This is defense in depth to enforce that the infrastructure-level
      // security properties we expect are configured on the instance.
      {
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            // Enforce that bors uses the launch template we asked it to when calling.
            "ec2:LaunchTemplate" = aws_launch_template.runner.arn
          }
          Bool = {
            // Enforce that any resource specified in the launch tempalte
            // cannot be overriden by the caller. This somewhat duplicates the
            // above (e.g., security group enforcement), but seems like good
            // defense in depth.
            "ec2:IsLaunchTemplateResource" = true
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
        ]
        Resource = [
          // Allow any subnet to be used.
          //
          // We don't specify subnets in the template because we don't know
          // which AZ we're going to launch in, so we need to let AWS pick. As
          // such it's not going to be a launch template resource.
          "arn:aws:ec2:us-east-2:*:subnet/*",
          // Same with the image (at least for now). This is dynamically
          // picked by resolving an SSM parameter, we can't embed that into
          // the policy.
          "arn:aws:ec2:us-east-2:*:image/*",
        ]
      },
      {
        // Allow tagging instances on launch.
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "RunInstances"
          }
        }
      }
    ]
  })
}
