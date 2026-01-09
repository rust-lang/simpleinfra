terraform {
  source = "../../../modules//bors"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  domain = "bors-staging.rust-lang.net"
  public_url = "bors-staging.rust-lang.net"
  gh_app_id = "343095"
  trusted_sub = "repo:rust-lang/bors:environment:staging"
  oauth_client_id = "Ov23liTJD2gXjfBvmjZN"
  cpu = 256
}
