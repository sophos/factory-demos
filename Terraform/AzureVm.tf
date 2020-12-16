provider "azurerm" {
  version = "=2.0.0"
  features {}
}

variable "prefix" {
}

variable "location" {
}

variable "publisher" {
}

variable "offer" {
}

variable "sku" {
}

variable "adminUsername" {
}

variable "publicKey" {
}

#Resource Group is commented out because it should already exist
#resource "azurerm_resource_group" "example" {
#  name     = var.prefix
#  location = var.location
#}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.prefix
}

resource "azurerm_subnet" "example" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = var.prefix
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefix       = "10.0.2.0/24"
  depends_on = [
    azurerm_virtual_network.example,
  ]
}

resource "azurerm_public_ip" "example" {
  name                    = "${var.prefix}-pip"
  location                = var.location
  resource_group_name     = var.prefix
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}

resource "azurerm_network_interface" "example" {
  name                = "${var.prefix}-nic"
  location            = var.location
  resource_group_name = var.prefix
  
  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
  depends_on = [
    azurerm_subnet.example,
    azurerm_virtual_network.example,
    azurerm_public_ip.example,
  ]
}

resource "azurerm_virtual_machine" "example" {
  name                  = "${var.prefix}-vm"
  location              = var.location
  resource_group_name   = var.prefix
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.prefix}-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${var.prefix}-vm"
    admin_username = var.adminUsername
    admin_password = "ABC123!!!abc"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
        path     = "/home/${var.adminUsername}/.ssh/authorized_keys"
        key_data = var.publicKey
    }   
    }
  depends_on = [
    azurerm_virtual_network.example,
    azurerm_subnet.example,
    azurerm_network_interface.example,
  ]
}

data "azurerm_public_ip" "example" {
  name                = azurerm_public_ip.example.name
  resource_group_name = var.prefix
}

output "ipAddress" {
  value = data.azurerm_public_ip.example.ip_address
}