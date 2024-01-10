terraform {
  source = "../../../..//terragrunt/modules/crates-io-logs"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  bucket_account = 890664054962
  bucket_arn = "arn:aws:s3:::rust-staging-crates-io-logs"
}
