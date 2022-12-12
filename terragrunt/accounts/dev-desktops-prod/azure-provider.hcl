# Automatically include the Azure provider with the right subscription
generate "azure" {
  path = "terragrunt-generated-azure-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
    provider "azurerm" {
      features {}
      subscription_id = "ff8cd1a5-37b4-4c55-a8db-b48366d902e0"
    }
  EOF
}
