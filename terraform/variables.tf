variable "location" {
  type    = string
  default = "centralindia"
}

variable "project_prefix" {
  type    = string
  default = "app"
}

variable "vm_admin" {
  type    = string
  default = "azureuser"
}

variable "ssh_pub_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}

# NodePort chosen in k8s manifest
variable "nodeport" {
  type    = number
  default = 30731
}
