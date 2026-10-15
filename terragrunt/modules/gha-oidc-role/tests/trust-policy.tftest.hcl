mock_provider "aws" {}

variables {
  org                  = "rust-lang"
  repo                 = "docs.rs"
  lookup_oidc_provider = false
  oidc_provider_arn    = "arn:aws:iam::519825364412:oidc-provider/token.actions.githubusercontent.com"
}

run "environment_only" {
  command = plan
  variables {
    environment = "staging"
  }
  assert {
    condition = jsondecode(aws_iam_role.ci_role.assume_role_policy).Statement == [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = var.oidc_provider_arn }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:sub" = "repo:rust-lang/docs.rs:environment:staging"
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
    error_message = "Environment-only roles must retain their scoped OIDC trust statement."
  }
}

run "branches_only" {
  command = plan
  variables {
    branch   = "main"
    branches = ["release"]
  }
  assert {
    condition = [for statement in jsondecode(aws_iam_role.ci_role.assume_role_policy).Statement : statement.Condition.StringEquals["token.actions.githubusercontent.com:sub"]] == [
      "repo:rust-lang/docs.rs:ref:refs/heads/main",
      "repo:rust-lang/docs.rs:ref:refs/heads/release",
    ]
    error_message = "Branch-only roles must retain their configured branch subjects."
  }
}

run "reject_neither" {
  command         = plan
  expect_failures = [var.environment]
}

run "reject_environment_and_branch" {
  command = plan
  variables {
    environment = "staging"
    branch      = "main"
  }
  expect_failures = [var.environment]
}

run "reject_environment_and_branches" {
  command = plan
  variables {
    environment = "staging"
    branches    = ["main"]
  }
  expect_failures = [var.environment]
}
