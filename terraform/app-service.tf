# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = local.app_service_plan_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name           = var.app_service_sku
  
  # Zone redundancy for production
  zone_balancing_enabled = var.environment == "prod"

  tags = local.common_tags
}

# Linux Web App for Umbraco
resource "azurerm_linux_web_app" "main" {
  name                = local.app_service_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_service_plan.main.location
  service_plan_id     = azurerm_service_plan.main.id

  # Enable system-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  # App Service configuration
  site_config {
    always_on         = true
    health_check_path = "/umbraco/api/health"
    
    # .NET 8 runtime
    application_stack {
      dotnet_version = "8.0"
    }

    # Security headers
    http2_enabled = true
    
    # IP restrictions (if specified)
    dynamic "ip_restriction" {
      for_each = var.allowed_ip_ranges
      content {
        ip_address = ip_restriction.value
        action     = "Allow"
        priority   = 100 + ip_restriction.key
        name       = "AllowedIP${ip_restriction.key}"
      }
    }

    # CORS settings for Umbraco backoffice
    cors {
      allowed_origins = [
        "https://${local.app_service_name}.azurewebsites.net",
        var.custom_domain != "" ? "https://${var.custom_domain}" : ""
      ]
      support_credentials = true
    }
  }

  # App settings
  app_settings = local.app_settings

  # Connection strings
  dynamic "connection_string" {
    for_each = local.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  # Logs configuration
  logs {
    detailed_error_messages = var.environment == "dev"
    failed_request_tracing  = var.environment == "dev"
    
    application_logs {
      file_system_level = var.environment == "dev" ? "Information" : "Warning"
      
      azure_blob_storage {
        level             = "Information"
        sas_url          = "${azurerm_storage_account.main.primary_blob_endpoint}${azurerm_storage_container.logs.name}"
        retention_in_days = var.environment == "prod" ? 30 : 7
      }
    }

    http_logs {
      azure_blob_storage {
        sas_url          = "${azurerm_storage_account.main.primary_blob_endpoint}${azurerm_storage_container.logs.name}"
        retention_in_days = var.environment == "prod" ? 30 : 7
      }
    }
  }

  # Virtual network integration
  virtual_network_subnet_id = azurerm_subnet.app.id

  # Backup configuration
  dynamic "backup" {
    for_each = var.enable_backup ? [1] : []
    content {
      name                = "daily-backup"
      enabled             = true
      storage_account_url = "${azurerm_storage_account.main.primary_blob_endpoint}${azurerm_storage_container.backups.name}?${data.azurerm_storage_account_blob_container_sas.backup.sas}"
      
      schedule {
        frequency_interval       = 1
        frequency_unit          = "Day"
        keep_at_least_one_backup = true
        retention_period_days    = var.environment == "prod" ? 30 : 7
        start_time              = "2023-01-01T02:00:00Z"
      }
    }
  }

  # Sticky settings (won't be swapped during deployment slots)
  sticky_settings {
    app_setting_names = [
      "ASPNETCORE_ENVIRONMENT",
      "APPINSIGHTS_INSTRUMENTATIONKEY",
      "APPLICATIONINSIGHTS_CONNECTION_STRING"
    ]
    connection_string_names = [
      "umbracoDbDSN"
    ]
  }

  tags = local.common_tags

  depends_on = [
    azurerm_key_vault_access_policy.current,
    azurerm_subnet.app
  ]
}

# SAS token for backup storage
data "azurerm_storage_account_blob_container_sas" "backup" {
  count = var.enable_backup ? 1 : 0
  
  connection_string = azurerm_storage_account.main.primary_connection_string
  container_name    = azurerm_storage_container.backups.name
  https_only        = true

  start  = "2023-01-01T00:00:00Z"
  expiry = "2025-01-01T00:00:00Z"

  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = true
    list   = true
  }
}

# App Service deployment slot for staging
resource "azurerm_linux_web_app_slot" "staging" {
  count          = var.environment == "prod" ? 1 : 0
  name           = "staging"
  app_service_id = azurerm_linux_web_app.main.id

  site_config {
    always_on = true
    
    application_stack {
      dotnet_version = "8.0"
    }
  }

  # Same app settings as production but with staging-specific values
  app_settings = merge(local.app_settings, {
    "ASPNETCORE_ENVIRONMENT" = "Staging"
  })

  # Same connection strings as production
  dynamic "connection_string" {
    for_each = local.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  tags = local.common_tags
}