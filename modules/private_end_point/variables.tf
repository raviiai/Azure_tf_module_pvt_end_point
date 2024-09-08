variable "private_endpoint_name" {
  description = "Name of the private endpoint."
  type        = string
}

variable "location" {
  description = "Location where the private endpoint will be created."
  type        = string
}

variable "pe_resource_group_name" {
  description = "Resource group name where the private endpoint will be created."
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet where the private endpoint will be placed."
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the virtual network containing the subnet."
  type        = string
}

variable "virtual_network_resource_group_name" {
  description = "Resource group name of the virtual network containing the subnet."
  type        = string
}

variable "endpoint_resource_id" {
  description = "Resource ID of the resource to be connected to via private endpoint."
  type        = string
}

variable "subresource_names" {
  description = "List of subresource names for the private connection."
  type        = list(string)
}

variable "is_manual_connection" {
  description = "Indicates whether manual approval is required for the connection."
  type        = bool
  default     = false
}

variable "dns_zone_name" {
  description = "Name of the private DNS zone."
  type        = string
}

variable "dns_resource_group_name" {
  description = "Resource group name of the private DNS zone."
  type        = string
}

