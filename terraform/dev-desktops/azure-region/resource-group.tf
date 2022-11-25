resource "azurerm_resource_group" "dev_desktops" {
  name     = "dev-desktops-${replace(lower(var.location), " ", "-")}"
  location = var.location

  tags = {
    Name = "dev-desktops"
  }
}
