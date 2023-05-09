# Fastly Integration for Datadog

[Datadog] is a monitoring and observability platform that we use to monitor
our cloud infrastructure. Datadog provides an
[integration for Fastly][datadog-fastly] and a [Terraform module] to manage it,
which we use in this module.

We use [tags](https://docs.datadoghq.com/getting_started/tagging/) to make it
easy to filter and group metrics in Datadog. Each Fastly service is tagged with
the following variables:

- `env`: The environment of the service, either `prod` or `staging`

[datadog]: https://datadoghq.com
[datadog-fastly]: https://docs.datadoghq.com/integrations/fastly
[terraform module]: https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_fastly_account
