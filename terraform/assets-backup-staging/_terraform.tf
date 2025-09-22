terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.3"
    }
  }

  backend "gcs" {
    bucket = "assets-backup-staging-tf-state"
    prefix = "terraform/state"
  }
}
