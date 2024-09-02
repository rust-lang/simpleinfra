locals {
  address_space = "10.1.0.0/16"
}

resource "azurerm_virtual_network" "dev_desktops" {
  name                = "${var.resource_group_name}-${replace(lower(var.location), " ", "")}"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [local.address_space]

  tags = {
    Name = "dev-desktops"
  }
}

resource "azurerm_subnet" "internal" {
  name                              = "internal"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.dev_desktops.name
  address_prefixes                  = [cidrsubnet(local.address_space, 8, 1)]
  private_endpoint_network_policies = "Enabled"
}
