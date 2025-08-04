locals {
  # Naming convention
  name_prefix = "${var.project_name}-${var.environment}"
  name_suffix = random_string.suffix.result
  
  # Resource names
  resource_group_name      = "rg-${local.name_prefix}-${local.name_suffix}"
  app_service_plan_name    = "asp-${local.name_prefix}-${local.name_suffix}"
  app_service_name         = "app-${local.name_prefix}-${local.name_suffix}"
  sql_server_name          = "sql-${local.name_prefix}-${local.name_suffix}"
  sql_database_name        = "sqldb-${local.name_prefix}"
  storage_account_name     = "st${var.project_name}${var.environment}${local.name_suffix}"
  key_vault_name           = "kv-${local.name_prefix}-${local.name_suffix}"
  log_analytics_name       = "log-${local.name_prefix}-${local.name_suffix}"
  app_insights_name        = "appi-${local.name_prefix}-${local.name_suffix}"
  vnet_name                = "vnet-${local.name_prefix}-${local.name_suffix}"
  subnet_app_name          = "snet-app-${local.name_prefix}"
  subnet_db_name           = "snet-db-${local.name_prefix}"
  subnet_gateway_name      = "snet-gateway-${local.name_prefix}"
  nsg_app_name             = "nsg-app-${local.name_prefix}"
  nsg_db_name              = "nsg-db-${local.name_prefix}"
  app_gateway_name         = "agw-${local.name_prefix}-${local.name_suffix}"
  cdn_profile_name         = "cdn-${local.name_prefix}-${local.name_suffix}"
  cdn_endpoint_name        = "cdne-${local.name_prefix}-${local.name_suffix}"

  # Network configuration
  vnet_address_space     = ["10.0.0.0/16"]
  subnet_app_address     = ["10.0.1.0/24"]
  subnet_db_address      = ["10.0.2.0/24"]
  subnet_gateway_address = ["10.0.3.0/24"]

  # Common tags
  common_tags = merge(var.tags, {
    Environment = var.environment
    Location    = var.location
    CreatedBy   = "Terraform"
    CreatedDate = timestamp()
  })

  # App Service configuration
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"                = "1"
    "APPINSIGHTS_INSTRUMENTATIONKEY"          = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING"   = azurerm_application_insights.main.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
    "XDT_MicrosoftApplicationInsights_Mode"   = "Recommended"
    "ASPNETCORE_ENVIRONMENT"                  = title(var.environment)
    "Umbraco__CMS__Content__ContentImageAutoFillProperties__0__Alias" = "umbracoFile"
    "Umbraco__CMS__Global__ReservedUrls"      = "~/config/,~/install/,~/umbraco/"
    "Umbraco__CMS__Hosting__Debug"            = var.environment == "dev" ? "true" : "false"
    "Umbraco__Storage__AzureBlob__Media__ConnectionString" = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=storage-connection-string)"
    "Umbraco__Storage__AzureBlob__Media__ContainerName"    = "media"
  }

  # Connection strings
  connection_strings = {
    "umbracoDbDSN" = {
      type  = "SQLAzure"
      value = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=sql-connection-string)"
    }
  }
}