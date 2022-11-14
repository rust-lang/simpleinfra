# Team Members on Fastly

This Terraform configuration manages user accounts on Fastly. When a user is
added to [`users.tf`](users.tf), they get invited to join our Fastly account.

## Roles

Fastly uses _roles_ to manage who can do what on the platform.

Members of the infra-admins team are assigned the `superuser` role. Members of
other teams get the `users` role and specific permissions for the staging
environment of the service they maintain. For example, the crates team gets
permission to test configuration changes on their staging environment.

Learn more about user roles here:
<https://docs.fastly.com/en/guides/configuring-user-roles-and-permissions>

## Usage

Applying the Terraform configuration requires a [Personal API token] with the
`global` scope. Go to <https://manage.fastly.com/account/personal/tokens> and
generate a token with the following settings:

- Choose a descriptive **Name**, e.g. `terraform`
- Set **Service Access** to `All Services`
- Select `global` as the **Scope** and make sure to disable read-only access
- Leave the **Expiration** date at 3 months in the future

Then export the token as an environment variable and run any Terraform command
like you normally would:

```shell
export FASTLY_API_KEY="afastlyapikey"
terraform plan
```

[personal api token]: https://manage.fastly.com/account/personal/tokens
