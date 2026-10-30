locals {
  admin_task_definition = module.admin.task_definition
}

# Reuse the admin image, roles, environment, secrets, storage, and logging.
# Only the task family and the app container's startup command differ.
resource "aws_ecs_task_definition" "release" {
  family                   = "docs-rs-release"
  cpu                      = local.admin_task_definition.cpu
  memory                   = local.admin_task_definition.memory
  network_mode             = local.admin_task_definition.network_mode
  task_role_arn            = local.admin_task_definition.task_role_arn
  execution_role_arn       = local.admin_task_definition.execution_role_arn
  requires_compatibilities = local.admin_task_definition.requires_compatibilities
  tags                     = local.admin_task_definition.tags

  container_definitions = jsonencode([
    for container in jsondecode(local.admin_task_definition.container_definitions) :
    # ECS adds these empty arrays when reading back the admin definition.
    # Include them during planning too, so a new admin revision cannot change
    # the derived JSON midway through apply. Preserve any configured entries.
    merge({
      mountPoints    = []
      systemControls = []
      volumesFrom    = []
      }, container, container.name == "app" ? {
      entryPoint = ["/usr/bin/tini", "--", "/bin/sh"]
      command    = ["/usr/local/bin/docs_rs_release.sh"]
    } : {})
  ])

  dynamic "ephemeral_storage" {
    for_each = local.admin_task_definition.ephemeral_storage
    content {
      size_in_gib = ephemeral_storage.value.size_in_gib
    }
  }
}
