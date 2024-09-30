provider "azurerm" {
  subscription_id = "c3bbc65c-c5e3-42e0-a2c7-f03a690e9c97"
  features {}
}

data "azurerm_resource_group" "example" {
  name = var.resource_group_name
}

############################
## KEY VAULT
############################
data "azurerm_client_config" "current" {}

# Create Key Vault resource
resource "azurerm_key_vault" "name" {
  name                = "test-service-key-vault"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

# Module for Private Endpoint configuration
module "private_end_point_key_vault" {
  source                             = "../modules/private_end_point"
  private_endpoint_name              = "key-vault-test-service"
  location                           = data.azurerm_resource_group.example.location
  pe_resource_group_name             = data.azurerm_resource_group.example.name
  subnet_name                        = "default"
  virtual_network_name               = "test-service-vnet"
  virtual_network_resource_group_name = data.azurerm_resource_group.example.name
  endpoint_resource_id               = azurerm_key_vault.name.id
  subresource_names                  = ["vault"]  # Correct the subresource name for Key Vault
  is_manual_connection               = false

  ####################
  ## DNS
  ####################
  dns_zone_name           = "privatelink.vaultcore.azure.net"
  dns_resource_group_name = data.azurerm_resource_group.example.name  # Corrected the reference
}

################################################
## Blob Storage
################################################
resource "azurerm_storage_account" "example" {
  name                     = "blobtestrandom1"  # Must be globally unique
  resource_group_name      = data.azurerm_resource_group.example.name
  location                 = data.azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}


module "private_endpoint_storage_account" {
  source = "../modules/private_end_point"

  private_endpoint_name  = "storage-blob-pe"
  location                = data.azurerm_resource_group.example.location
  pe_resource_group_name  = data.azurerm_resource_group.example.name
  subnet_name             = "default"
  virtual_network_name    = "test-service-vnet"
  virtual_network_resource_group_name = "test-service-rg"
  endpoint_resource_id   = azurerm_storage_account.example.id
  subresource_names      = ["blob"]  # Or ["file"] depending on what you need
  is_manual_connection   = false

  ####################
  ## DNS
  ####################
  dns_zone_name           = "privatelink.blob.core.windows.net"  # Adjust for the subresource
  dns_resource_group_name = data.azurerm_resource_group.example.name
}


# #######################################
# ## EventHUB
# #######################################

# Create an Event Hub Namespace
resource "azurerm_eventhub_namespace" "example" {
  name                = "test-service-event-hub-ns"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  sku                 = "Standard"
}

# Create an Event Hub
resource "azurerm_eventhub" "example" {
  name                = "test-service-event-hub"
  namespace_name      = azurerm_eventhub_namespace.example.name
  resource_group_name = data.azurerm_resource_group.example.name
  partition_count     = 2
  message_retention   = 1
}

# Optional: Create Authorization Rule for the Event Hub
resource "azurerm_eventhub_authorization_rule" "example" {
  name                = "example-auth-rule"
  namespace_name      = azurerm_eventhub_namespace.example.name
  eventhub_name       = azurerm_eventhub.example.name
  resource_group_name = data.azurerm_resource_group.example.name

  listen = true
  send   = true
  manage = true
}

# Create Private Endpoint for the Event Hub
module "private_endpoint_event_hub" {
  source = "../modules/private_end_point"

  private_endpoint_name              = "test-service-event-hub-pe"
  location                            = data.azurerm_resource_group.example.location
  pe_resource_group_name              = data.azurerm_resource_group.example.name
  subnet_name                         = "default" # Ensure the subnet exists in the specified VNet
  virtual_network_name                = "test-service-vnet"
  virtual_network_resource_group_name  = "test-service-rg"
  endpoint_resource_id                = azurerm_eventhub_namespace.example.id # Changed to the Event Hub Namespace
  subresource_names                   = ["namespace"] 
  is_manual_connection                = false

  ####################
  ## DNS
  ####################
  dns_zone_name                      = "privatelink.servicebus.windows.net" # Removed leading space
  dns_resource_group_name            = data.azurerm_resource_group.example.name
}


##################################
## SQL Server
##################################


# Create Azure SQL Server
resource "azurerm_mssql_server" "example" {
  name                         = "test-service-mssqlserver"
  resource_group_name          = data.azurerm_resource_group.example.name
  location                     = data.azurerm_resource_group.example.location
  version                      = "12.0"
  administrator_login          = "missadministrator"
  administrator_login_password = "thisIsKat11"
  minimum_tls_version          = "1.2"

#   azuread_administrator {
#     login_username = "AzureAD Admin"
#     object_id      = "00000000-0000-0000-0000-000000000000"
#   }

  tags = {
    environment = "production"
  }
}

# module
module "private_endpoint_sql_server" {
  source = "../modules/private_end_point"

  private_endpoint_name  = "test-service-sql-server-pe"
  location                = data.azurerm_resource_group.example.location
  pe_resource_group_name  = data.azurerm_resource_group.example.name
  subnet_name             = "default"
  virtual_network_name    = "test-service-vnet"
  virtual_network_resource_group_name = "test-service-rg"
  endpoint_resource_id   = azurerm_mssql_server.example.id
  subresource_names      = ["sqlServer"]
  is_manual_connection   = false

  ####################
  ## DNS
  ####################
  dns_zone_name           =  "privatelink.database.windows.net"
  dns_resource_group_name = data.azurerm_resource_group.example.name
}

##############################
## Azure DataFactory
##############################

resource "azurerm_data_factory" "example" {
  name                = "test-service-data-factory"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
}

module "private_endpoint_data_factory" {
  source = "../modules/private_end_point"

  private_endpoint_name  = "test-service-data-factory-pe"
  location                = data.azurerm_resource_group.example.location
  pe_resource_group_name  = data.azurerm_resource_group.example.name
  subnet_name             = "default"
  virtual_network_name    = "test-service-vnet"
  virtual_network_resource_group_name = "test-service-rg"
  endpoint_resource_id   = azurerm_data_factory.example.id
  subresource_names      = ["dataFactory"]
  is_manual_connection   = false

  ####################
  ## DNS
  ####################
  dns_zone_name           = "privatelink.datafactory.azure.net"
  dns_resource_group_name = data.azurerm_resource_group.example.name
}


#############################
## Azure synapse Workspace
#############################
resource "azurerm_storage_data_lake_gen2_filesystem" "example" {
  name               = "data-lake"
  storage_account_id = azurerm_storage_account.example.id
}

resource "azurerm_synapse_workspace" "example" {
  name                                 = "test-service-synapse-workspace"
  resource_group_name                  = data.azurerm_resource_group.example.name
  location                             = data.azurerm_resource_group.example.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.example.id
  sql_administrator_login              = "sqladminuser"
  sql_administrator_login_password     = "H@Sh1CoR3!"

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Env = "production"
  }
}

#module

module "private_endpoint_synapse_workspace" {
  source = "../modules/private_end_point"

  private_endpoint_name  = "test-service-synapse-workspace-pe"
  location                = data.azurerm_resource_group.example.location
  pe_resource_group_name  = data.azurerm_resource_group.example.name
  subnet_name             = "default"
  virtual_network_name    = "test-service-vnet"
  virtual_network_resource_group_name = "test-service-rg"
  endpoint_resource_id   = azurerm_synapse_workspace.example.id
  subresource_names      = ["sql"]
  is_manual_connection   = false

  ####################
  ## DNS
  ####################
  dns_zone_name           = "privatelink.sql.azuresynapse.net"
  dns_resource_group_name = data.azurerm_resource_group.example.name
}


################################
# ## Azure App Service Plan
# ###############################
# resource "azurerm_app_service_plan" "example" {
#   name                = "test-service-app-service-plan"
#   location            = data.azurerm_resource_group.example.location
#   resource_group_name = data.azurerm_resource_group.example.name
#   sku {
#     tier     = "Standard"
#     size     = "S1"
#     capacity = 1
#   }
#   reserved = true
#   kind = "Linux"
# }

# resource "azurerm_app_service" "example" {
#   name                = "example-web-app"
#   location            = data.azurerm_resource_group.example.location
#   resource_group_name = data.azurerm_resource_group.example.name
#   app_service_plan_id = azurerm_app_service_plan.example.id

#   site_config {
#     linux_fx_version = "NODE|14-lts" # Specify the runtime version you need
#   }
# }

#####################################
## Azure Monitor Private Link Scope
#####################################

resource "azurerm_monitor_private_link_scope" "example" {
  name                = "azure-monitor-pvt-link-scope-tf"
  resource_group_name = data.azurerm_resource_group.example.name
  ingestion_access_mode = "PrivateOnly"
  query_access_mode     = "Open"
}
## Analytic Log Workspace
resource "azurerm_log_analytics_workspace" "example" {
  name                = "test-svc-analytics-workspace-tf"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
## linking
resource "azurerm_monitor_private_link_scoped_service" "example" {
  name                = "example-amplsservice"
  resource_group_name = data.azurerm_resource_group.example.name
  scope_name          = azurerm_monitor_private_link_scope.example.name
  linked_resource_id  = azurerm_log_analytics_workspace.example.id
}

## module for private end point
module "private_endpoint_azure_monitor_private_link_scope" {
  source = "../modules/private_end_point"

  private_endpoint_name  = "test-service-azure-monitor-pvt-link-scope"
  location                = data.azurerm_resource_group.example.location
  pe_resource_group_name  = data.azurerm_resource_group.example.name
  subnet_name             = "default"
  virtual_network_name    = "test-service-vnet"
  virtual_network_resource_group_name = "test-service-rg"
  endpoint_resource_id   = azurerm_monitor_private_link_scope.example.id
  subresource_names      = ["azuremonitor"]
  is_manual_connection   = false

  ####################
  ## DNS
  ####################
  
  dns_zone_name           = "privatelink.monitor.azure.com"
  dns_resource_group_name = data.azurerm_resource_group.example.name
}

##########################
## Azure app insights
##########################

resource "azurerm_application_insights" "example" {
  name                = "tf-test-appinsights"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  application_type    = "web"
}

## linking
resource "azurerm_monitor_private_link_scoped_service" "app-insight-link" {
  name                = "test-svc-app-insight-linking"
  resource_group_name = data.azurerm_resource_group.example.name
  scope_name          = azurerm_monitor_private_link_scope.example.name
  linked_resource_id  = azurerm_application_insights.example.id
}

module "private_endpoint_azure_app_insight_private_link_scope" {
  source = "../modules/private_end_point"

  private_endpoint_name  = "test-service-azure-insight-pvt-link-scope"
  location                = data.azurerm_resource_group.example.location
  pe_resource_group_name  = data.azurerm_resource_group.example.name
  subnet_name             = "default"
  virtual_network_name    = "test-service-vnet"
  virtual_network_resource_group_name = "test-service-rg"
  endpoint_resource_id   = azurerm_monitor_private_link_scope.example.id
  subresource_names      = ["azuremonitor"]
  is_manual_connection   = false

  ####################
  ## DNS
  ####################
  
  dns_zone_name           = "privatelink.oms.opinsights.azure.com"
  dns_resource_group_name = data.azurerm_resource_group.example.name
}

