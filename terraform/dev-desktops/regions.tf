module "aws_eu_central_1" {
  source = "./aws-region"
  providers = {
    aws = aws.eu-central-1
  }

  instances = {
    "dev-desktop-staging" = {
      instance_type = "t3a.micro"
      storage       = 25
    }
    "dev-desktop-eu-1" = {
      instance_type = "c6g.8xlarge"
      storage       = 1000
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
      storage       = 1000
    }
  }
}
