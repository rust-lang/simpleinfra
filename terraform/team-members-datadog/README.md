# Team Members on Datadog

This Terraform configuration manages user accounts on Datadog. When a user is
added to [`users.tf`](users.tf), they get invited to join our Datadog account.

## Roles

Datadog uses _roles_ to manage who can do what on the platform.

Members of the infra-admins team are assigned the `Datadog Admin Role` role.
Members of other teams get the `Datadog Standard Role` role.

## Usage

Applying the Terraform configuration requires an API key as well as an app key.
Both can be found on the [Datadog API keys page][api-keys].

```shell
export DD_API_KEY="datadog-api-key"
export DD_APP_KEY="datadog-app-key"
terraform plan
```

[api-keys]: https://app.datadoghq.com/organization-settings/api-keys
