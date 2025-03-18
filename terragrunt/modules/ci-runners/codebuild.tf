module "ubuntu_22_2c" {
  source = "../../modules/codebuild-project"

  name                = "ubuntu-22-2c"
  service_role        = aws_iam_role.codebuild_role.arn
  compute_type        = "BUILD_GENERAL1_SMALL"
  repository          = var.repository
  code_connection_arn = var.code_connection_arn
}

module "ubuntu_22_4c" {
  source = "../../modules/codebuild-project"

  name                = "ubuntu-22-4c"
  service_role        = aws_iam_role.codebuild_role.arn
  compute_type        = "BUILD_GENERAL1_MEDIUM"
  repository          = var.repository
  code_connection_arn = var.code_connection_arn
}

module "ubuntu_22_8c" {
  source = "../../modules/codebuild-project"

  name                = "ubuntu-22-8c"
  service_role        = aws_iam_role.codebuild_role.arn
  compute_type        = "BUILD_GENERAL1_LARGE"
  repository          = var.repository
  code_connection_arn = var.code_connection_arn
}

module "ubuntu_22_36c" {
  source = "../../modules/codebuild-project"

  name                = "ubuntu-22-36c"
  service_role        = aws_iam_role.codebuild_role.arn
  compute_type        = "BUILD_GENERAL1_XLARGE"
  repository          = var.repository
  code_connection_arn = var.code_connection_arn
}
