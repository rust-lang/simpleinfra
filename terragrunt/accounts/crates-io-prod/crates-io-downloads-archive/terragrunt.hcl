terraform {
  source = "../../../..//terragrunt/modules/crates-io-downloads-archive"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  downloads_archive_bucket_name = "crates-io-downloads-archive"
}
