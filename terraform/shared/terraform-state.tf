// This file contains the definition of the resources needed to store the
// Terraform State, **except** the underlying S3 bucket and DynamoDB table.
//
// Those are not configured through Terraform to avoid cyclic dependencies: the
// cycle could make solving issues if things go wrong way harder.

locals {
  // List of IAM users authorized to access the Terraform bucket.
  terraform_state_users = [
    "acrichto",
    "pietroalbini",
    "simulacrum",
  ]
}

data "aws_s3_bucket" "rust_terraform" {
  bucket = "rust-terraform"
}

data "aws_iam_user" "rust_terraform_allowed" {
  for_each  = toset(local.terraform_state_users)
  user_name = each.value
}

// Deny access to unauthorized administrators.
//
// Not all the administrators should be able to access the Terraform state.
// Because of that the bucket has a policy to deny access to everyone except
// selected infra team members and the root account.
//
// https://aws.amazon.com/blogs/security/how-to-restrict-amazon-s3-bucket-access-to-a-specific-iam-role/
resource "aws_s3_bucket_policy" "rust_terraform" {
  bucket = data.aws_s3_bucket.rust_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          data.aws_s3_bucket.rust_terraform.arn,
          "${data.aws_s3_bucket.rust_terraform.arn}/*",
        ]
        Condition = {
          StringNotLike = {
            "aws:userId" = concat(
              [data.aws_caller_identity.current.account_id],
              [for name, user in data.aws_iam_user.rust_terraform_allowed : user.user_id],
            )
          }
        }
      }
    ]
  })
}
