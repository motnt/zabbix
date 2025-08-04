output "app_service_plan_id" {
  description = "ID of the App Service Plan"
  value       = azurerm_service_plan.app_service_plan.id
}

output "app_service_id" {
  description = "ID of the App Service"
  value       = azurerm_windows_web_app.app_service.id
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_windows_web_app.app_service.name
}

output "app_service_url" {
  description = "URL of the App Service"
  value       = "https://${azurerm_windows_web_app.app_service.default_hostname}"
}

output "app_service_default_hostname" {
  description = "Default hostname of the App Service"
  value       = azurerm_windows_web_app.app_service.default_hostname
}

output "app_service_ftp_hostname" {
  description = "FTP hostname for the App Service"
  value       = azurerm_windows_web_app.app_service.site_credential[0].name
}

output "app_service_principal_id" {
  description = "Principal ID of the App Service (for Key Vault access)"
  value       = azurerm_windows_web_app.app_service.identity[0].principal_id
}