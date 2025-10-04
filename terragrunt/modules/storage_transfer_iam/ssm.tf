# The access key is stored in SSM Parameter Store so that an aws admin can read it and send it to the
# GCP admins.
# This manual step is necessary because GCP admins don't have access to AWS, so they can't retrieve these secrets
# from terraform.

# Store access key secret in SSM Parameter Store with access key ID in the path
resource "aws_ssm_parameter" "storage_transfer_access_key" {
  name        = "/${var.environment}/gcp-backup/storage-transfer/${var.iam_prefix}/access-key/${aws_iam_access_key.storage_transfer.id}"
  description = "Secret Access Key for Storage Transfer Service"
  type        = "SecureString"
  value       = aws_iam_access_key.storage_transfer.secret
}
