// ECS deployment and CI integration of highfive.

module "highfive" {
  source         = "../shared/modules/ecs-app"
  cluster_config = data.terraform_remote_state.shared.outputs.ecs_cluster_config

  env  = "prod"
  name = "highfive"
  repo = "rust-lang/highfive"

  cpu              = 256
  memory           = 512
  tasks_count      = 1
  platform_version = "1.4.0"

  secrets = {
    HIGHFIVE_GITHUB_TOKEN   = "/prod/highfive/github-token"
    HIGHFIVE_WEBHOOK_SECRETS = "/prod/highfive/webhook-secrets"
  }

  expose_http = {
    container_port = 80
    domains        = ["highfive.infra.rust-lang.org"]

    health_check_path     = "/"
    health_check_interval = 30
    health_check_timeout  = 5
  }
}
