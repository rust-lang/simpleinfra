// ECS deployment and CI integration of crates-io-heroku-metrics.

module "crates_io_heroku_metrics" {
  source         = "../shared/modules/ecs-app"
  cluster_config = data.terraform_remote_state.shared.outputs.ecs_cluster_config

  env  = "prod"
  name = "crates-io-heroku-metrics"
  repo = "rust-lang/crates-io-heroku-metrics"

  cpu              = 1024
  memory           = 2048
  tasks_count      = 1
  platform_version = "1.4.0"

  secrets = {
    PASSWORD_DRAIN   = "/prod/crates-io-heroku-metrics/password-drain"
    PASSWORD_METRICS = "/prod/crates-io-heroku-metrics/password-metrics"
  }

  expose_http = {
    container_port = 80
    domains        = ["crates-io-heroku-metrics.infra.rust-lang.org"]

    prometheus = null

    health_check_path     = "/health"
    health_check_interval = 60
    health_check_timeout  = 15
  }
}
