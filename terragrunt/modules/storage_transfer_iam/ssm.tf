# The access key is stored in SSM Parameter Store so that an aws admin can read it and send it to the
# GCP admins.
# This manual step is necessary because GCP admins don't have access to AWS, so they can't retrieve these secrets
# from terraform.

# Store access key ID in SSM Parameter Store
resource "aws_ssm_parameter" "storage_transfer_access_key_id" {
  name        = "${local.ssm_parameter_prefix}/access-key-id"
  description = "Access Key ID for Storage Transfer Service"
  type        = "SecureString"
  value       = aws_iam_access_key.storage_transfer.id
}

# Store secret access key in SSM Parameter Store
resource "aws_ssm_parameter" "storage_transfer_secret_access_key" {
  name        = "${local.ssm_parameter_prefix}/access-key-secret"
  description = "Secret Access Key for Storage Transfer Service"
  type        = "SecureString"
  value       = aws_iam_access_key.storage_transfer.secret
}
