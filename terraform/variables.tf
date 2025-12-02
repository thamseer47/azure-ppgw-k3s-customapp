variable "location" {
  type        = string
  default     = "centralindia"
  description = "Azure region"
}

variable "vm_admin" {
  type    = string
  default = "azureuser"
}

variable "ssh_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}
