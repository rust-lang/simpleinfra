// ECS deployment and CI integration of bors.

module "monitorbot" {
  source         = "../shared/modules/ecs-app"
  cluster_config = data.terraform_remote_state.shared.outputs.ecs_cluster_config

  env  = "prod"
  name = "monitorbot"
  repo = "rust-lang/monitorbot"

  cpu              = 256
  memory           = 512
  tasks_count      = 1
  platform_version = "1.4.0"

  environment = {
    MONITORBOT_GH_RATE_LIMIT_STATS_REFRESH = 60
  }

  secrets = {
    MONITORBOT_RATE_LIMIT_TOKENS = "/prod/ecs/monitorbot/rate-limit-tokens"
  }

  expose_http = {
    container_port = 80
    domains        = ["monitorbot.infra.rust-lang.org"]

    health_check_path     = "/"
    health_check_interval = 5
    health_check_timeout  = 2
  }
}
