resource "azurerm_resource_group" "rg" {
  name     = "example-resources"
  location = "East US"  # Choose the appropriate Azure region
}

# Storage Account Definition
resource "azurerm_storage_account" "example" {
  name                     = "example534storacc"  # Must be globally unique
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# ###############################################
# # Deploy the Private Endpoint using the module
# ###############################################

module "private_endpoint_storage_account" {
  source = "./modules/private_end_point"

  private_endpoint_name  = "${azurerm_storage_account.example.name}-pe"
  location                = azurerm_storage_account.example.location
  pe_resource_group_name  = azurerm_storage_account.example.resource_group_name
  subnet_name             = "default"
  virtual_network_name    = "vn-spoke"
  virtual_network_resource_group_name = "rg-network"
  endpoint_resource_id   = azurerm_storage_account.example.id
  subresource_names      = ["blob"]  # Or ["file"] depending on what you need
  is_manual_connection   = false

  ####################
  ## DNS
  ####################
  dns_zone_name           = "privatelink.blob.core.windows.net"  # Adjust for the subresource
  dns_resource_group_name = azurerm_resource_group.rg.name
}

