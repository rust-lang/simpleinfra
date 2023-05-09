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
      env = "staging"
    },
    "gEfRWQihVaQqh6vsPlY0H1" = {
      env = "prod"
    },
    "MWlq3AIDXubpbw725c7og3" = {
      env = "prod"
    },
    "liljrvY3Xt0CzNk0mpuLa7" = {
      env = "staging"
    },
  }
}
