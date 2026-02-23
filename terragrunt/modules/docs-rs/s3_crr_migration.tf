locals {
  s3_crr_source_account_id = "890664054962"

  # Use the source account as the bucket policy principal so the policy can be
  # created before the source replication role exists.
  s3_crr_source_account_root_arn = "arn:aws:iam::${local.s3_crr_source_account_id}:root"

  replication = "docs-rs-s3-crr-replication"
  # IAM role ARN in the source account used by S3 CRR
  s3_crr_source_replication_role_arn = "arn:aws:iam::${local.s3_crr_source_account_id}:role/${local.replication}"
  s3_crr_assumed_role                = "arn:aws:sts::${local.s3_crr_source_account_id}:assumed-role/${local.replication}/*"
}

resource "aws_s3_bucket_versioning" "storage_crr" {
  count = var.s3_crr_enabled ? 1 : 0

  bucket = aws_s3_bucket.storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

// Allow the source account replication role to replicate into this bucket.
resource "aws_s3_bucket_policy" "storage_crr_replication" {
  count = var.s3_crr_enabled ? 1 : 0

  bucket = aws_s3_bucket.storage.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSourceReplicationRoleToReadDestinationVersioning"
        Effect = "Allow"
        Principal = {
          AWS = local.s3_crr_source_account_root_arn
        }
        Condition = {
          ArnLike = {
            "aws:PrincipalArn" = [
              local.s3_crr_source_replication_role_arn,
              local.s3_crr_assumed_role
            ]
          }
        }
        Action = [
          "s3:GetBucketVersioning"
        ]
        Resource = aws_s3_bucket.storage.arn
      },
      {
        Sid    = "AllowSourceReplicationRoleToWriteReplicas"
        Effect = "Allow"
        Principal = {
          AWS = local.s3_crr_source_account_root_arn
        }
        Condition = {
          ArnLike = {
            "aws:PrincipalArn" = [
              local.s3_crr_source_replication_role_arn,
              local.s3_crr_assumed_role
            ]
          }
        }
        Action = [
          "s3:ObjectOwnerOverrideToBucketOwner",
          "s3:ReplicateDelete",
          "s3:ReplicateObject",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.storage.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_versioning.storage_crr]
}
