// Storage for the GPG keys used to sign releases.

locals {
  // List of IAM Users allowed to interact with the rust-release-keys bucket.
  release_keys_bucket_users = [
    "pietroalbini",
    "simulacrum",
    "jdn",
    "marcoieni",
  ]
}

resource "aws_s3_bucket" "release_keys" {
  bucket = "rust-release-keys"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "release_keys" {
  bucket = aws_s3_bucket.release_keys.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "release_keys" {
  bucket = aws_s3_bucket.release_keys.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "release_keys" {
  bucket = aws_s3_bucket.release_keys.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_user" "release_keys_bucket_users" {
  for_each  = toset(local.release_keys_bucket_users)
  user_name = each.value
}

// Deny access to unauthorized administrators.
//
// Not all the administrators should be able to access the release keys.
// Because of that the bucket has a policy to deny access to everyone except
// selected infra team members and the root account.
//
// https://aws.amazon.com/blogs/security/how-to-restrict-amazon-s3-bucket-access-to-a-specific-iam-role/
resource "aws_s3_bucket_policy" "rust_terraform" {
  bucket = aws_s3_bucket.release_keys.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.release_keys.arn,
          "${aws_s3_bucket.release_keys.arn}/*",
        ]
        Condition = {
          StringNotLike = {
            "aws:userId" = concat(
              [
                data.aws_caller_identity.current.account_id,
                "${module.dev.promote_release_role_id}:*",
                "${module.prod.promote_release_role_id}:*",
              ],
              [for name, user in data.aws_iam_user.release_keys_bucket_users : user.user_id],
            )
          }
        }
      }
    ]
  })
}
