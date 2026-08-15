locals {
  datadog_iam_role_name = "DatadogAWSIntegrationRole"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "datadog" {
  name        = "DatadogAWSIntegrationPolicy"
  description = "Read-only access for Datadog"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "account:GetAccountInformation",
          "apigateway:GET",
          "autoscaling:Describe*",
          "backup:List*",
          "budgets:ViewBudget",
          "cloudfront:GetDistributionConfig",
          "cloudfront:ListDistributions",
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrail",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:ListTrails",
          "cloudtrail:LookupEvents",
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "codedeploy:BatchGet*",
          "codedeploy:List*",
          "directconnect:Describe*",
          "dynamodb:Describe*",
          "dynamodb:List*",
          "ec2:Describe*",
          "ecs:Describe*",
          "ecs:List*",
          "elasticache:Describe*",
          "elasticache:List*",
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeTags",
          "elasticloadbalancing:Describe*",
          "elasticmapreduce:Describe*",
          "elasticmapreduce:List*",
          "es:DescribeElasticsearchDomains",
          "es:ListDomainNames",
          "es:ListTags",
          "events:CreateEventBus",
          "fsx:DescribeFileSystems",
          "fsx:ListTagsForResource",
          "health:DescribeAffectedEntities",
          "health:DescribeEventDetails",
          "health:DescribeEvents",
          "kinesis:Describe*",
          "kinesis:List*",
          "lambda:GetPolicy",
          "lambda:List*",
          "logs:DeleteSubscriptionFilter",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:DescribeSubscriptionFilters",
          "logs:FilterLogEvents",
          "logs:PutSubscriptionFilter",
          "logs:TestMetricFilter",
          "organizations:Describe*",
          "organizations:List*",
          "rds:Describe*",
          "rds:List*",
          "redshift:DescribeClusters",
          "redshift:DescribeLoggingStatus",
          "route53:List*",
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:GetBucketNotification",
          "s3:GetBucketTagging",
          "s3:ListAllMyBuckets",
          "s3:PutBucketNotification",
          "ses:Get*",
          "sns:List*",
          "sns:Publish",
          "sqs:ListQueues",
          "states:DescribeStateMachine",
          "states:ListStateMachines",
          "support:DescribeTrustedAdvisor*",
          "support:RefreshTrustedAdvisorCheck",
          "tag:GetResources",
          "tag:GetTagKeys",
          "tag:GetTagValues",
          "trustedadvisor:ListRecommendations",
          "xray:BatchGetTraces",
          "xray:GetTraceSummaries",
        ],
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "datadog" {
  name = local.datadog_iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          AWS = "464622532012"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = datadog_integration_aws.aws.external_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "datadog" {
  role       = aws_iam_role.datadog.name
  policy_arn = aws_iam_policy.datadog.arn
}

resource "datadog_integration_aws" "aws" {
  account_id = data.aws_caller_identity.current.account_id
  role_name  = local.datadog_iam_role_name

  account_specific_namespace_rules = {
    # The AWS Lambda integration includes CloudFront functions, which are
    # redundantly deployed to many regions. This creates a large number of
    # serverless functions in Datadog, which we don't need.
    lambda = false
  }

  host_tags = [
    "env:${var.env}"
  ]
}
