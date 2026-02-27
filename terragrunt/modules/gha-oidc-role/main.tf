data "aws_iam_openid_connect_provider" "github_actions" {
  count = var.lookup_oidc_provider ? 1 : 0
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  oidc_provider_arn = var.lookup_oidc_provider ? data.aws_iam_openid_connect_provider.github_actions[0].arn : var.oidc_provider_arn
}

output "role" {
  value = aws_iam_role.ci_role
}

resource "aws_iam_role" "ci_role" {
  name = "ci--${var.org}--${var.repo}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = (var.environment != null ?
              "repo:${var.org}/${var.repo}:environment:${var.environment}" :
            "repo:${var.org}/${var.repo}:ref:refs/heads/${var.branch}")
            # Restrict the OIDC token validation to only accept tokens
            # where the audience claim is set to "sts.amazonaws.com". This ensures that
            # GitHub Actions OIDC tokens can only be used to request AWS
            # Security Token Service (STS) credentials,
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

variable "oidc_provider_arn" {
  type        = string
  default     = null
  nullable    = true
  description = "Optional ARN of an existing GitHub Actions OIDC provider. When null, the provider is discovered by URL."
}

variable "lookup_oidc_provider" {
  type        = bool
  default     = true
  description = "Whether to discover the GitHub Actions OIDC provider by URL."
}

variable "org" {
  type        = string
  description = "The GitHub organization where the repository lives"
}

variable "repo" {
  type        = string
  description = "The name of the repository inside the organization"
}

variable "branch" {
  type        = string
  default     = null
  description = "The branch of the repository allowed to assume the role"
}

variable "environment" {
  type        = string
  default     = null
  description = "The GitHub environment allowed to assume the role"
}
