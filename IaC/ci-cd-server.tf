# ci-cd-server.tf

# Network Configuration
resource "azurerm_virtual_network" "default" {
  name                = "${random_pet.prefix.id}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"  # Change the region to "eastus" or any other region
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_subnet" "default" {
  name                 = "${random_pet.prefix.id}-subnet"
  resource_group_name  = azurerm_resource_group.default.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "ci_cd_nsg" {
  name                = "${random_pet.prefix.id}-nsg"
  location            = "eastus"  # Change the region to "eastus" or any other region
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_network_security_rule" "allow_9000" {
  name                        = "Allow_TCP_9000"
  priority                    = 1003
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 9000
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.default.name
  network_security_group_name = azurerm_network_security_group.ci_cd_nsg.name
}

resource "azurerm_network_security_rule" "allow_8080" {
  name                        = "Allow_TCP_8080"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 8080
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.default.name
  network_security_group_name = azurerm_network_security_group.ci_cd_nsg.name
}
resource "azurerm_network_security_rule" "allow_22" {
  name                        = "Allow_TCP_22"
  priority                    = 1004
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 22
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.default.name
  network_security_group_name = azurerm_network_security_group.ci_cd_nsg.name
}
# Virtual Machine Configuration
resource "azurerm_network_interface" "ci_cd_nic" {
  name                = "${random_pet.prefix.id}-nic"
  location            = "eastus"  # Change the region to "eastus" or any other region
  resource_group_name = azurerm_resource_group.default.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_public_ip" "ci_cd_public_ip" {
  name                = "${random_pet.prefix.id}-public-ip"
  location            = "eastus"  # Change the region to "eastus" or any other region
  resource_group_name = azurerm_resource_group.default.name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_machine" "ci_cd_vm" {
  name                  = "${random_pet.prefix.id}-vm"
  location              = "eastus"  # Change the region to "eastus" or any other region
  resource_group_name   = azurerm_resource_group.default.name
  network_interface_ids = [azurerm_network_interface.ci_cd_nic.id]

  vm_size = "Standard_D2_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "wondrous-cicada-osdisk222"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${random_pet.prefix.id}-vm"
    admin_username = "ai-admin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/ai-admin/.ssh/authorized_keys"
      key_data = file("./id_rsa.pub")
    }
  }

  tags = {
    environment = "Staging"
  }
}
