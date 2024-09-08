# Fetch the Subnet Data Source
data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.virtual_network_resource_group_name
}


# Fetch the DNS Zone Data Source
resource "azurerm_private_dns_zone" "dns" {
  name                = var.dns_zone_name
  resource_group_name = var.dns_resource_group_name
}

# Define the Private Endpoint Resource
resource "azurerm_private_endpoint" "pe" {
  name                = var.private_endpoint_name
  location            = var.location
  resource_group_name = var.pe_resource_group_name
  subnet_id           = data.azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "${var.private_endpoint_name}-connection"
    is_manual_connection           = var.is_manual_connection
    private_connection_resource_id = var.endpoint_resource_id
    subresource_names              = var.subresource_names
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.dns.name
    private_dns_zone_ids = [azurerm_private_dns_zone.dns.id]
  }
  
}

