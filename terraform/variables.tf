variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "vm_admin" {
  description = "Admin username for VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "prefix" {
  type    = string
  default = "app"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B1s"
}


