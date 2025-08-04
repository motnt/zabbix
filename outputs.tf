output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.umbraco_rg.name
}

output "app_service_url" {
  description = "URL of the Umbraco App Service"
  value       = "https://${azurerm_windows_web_app.umbraco_app.default_hostname}"
}

output "application_gateway_url" {
  description = "URL of the Application Gateway"
  value       = "http://${azurerm_public_ip.appgw_pip.ip_address}"
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

output "cdn_endpoint_url" {
  description = "URL of the CDN Endpoint"
  value       = "https://${azurerm_cdn_endpoint.umbraco_cdn_endpoint.host_name}"
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.umbraco_kv.name
}

output "application_insights_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.umbraco_ai.instrumentation_key
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.umbraco_law.id
}

output "virtual_network_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.umbraco_vnet.name
}

output "app_subnet_id" {
  description = "ID of the App Subnet"
  value       = azurerm_subnet.app_subnet.id
}

output "database_subnet_id" {
  description = "ID of the Database Subnet"
  value       = azurerm_subnet.database_subnet.id
}