terraform {
  source = "../../../modules//bors"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  domain = "bors-prod.rust-lang.net"
  public_url = "bors.rust-lang.org"
  gh_app_id = "278306"
  trusted_sub = "repo:rust-lang/bors:environment:production"
  oauth_client_id = "Ov23li6CuHNVV4KULH9X"
  zulip_username = "bors-bot@rust-lang.zulipchat.com"
  cpu = 1024
  memory = 2048
  ec2_runner_role = "arn:aws:iam::008376430877:role/gha-runner-management"
}
