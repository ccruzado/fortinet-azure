#############################################################################################
### Create Virtual Network
#############################################################################################
resource "azurerm_virtual_network" "spoke02vnet" {
  name                = "spoke02vnet"
  address_space       = [var.spoke02vnetcidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  tags = merge(
    local.common_tags
  )
}

resource "azurerm_subnet" "spoke02privatesubnet" {
  name                 = "spoke02privatesubnet"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.spoke02vnet.name
  address_prefixes     = [var.spoke02privatecidr]
}

#############################################################################################
### Network Security Group
#############################################################################################
resource "azurerm_network_security_group" "spoke02SecurityGroupServer" {
  name                = "spoke02SecurityGroupServer"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  security_rule {
    name                       = "All"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = merge(
    local.common_tags
  )
}

#############################################################################################
### Server Interface
#############################################################################################
resource "azurerm_network_interface" "spoke02ServerPort" {
  name                = "spoke02ServerPort"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.spoke02privatesubnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ipserverspoke02
    primary                       = true
  }

  tags = merge(
    local.common_tags
  )
}

#############################################################################################
### Connect the security group to the network interfaces
#############################################################################################
resource "azurerm_network_interface_security_group_association" "serverportspoke02" {
  depends_on                = [azurerm_network_interface.spoke02ServerPort]
  network_interface_id      = azurerm_network_interface.spoke02ServerPort.id
  network_security_group_id = azurerm_network_security_group.spoke02SecurityGroupServer.id
}

#############################################################################################
### VM spoke02
#############################################################################################
resource "azurerm_linux_virtual_machine" "spoke02Server" {
  name                = "spoke02Server"
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  location            = azurerm_resource_group.myterraformgroup.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.spoke02ServerPort.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.spoke02Ssh.public_key_openssh
  }

  os_disk {
    name                  = "spoke02Disk"
    caching               = "ReadWrite"
    storage_account_type  = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

#############################################################################################
### VM KEY
#############################################################################################
resource "tls_private_key" "spoke02Ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "spoke02SshKey" {
  filename = "spoke02SshKey.pem"
  content  = tls_private_key.spoke02Ssh.private_key_pem
}

#############################################################################################
### PEERING
#############################################################################################
resource "azurerm_virtual_network_peering" "spoke02vnetpeering01" {
  name                      = "hub-spoke02"
  resource_group_name       = azurerm_resource_group.myterraformgroup.name
  virtual_network_name      = azurerm_virtual_network.fgtvnetwork.name
  remote_virtual_network_id = azurerm_virtual_network.spoke02vnet.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "spoke02vnetpeering02" {
  name                      = "spoke02-hub"
  resource_group_name       = azurerm_resource_group.myterraformgroup.name
  virtual_network_name      = azurerm_virtual_network.spoke02vnet.name
  remote_virtual_network_id = azurerm_virtual_network.fgtvnetwork.id
  allow_forwarded_traffic   = true
}

#############################################################################################
### VM ROUTES
#############################################################################################
resource "azurerm_route_table" "spoke02Internal" {
  depends_on          = [azurerm_linux_virtual_machine.spoke02Server]
  name                = "Spoke01RouteTablesPub"
  location            = azurerm_resource_group.myterraformgroup.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
}

resource "azurerm_route" "spoke02Default" {
  name                   = "default"
  resource_group_name    = azurerm_resource_group.myterraformgroup.name
  route_table_name       = azurerm_route_table.spoke02Internal.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.fgtport2.private_ip_address
}

resource "azurerm_subnet_route_table_association" "spoke02InternalAssociate" {
  depends_on     = [azurerm_route_table.spoke02Internal]
  subnet_id      = azurerm_subnet.spoke02privatesubnet.id
  route_table_id = azurerm_route_table.spoke02Internal.id
}

#############################################################################################
### VARIABLES
#############################################################################################
variable "spoke02vnetcidr" {
}
variable "spoke02privatecidr" {
}
variable "ipserverspoke02" {
}
