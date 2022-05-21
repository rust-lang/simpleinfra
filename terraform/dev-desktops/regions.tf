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
  }
}
