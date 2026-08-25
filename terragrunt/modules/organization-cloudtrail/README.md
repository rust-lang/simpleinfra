# Organization CloudTrail

This module creates one multi-Region organization trail. The trail records read
and write management events in a private, versioned S3 bucket. CloudTrail
delivers signed digest files that can be used to validate log-file integrity.
The bucket expires current log objects after 365 days and permanently deletes
their noncurrent versions 30 days later.

The module also deploys the official Datadog Forwarder using Datadog's
[`log-lambda-forwarder-datadog` Terraform module][forwarder-module]. The
[`datadog-aws`](../datadog-aws) module reads the output to
register the Forwarder and enable CloudTrail logs auto-subscription.

The Forwarder assigns the `cloudtrail` source to the logs.
Datadog Cloud SIEM can analyze these logs filtering by source.

[forwarder-module]: https://registry.terraform.io/modules/DataDog/log-lambda-forwarder-datadog/aws/latest
