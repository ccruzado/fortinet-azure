// Resource Group

resource "azurerm_resource_group" "myterraformgroup" {
  name     = "ccruzado-single"
  location = var.location

  tags = merge(
    local.common_tags
  )
}
locals {
  common_tags = {
    Name                = var.t_name
    Username            = var.t_username
    ExpectedUseThrough  = var.t_expectedusethrough
    VMState             = var.t_vmstate
    CostCenter          = var.t_costcenter
  }
}