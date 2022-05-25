output "ResourceGroup" {
  value = azurerm_resource_group.myterraformgroup.name
}

output "FGTPublicIP" {
  value = azurerm_public_ip.FGTPublicIp.ip_address
}
output "Username" {
  value = var.adminusername
}

output "Password" {
  value = var.adminpassword
}
output "Spoke01PublicIP" {
  value = azurerm_public_ip.spoke01ServerPublicIP.ip_address

}

