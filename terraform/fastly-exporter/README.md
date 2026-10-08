# Prometheus Exporter for Fastly

This module deploys a Prometheus exporter for Fastly using the official
[fastly/fastly-exporter] Docker image.

## ECS Express Migration

**Note**: This service has been migrated to **AWS ECS Express** (November 2025), 
which simplifies deployment by automatically managing load balancing, networking, 
and scaling infrastructure. See [MIGRATION_TO_ECS_EXPRESS.md](MIGRATION_TO_ECS_EXPRESS.md) 
for details about the migration.

The implementation now uses `aws_ecs_express_gateway_service` instead of the 
traditional `ecs-task` and `ecs-service` modules, reducing complexity while 
maintaining the same functionality.

[fastly/fastly-exporter]: https://github.com/fastly/fastly-exporter
