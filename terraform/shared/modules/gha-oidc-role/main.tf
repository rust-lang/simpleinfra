data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "rust-terraform"
    key    = "simpleinfra/shared.tfstate"
    region = "us-west-1"
  }
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
          Federated = data.terraform_remote_state.shared.outputs.gha_oidc_arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.org}/${var.repo}:ref:refs/heads/${var.branch}"
          }
        }
      }
    ]
  })
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
  description = "The branch of the repository allowed to assume the role"
}
