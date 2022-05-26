variable "size" {
}

// To use custom image
// by default is false
variable "custom" {
  default = false
}

//  Custom image blob uri
variable "customuri" {
  type    = string
  default = "<custom image blob uri>"
}

variable "custom_image_name" {
  type    = string
  default = "<custom image name>"
}

variable "custom_image_resource_group_name" {
  type    = string
  default = "<custom image resource group>"
}

// License Type to create FortiGate-VM
// Provide the license type for FortiGate-VM Instances, either byol or payg.
variable "license_type" {
}

variable "publisher" {
  type    = string
  default = "fortinet"
}

variable "fgtoffer" {
  type    = string
  default = "fortinet_fortigate-vm_v5"
}

// BYOL sku: fortinet_fg-vm
// PAYG sku: fortinet_fg-vm_payg_2022
variable "fgtsku" {
  type = map(any)
  default = {
    byol = "fortinet_fg-vm"
    payg = "fortinet_fg-vm_payg_2022"
  }
}

variable "fgtversion" {
  type    = string
  default = "7.2.0"
}

variable "adminusername" {
  type    = string
  default = "azureadmin"
}

variable "adminpassword" {
  type    = string
  default = "Fortinet123#"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "vnetcidr" {
}
variable "publiccidr" {
}
variable "privatecidr" {
}
variable "ipfgtport1" {
}
variable "ipfgtport2" {
}
variable "bootstrap-fgtvm" {
  // Change to your own path
  type    = string
  default = "fgtvm.conf"
}

// license file for the fgt
variable "license" {
}

variable "t_name" {
}
variable "t_username" {
}
variable "t_expectedusethrough" {
}
variable "t_vmstate" {
}
variable "t_costcenter" {
}