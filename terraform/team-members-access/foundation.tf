// This file defines the permissions of crates.io team members with access to the
// production environment.

resource "aws_iam_group" "foundation" {
  name = "foundation"
}

resource "aws_iam_group_policy_attachment" "foundation_manage_own_credentials" {
  group      = aws_iam_group.foundation.name
  policy_arn = aws_iam_policy.manage_own_credentials.arn
}

resource "aws_iam_group_policy_attachment" "foundation_enforce_mfa" {
  group      = aws_iam_group.foundation.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

data "aws_route53_zone" "allowed_zones" {
  for_each = toset([
    "rust.foundation",
    "rustfoundation.com",
    "rust-foundation.com",
    "rust-foundation.org",
    "rustfoundation.net",
    "rust-foundation.net",
    "therustfoundation.com",
    "therustfoundation.org",
  ])
  name = each.value
}

resource "aws_iam_group_policy" "foundation" {
  group = aws_iam_group.foundation.name
  name  = "prod-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      // Support access
      //
      // The following rules allow foundation team members to reach out to AWS
      // Support without involving someone from the infrastructure team.
      {
        Sid      = "SupportAccess"
        Effect   = "Allow"
        Action   = ["support:*"]
        Resource = "*"
      },
      // Billing-related resources
      {
        Effect = "Allow"
        Action = [
          "aws-portal:*Usage",
          "aws-portal:*Billing",
          "aws-portal:*PaymentMethods",
          "ce:*",
          "purchase-orders:*",
          "tax:*",
          "cur:DescribeReportDefinitions",
          "cur:PutReportDefinition",
          "cur:DeleteReportDefinition",
          "cur:ModifyReportDefinition"
        ]
        Resource = "*"
      },
      // But not account settings
      {
        Effect = "Deny"
        Action = [
          "aws-portal:*Account",
        ]
        Resource = "*"
      },
      // Access to the Route 53 console
      {
        Effect = "Allow"
        Action = [
          "route53:GetHostedZoneCount",
          "route53:ListHostedZonesByName",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets",
          "route53:ChangeResourceRecordSets",
        ]
        Resource = [for zone in data.aws_route53_zone.allowed_zones : zone.arn]
      }
    ]
  })
}
