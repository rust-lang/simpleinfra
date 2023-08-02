resource "aws_iam_role_policy" "tf-policy" {
  name = "WizCustomPolicy"
  role = aws_iam_role.user-role-tf.id

  policy = jsonencode({
    "Statement" : [
      {
        "Action" : [
          "acm:GetCertificate",
          "apigateway:GET",
          "backup:DescribeGlobalSettings",
          "backup:GetBackupVaultAccessPolicy",
          "backup:GetBackupVaultNotifications",
          "backup:ListBackupVaults",
          "backup:ListTags",
          "cloudtrail:GetInsightSelectors",
          "cloudtrail:ListTrails",
          "codebuild:BatchGetProjects",
          "codebuild:GetResourcePolicy",
          "codebuild:ListProjects",
          "cognito-identity:DescribeIdentityPool",
          "connect:ListInstances",
          "connect:ListInstanceAttributes",
          "connect:ListInstanceStorageConfigs",
          "connect:ListSecurityKeys",
          "connect:ListLexBots",
          "connect:ListLambdaFunctions",
          "connect:ListApprovedOrigins",
          "connect:ListIntegrationAssociations",
          "dynamodb:DescribeExport",
          "dynamodb:DescribeKinesisStreamingDestination",
          "dynamodb:ListExports",
          "ec2:GetEbsEncryptionByDefault",
          "ec2:SearchTransitGatewayRoutes",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:GetAuthorizationToken",
          "ecr:GetDownloadUrlForLayer",
          "ecr:ListTagsForResource",
          "ecr:GetRegistryPolicy",
          "ecr:DescribeRegistry",
          "ecr-public:BatchGetImage",
          "ecr-public:DescribeImages",
          "ecr-public:GetAuthorizationToken",
          "ecr-public:GetDownloadUrlForLayer",
          "ecr-public:ListTagsForResource",
          "ecr-public:GetRegistryPolicy",
          "eks:ListTagsForResource",
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystemPolicy",
          "elasticmapreduce:GetAutoTerminationPolicy",
          "elasticmapreduce:GetManagedScalingPolicy",
          "emr-serverless:ListApplications",
          "emr-serverless:ListJobRuns",
          "ssm:GetDocument",
          "ssm:GetServiceSetting",
          "glacier:GetDataRetrievalPolicy",
          "glacier:GetVaultLock",
          "glue:GetConnection",
          "glue:GetSecurityConfiguration",
          "glue:GetTags",
          "health:DescribeAffectedAccountsForOrganization",
          "health:DescribeAffectedEntities",
          "health:DescribeAffectedEntitiesForOrganization",
          "health:DescribeEntityAggregates",
          "health:DescribeEventAggregates",
          "health:DescribeEventDetails",
          "health:DescribeEventDetailsForOrganization",
          "health:DescribeEventTypes",
          "health:DescribeEvents",
          "health:DescribeEventsForOrganization",
          "health:DescribeHealthServiceStatusForOrganization",
          "kafka:ListClusters",
          "kendra:DescribeDataSource",
          "kendra:DescribeIndex",
          "kendra:ListDataSources",
          "kendra:ListIndices",
          "kendra:ListTagsForResource",
          "kinesisanalytics:ListApplications",
          "kinesisanalytics:DescribeApplication",
          "kinesisanalytics:ListTagsForResource",
          "kinesisvideo:ListStreams",
          "kinesisvideo:ListTagsForStream",
          "kinesisvideo:GetDataEndpoint",
          "kms:GetKeyRotationStatus",
          "kms:ListResourceTags",
          "lambda:GetFunction",
          "lambda:GetLayerVersion",
          "logs:ListTagsForResource",
          "profile:GetDomain",
          "profile:ListDomains",
          "profile:ListIntegrations",
          "s3:GetBucketNotification",
          "s3:GetMultiRegionAccessPointPolicy",
          "s3:ListMultiRegionAccessPoints",
          "ses:DescribeActiveReceiptRuleSet",
          "ses:GetAccount",
          "ses:GetConfigurationSet",
          "ses:GetConfigurationSetEventDestinations",
          "ses:GetDedicatedIps",
          "ses:GetEmailIdentity",
          "ses:ListConfigurationSets",
          "ses:ListDedicatedIpPools",
          "ses:ListReceiptFilters",
          "voiceid:DescribeDomain",
          "wafv2:GetLoggingConfiguration",
          "wafv2:GetWebACLForResource",
          "wisdom:GetAssistant",
          "macie2:ListFindings",
          "macie2:GetFindings",
          "identitystore:List*",
          "identitystore:Describe*",
          "sso-directory:Describe*",
          "sso-directory:ListMembersInGroup",
          "cloudwatch:GetMetricStatistics"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Action" : [
          "ec2:CopySnapshot",
          "ec2:CreateSnapshot",
          "kms:CreateKey",
          "kms:DescribeKey",
          "ec2:GetEbsEncryptionByDefault",
          "ec2:DescribeSnapshots"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Action" : [
          "ec2:CreateTags"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:ec2:*::snapshot/*"
      },
      {
        "Action" : "kms:CreateAlias",
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:kms:*:*:alias/wizKey",
          "arn:aws:kms:*:*:key/*"
        ]
      },
      {
        "Action" : [
          "kms:CreateGrant",
          "kms:ReEncryptFrom"
        ],
        "Condition" : {
          "StringLike" : {
            "kms:ViaService" : "ec2.*.amazonaws.com"
          }
        },
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Action" : [
          "kms:GetKeyPolicy",
          "kms:PutKeyPolicy"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/wiz" : "auto-gen-cmk"
          }
        },
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Action" : [
          "ec2:DeleteSnapshot",
          "ec2:ModifySnapshotAttribute"
        ],
        "Condition" : {
          "StringEquals" : {
            "ec2:ResourceTag/wiz" : "auto-gen-snapshot"
          }
        },
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Action" : [
          "s3:*",
        ],
        "Effect" : "Deny",
        "Resource" : [
          "arn:aws:s3:::*terraform*",
          "arn:aws:s3:::*tfstate*",
          "arn:aws:s3:::*tf?state*",
          "arn:aws:s3:::*cloudtrail*",
          "arn:aws:s3:::elasticbeanstalk-*",
          "arn:aws:s3:::rust-release-keys",
        ],
        "Sid" : "WizAccessS3"
      }
    ]
    "Version" : "2012-10-17"
    }
  )
}
