// ECS deployment and CI integration of rust-log-analyzer.

module "rla" {
  source         = "../shared/modules/ecs-app"
  cluster_config = data.terraform_remote_state.shared.outputs.ecs_cluster_config

  env  = "prod"
  name = "rust-log-analyzer"
  repo = "rust-lang/rust-log-analyzer"

  cpu              = 256
  memory           = 512
  tasks_count      = 1
  platform_version = "1.4.0"
  mount_efs        = "/opt/rla"

  environment = {
    CI_REPO     = "rust-lang/rust"
    CI_PROVIDER = "actions"
    EXTRA_ARGS  = "--secondary-repo rust-lang-ci/rust"
    GITHUB_USER = "rust-log-analyzer"
    INDEX_FILE  = "/opt/rla/rust-lang/rust/actions.idx"
    RLA_LOG     = "rla_server=trace,rust_log_analyzer=trace"
  }

  secrets = {
    GITHUB_TOKEN          = "/prod/ecs/rust-log-analyzer/github-token"
    GITHUB_WEBHOOK_SECRET = "/prod/ecs/rust-log-analyzer/webhook-secret"
  }

  expose_http = {
    container_port = 80
    domains        = ["rla.infra.rust-lang.org"]

    health_check_path     = "/"
    health_check_interval = 5
    health_check_timeout  = 2
  }
}
