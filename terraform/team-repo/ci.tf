// Resources needed for the CI of rust-lang/team and rust-lang/sync-team.

// ECR repo used to store the Docker image built by rust-lang/sync-team's CI.

module "ecr" {
  source = "../shared/modules/ecr-repo"
  name   = "sync-team"
}
