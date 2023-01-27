locals {
  container_name = "app"
}

module "ecs_task" {
  source = "../ecs-task"

  name                 = var.name
  env                  = var.env
  cpu                  = var.cpu
  memory               = var.memory
  ephemeral_storage_gb = var.ephemeral_storage_gb

  container_name        = local.container_name
  secrets               = var.secrets
  computed_secrets      = var.computed_secrets
  environment_variables = var.environment
  port_mappings = var.expose_http == null ? [] : [
    {
      containerPort = var.expose_http.container_port
      hostPort      = 80
      protocol      = "tcp"
    }
  ]
  docker_labels = var.expose_http == null || var.expose_http.prometheus == null ? {} : {
    PROMETHEUS_EXPORTER_PORT     = 80
    PROMETHEUS_EXPORTER_PATH     = var.expose_http.prometheus
    PROMETHEUS_EXPORTER_JOB_NAME = "ecs-${var.name}"
  }
}

// Service of the application, which schedules the application to run on the
// cluster.

module "ecs_service" {
  source           = "../ecs-service"
  cluster_config   = var.cluster_config
  platform_version = var.platform_version

  name        = var.name
  task_arn    = module.ecs_task.task_arn
  tasks_count = var.tasks_count

  http_container = local.container_name
  http_port      = 80
  domains        = var.expose_http.domains
  zone_id        = var.expose_http.zone_id

  health_check_path     = var.expose_http.health_check_path
  health_check_interval = var.expose_http.health_check_interval
  health_check_timeout  = var.expose_http.health_check_timeout

  additional_security_group_ids = var.additional_security_group_ids
}
