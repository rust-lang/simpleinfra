# AWS Integration for Datadog

[Datadog] is a monitoring and observability platform that we use to monitor
our cloud infrastructure. Datadog provides an [integration for AWS][datadog-aws]
and a [Terraform module] to manage it, which we use in this module.

We use [tags](https://docs.datadoghq.com/getting_started/tagging/) to make it
easy to filter and group metrics in Datadog. Each AWS account is tagged with the
following variables:

- `env`: The environment of the account, either `prod` or `staging`

## Organization CloudTrail

The organization management account enables the optional organization
CloudTrail integration. It creates one multi-Region trail that records read and
write management events, including global service events, in a private,
versioned S3 bucket. Log-file validation is enabled, and objects are retained
for 365 days by default.

The integration also deploys the official Datadog Forwarder using Datadog's
[`log-lambda-forwarder-datadog` Terraform module][forwarder-module]. The
Datadog AWS integration registers the Forwarder and enables CloudTrail log
auto-subscription. This lets Datadog configure the S3 notification that invokes
the Forwarder for new log files. Forwarded logs have the `cloudtrail` source and
can be analyzed by Cloud SIEM.

The Forwarder's S3 read permission is deliberately restricted to the bucket
created for this organization trail instead of using the upstream module's
default access to all S3 buckets. This preserves least privilege for the
intended single-trail setup. Enabling the `cloudtrail` log source makes Datadog
auto-subscription discover every CloudTrail trail in the account; the
`dd_s3_log_bucket_arns` setting only limits which objects the Forwarder can
read. If another trail is added, Datadog can attach the Forwarder to its
destination while the Forwarder remains unable to read its objects. Add the new
destination's object ARN (`arn:aws:s3:::bucket-name/*`) to
`dd_s3_log_bucket_arns` before enabling another trail, or remove the restriction
to accept the upstream module's broader automatic-subscription behavior. See
the upstream module's [S3 access warning][forwarder-s3-access].

### Prerequisite

Create a dedicated Datadog API key and store it as a plaintext Secrets Manager
secret in the root account. The key value must not be committed to this
repository or passed through Terraform state:

```shell
aws secretsmanager create-secret \
  --profile rust-root \
  --region us-east-1 \
  --name /prod/datadog/cloudtrail-api-key \
  --secret-string "$DD_API_KEY"
```

Terraform resolves the secret's metadata while planning, and the Forwarder
reads its value at runtime. The secret must therefore exist before running
`terragrunt plan` or `terragrunt apply`.

### Deployment

CloudTrail trusted access must be enabled in AWS Organizations before creating
an organization trail. This repository manages trusted access in the
`aws-organization` state, which must be applied first:

```shell
cd terragrunt/accounts/root/aws-organization
terragrunt apply

cd ../datadog-aws
terragrunt apply
```

The `datadog-aws` apply requires `DD_API_KEY` and `DD_APP_KEY` for the Datadog
provider in addition to the `rust-root` AWS profile. These operator credentials
are separate from the Forwarder API key stored in Secrets Manager. Datadog
creates the S3 notification asynchronously after the apply.

Before applying, check for an existing unmanaged organization trail. Creating a
second copy of management events can incur duplicate CloudTrail charges. Import
an equivalent existing trail and bucket instead of creating a duplicate.

After deployment, enable Cloud SIEM and its AWS content pack in Datadog, then
verify that the Log Explorer query `source:cloudtrail` returns recent events.

[datadog]: https://datadoghq.com
[datadog-aws]: https://docs.datadoghq.com/integrations/amazon_web_services/
[forwarder-module]: https://registry.terraform.io/modules/DataDog/log-lambda-forwarder-datadog/aws/latest
[forwarder-s3-access]: https://github.com/DataDog/terraform-aws-log-lambda-forwarder-datadog#restricting-s3-log-read-access
[terraform module]: https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_aws_account
