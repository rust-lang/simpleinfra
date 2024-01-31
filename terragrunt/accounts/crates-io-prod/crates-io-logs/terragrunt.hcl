terraform {
  source = "git::../../../..//terragrunt/modules/crates-io-logs?ref=${trimspace(file("../deployed-ref"))}"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  bucket_account = 890664054962
  bucket_arn = "arn:aws:s3:::rust-crates-io-logs"
}
