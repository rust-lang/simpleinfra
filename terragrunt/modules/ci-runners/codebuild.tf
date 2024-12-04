// Manual steps required after provisioning a project:
// - Connect the GitHub App of the organization, indicating the repositories.
// - Set webhooks with event type `WORKFLOW_JOB_QUEUED` in the filter group.
//
// These manual steps are required because the terraform provider is missing
// support for GitHub Actions runners.
// See https://github.com/hashicorp/terraform-provider-aws/issues/39011

resource "aws_codebuild_project" "ubuntu_small" {
  name         = "ubuntu-small"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type = "NO_CACHE"
    // TODO: evaluate if it's worth adding cache
    // modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    // ubuntu
    image                       = "aws/codebuild/standard:7.0-24.10.29"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    // Whether to enable running the Docker daemon.
    // The Rust CI uses Docker to build linux artifacts,
    // so we need this if the target is linux.
    privileged_mode = true
  }

  // Disable cloudwatch logs for cost saving.
  // Logs are available in GitHub Actions.
  logs_config {
    cloudwatch_logs {
      status = "DISABLED"
    }
  }

  source {
    type = "GITHUB"
    // Dummy repository.
    // TODO: can we put the real repos even if we use github app?
    location        = "https://github.com/rust-lang/infra-team.git"
    git_clone_depth = 1
  }
}
