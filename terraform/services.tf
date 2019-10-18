// This terraform module imports all the services from the services/ directory,
// and configures them.

module "service_crater" {
  source                   = "./services/crater"
  ecr_repo                 = module.ecr_crater
  agent_ami_id             = data.aws_ami.ubuntu_bionic.id
  agent_subnet_id          = aws_subnet.rust_prod.id
  agent_key_pair           = aws_key_pair.buildbot_west_slave_key.key_name
  common_security_group_id = aws_security_group.rust_prod_common.id
}

module "service_bastion" {
  source                   = "./services/bastion"
  ami_id                   = data.aws_ami.ubuntu_bionic.id
  vpc_id                   = aws_vpc.rust_prod.id
  subnet_id                = aws_subnet.rust_prod.id
  common_security_group_id = aws_security_group.rust_prod_common.id
  key_pair                 = aws_key_pair.buildbot_west_slave_key.key_name

  // Users allowed to connect to the bastion through SSH. Each user needs to
  // have the CIDR of the static IP they want to connect from stored in AWS SSM
  // Parameter Store (us-west-1), in a string key named:
  //
  //     /prod/bastion/allowed-ips/${user}
  //
  allowed_users = [
    "aidanhs",
    "guillaumegomez",
    "mozilla-mountain-view",
    "mozilla-portland",
    "mozilla-san-francisco",
    "onur",
    "pietro",
    "quietmisdreavus",
    "shep",
    "simulacrum",
  ]
}
