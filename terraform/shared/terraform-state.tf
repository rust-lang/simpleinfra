// This file contains the definition of the resources needed to store the
// Terraform State, **except** the underlying S3 bucket and DynamoDB table.
//
// Those are not configured through Terraform to avoid cyclic dependencies: the
// cycle could make solving issues if things go wrong way harder.

locals {
  // List of IAM or SSO users authorized to access the Terraform bucket.
  terraform_state_users = [
    "pietroalbini",
    "simulacrum",
    "jdn",
    "marcoieni",
    "ubiratansoares",
  ]

  // We use this to allow federated identities (AWS Identity Center)
  // to access the Terraform state bucket.
  // For SSO sessions, aws:userId follows the pattern "<role-id>:username".
  // Check rust_terraform_sso_allowed below
  terraform_state_allowed_sso_userids = [
    for username in local.terraform_state_users :
    "${data.aws_iam_role.rust_terraform_sso_allowed.unique_id}:${username}"
  ]
}

// Look up the AdministratorAccess role created by AWS Identity Center.
data "aws_iam_roles" "sso_infra_admin" {
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
}

// Fetch the full role details (including unique_id) by extracting the role name
// from the ARN returned above.
data "aws_iam_role" "rust_terraform_sso_allowed" {
  name = regex(".*/(.*)", tolist(data.aws_iam_roles.sso_infra_admin.arns)[0])[0]
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
// Access is controlled via aws:userId, which works for
// both IAM users and SSO assumed-role sessions
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
              // Root account — always allowed
              [data.aws_caller_identity.current.account_id],
              // IAM users (SSO session via aws-creds.py)
              [for name, user in data.aws_iam_user.rust_terraform_allowed : user.user_id],
              // SSO users (SSO session via AWS Identity Center)
              local.terraform_state_allowed_sso_userids,
            )
          }
        }
      }
    ]
  })
}
