locals {
  # This is a list of all users from all teams. When a user is part of multiple teams, this list will contain multiple
  # entries for that user (one for each team). These entries will have different roles.
  #
  # Example:
  #
  #   [
  #     { "alice" = { login = "Alice", email = "alice@example.com", roles = ["crates.io"] } },
  #     { "bob" = { login = "Bob", email = "bob@example.com", roles = ["Board Member"] } },
  #     { "alice" = { login = "Alice", email = "alice@example.com", roles = ["Foundation Staff"] } },
  #   ]
  _do_not_use_all_teams = [
    { for name, user in local.crates_io : name => merge(user, { roles = [datadog_role.crates_io.name] }) },
    { for name, user in local.foundation : name => merge(user, { roles = [datadog_role.foundation.name] }) },
    { for name, user in local.foundation_board : name => merge(user, { roles = [datadog_role.board_member.name] }) },
    { for name, user in local.infra_admins : name => merge(user, { roles = ["Datadog Admin Role"] }) },
  ]

  # This is an intermediate list that contains a single entry per user, but only with the roles from the first team.
  # The list is used in the next step to merge all roles for each user.
  # Example:
  #
  #   {
  #     "alice" = { login = "Alice", email = "alice@example.com", roles = ["crates.io"] },
  #     "bob" = { login = "Bob", email = "bob@example.com", roles = ["Board Member"] }
  #   }
  _do_not_use_all_users_with_single_role = merge(local._do_not_use_all_teams...)

  # This list contains a single entry per user, with all the roles that user has across all teams.
  #
  # Example:
  #
  #   [
  #     { "alice" = { login = "Alice", email = "alice@example.com", roles = ["crates.io", "Foundation Staff"] } },
  #     { "bob" = { login = "Bob", email = "bob@example.com", roles = ["Board Member"] } },
  #   ]
  all_user_with_merged_roles = {
    for name, user in local._do_not_use_all_users_with_single_role : name => {
      login = user.login
      name  = user.name
      roles = distinct(flatten([
        for team in local._do_not_use_all_teams : concat([
          for inner_name, user in team : user.roles if name == inner_name
        ])
      ]))
    }
  }
}

data "datadog_role" "role" {
  for_each = toset(flatten(values({
    for index, user in local.all_user_with_merged_roles : user.login => user.roles
  })))

  filter = each.value
}

resource "datadog_user" "users" {
  for_each = local.all_user_with_merged_roles

  email                = each.value.login
  name                 = each.value.name
  roles                = [for role in each.value.roles : data.datadog_role.role[role].id]
  send_user_invitation = true
}
