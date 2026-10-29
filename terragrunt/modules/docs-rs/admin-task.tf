module "admin" {
  source = "../ecs-task"

  name           = "docs-rs-admin"
  container_name = "app"
  # Total task resources, including Datadog; leave 1 GiB for the app.
  cpu           = 512
  memory        = 2048
  port_mappings = []
  datadog       = local.datadog

  # Keep the image entrypoint (tini + docs_rs_admin); RunTask overrides arguments.
  command = ["--help"]

  environment_variables = merge(local.common_environment, {
    DOCSRS_MIN_POOL_IDLE = "1"
    DOCSRS_MAX_POOL_SIZE = "10"
  })
  computed_secrets = local.common_computed_secrets
}
