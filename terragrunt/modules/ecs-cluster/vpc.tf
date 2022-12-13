module "vpc" {
  source = "../shared/vpc"

  name      = "docs-rs-staging"
  ipv4_cidr = "10.0.0.0/16"

  public_subnets = {
    0 = "usw1-az1",
    1 = "usw1-az3",
  }
  private_subnets = {
    2 = "usw1-az1",
    3 = "usw1-az3",
  }
  untrusted_subnets = {
    4 = "usw1-az1",
    5 = "usw1-az3",
  }
}
