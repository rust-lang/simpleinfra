resource "azurerm_network_security_group" "dev_desktops" {
  name                = "dev-desktops"
  resource_group_name = azurerm_resource_group.dev_desktops.name
  location            = azurerm_resource_group.dev_desktops.location

  security_rule {
    name                       = "node_exporter"
    description                = "node_exporter from monitoring.infra.rust-lang.org"
    access                     = "Allow"
    direction                  = "Inbound"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefixes    = toset(data.dns_a_record_set.monitoring.addrs)
    destination_port_range     = 9100
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ssh"
    description                = "SSH access from the world"
    access                     = "Allow"
    direction                  = "Inbound"
    priority                   = 101
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = 22
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "mosh"
    description                = "Mosh access from the world"
    access                     = "Allow"
    direction                  = "Inbound"
    priority                   = 102
    protocol                   = "Udp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "60000-61000"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ping"
    description                = "Ping access from the world"
    access                     = "Allow"
    direction                  = "Inbound"
    priority                   = 103
    protocol                   = "Icmp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "egress"
    description                = "Outbound traffic to the world"
    access                     = "Allow"
    direction                  = "Outbound"
    priority                   = 104
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "*"
    destination_address_prefix = "*"
  }
}

data "dns_a_record_set" "monitoring" {
  host = "monitoring.infra.rust-lang.org"
}
