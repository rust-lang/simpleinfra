resource "azurerm_public_ip" "v4" {
  for_each = var.instances

  name                = "${each.key}-v4"
  resource_group_name = azurerm_resource_group.dev_desktops.name
  location            = azurerm_resource_group.dev_desktops.location
  allocation_method   = "Dynamic"
  domain_name_label   = each.key

  tags = {
    Name = "dev-desktops"
  }
}

resource "azurerm_network_interface" "instance" {
  for_each = var.instances

  name                = each.key
  resource_group_name = azurerm_resource_group.dev_desktops.name
  location            = azurerm_resource_group.dev_desktops.location

  ip_configuration {
    name                          = "primary4"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.v4[each.key].id
    primary                       = true
  }

  tags = {
    Name = "dev-desktops"
  }
}

resource "azurerm_network_interface_security_group_association" "instance" {
  for_each = var.instances

  network_interface_id      = azurerm_network_interface.instance[each.key].id
  network_security_group_id = azurerm_network_security_group.dev_desktops.id
}

resource "azurerm_linux_virtual_machine" "instance" {
  for_each = var.instances

  name                = each.key
  resource_group_name = azurerm_resource_group.dev_desktops.name
  location            = azurerm_resource_group.dev_desktops.location
  size                = each.value.instance_type

  admin_username = "ubuntu"

  network_interface_ids = [
    azurerm_network_interface.instance[each.key].id,
  ]

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    name                 = each.key
    storage_account_type = "StandardSSD_LRS"
    caching              = "None"
    disk_size_gb         = each.value.storage
  }

  admin_ssh_key {
    username = "ubuntu"
    # buildbot-west-slave-key
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdGoRV9XPamZwqCMr4uk1oHWPnknzwOOSjuRBnu++WRkn7TtCM4ndDfqtKnvzlX5mzPhdvO1KKx1K8TiJ3wiq7WS4AFLGKQmPHWjg8qxGW7x4S8DHrb4ctmaujZ1+XCNSK3nsCl1lLW8DOrRlKbfeHIAllbMBZxIRmQ+XICVvhKAmSmxzTmYC8tBqvqQprG/uIuKonjLxL/ljtBxXBNECXl/JFCYG0AsB0aiuiMVeHLVzMiEppQ7YP/5Ml1Rpmn6h0dDzFtoD7xenroS98BIQF5kQWhakHbtWcNMz7DVFghWgi9wYr0gtoIshhqWYorC4yJq6HGXd0qdNHuLWNz39h"
  }

  tags = {
    Name = "dev-desktops"
  }
}
