resource "aws_ecs_service" "service" {
  name             = var.name
  cluster          = var.cluster_config.cluster_id
  task_definition  = var.task_arn
  desired_count    = var.tasks_count
  launch_type      = "FARGATE"
  platform_version = var.platform_version

  deployment_minimum_healthy_percent = var.deployment_minimum_healty_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  enable_ecs_managed_tags = true

  load_balancer {
    target_group_arn = aws_lb_target_group.service.arn
    container_name   = var.http_container
    container_port   = var.http_port
  }

  network_configuration {
    subnets = var.cluster_config.subnet_ids
    security_groups = concat(
      [var.cluster_config.service_security_group_id],
      var.additional_security_group_ids,
    )
    assign_public_ip = false
  }
}
