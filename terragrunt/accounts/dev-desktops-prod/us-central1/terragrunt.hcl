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
      # vCPUs: 32, RAM: 64 GiB, AMD Milan.
      instance_type = "c2d-highcpu-32"
      storage       = 2000
    }
  }
}
