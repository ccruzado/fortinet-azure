#############################################################################################
### ROUTE PUB
#############################################################################################
resource "azurerm_route_table" "fgtRouteTablePub" {
  depends_on          = [azurerm_virtual_machine.fgtvm]
  name                = "fgtRouteTablePub"
  location            = azurerm_resource_group.myterraformgroup.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
}
resource "azurerm_route" "fgtRouteTablePubInternet" {
  name                   = "Internet"
  resource_group_name    = azurerm_resource_group.myterraformgroup.name
  route_table_name       = azurerm_route_table.fgtRouteTablePub.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "Internet"
}
resource "azurerm_route" "fgtRouteTablePubInside" {
  name                   = "InsideSubnet"
  resource_group_name    = azurerm_resource_group.myterraformgroup.name
  route_table_name       = azurerm_route_table.fgtRouteTablePub.name
  address_prefix         = var.privatecidr
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.fgtport1.private_ip_address
  
}
resource "azurerm_subnet_route_table_association" "rtPublicAssociate" {
  depends_on     = [azurerm_route_table.fgtRouteTablePub]
  subnet_id      = azurerm_subnet.publicsubnet.id
  route_table_id = azurerm_route_table.fgtRouteTablePub.id
}
#############################################################################################
### ROUTE PRI
#############################################################################################
resource "azurerm_route_table" "fgtRouteTablePri" {
  depends_on          = [azurerm_virtual_machine.fgtvm]
  name                = "fgtRouteTablePri"
  location            = azurerm_resource_group.myterraformgroup.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
}
resource "azurerm_route" "default" {
  name                   = "default"
  resource_group_name    = azurerm_resource_group.myterraformgroup.name
  route_table_name       = azurerm_route_table.fgtRouteTablePri.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.fgtport2.private_ip_address
}

resource "azurerm_subnet_route_table_association" "rtPrivateAssociate" {
  depends_on     = [azurerm_route_table.fgtRouteTablePri]
  subnet_id      = azurerm_subnet.privatesubnet.id
  route_table_id = azurerm_route_table.fgtRouteTablePri.id
}
