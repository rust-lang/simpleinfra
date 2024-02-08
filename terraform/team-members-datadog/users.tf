locals {
  users = merge(
    { for name, user in local.crates_io : name => merge(user, { roles = ["crates.io"] }) },
    { for name, user in local.foundation : name => merge(user, { roles = ["Datadog Read Only Role"] }) },
    { for name, user in local.foundation_board : name => merge(user, { roles = ["Board Member"] }) },
    { for name, user in local.infra_admins : name => merge(user, { roles = ["Datadog Admin Role"] }) },
  )
}

data "datadog_role" "role" {
  for_each = toset(flatten(values({
    for index, user in local.users : user.login => user.roles
  })))

  filter = each.value
}

resource "datadog_user" "users" {
  for_each = local.users

  email                = each.value.login
  name                 = each.value.name
  roles                = [for role in each.value.roles : data.datadog_role.role[role].id]
  send_user_invitation = true
}
