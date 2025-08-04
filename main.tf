terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  project_suffix = random_string.suffix.result
  resource_name  = "${var.project_name}-${var.environment}-${local.project_suffix}"
}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${local.resource_name}-rg"
  location = var.location
}

# Application Insights
resource "azurerm_application_insights" "ai" {
  name                = "${local.resource_name}-ai"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

# App Service Plan (Linux)
resource "azurerm_service_plan" "plan" {
  name                = "${local.resource_name}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"

  sku_name = var.app_service_plan_sku
}

# Azure SQL Server & DB
resource "random_password" "sql" {
  length               = 20
  special              = true
  override_characters  = "!@#$%&*()-_=+[]{}"
}

resource "azurerm_mssql_server" "sql" {
  name                         = "${local.resource_name}-sql"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = random_password.sql.result
  minimum_tls_version          = "1.2"
}

resource "azurerm_mssql_database" "db" {
  name                = "${local.resource_name}-db"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_id           = azurerm_mssql_server.sql.id
  sku_name            = var.sql_sku_name
  max_size_gb         = 5
}

# Umbraco Web App (Docker on Linux)
resource "azurerm_linux_web_app" "umbraco" {
  name                = "${local.resource_name}-webapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true

  site_config {
    always_on        = true
    linux_fx_version = "DOCKER|${var.umbraco_docker_image}"
  }

  app_settings = {
    WEBSITES_PORT                         = "8080"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE   = "true"
    APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.ai.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.ai.connection_string
  }

  connection_string {
    name  = "umbracoDbDSN"
    type  = "SQLAzure"
    value = format(
      "Server=tcp:%s.database.windows.net,1433;Initial Catalog=%s;Persist Security Info=False;User ID=%s;Password=%s;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;",
      azurerm_mssql_server.sql.name,
      azurerm_mssql_database.db.name,
      var.sql_admin_username,
      random_password.sql.result
    )
  }

  tags = {
    environment = var.environment
    managed-by  = "terraform"
  }
}

# Allow Azure services (including the Web App) to access the SQL server
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}