resource "azurerm_resource_group" "vmss_test" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "vmss_test" {
  name = var.resource_group_name
  location = var.location
  address_space = ["10.0.0.0/16"]
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "vmss_test" {
  name = var.resource_group_name
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vmss_test.name
  address_prefixes = ["10.0.2.0/24"]
}

resource "azurerm_linux_virtual_machine_scale_set" "vmss_test" {
  name = var.resource_group_name
  resource_group_name = var.resource_group_name
  location = var.location
  sku = "Standard_F2"
  instances = 1
  admin_username = "adminuser"

  admin_ssh_key {
    username = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "0001-com-ubuntu-server-jammy"
    sku = "22_04-lts"
    version = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching = "ReadWrite"
  }

  network_interface {
    name = var.resource_group_name
    primary = true
    network_security_group_id = azurerm_network_security_group.vmss_test.id

    ip_configuration {
      name = var.resource_group_name
      primary = true
      subnet_id = azurerm_subnet.vmss_test.id

      public_ip_address {
        name = var.resource_group_name
        domain_name_label = "foo"
        public_ip_prefix_id = azurerm_public_ip.vmss_test.public_ip_prefix_id
      }
    }
  }
}

resource "azurerm_public_ip" "vmss_test" {
  name = var.resource_group_name
  resource_group_name = var.resource_group_name
  location = var.location
  allocation_method = "Static"


}

resource "azurerm_network_security_group" "vmss_test" {
  name = var.resource_group_name
  resource_group_name = var.resource_group_name
  location = var.location

  security_rule {
    name = "ssh"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}