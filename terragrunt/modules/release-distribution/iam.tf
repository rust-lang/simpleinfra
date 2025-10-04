# Provision IAM for GCP Storage Transfer to read from the static bucket
module "release_distribution_storage_transfer_iam" {
  source      = "../storage_transfer_iam"
  environment = var.environment

  iam_prefix = var.static_bucket

  s3_bucket_arns = [
    data.aws_s3_bucket.static.arn,
    "${data.aws_s3_bucket.static.arn}/*"
  ]
}
