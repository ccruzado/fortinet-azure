#############################################################################################
### Create Virtual Network
#############################################################################################
resource "azurerm_virtual_network" "spoke01vnet" {
  name                = "spoke01vnet"
  address_space       = [var.spoke01vnetcidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  tags = merge(
    local.common_tags
  )
}

resource "azurerm_subnet" "spoke01publicsubnet" {
  name                 = "spoke01publicsubnet"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.spoke01vnet.name
  address_prefixes     = [var.spoke01publiccidr]
}

resource "azurerm_subnet" "spoke01privatesubnet" {
  name                 = "spoke01privatesubnet"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.spoke01vnet.name
  address_prefixes     = [var.spoke01privatecidr]
}

# Allocated Public IP
resource "azurerm_public_ip" "spoke01ServerPublicIP" {
  name                = "spoke01ServerPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  allocation_method   = "Static"

  tags = merge(
    local.common_tags
  )
}

#############################################################################################
### Network Security Group
#############################################################################################
resource "azurerm_network_security_group" "spoke01SecurityGroupServer" {
  name                = "spoke01SecurityGroupServer"
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
resource "azurerm_network_interface" "spoke01ServerPort" {
  name                = "spoke01ServerPort"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.spoke01publicsubnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ipserverspoke01
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.spoke01ServerPublicIP.id
  }

  tags = merge(
    local.common_tags
  )
}

#############################################################################################
### Connect the security group to the network interfaces
#############################################################################################
resource "azurerm_network_interface_security_group_association" "serverportspoke01" {
  depends_on                = [azurerm_network_interface.spoke01ServerPort]
  network_interface_id      = azurerm_network_interface.spoke01ServerPort.id
  network_security_group_id = azurerm_network_security_group.spoke01SecurityGroupServer.id
}

#############################################################################################
### VM SPOKE01
#############################################################################################
resource "azurerm_linux_virtual_machine" "spoke01Server" {
  name                = "spoke01Server"
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  location            = azurerm_resource_group.myterraformgroup.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.spoke01ServerPort.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.spoke01Ssh.public_key_openssh
  }

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
}

#############################################################################################
### VM KEY
#############################################################################################
resource "tls_private_key" "spoke01Ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "spoke01SshKey" {
  filename = "spoke01SshKey.pem"
  content  = tls_private_key.spoke01Ssh.private_key_pem
}

#############################################################################################
### PEERING
#############################################################################################
resource "azurerm_virtual_network_peering" "spoke01vnetpeering01" {
  name                      = "hub-spoke01"
  resource_group_name       = azurerm_resource_group.myterraformgroup.name
  virtual_network_name      = azurerm_virtual_network.fgtvnetwork.name
  remote_virtual_network_id = azurerm_virtual_network.spoke01vnet.id
}

resource "azurerm_virtual_network_peering" "spoke01vnetpeering02" {
  name                      = "spoke01-hub"
  resource_group_name       = azurerm_resource_group.myterraformgroup.name
  virtual_network_name      = azurerm_virtual_network.spoke01vnet.name
  remote_virtual_network_id = azurerm_virtual_network.fgtvnetwork.id
}

#############################################################################################
### VM ROUTES
#############################################################################################
resource "azurerm_route_table" "spoke01Internal" {
  depends_on          = [azurerm_linux_virtual_machine.spoke01Server]
  name                = "Spoke01InternalRouteTables"
  location            = azurerm_resource_group.myterraformgroup.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
}

resource "azurerm_route" "spoke01Default" {
  name                   = "default"
  resource_group_name    = azurerm_resource_group.myterraformgroup.name
  route_table_name       = azurerm_route_table.spoke01Internal.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.fgtport2.private_ip_address
}

resource "azurerm_subnet_route_table_association" "spokeInternalAssociate" {
  depends_on     = [azurerm_route_table.spoke01Internal]
  subnet_id      = azurerm_subnet.spoke01publicsubnet.id
  route_table_id = azurerm_route_table.spoke01Internal.id
}