// ECR repository used to store the docs.rs container. CI is authorized to
// download and upload images ot it.

module "ecr" {
  source = "../../shared/modules/ecr-repo"
  name   = "${var.env_name}-docs-rs"
}

resource "aws_iam_user_policy_attachment" "ci_push" {
  user       = var.ci_username
  policy_arn = module.ecr.policy_push_arn
}

resource "aws_iam_user_policy_attachment" "ci_pull" {
  user       = var.ci_username
  policy_arn = module.ecr.policy_pull_arn
}

// S3 bucket used to store the built documentation.

resource "aws_s3_bucket" "storage" {
  bucket = "${var.env_name}-docs-rs"
  acl    = "private"
}

resource "aws_s3_bucket_inventory" "storage" {
  name    = "all-objects-csv"
  bucket  = aws_s3_bucket.storage.id
  enabled = true

  included_object_versions = "Current"
  optional_fields          = ["ETag", "ReplicationStatus", "Size"]

  schedule {
    frequency = "Weekly"
  }
  destination {
    bucket {
      bucket_arn = var.inventories_bucket_arn
      prefix     = aws_s3_bucket.storage.id
      format     = "CSV"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
