module "vpc" {
  source = "../shared/vpc"

  name      = "docs-rs-staging"
  ipv4_cidr = "10.0.0.0/16"

  public_subnets = {
    0 = "usw1-az1",
  }
  private_subnets = {
    1 = "usw1-az1",
  }
}
