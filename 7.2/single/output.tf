output "FGT-01PublicIP" {
  value = azurerm_public_ip.FGTPublicIp.ip_address
}
output "FGT-02Username" {
  value = var.adminusername
}
output "FGT-03Password" {
  value = var.adminpassword
}