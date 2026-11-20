terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  backend "s3" {
    # The bucket name ends with the id of the bors-staging AWS account.
    bucket       = "terraform-state-392478027976"
    key          = "wiz.tfstate"
    region       = "us-east-1"
    profile      = "bors-staging"
    use_lockfile = true
  }
}

provider "aws" {
  region  = "us-east-2"
  profile = "bors-staging"
}
