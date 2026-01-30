terraform {
  source = "../../../modules//dev-desktops-gcp"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

inputs = {
  project = "dev-desktops-prod"
  region  = "europe-west1"
  zone    = "europe-west1-b"
  instances = {
    "dev-desktop-eu-2" = {
      # vCPUs: 32, RAM: 64 GiB, AMD Milan.
      instance_type = "c2d-highcpu-32"
      storage       = 2000
    }
  }
}
