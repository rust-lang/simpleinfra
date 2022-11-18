locals {
  users = {
    "jdno" = {
      given_name  = "Jan David",
      family_name = "Nose"
      email       = "jandavidnose@rustfoundation.org"
      groups      = ["infra", "infra-admins"]
    }
  }
}

resource "aws_identitystore_user" "users" {
  for_each          = local.users
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

resource "aws_identitystore_group_membership" "infra_admins_group_membership" {
  for_each = { for key, val in local.users :
  key => val if contains(val.groups, "infra-admins") }
  identity_store_id = local.identity_store_id

  member_id = aws_identitystore_user.users[each.key].user_id
  group_id  = aws_identitystore_group.infra-admins.group_id
}

resource "aws_identitystore_group_membership" "infra_group_membership" {
  for_each = { for key, val in local.users :
  key => val if contains(val.groups, "infra") }
  identity_store_id = local.identity_store_id

  member_id = aws_identitystore_user.users[each.key].user_id
  group_id  = aws_identitystore_group.infra.group_id
}
