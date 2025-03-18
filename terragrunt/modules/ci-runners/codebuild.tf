// Manual steps required after provisioning a project:
// - Connect the GitHub App of the organization, indicating the repositories.
// - Set webhooks with event type `WORKFLOW_JOB_QUEUED` in the filter group.
//
// These manual steps are required because the terraform provider is missing
// support for GitHub Actions runners.
// See https://github.com/hashicorp/terraform-provider-aws/issues/39011

module "ubuntu_22_2c" {
  source = "../../modules/codebuild-project"

  name         = "ubuntu-22-2c"
  service_role = aws_iam_role.codebuild_role.arn
  compute_type = "BUILD_GENERAL1_SMALL"
  repository   = "rust-lang/aws-runners-test"
}

module "ubuntu_22_4c" {
  source = "../../modules/codebuild-project"

  name         = "ubuntu-22-4c"
  service_role = aws_iam_role.codebuild_role.arn
  compute_type = "BUILD_GENERAL1_MEDIUM"
  repository   = "rust-lang-ci/rust"
}

module "ubuntu_22_8c" {
  source = "../../modules/codebuild-project"

  name         = "ubuntu-22-8c"
  service_role = aws_iam_role.codebuild_role.arn
  compute_type = "BUILD_GENERAL1_LARGE"
  repository   = "rust-lang-ci/rust"
}

module "ubuntu_22_36c" {
  source = "../../modules/codebuild-project"

  name         = "ubuntu-22-36c"
  service_role = aws_iam_role.codebuild_role.arn
  compute_type = "BUILD_GENERAL1_XLARGE"
  repository   = "rust-lang-ci/rust"
}
