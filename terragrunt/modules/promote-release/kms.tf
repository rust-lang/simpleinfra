data "aws_caller_identity" "current" {}

resource "aws_kms_key" "signing" {
  description         = "Signing key"
  enable_key_rotation = false
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "tag-signing-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      },
      // Remove the ability to sign with this key from users authenticated via
      // SSO (Identity Center) credentials.
      //
      // This prevents easy access (without modifying the key policy) for
      // humans to being able to sign. This isn't hard enforcement (e.g., Admin
      // credentials can create their own role or otherwise bypass this), but
      // it does make it harder to sign without using our code to do so.
      {
        Sid = "Deny all signing operations to SSO users"
        // Skip denying signing with the staging key.
        // End-users shouldn't trust that key and it's convenient for local
        // testing (and maybe CI?) of promote-release to be able to access it.
        Effect   = var.env == "staging" ? "Allow" : "Deny"
        Action   = "kms:Sign"
        Resource = "*"
        Principal = {
          AWS = "*"
        },
        Condition = {
          Null = {
            "identitystore:UserId" = false
          }
        }
      },
    ]
  })
  key_usage                = "SIGN_VERIFY"
  customer_master_key_spec = "RSA_4096"
}

resource "aws_kms_alias" "signing" {
  name          = "alias/signing"
  target_key_id = aws_kms_key.signing.key_id
}
