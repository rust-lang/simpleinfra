data "aws_region" "current" {}

locals {
  name = "s3-tsv"
}

module "lambda" {
  source = "../lambda"

  name        = local.name
  source_dir  = var.source_dir
  destination = "${path.module}/packages/${data.aws_region.current.name}/${local.name}.zip"
  environment = {}
  # TODO: set this to 840 (14 minutes), to allow for large TSV files to be processed
  lambda_timeout = 30
}
