terraform {
  source = "../../../modules//crates-io/docs-rs-event-queue"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  env = "prod"

  producer_principal_arns = [
    "arn:aws:iam::890664054962:user/crates-io--heroku",
  ]

  consumer_principal_arns = [
    "arn:aws:iam::760062276060:role/builder",
    "arn:aws:iam::760062276060:role/docs-rs-web",
  ]
}
