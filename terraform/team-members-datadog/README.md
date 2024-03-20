# Team Members on Datadog

This Terraform configuration manages user accounts on Datadog. When a user is
added to [`users.tf`](users.tf), they get invited to join our Datadog account.

## Usage

Applying the Terraform configuration requires an API key as well as an app key.
Both can be found on the [Datadog API keys page][api-keys].

```shell
export DD_API_KEY="datadog-api-key"
export DD_APP_KEY="datadog-app-key"
terraform plan
```

### Add a user

Adding a user is a two-step process. First, add the user to the `users.tf` file.
Then, add them to their respective team, referencing the user in `users.tf`.

For example, `jdn` has first been added as a users in `users.tf`:

```hcl
locals {
  users = {
    "jdn" = {
      // ...
    }
  }
}
```

And then to the `infra` team in `infra.tf`:

```hcl
locals {
  infra = {
    "jdn" = local.users.jdn
  }
}
```

### Add a Team

The easiest way to add a team is to copy an existing team and update its
resources. Go through the following steps before applying the configuration:

1. At the top of the file, update the `locals` block to include the correct team
   members.
2. Then update the `datadog_role` for the team and assign the appropriate
   permissions to the team.
3. Update the `datadog_team` with the proper name and description.

Then, register the team in `users.tf` in the `_do_not_use_all_teams` local.
Without this step, no team memberships will be assigned and users won't be
created.

[api-keys]: https://app.datadoghq.com/organization-settings/api-keys
