terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  backend "s3" {
    # The bucket name ends with the id of the bors-prod AWS account.
    bucket       = "terraform-state-351621253146"
    key          = "app.tfstate"
    region       = "us-east-1"
    profile      = "bors-prod"
    use_lockfile = true
  }
}

provider "aws" {
  region  = "us-east-2"
  profile = "bors-prod"
}
