locals {
  infra_group        = aws_identitystore_group.infra
  infra_admins_group = aws_identitystore_group.infra-admins

  # Expand local.users into collection by group association
  group_memberships = distinct(flatten([for user_name, user in var.users : [
    for group in user.groups : {
      name : user_name, group : group == "infra-admins" ? local.infra_admins_group : local.infra_group
    }
  ]]))
}

resource "aws_identitystore_user" "users" {
  for_each          = var.users
  identity_store_id = local.identity_store_id

  display_name = "${each.value.given_name} ${each.value.family_name}"
  user_name    = each.key

  name {
    given_name  = each.value.given_name
    family_name = each.value.family_name
  }

  emails {
    value   = each.value.email
    primary = true
  }
}

resource "aws_identitystore_group_membership" "group_membership" {
  for_each          = { for membership in local.group_memberships : "${membership.name}.${membership.group.id}" => membership }
  identity_store_id = local.identity_store_id

  member_id = aws_identitystore_user.users[each.value.name].user_id
  group_id  = each.value.group.group_id
}
