terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "umbraco_rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "umbraco_vnet" {
  name                = "${var.project_name}-vnet"
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  location            = azurerm_resource_group.umbraco_rg.location
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.umbraco_rg.name
  virtual_network_name = azurerm_virtual_network.umbraco_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "database_subnet" {
  name                 = "database-subnet"
  resource_group_name  = azurerm_resource_group.umbraco_rg.name
  virtual_network_name = azurerm_virtual_network.umbraco_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Security Groups
resource "azurerm_network_security_group" "app_nsg" {
  name                = "${var.project_name}-app-nsg"
  location            = azurerm_resource_group.umbraco_rg.location
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  tags                = var.tags

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_ip_address
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "database_nsg" {
  name                = "${var.project_name}-database-nsg"
  location            = azurerm_resource_group.umbraco_rg.location
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  tags                = var.tags

  security_rule {
    name                       = "SQL"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = azurerm_subnet.app_subnet.address_prefixes[0]
    destination_address_prefix = "*"
  }
}

# Subnet NSG Associations
resource "azurerm_subnet_network_security_group_association" "app_nsg_association" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "database_nsg_association" {
  subnet_id                 = azurerm_subnet.database_subnet.id
  network_security_group_id = azurerm_network_security_group.database_nsg.id
}

# Application Gateway
resource "azurerm_public_ip" "appgw_pip" {
  name                = "${var.project_name}-appgw-pip"
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  location            = azurerm_resource_group.umbraco_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_application_gateway" "appgw" {
  name                = "${var.project_name}-appgw"
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  location            = azurerm_resource_group.umbraco_rg.location
  tags                = var.tags

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = azurerm_subnet.app_subnet.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-configuration"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "http-settings"
    priority                   = 100
  }
}

# App Service Plan
resource "azurerm_service_plan" "umbraco_plan" {
  name                = "${var.project_name}-plan"
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  location            = azurerm_resource_group.umbraco_rg.location
  os_type             = "Windows"
  sku_name            = "P1v2"
  tags                = var.tags
}

# App Service
resource "azurerm_windows_web_app" "umbraco_app" {
  name                = "${var.project_name}-app"
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  location            = azurerm_resource_group.umbraco_rg.location
  service_plan_id     = azurerm_service_plan.umbraco_plan.id
  tags                = var.tags

  site_config {
    application_stack {
      dotnet_version = "v6.0"
    }
    
    app_settings = {
      "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
      "WEBSITE_RUN_FROM_PACKAGE"     = "1"
    }
  }

  app_settings = {
    "ConnectionStrings__umbracoDbDSN" = "Server=${azurerm_mssql_server.umbraco_sql.fully_qualified_domain_name};Database=${azurerm_mssql_database.umbraco_db.name};User Id=${azurerm_mssql_server.umbraco_sql.administrator_login};Password=${azurerm_mssql_server.umbraco_sql.administrator_login_password};TrustServerCertificate=true;"
  }
}

# SQL Server
resource "azurerm_mssql_server" "umbraco_sql" {
  name                         = "${var.project_name}-sql"
  resource_group_name          = azurerm_resource_group.umbraco_rg.name
  location                     = azurerm_resource_group.umbraco_rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  tags                         = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# SQL Database
resource "azurerm_mssql_database" "umbraco_db" {
  name           = "${var.project_name}-db"
  server_id      = azurerm_mssql_server.umbraco_sql.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "Basic"
  tags           = var.tags
}

# Key Vault
resource "azurerm_key_vault" "umbraco_kv" {
  name                        = "${var.project_name}-kv"
  location                    = azurerm_resource_group.umbraco_rg.location
  resource_group_name         = azurerm_resource_group.umbraco_rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  tags                        = var.tags
}

# Key Vault Access Policy for SQL Server
resource "azurerm_key_vault_access_policy" "sql_access_policy" {
  key_vault_id = azurerm_key_vault.umbraco_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_mssql_server.umbraco_sql.identity[0].principal_id

  key_permissions = [
    "Get", "List", "WrapKey", "UnwrapKey"
  ]
}

# Storage Account for Umbraco Media
resource "azurerm_storage_account" "umbraco_storage" {
  name                     = "${replace(var.project_name, "-", "")}storage"
  resource_group_name      = azurerm_resource_group.umbraco_rg.name
  location                 = azurerm_resource_group.umbraco_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_storage_container" "umbraco_media" {
  name                  = "umbraco-media"
  storage_account_name  = azurerm_storage_account.umbraco_storage.name
  container_access_type = "private"
}

# CDN Profile
resource "azurerm_cdn_profile" "umbraco_cdn" {
  name                = "${var.project_name}-cdn"
  location            = azurerm_resource_group.umbraco_rg.location
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  sku                 = "Standard_Microsoft"
  tags                = var.tags
}

# CDN Endpoint
resource "azurerm_cdn_endpoint" "umbraco_cdn_endpoint" {
  name                = "${var.project_name}-cdn-endpoint"
  profile_name        = azurerm_cdn_profile.umbraco_cdn.name
  location            = azurerm_resource_group.umbraco_rg.location
  resource_group_name = azurerm_resource_group.umbraco_rg.name

  origin {
    name       = "umbraco-storage"
    host_name  = azurerm_storage_account.umbraco_storage.primary_blob_host
  }
}

# Application Insights
resource "azurerm_application_insights" "umbraco_ai" {
  name                = "${var.project_name}-ai"
  location            = azurerm_resource_group.umbraco_rg.location
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  application_type    = "web"
  tags               = var.tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "umbraco_law" {
  name                = "${var.project_name}-law"
  location            = azurerm_resource_group.umbraco_rg.location
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}