locals {
  groups = {
    billing : aws_identitystore_group.billing
    infra : aws_identitystore_group.infra
    infra-admins : aws_identitystore_group.infra-admins
    crates-io : aws_identitystore_group.crates_io
    triagebot : aws_identitystore_group.triagebot
  }

  # Expand var.users into collection of group memberships associations
  group_memberships = flatten([for user_name, user in var.users : [
    for group in user.groups : { user : user_name, group : group }
  ]])
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
  for_each          = { for membership in local.group_memberships : "${local.groups[membership.group].display_name}[${membership.user}]" => membership }
  identity_store_id = local.identity_store_id

  member_id = aws_identitystore_user.users[each.value.user].user_id
  group_id  = local.groups[each.value.group].group_id
}
