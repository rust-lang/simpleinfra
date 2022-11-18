resource "aws_identitystore_user" "jdno" {
  identity_store_id = local.identity_store_id

  display_name = "Jan David Nose"
  user_name    = "jdno"

  name {
    given_name  = "Jan David"
    family_name = "Nose"
  }

  emails {
    value   = "jandavidnose@rustfoundation.org"
    primary = true
    type    = "work"
  }
}

resource "aws_identitystore_group_membership" "jdno" {
  identity_store_id = local.identity_store_id

  member_id = aws_identitystore_user.jdno.user_id
  group_id  = aws_identitystore_group.infra-admins.group_id
}
