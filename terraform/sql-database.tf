# SQL Server
resource "azurerm_mssql_server" "main" {
  name                = local.sql_server_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  version             = "12.0"
  
  administrator_login          = var.sql_admin_username
  administrator_login_password = random_password.sql_admin_password.result
  
  # Security settings
  minimum_tls_version               = "1.2"
  public_network_access_enabled     = false
  outbound_network_restriction_enabled = false

  # Azure AD authentication
  azuread_administrator {
    login_username = "sql-admin"
    object_id      = data.azurerm_client_config.current.object_id
  }

  # Identity for Key Vault access
  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name           = local.sql_database_name
  server_id      = azurerm_mssql_server.main.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  sku_name       = var.sql_database_sku
  zone_redundant = var.environment == "prod"
  
  # Backup settings
  short_term_retention_policy {
    retention_days = var.environment == "prod" ? 35 : 7
  }

  long_term_retention_policy {
    weekly_retention  = var.environment == "prod" ? "P12W" : "P4W"
    monthly_retention = var.environment == "prod" ? "P12M" : "P3M"
    yearly_retention  = var.environment == "prod" ? "P5Y" : "P1Y"
    week_of_year      = 1
  }

  # Threat detection
  threat_detection_policy {
    state                      = "Enabled"
    email_account_admins       = "Enabled"
    retention_days             = 30
    storage_endpoint           = azurerm_storage_account.main.primary_blob_endpoint
    storage_account_access_key = azurerm_storage_account.main.primary_access_key
  }

  tags = local.common_tags
}

# Private endpoint for SQL Server
resource "azurerm_private_endpoint" "sql" {
  name                = "pe-${local.sql_server_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.db.id

  private_service_connection {
    name                           = "psc-${local.sql_server_name}"
    private_connection_resource_id = azurerm_mssql_server.main.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdz-group-sql"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }

  tags = local.common_tags
}

# Private DNS Zone for SQL Server
resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "pdz-link-sql"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = local.common_tags
}

# SQL Server firewall rule for Azure services (needed for Key Vault integration)
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}