# One-off migration from Terragrunt, which ran the module as the root module.
# These blocks move the existing state into `module.datadog_aws`. Delete this file
# once the configuration has been applied.

moved {
  from = aws_s3_bucket.datadog_archives
  to   = module.datadog_aws.aws_s3_bucket.datadog_archives
}

moved {
  from = aws_s3_bucket_versioning.datadog_archives
  to   = module.datadog_aws.aws_s3_bucket_versioning.datadog_archives
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.datadog_archives
  to   = module.datadog_aws.aws_s3_bucket_lifecycle_configuration.datadog_archives
}

moved {
  from = aws_s3_bucket_public_access_block.datadog_archives
  to   = module.datadog_aws.aws_s3_bucket_public_access_block.datadog_archives
}

moved {
  from = aws_iam_policy.datadog_archives
  to   = module.datadog_aws.aws_iam_policy.datadog_archives
}

moved {
  from = aws_iam_role_policy_attachment.datadog_archives
  to   = module.datadog_aws.aws_iam_role_policy_attachment.datadog_archives
}

moved {
  from = datadog_logs_archive.s3_archive
  to   = module.datadog_aws.datadog_logs_archive.s3_archive
}

moved {
  from = aws_iam_policy.datadog
  to   = module.datadog_aws.aws_iam_policy.datadog
}

moved {
  from = aws_iam_role.datadog
  to   = module.datadog_aws.aws_iam_role.datadog
}

moved {
  from = aws_iam_role_policy_attachment.datadog
  to   = module.datadog_aws.aws_iam_role_policy_attachment.datadog
}

moved {
  from = aws_iam_role_policy.datadog_forwarders
  to   = module.datadog_aws.aws_iam_role_policy.datadog_forwarders
}

moved {
  from = datadog_integration_aws_account.aws
  to   = module.datadog_aws.datadog_integration_aws_account.aws
}
