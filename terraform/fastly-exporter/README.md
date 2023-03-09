# Prometheus Exporter for Fastly

This module deploys a Prometheus exporter for Fastly using the official
[fastly/fastly-exporter] Docker image. The implementation uses the [`ecs-task`]
and [`ecs-service`] modules to deploy the exporter to ECS.

[`ecs-service`]: ../../terragrunt/modules/ecs-service
[`ecs-task`]: ../../terragrunt/modules/ecs-task
[fastly/fastly-exporter]: https://github.com/fastly/fastly-exporter
