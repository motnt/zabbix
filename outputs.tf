output "web_app_url" {
  description = "Primary URL for the Umbraco web application"
  value       = azurerm_linux_web_app.umbraco.default_hostname
}

output "sql_admin_login" {
  description = "SQL administrator login"
  value       = var.sql_admin_username
}

output "sql_admin_password" {
  description = "SQL administrator password (sensitive)"
  value       = random_password.sql.result
  sensitive   = true
}