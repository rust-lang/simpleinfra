module "aws_eu_central_1" {
  source = "./aws-region"
  providers = {
    aws = aws.eu-central-1
  }

  instances = {
    "dev-desktop-staging" = {
      instance_type = "t3a.micro"
      instance_arch = "amd64"
      storage       = 250
    }
    "dev-desktop-eu-1" = {
      instance_type = "c6g.8xlarge"
      instance_arch = "arm64"
      storage       = 3000
    }
  }
}

module "aws_us_east_1" {
  source = "./aws-region"
  providers = {
    aws = aws.us-east-1
  }

  instances = {
    "dev-desktop-us-1" = {
      instance_type = "c7g.8xlarge"
      instance_arch = "arm64"
      storage       = 2000
    }
  }
}
