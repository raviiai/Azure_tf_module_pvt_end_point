provider "azurerm" {
   subscription_id = "c3bbc65c-c5e3-42e0-a2c7-f03a690e9c97"
   features {
   }
   
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-databricks"
  location = "West Europe"
}

# Create Virtual Network and Subnet
resource "azurerm_virtual_network" "vn" {
  name                = "vn-spoke"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Databricks"]
}

# Create Azure Databricks Workspace
resource "azurerm_databricks_workspace" "example" {
  name                = "databricks-workspace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "standard"
}

# Private DNS Zone for Databricks
resource "azurerm_private_dns_zone" "databricks_dns" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# Virtual Network Link to DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "vn_link" {
  name                  = "databricks-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.databricks_dns.name
  virtual_network_id    = azurerm_virtual_network.vn.id
}

# Module for Private Endpoint for Databricks
module "private_endpoint_databricks" {
  source = "../modules/private_end_point"
    depends_on = [ azurerm_subnet.subnet ]
  private_endpoint_name   = "workspace-databricks-pe"
  location                = azurerm_databricks_workspace.example.location
  pe_resource_group_name  = azurerm_databricks_workspace.example.resource_group_name
  subnet_name             = azurerm_subnet.subnet.name
  virtual_network_name    = azurerm_virtual_network.vn.name
  virtual_network_resource_group_name = azurerm_resource_group.rg.name
  endpoint_resource_id    = azurerm_databricks_workspace.example.id
  subresource_names       = ["databricks_ui_api"]
  is_manual_connection    = false

  ####################
  ## DNS
  ####################
  dns_zone_name           = azurerm_private_dns_zone.databricks_dns.name
  dns_resource_group_name = azurerm_resource_group.rg.name
}

