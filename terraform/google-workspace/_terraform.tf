terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.3"
    }
  }

  backend "gcs" {
    bucket = "gws-rustlang-tfstate"
    prefix = "terraform/state"
  }
}
