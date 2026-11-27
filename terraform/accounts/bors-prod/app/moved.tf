# One-off migration from Terragrunt, which ran the module as the root module.
# These blocks move the existing state into `module.bors`. Delete this file
# once the configuration has been applied.

moved {
  from = aws_ecr_repository.primary
  to   = module.bors.aws_ecr_repository.primary
}

moved {
  from = aws_ecr_repository_policy.policy
  to   = module.bors.aws_ecr_repository_policy.policy
}

moved {
  from = aws_ecr_lifecycle_policy.policy
  to   = module.bors.aws_ecr_lifecycle_policy.policy
}

moved {
  from = aws_ecs_cluster.primary
  to   = module.bors.aws_ecs_cluster.primary
}

moved {
  from = aws_cloudwatch_log_group.bors
  to   = module.bors.aws_cloudwatch_log_group.bors
}

moved {
  from = aws_ecs_cluster_capacity_providers.fargate
  to   = module.bors.aws_ecs_cluster_capacity_providers.fargate
}

moved {
  from = aws_ecs_service.bors
  to   = module.bors.aws_ecs_service.bors
}

moved {
  from = aws_security_group.ecs
  to   = module.bors.aws_security_group.ecs
}

moved {
  from = aws_vpc_security_group_ingress_rule.ingress_lb
  to   = module.bors.aws_vpc_security_group_ingress_rule.ingress_lb
}

moved {
  from = aws_vpc_security_group_egress_rule.egress_anywhere_v4
  to   = module.bors.aws_vpc_security_group_egress_rule.egress_anywhere_v4
}

moved {
  from = aws_vpc_security_group_egress_rule.egress_anywhere_v6
  to   = module.bors.aws_vpc_security_group_egress_rule.egress_anywhere_v6
}

moved {
  from = aws_ecs_task_definition.bors
  to   = module.bors.aws_ecs_task_definition.bors
}

moved {
  from = aws_iam_openid_connect_provider.gh_oidc
  to   = module.bors.aws_iam_openid_connect_provider.gh_oidc
}

moved {
  from = aws_iam_role.gha
  to   = module.bors.aws_iam_role.gha
}

moved {
  from = aws_iam_role.runtime
  to   = module.bors.aws_iam_role.runtime
}

moved {
  from = aws_iam_role_policy_attachment.ecs_ssm
  to   = module.bors.aws_iam_role_policy_attachment.ecs_ssm
}

moved {
  from = aws_iam_role_policy_attachment.ecs_ecr
  to   = module.bors.aws_iam_role_policy_attachment.ecs_ecr
}

moved {
  from = aws_iam_policy.ssm_access
  to   = module.bors.aws_iam_policy.ssm_access
}

moved {
  from = aws_iam_role_policy.gha-self-hosted
  to   = module.bors.aws_iam_role_policy.gha-self-hosted
}

moved {
  from = aws_lb_target_group.primary
  to   = module.bors.aws_lb_target_group.primary
}

moved {
  from = aws_lb.primary
  to   = module.bors.aws_lb.primary
}

moved {
  from = aws_lb_listener.primary
  to   = module.bors.aws_lb_listener.primary
}

moved {
  from = aws_acm_certificate.primary
  to   = module.bors.aws_acm_certificate.primary
}

moved {
  from = aws_route53_record.acm_validation
  to   = module.bors.aws_route53_record.acm_validation
}

moved {
  from = aws_acm_certificate_validation.primary
  to   = module.bors.aws_acm_certificate_validation.primary
}

moved {
  from = aws_route53_record.lb
  to   = module.bors.aws_route53_record.lb
}

moved {
  from = aws_db_instance.primary
  to   = module.bors.aws_db_instance.primary
}

moved {
  from = random_password.db
  to   = module.bors.random_password.db
}

moved {
  from = aws_security_group.rds
  to   = module.bors.aws_security_group.rds
}

moved {
  from = aws_vpc_security_group_ingress_rule.bastion
  to   = module.bors.aws_vpc_security_group_ingress_rule.bastion
}

moved {
  from = aws_vpc_security_group_ingress_rule.ingress_ecs
  to   = module.bors.aws_vpc_security_group_ingress_rule.ingress_ecs
}

moved {
  from = aws_vpc_security_group_egress_rule.rds_egress_anywhere_v4
  to   = module.bors.aws_vpc_security_group_egress_rule.rds_egress_anywhere_v4
}

moved {
  from = aws_vpc_security_group_egress_rule.rds_egress_anywhere_v6
  to   = module.bors.aws_vpc_security_group_egress_rule.rds_egress_anywhere_v6
}

moved {
  from = aws_ssm_parameter.db_endpoint
  to   = module.bors.aws_ssm_parameter.db_endpoint
}
