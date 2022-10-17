terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.59"
    }
  }
}

variable "instances" {
  type = map(object({
    instance_type = string
    instance_arch = string
    storage       = number
  }))
}
