resource "aws_codebuild_project" "ubuntu_project" {
  name         = var.name
  service_role = var.service_role

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type = "NO_CACHE"
    // TODO: evaluate if it's worth adding cache
    // modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  build_timeout = 60 * 6 // 6 hours

  environment {
    compute_type = var.compute_type
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
    type            = "GITHUB"
    location        = "https://github.com/${var.repository}"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = false
    }

    auth {
      type     = "CODECONNECTIONS"
      resource = var.code_connection_arn
    }
  }
}

resource "aws_codebuild_webhook" "ubuntu_project_webhook" {
  project_name = aws_codebuild_project.ubuntu_project.name
  build_type   = "BUILD"
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "WORKFLOW_JOB_QUEUED"
    }
  }
}
