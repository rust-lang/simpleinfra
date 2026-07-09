terraform {
  source = "../../../modules//crates-io/docs-rs-event-queue"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  env = "staging"

  producer_principal_arns = [
    "arn:aws:iam::890664054962:user/staging-crates-io--heroku",
  ]

  consumer_principal_arns = [
    "arn:aws:iam::519825364412:role/builder",
    "arn:aws:iam::519825364412:role/docs-rs-web",
  ]
}
