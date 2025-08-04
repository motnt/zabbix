output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.umbraco_rg.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.umbraco_rg.location
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_windows_web_app.umbraco_app.name
}

output "app_service_url" {
  description = "URL of the Umbraco application"
  value       = "https://${azurerm_windows_web_app.umbraco_app.default_hostname}"
}

output "app_service_ftp_hostname" {
  description = "FTP hostname for the App Service"
  value       = azurerm_windows_web_app.umbraco_app.site_credential[0].name
}

output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = azurerm_mssql_server.umbraco_sql.name
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.umbraco_sql.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "Name of the SQL Database"
  value       = azurerm_mssql_database.umbraco_db.name
}

output "storage_account_name" {
  description = "Name of the Storage Account"
  value       = azurerm_storage_account.umbraco_storage.name
}

output "storage_account_primary_key" {
  description = "Primary access key for the Storage Account"
  value       = azurerm_storage_account.umbraco_storage.primary_access_key
  sensitive   = true
}

output "storage_account_connection_string" {
  description = "Connection string for the Storage Account"
  value       = azurerm_storage_account.umbraco_storage.primary_connection_string
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.umbraco_insights.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.umbraco_insights.connection_string
  sensitive   = true
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.umbraco_kv.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.umbraco_kv.vault_uri
}

output "cdn_endpoint_hostname" {
  description = "Hostname of the CDN endpoint"
  value       = azurerm_cdn_endpoint.umbraco_cdn_endpoint.host_name
}

output "cdn_endpoint_url" {
  description = "URL of the CDN endpoint"
  value       = "https://${azurerm_cdn_endpoint.umbraco_cdn_endpoint.host_name}"
}

output "virtual_network_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.umbraco_vnet.name
}

output "virtual_network_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.umbraco_vnet.id
}

output "app_subnet_id" {
  description = "ID of the App Service subnet"
  value       = azurerm_subnet.app_subnet.id
}

output "sql_subnet_id" {
  description = "ID of the SQL Server subnet"
  value       = azurerm_subnet.sql_subnet.id
}

output "private_endpoint_ip" {
  description = "Private IP address of the SQL Server private endpoint"
  value       = azurerm_private_endpoint.sql_private_endpoint.private_service_connection[0].private_ip_address
}

output "umbraco_admin_url" {
  description = "URL for Umbraco admin interface"
  value       = "https://${azurerm_windows_web_app.umbraco_app.default_hostname}/umbraco"
}

output "deployment_summary" {
  description = "Summary of the deployed Umbraco infrastructure"
  value = {
    app_service_url = "https://${azurerm_windows_web_app.umbraco_app.default_hostname}"
    admin_url       = "https://${azurerm_windows_web_app.umbraco_app.default_hostname}/umbraco"
    sql_server      = azurerm_mssql_server.umbraco_sql.fully_qualified_domain_name
    storage_account = azurerm_storage_account.umbraco_storage.name
    cdn_url         = "https://${azurerm_cdn_endpoint.umbraco_cdn_endpoint.host_name}"
    key_vault       = azurerm_key_vault.umbraco_kv.name
    insights        = azurerm_application_insights.umbraco_insights.name
  }
}