terraform {
  source = "../../../modules//bors"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  domain = "bors-staging.rust-lang.net"
  gh_app_id = "343095"
  trusted_sub = "repo:rust-lang/bors:environment:staging"
}
