terraform {
  source = "../../../../modules//s3-tsv"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  # Ensure packaging reads from the original repo (not Terragrunt cache)
  source_dir = "${get_original_terragrunt_dir()}/../../../../../target/lambda/s3-tsv-lambda"
}
