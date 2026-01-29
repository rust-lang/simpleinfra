terraform {
  source = "../../../modules//dev-desktops-gcp"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  project = "dev-desktops-prod"
  region  = "us-central1"
  zone    = "us-central1-a"
  instances = {
    "dev-desktop-us-2" = {
      instance_type = "n2-standard-2"
      storage       = 2000
    }
  }
}
