resource "azurerm_resource_group" "gaming" {
  name     = var.rg
  location = var.region
}

resource "random_password" "gaming" {
  length = 16
  special = true
  override_special = "_%@"
}


resource "azurerm_virtual_network" "gaming" {
  name                = "gaming-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.gaming.location
  resource_group_name = azurerm_resource_group.gaming.name
}

resource "azurerm_subnet" "gaming" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.gaming.name
  virtual_network_name = azurerm_virtual_network.gaming.name
  address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "gaming" {
  name                = "gaming-ip"
  location            = azurerm_resource_group.gaming.location
  resource_group_name = azurerm_resource_group.gaming.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "gaming" {
  name                = "gaming-nic"
  location            = azurerm_resource_group.gaming.location
  resource_group_name = azurerm_resource_group.gaming.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.gaming.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.gaming.id
  }
}

resource "azurerm_windows_virtual_machine" "gaming" {
  name                = "gaming-machine"
  resource_group_name = azurerm_resource_group.gaming.name
  location            = azurerm_resource_group.gaming.location
  priority            = var.priority == "" ? "Regular" : var.priority
  max_bid_price       = var.priority == "Spot" ? 0.6 : null
  eviction_policy     = var.priority == "Spot" ? "Deallocate" : null
  size                = var.vm_size
  admin_username      = var.user_name
  admin_password      = random_password.gaming.result
  allow_extension_operations = true
  network_interface_ids = [
    azurerm_network_interface.gaming.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h2-pron"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "gpudrivers" {
  count                = var.gpu_enabled ? 1: 0
  name                 = "NvidiaGpuDrivers"
  virtual_machine_id   = azurerm_windows_virtual_machine.gaming.id
  publisher            = "Microsoft.HpcCompute"
  type                 = "NvidiaGpuDriverWindows"
  type_handler_version = "1.3"
  auto_upgrade_minor_version = true

}

resource "azurerm_virtual_machine_extension" "ansbile" {
  name                 = "Ansible"
  virtual_machine_id   = azurerm_windows_virtual_machine.gaming.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File ConfigureRemotingForAnsible.ps1",
        "fileUris" : ["https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"]
     }
  SETTINGS
}
