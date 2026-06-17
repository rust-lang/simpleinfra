terraform {
  source = "../../../modules//datadog-fastly"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  services = {
    "yEvEoHsDVsUDRLd6ZTxipI" = {
      env     = "prod"
      app     = "crates-io"
      service = "crates-io"
    },
    "t5Ms9xHxvMQ0oX8vMs88DG" = {
      env     = "prod"
      app     = "crates-io"
      service = "index.crates.io"
    },
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
    "zEKt1p82mWliIlbTQh5Hl1" = {
      env     = "staging"
      app     = "crates-io"
      service = "staging-crates-io"
    },
    "k8I4J4zBUYdoQ0oJt98df7" = {
      env     = "staging"
      app     = "crates-io"
      service = "index.staging.crates.io"
    },
  }
}
