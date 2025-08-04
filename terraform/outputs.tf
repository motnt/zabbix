output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.main.name
}

output "app_service_url" {
  description = "URL of the App Service"
  value       = "https://${azurerm_linux_web_app.main.name}.azurewebsites.net"
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = var.enable_application_gateway ? azurerm_public_ip.app_gateway[0].ip_address : null
}

output "application_gateway_fqdn" {
  description = "FQDN of the Application Gateway"
  value       = var.enable_application_gateway ? azurerm_public_ip.app_gateway[0].fqdn : null
}

output "cdn_endpoint_url" {
  description = "URL of the CDN endpoint"
  value       = var.enable_cdn ? "https://${azurerm_cdn_endpoint.main[0].name}.azureedge.net" : null
}

output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = azurerm_mssql_server.main.name
}

output "sql_database_name" {
  description = "Name of the SQL Database"
  value       = azurerm_mssql_database.main.name
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "storage_account_name" {
  description = "Name of the Storage Account"
  value       = azurerm_storage_account.main.name
}

output "application_insights_name" {
  description = "Name of Application Insights"
  value       = azurerm_application_insights.main.name
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "sql_admin_username" {
  description = "SQL Server admin username"
  value       = var.sql_admin_username
}

output "deployment_instructions" {
  description = "Instructions for deploying the Umbraco application"
  value = <<-EOT
    Deployment Instructions:
    
    1. **Database Setup:**
       - SQL Server: ${azurerm_mssql_server.main.name}.database.windows.net
       - Database: ${azurerm_mssql_database.main.name}
       - Connection string is stored in Key Vault: ${azurerm_key_vault.main.name}
    
    2. **Application Deployment:**
       - Deploy your Umbraco application to: ${azurerm_linux_web_app.main.name}
       - Use deployment slots for zero-downtime deployments
       - App Service URL: https://${azurerm_linux_web_app.main.name}.azurewebsites.net
    
    3. **DNS Configuration:**
       ${var.enable_application_gateway ? "- Point your domain to: ${azurerm_public_ip.app_gateway[0].ip_address}" : "- Configure custom domain in App Service"}
       ${var.enable_cdn ? "- CDN endpoint: https://${azurerm_cdn_endpoint.main[0].name}.azureedge.net" : ""}
    
    4. **SSL Certificate:**
       - Replace the self-signed certificate in Application Gateway with a real certificate
       - Update the certificate in: terraform/certificates/app-cert.pfx
    
    5. **Monitoring:**
       - Application Insights: ${azurerm_application_insights.main.name}
       - Log Analytics: ${azurerm_log_analytics_workspace.main.name}
       - Update email addresses in the monitoring action group
    
    6. **Security:**
       - All secrets are stored in Key Vault: ${azurerm_key_vault.main.name}
       - App Service uses managed identity for secure access
       - Network security groups restrict access to appropriate subnets
    
    7. **Backup:**
       - App Service backup is configured to run daily
       - SQL Database has automated backups with point-in-time restore
       - Storage account has soft delete and versioning enabled
  EOT
}

output "umbraco_configuration" {
  description = "Umbraco-specific configuration notes"
  value = <<-EOT
    Umbraco Configuration:
    
    1. **appsettings.json Configuration:**
       - Connection string: Use Key Vault reference
       - Storage: Configured for Azure Blob Storage
       - Application Insights: Automatically configured
    
    2. **Required NuGet Packages:**
       - Umbraco.Cms (latest version)
       - Umbraco.Storage.AzureBlob
       - Microsoft.ApplicationInsights.AspNetCore
    
    3. **Media Storage:**
       - Media files stored in Azure Blob Storage
       - Container: media
       - CDN enabled for improved performance
    
    4. **Environment Variables:**
       - ASPNETCORE_ENVIRONMENT: ${title(var.environment)}
       - Connection strings configured via Key Vault
       - Application Insights instrumentation key configured
    
    5. **Scaling:**
       - App Service Plan: ${var.app_service_sku}
       - SQL Database: ${var.sql_database_sku}
       - Auto-scaling configured for production environments
  EOT
}