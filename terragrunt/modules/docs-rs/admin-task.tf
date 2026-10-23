module "admin" {
  source = "../ecs-task"

  name           = "docs-rs-admin"
  container_name = "app"
  cpu            = 256
  memory         = 512
  port_mappings  = []

  # Keep the image entrypoint (tini + docs_rs_admin); RunTask overrides arguments.
  command = ["--help"]

  environment_variables = merge(local.common_environment, {
    DOCSRS_MIN_POOL_IDLE = "1"
    DOCSRS_MAX_POOL_SIZE = "10"
  })
  computed_secrets = local.common_computed_secrets
  secrets          = local.common_secrets
}
