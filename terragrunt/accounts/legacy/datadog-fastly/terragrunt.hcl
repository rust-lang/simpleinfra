terraform {
  source = "../../../modules//datadog-fastly"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  services = {
    "5qaYFyyiorVua6uCZg7It0" = {
      env     = "staging"
      app     = "releases"
      service = "dev-static-rust-lang-org"
    },
    "gEfRWQihVaQqh6vsPlY0H1" = {
      env     = "prod"
      app     = "crates-io"
      service = "static-crates-io"
    },
    "MWlq3AIDXubpbw725c7og3" = {
      env     = "prod"
      app     = "releases"
      service = "static-rust-lang-org"
    },
    "liljrvY3Xt0CzNk0mpuLa7" = {
      env     = "staging"
      app     = "crates-io"
      service = "static-staging-crates-io"
    },
  }
}
