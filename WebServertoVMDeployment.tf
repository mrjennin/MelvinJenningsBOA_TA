# Define the provider (in this case, Azure)
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "MelvinTest_rg" {
  name     = "MelvinTest-resources"
  location = "East US"
}

# Create a virtual network
resource "azurerm_virtual_network" "MelvinTest_vnet" {
  name                = "MelvinTest-vnet"
  location            = azurerm_resource_group.MelvinTest_rg.location
  resource_group_name = azurerm_resource_group.MelvinTest_rg.name
  address_space       = ["10.0.0.0/16"]
}

# Create a subnet
resource "azurerm_subnet" "MelvinTest_subnet" {
  name                 = "MelvinTest-subnet"
  resource_group_name  = azurerm_resource_group.MelvinTest_rg.name
  virtual_network_name = azurerm_virtual_network.MelvinTest_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a public IP
resource "azurerm_public_ip" "MelvinTest_public_ip" {
  name                = "MelvinTest-public-ip"
  location            = azurerm_resource_group.MelvinTest_rg.location
  resource_group_name = azurerm_resource_group.MelvinTest_rg.name
  allocation_method   = "Dynamic"
}

# Create a network interface
resource "azurerm_network_interface" "MelvinTest_nic" {
  name                = "MelvinTest-nic"
  location            = azurerm_resource_group.MelvinTest_rg.location
  resource_group_name = azurerm_resource_group.MelvinTest_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.MelvinTest_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.MelvinTest_public_ip.id
  }
}

# Create a virtual machine
resource "azurerm_linux_virtual_machine" "MelvinTest_vm" {
  name                = "MelvinTest-vm"
  resource_group_name = azurerm_resource_group.MelvinTest_rg.name
  location            = azurerm_resource_group.MelvinTest_rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.MelvinTest_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name  = "MelvinTestvm"
  admin_password = "P@ssw0rd1234!"

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx",
    ]
  }
}

# Output the public IP of the VM
output "public_ip" {
  value = azurerm_public_ip.MelvinTest_public_ip.ip_address
}
