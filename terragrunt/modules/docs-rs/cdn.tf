locals {
  secret_store_name = "docs_rs_secrets"
  config_store_name = "docs_rs_config"
}

resource "random_password" "origin_auth" {
  length  = 32
  special = false
}
