variable "subscription_id" {
  description = "Azure Subscription ID (optional when using AZURE_CREDENTIALS in GitHub Actions)"
  type        = string
  default     = ""
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "Existing resource group name where VM will be created"
  type        = string
  default     = "rg-app"
}

variable "prefix" {
  description = "Naming prefix for resources (vm, nic, publicip, vnet, subnet, nsg)"
  type        = string
  default     = "k3s"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Central India"
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B2ms"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key contents (for admin user). Use file() with terraform.tfvars or set TF_VAR_ssh_public_key env var."
  type        = string
  default     = ""
}

variable "vnet_address_space" {
  description = "VNet address space"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_prefix" {
  description = "Subnet prefix"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_node_ports" {
  description = "List of NodePort ports to allow in NSG (example values, adjust if needed)"
  type        = list(number)
  default     = [32302]
}
