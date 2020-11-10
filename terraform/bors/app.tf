// ECS deployment and CI integration of bors.

module "bors" {
  source         = "../shared/modules/ecs-app"
  cluster_config = data.terraform_remote_state.shared.outputs.ecs_cluster_config

  env  = "prod"
  name = "bors"
  repo = "rust-lang/homu"

  cpu              = 1024
  memory           = 2048
  tasks_count      = 1
  platform_version = "1.4.0"
  mount_efs        = "/efs"

  secrets = merge(
    {
      GITHUB_TOKEN         = "/prod/ecs/bors/github-token"
      GITHUB_CLIENT_ID     = "/prod/ecs/bors/github-client-id"
      GITHUB_CLIENT_SECRET = "/prod/ecs/bors/github-client-secret"
      HOMU_SSH_KEY         = "/prod/ecs/bors/ssh-key"
    },
    {
      for repo in keys(var.repositories) :
      "HOMU_WEBHOOK_SECRET_${upper(replace(repo, "-", "_"))}" => aws_ssm_parameter.webhook_secrets[repo].name
    },
  )

  expose_http = {
    container_port = 80
    domains        = concat([var.domain_name], var.legacy_domain_names)

    health_check_path     = "/health"
    health_check_interval = 60
    health_check_timeout  = 50
  }
}
