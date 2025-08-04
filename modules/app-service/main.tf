# App Service Plan
resource "azurerm_service_plan" "app_service_plan" {
  name                = var.app_service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Windows"
  sku_name            = var.app_service_plan_sku
  tags                = var.tags
}

# App Service
resource "azurerm_windows_web_app" "app_service" {
  name                = var.app_service_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.app_service_plan.id

  site_config {
    application_stack {
      dotnet_version = "v6.0"
    }
    
    always_on = true
    
    app_command_line = ""
    
    health_check_path = "/umbraco"
    
    dynamic "ip_restriction" {
      for_each = var.enable_vnet_integration ? [1] : []
      content {
        virtual_network_subnet_id = var.app_subnet_id
        action                    = "Allow"
        name                      = "VNet"
      }
    }
  }

  app_settings = merge(
    var.app_settings,
    {
      "WEBSITE_RUN_FROM_PACKAGE" = "1"
      "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
      "WEBSITE_DYNAMIC_CACHE" = "0"
      "WEBSITE_LOCAL_CACHE_OPTION" = "Always"
      "WEBSITE_LOCAL_CACHE_SIZEINMB" = "1024"
      "WEBSITE_LOCAL_CACHE_TTL" = "600"
    }
  )

  tags = var.tags
}

# App Service VNet Integration (if enabled)
resource "azurerm_app_service_virtual_network_swift_connection" "app_vnet_integration" {
  count      = var.enable_vnet_integration ? 1 : 0
  app_service_id = azurerm_windows_web_app.app_service.id
  subnet_id      = var.app_subnet_id
}