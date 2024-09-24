// ECS deployment and CI integration of monitorbot.

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
    MONITORBOT_RUNNERS_REPOS               = "rust-lang-ci/rust"
    MONITORBOT_GH_RATE_LIMIT_STATS_REFRESH = 40
  }

  secrets = {
    MONITORBOT_GITHUB_TOKEN      = "/prod/monitorbot/github-token"
    MONITORBOT_RATE_LIMIT_TOKENS = "/prod/monitorbot/rate-limit-tokens"
  }

  computed_secrets = {
    MONITORBOT_SECRET = aws_ssm_parameter.secret.arn
  }

  expose_http = {
    container_port = 80
    domains        = ["monitorbot.infra.rust-lang.org"]

    prometheus = null

    health_check_path     = "/"
    health_check_interval = 5
    health_check_timeout  = 2
  }
}

// Generate the secret key used to access the metrics and store it in AWS
// Parameter Store. Prometheus will then fetch the credentials from it.

resource "random_password" "secret" {
  length  = 32
  special = true
}

resource "aws_ssm_parameter" "secret" {
  type  = "SecureString"
  name  = "/prod/monitorbot/secret"
  value = random_password.secret.result
}
