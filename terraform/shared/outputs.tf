output "master_ec2_key_pair" {
  value = aws_key_pair.buildbot_west_slave_key.key_name
}

output "legacy_vpc" {
  value = {
    subnet_id                = aws_subnet.legacy.id
    common_security_group_id = aws_security_group.legacy_common.id
  }
}

output "prod_vpc" {
  value = {
    id                = module.vpc_prod.id
    public_subnets    = module.vpc_prod.public_subnets
    private_subnets   = module.vpc_prod.private_subnets
    untrusted_subnets = module.vpc_prod.untrusted_subnets
  }
}

output "allowed_users" {
  value = local.allowed_users
}

output "ecs_cluster_config" {
  value = module.service_ecs_cluster.config
}

output "inventories_bucket_arn" {
  value = aws_s3_bucket.rust_inventories.arn
}
