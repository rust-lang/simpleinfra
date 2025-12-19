terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      // Allow 4.x, 5.x and 6.x
      version = ">= 4.20, < 7"
    }
  }
}
