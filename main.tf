terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.16.0"
    }
  }
}

provider "azurerm" {
  features {
     resource_group {
       prevent_deletion_if_contains_resources = false
     }
  }
}

resource "azurerm_resource_group" "rg_tf_mgm" {
    name = var.rgName
    location = var.location
    tags = {
      environment = "management"
    }
}

resource "azurerm_virtual_network" "mgm-network" {
  name                = var.netName
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_tf_mgm.location
  resource_group_name = azurerm_resource_group.rg_tf_mgm.name
}

resource "azurerm_subnet" "internal" {
  name                 = var.subnetName
  resource_group_name  = azurerm_resource_group.rg_tf_mgm.name
  virtual_network_name = azurerm_virtual_network.mgm-network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "windowsRDP-vm-nsg" {
  name                = "windowsRDP-vm-nsg"
  location            = azurerm_resource_group.rg_tf_mgm.location
  resource_group_name = azurerm_resource_group.rg_tf_mgm.name
  security_rule {
    name                       = "allow-rdp"
    description                = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*" 
  }
}

resource "azurerm_subnet_network_security_group_association" "windows-vm-nsg-association" {
  depends_on=[azurerm_network_security_group.windowsRDP-vm-nsg]
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.windowsRDP-vm-nsg.id
}

resource "azurerm_public_ip" "windows-vm-ip" {
  name                = "windows-vm-ip"
  location            = azurerm_resource_group.rg_tf_mgm.location
  resource_group_name = azurerm_resource_group.rg_tf_mgm.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "windows-vm-nic" {
  depends_on=[azurerm_public_ip.windows-vm-ip]
  name                = "windows-vm-nic"
  location            = azurerm_resource_group.rg_tf_mgm.location
  resource_group_name = azurerm_resource_group.rg_tf_mgm.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.windows-vm-ip.id
  }
}

resource "azurerm_virtual_machine" "windows-vm" {
  depends_on=[azurerm_network_interface.windows-vm-nic]
  name                  = var.vmName
  location              = azurerm_resource_group.rg_tf_mgm.location
  resource_group_name   = azurerm_resource_group.rg_tf_mgm.name
  network_interface_ids = [azurerm_network_interface.windows-vm-nic.id]
  vm_size               = "Standard_DS1_v2"
  os_profile_windows_config {}
  os_profile {
    computer_name  = var.vmName
    admin_username = var.user
    admin_password = var.pass
  }
  storage_os_disk {
    name                 = "windows-vm-os-disk"
    caching              = "ReadWrite"
    create_option        = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}
