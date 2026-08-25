locals {
  trail_name = "rust-organization"
  trail_arn  = "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${local.trail_name}"
}

data "aws_caller_identity" "current" {}
data "aws_organizations_organization" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_secretsmanager_secret" "datadog_api_key" {
  name = "/prod/datadog/cloudtrail-api-key"
}

# Bucket to store CloudTrail logs.
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "rust-organization-cloudtrail"

  # Audit logs should never be deleted implicitly when this resource is removed from Terraform.
  force_destroy = false
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    # Disable ACLs for authorization. Manage bucket access centrally, through IAM and bucket policies.
    object_ownership = "BucketOwnerEnforced"
  }
}

# Disable public access to the bucket.
resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      # Encrypt all log objects at rest without the need of managing a key.
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    # Preserve prior object versions so accidental overwrites or deletes are recoverable.
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  # Configure versioning before applying version-aware lifecycle rules.
  depends_on = [aws_s3_bucket_versioning.cloudtrail]

  rule {
    id     = "expire-cloudtrail-logs"
    status = "Enabled"

    # An empty filter applies the retention policy to every object in the bucket.
    filter {}

    expiration {
      # Expire the current version after one year. S3 retains it temporarily as
      # a noncurrent version according to the rule below.
      days = 365
    }

    noncurrent_version_expiration {
      # Keep replaced/deleted versions long enough for operational recovery without retaining them
      # for the full audit-log period.
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      # Failed uploads are not usable audit records. Remove their orphaned parts.
      days_after_initiation = 7
    }
  }
}

# Policy described in https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html#org-trail-bucket-policy
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Protect all bucket and object operations from accidental plaintext HTTP access.
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.cloudtrail.arn,
          "${aws_s3_bucket.cloudtrail.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        # Allow CloudTrail to check bucket ownership and permissions.
        Sid    = "AWSCloudTrailAclCheck20150319"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = local.trail_arn
          }
        }
      },
      {
        # Allows logging in the event the trail is changed from an organization trail to a trail for that account only.
        Sid    = "AWSCloudTrailWrite20150319"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "aws:SourceArn" = local.trail_arn
            "s3:x-amz-acl"  = "bucket-owner-full-control"
          }
        }
      },
      {
        # Allow logging for an organization trail.
        Sid    = "AWSCloudTrailOrganizationWrite20150319"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_organizations_organization.current.id}/*"
        Condition = {
          StringEquals = {
            "aws:SourceArn" = local.trail_arn
            "s3:x-amz-acl"  = "bucket-owner-full-control"
          }
        }
      },
    ]
  })
}

# The Datadog Forwarder is declared in this module because moving it into the datadog-aws module
# would add its transitive provider dependencies to every account's lock file, even when the
# Forwarder is disabled.
module "datadog_forwarder" {
  # Datadog module: https://registry.terraform.io/modules/DataDog/log-lambda-forwarder-datadog/aws
  source  = "DataDog/log-lambda-forwarder-datadog/aws"
  version = "2.0.1"

  # The secret is provisioned independently.
  create_dd_api_key_secret = false
  dd_api_key_secret_arn    = data.aws_secretsmanager_secret.datadog_api_key.arn
  # Schedule retries for payloads the Forwarder stored after Datadog delivery failures.
  dd_schedule_retry_failed_events = true
  # Limit the Forwarder to CloudTrail logs to avoid giving Datadog access to other S3 buckets.
  dd_s3_log_bucket_arns = ["${aws_s3_bucket.cloudtrail.arn}/*"]
  dd_site               = "datadoghq.com"
  # Retain failed payloads so they remain available for replay and investigation.
  dd_store_failed_events = true
  function_name          = "DatadogCloudTrailForwarder"
  # https://github.com/DataDog/datadog-serverless-functions/releases
  layer_version = "110" # Datadog Forwarder 5.4.11
  # Retain operational Lambda logs long enough to investigate delayed forwarding failures.
  log_retention_in_days = 30
}

# Record activity from the management account and every member account in the
# organization, then deliver it to the protected bucket above.
resource "aws_cloudtrail" "organization" {
  name           = local.trail_name
  s3_bucket_name = aws_s3_bucket.cloudtrail.id
  # Digest files make it possible to verify that delivered logs were not modified or deleted.
  enable_log_file_validation = true
  # Start recording as soon as the trail is created.
  enable_logging = true
  # Include global services such as IAM whose events are not tied to a single Region.
  include_global_service_events = true
  # Capture activity in all current and future enabled Regions.
  is_multi_region_trail = true
  # Extend the trail from the management account to every account in the AWS organization.
  is_organization_trail = true

  event_selector {
    # This trail captures control-plane activity only; high-volume data events such
    # as S3 object access and Lambda invocations require separate, explicitly scoped selectors.
    include_management_events = true
    # Keep both read and write management calls for complete investigations and detections.
    read_write_type = "All"
  }

  # Start logging only after the destination policy and all bucket protections are active.
  depends_on = [
    aws_s3_bucket_lifecycle_configuration.cloudtrail,
    aws_s3_bucket_ownership_controls.cloudtrail,
    aws_s3_bucket_policy.cloudtrail,
    aws_s3_bucket_public_access_block.cloudtrail,
    aws_s3_bucket_server_side_encryption_configuration.cloudtrail,
    aws_s3_bucket_versioning.cloudtrail,
  ]
}
