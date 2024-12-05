terraform {
  source = "../../../..//terragrunt/modules/ci-runners"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  rust_lang_code_connection_arn    = "arn:aws:codeconnections:us-east-2:442426873467:connection/98864d5c-b905-4f8e-bd76-2f69cf181818"
  rust_lang_ci_code_connection_arn = "arn:aws:codeconnections:us-east-2:442426873467:connection/dfa33048-75a5-4409-8700-5f099d558c52"
}
