resource "github_repository_environment" "bors" {
  environment = "bors"
  repository  = var.repo
  deployment_branch_policy {
    custom_branch_policies = true
    protected_branches     = false
  }
}
