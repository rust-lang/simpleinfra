locals {
  address_space = "10.1.0.0/16"
}

resource "azurerm_virtual_network" "dev_desktops" {
  name                = "dev-desktops"
  resource_group_name = azurerm_resource_group.dev_desktops.name
  location            = azurerm_resource_group.dev_desktops.location
  address_space       = [local.address_space]

  tags = {
    Name = "dev-desktops"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.dev_desktops.name
  virtual_network_name = azurerm_virtual_network.dev_desktops.name
  address_prefixes     = [cidrsubnet(local.address_space, 8, 1)]
}
