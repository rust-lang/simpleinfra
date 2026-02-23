data "aws_caller_identity" "current" {}

locals {
  docs_rs_prod_account_id         = "760062276060"
  docs_rs_prod_storage_bucket_arn = "arn:aws:s3:::docs-rs-storage-${local.docs_rs_prod_account_id}"
}

resource "aws_iam_role" "storage_crr_replication" {
  name = "docs-rs-s3-crr-replication"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            "aws:SourceArn"     = aws_s3_bucket.storage.arn
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "storage_crr_replication" {
  role = aws_iam_role.storage_crr_replication.id
  name = "docs-rs-s3-crr-replication"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.storage.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.storage.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ObjectOwnerOverrideToBucketOwner",
          "s3:ReplicateDelete",
          "s3:ReplicateObject",
          "s3:ReplicateTags"
        ]
        Resource = "${local.docs_rs_prod_storage_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "storage_docs_rs_prod" {
  role   = aws_iam_role.storage_crr_replication.arn
  bucket = aws_s3_bucket.storage.id

  rule {
    id     = "replicate-to-docs-rs-prod-storage"
    status = "Enabled"

    filter {}

    destination {
      account = local.docs_rs_prod_account_id
      bucket  = local.docs_rs_prod_storage_bucket_arn

      access_control_translation {
        owner = "Destination"
      }
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }

  depends_on = [
    aws_iam_role_policy.storage_crr_replication,
    aws_s3_bucket_versioning.storage,
  ]
}
