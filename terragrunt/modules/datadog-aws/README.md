# AWS Integration for Datadog

[Datadog] is a monitoring and observability platform that we use to monitor
our cloud infrastructure. Datadog provides an [integration for AWS][datadog-aws]
and a [Terraform module] to manage it, which we use in this module.

We use [tags](https://docs.datadoghq.com/getting_started/tagging/) to make it
easy to filter and group metrics in Datadog. Each AWS account is tagged with the
following variables:

- `env`: The environment of the account, either `prod` or `staging`

[datadog]: https://datadoghq.com
[datadog-aws]: https://docs.datadoghq.com/integrations/amazon_web_services/
[terraform module]: https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_aws
