output "master_ec2_key_pair" {
  value = aws_key_pair.buildbot_west_slave_key.key_name
}

output "legacy_vpc" {
  value = {
    subnet_id                = aws_subnet.legacy.id
    common_security_group_id = aws_security_group.legacy_common.id
  }
}
