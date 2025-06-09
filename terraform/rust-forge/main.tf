resource "aws_iam_role" "invalidate_forge" {
  name = "forge-rust-lang-org-ci"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = data.terraform_remote_state.shared.outputs.gha_oidc_arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:rust-lang/rust-forge:environment:github-pages"
          }
        }
      }
    ]
  })

  inline_policy {
    name = "invalidate"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "cloudfront:CreateInvalidation"
          Resource = module.website.distribution_arn
        },
      ]
    })
  }
}

module "website" {
  source             = "../shared/modules/static-website"
  domain_name        = "forge.rust-lang.org"
  origin_domain_name = "rust-lang.github.io"
  origin_path        = "/rust-forge"
  response_policy_id = data.terraform_remote_state.shared.outputs.mdbook_response_policy
}

output "role_arn" {
  value = aws_iam_role.invalidate_forge.arn
}
