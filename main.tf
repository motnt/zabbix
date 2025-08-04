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
  features {}
}

# Resource Group
resource "azurerm_resource_group" "umbraco_rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Random string for unique naming
resource "random_string" "unique" {
  length  = 8
  special = false
  upper   = false
}

# Storage Account for Umbraco media files
resource "azurerm_storage_account" "umbraco_storage" {
  name                     = "umbracostorage${random_string.unique.result}"
  resource_group_name      = azurerm_resource_group.umbraco_rg.name
  location                 = azurerm_resource_group.umbraco_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }
  
  tags = var.tags
}

# Storage Container for Umbraco media
resource "azurerm_storage_container" "umbraco_media" {
  name                  = "umbraco-media"
  storage_account_name  = azurerm_storage_account.umbraco_storage.name
  container_access_type = "private"
}

# App Service Plan
resource "azurerm_service_plan" "umbraco_plan" {
  name                = "umbraco-plan-${random_string.unique.result}"
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  location            = azurerm_resource_group.umbraco_rg.location
  os_type             = "Windows"
  sku_name            = var.app_service_plan_sku
  tags                = var.tags
}

# App Service for Umbraco
resource "azurerm_windows_web_app" "umbraco_app" {
  name                = "umbraco-app-${random_string.unique.result}"
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  location            = azurerm_resource_group.umbraco_rg.location
  service_plan_id     = azurerm_service_plan.umbraco_plan.id

  site_config {
    application_stack {
      dotnet_version = "v6.0"
    }
    
    application_stack {
      dotnet_version = "v6.0"
    }
    
    always_on = true
    
    app_command_line = ""
    
    health_check_path = "/umbraco"
    
    ip_restriction {
      virtual_network_subnet_id = azurerm_subnet.app_subnet.id
      action                    = "Allow"
      name                      = "VNet"
    }
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
    "WEBSITE_DYNAMIC_CACHE" = "0"
    "WEBSITE_LOCAL_CACHE_OPTION" = "Always"
    "WEBSITE_LOCAL_CACHE_SIZEINMB" = "1024"
    "WEBSITE_LOCAL_CACHE_TTL" = "600"
    
    # Umbraco specific settings
    "umbracoDbDSN" = "Server=${azurerm_mssql_server.umbraco_sql.fully_qualified_domain_name};Database=${azurerm_mssql_database.umbraco_db.name};User Id=${azurerm_mssql_server.umbraco_sql.administrator_login};Password=${azurerm_mssql_server.umbraco_sql.administrator_login_password};TrustServerCertificate=true;"
    "umbracoUseHttps" = "true"
    "umbracoHideTopLevelNodeFromPath" = "true"
    "umbracoPath" = "/umbraco"
    "umbracoReservedUrls" = "/config/umbracoSettings.config,/config/umbraco.config,/config/user.config,/config/tinyMceConfig.config,/config/restExtensions.config,/config/embeddedMedia.config,/config/createdUiPages.config,/config/dashboard.config,/config/examineSettings.config,/config/fileSystemProviders.config,/config/healthChecks.config,/config/imageprocessor/cache.config,/config/imageprocessor/security.config,/config/imageprocessor/processing.config,/config/log4net.config,/config/nuget.config,/config/splashes.config,/config/trees.config,/config/umbracoSettings.config,/config/web.config,/config/clientdependency.config,/config/umbracoSettings.config,/config/umbraco.config,/config/user.config,/config/tinyMceConfig.config,/config/restExtensions.config,/config/embeddedMedia.config,/config/createdUiPages.config,/config/dashboard.config,/config/examineSettings.config,/config/fileSystemProviders.config,/config/healthChecks.config,/config/imageprocessor/cache.config,/config/imageprocessor/security.config,/config/imageprocessor/processing.config,/config/log4net.config,/config/nuget.config,/config/splashes.config,/config/trees.config,/config/umbracoSettings.config,/config/web.config,/config/clientdependency.config"
    "umbracoReservedPaths" = "/umbraco/,/install/,/mini-profiler-resources/,/app_plugins/,/bin/,/config/,/css/,/js/,/media/,/scripts/,/umbraco/,/umbraco_client/,/views/,/xslt/,/masterpages/,/web.config"
    "umbracoReservedExtensions" = ".aspx,.ascx,.asmx,.ashx,.asax,.axd,.cshtml,.vbhtml,.config,.cs,.vb,.csproj,.vbproj,.sln,.resx,.resources,.licx,.lic,.cache,.dll,.pdb,.com,.exe,.bat,.cmd,.vbs,.js,.htc,.htc,.class,.jar,.war,.ear,.swf,.fla,.flv,.gif,.jpg,.jpeg,.png,.bmp,.ico,.tiff,.tif,.svg,.svgz,.mp3,.mp4,.avi,.wmv,.wma,.mov,.wav,.flv,.webm,.ogg,.ogv,.m4a,.m4v,.3gp,.3g2,.mkv,.ts,.mts,.m2ts,.divx,.xvid,.h264,.h265,.hevc,.vp8,.vp9,.av1,.theora,.opus,.vorbis,.aac,.ac3,.dts,.dtshd,.truehd,.eac3,.mp2,.mp1,.wma,.ra,.rm,.rmvb,.asf,.wmv,.flv,.f4v,.f4p,.f4a,.f4b,.m4v,.3gp,.3g2,.3gpp,.3gpp2,.amc,.amv,.bik,.bix,.box,.bsf,.camrec,.dat,.divx,.dv,.dvr-ms,.evo,.fli,.flc,.flv,.flic,.gvi,.gvp,.hdmov,.ifo,.ivf,.m1v,.m2v,.m4e,.m4u,.m4v,.mjp,.mjpeg,.mjpg,.mkv,.moov,.mov,.movie,.mp21,.mp21,.mp42,.mp4,.mpe,.mpeg,.mpg,.mpv,.mqv,.msdvd,.mts,.mtv,.mxf,.mxr,.nsv,.nuv,.ogm,.ogv,.ogx,.qt,.qtch,.qti,.qtif,.qtx,.rec,.rm,.rmd,.rmp,.rms,.rmvb,.roq,.rpl,.smil,.smk,.swf,.tivo,.tod,.trp,.ts,.tts,.vfw,.vid,.video,.vob,.vp6,.vp7,.vp8,.vp9,.wmv,.wtv,.xesc,.xvid,.yuv"
    
    # Azure Storage for media files
    "umbracoFileSystemProviders:Media:type" = "AzureBlobFileSystem"
    "umbracoFileSystemProviders:Media:parameters:containerName" = azurerm_storage_container.umbraco_media.name
    "umbracoFileSystemProviders:Media:parameters:connectionString" = azurerm_storage_account.umbraco_storage.primary_connection_string
    "umbracoFileSystemProviders:Media:parameters:virtualPath" = "/media/"
    
    # Application Insights
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.umbraco_insights.instrumentation_key
    "APPINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.umbraco_insights.connection_string
  }

  tags = var.tags
}

# Application Insights
resource "azurerm_application_insights" "umbraco_insights" {
  name                = "umbraco-insights-${random_string.unique.result}"
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  location            = azurerm_resource_group.umbraco_rg.location
  application_type    = "web"
  tags                = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "umbraco_vnet" {
  name                = "umbraco-vnet-${random_string.unique.result}"
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  location            = azurerm_resource_group.umbraco_rg.location
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# Subnet for App Service
resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.umbraco_rg.name
  virtual_network_name = azurerm_virtual_network.umbraco_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  
  delegation {
    name = "app-service-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Subnet for SQL Server
resource "azurerm_subnet" "sql_subnet" {
  name                 = "sql-subnet"
  resource_group_name  = azurerm_resource_group.umbraco_rg.name
  virtual_network_name = azurerm_virtual_network.umbraco_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  
  delegation {
    name = "sql-delegation"
    service_delegation {
      name    = "Microsoft.Sql/servers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# SQL Server
resource "azurerm_mssql_server" "umbraco_sql" {
  name                         = "umbraco-sql-${random_string.unique.result}"
  resource_group_name          = azurerm_resource_group.umbraco_rg.name
  location                     = azurerm_resource_group.umbraco_rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
  
  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = var.azure_ad_admin_object_id
  }
  
  tags = var.tags
}

# SQL Database
resource "azurerm_mssql_database" "umbraco_db" {
  name           = "umbraco-db"
  server_id      = azurerm_mssql_server.umbraco_sql.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "Basic"
  
  short_term_retention_policy {
    retention_days = 7
  }
  
  tags = var.tags
}

# Private Endpoint for SQL Server
resource "azurerm_private_endpoint" "sql_private_endpoint" {
  name                = "sql-private-endpoint-${random_string.unique.result}"
  location            = azurerm_resource_group.umbraco_rg.location
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  subnet_id           = azurerm_subnet.sql_subnet.id

  private_service_connection {
    name                           = "sql-private-connection"
    private_connection_resource_id = azurerm_mssql_server.umbraco_sql.id
    is_manual_connection           = false
    subresource_names             = ["sqlServer"]
  }
  
  tags = var.tags
}

# Private DNS Zone for SQL Server
resource "azurerm_private_dns_zone" "sql_dns_zone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  tags                = var.tags
}

# Private DNS Zone Virtual Network Link
resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_link" {
  name                  = "sql-dns-link"
  resource_group_name   = azurerm_resource_group.umbraco_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.umbraco_vnet.id
  tags                  = var.tags
}

# Private DNS A Record
resource "azurerm_private_dns_a_record" "sql_dns_record" {
  name                = azurerm_mssql_server.umbraco_sql.name
  zone_name           = azurerm_private_dns_zone.sql_dns_zone.name
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.sql_private_endpoint.private_service_connection[0].private_ip_address]
}

# App Service VNet Integration
resource "azurerm_app_service_virtual_network_swift_connection" "app_vnet_integration" {
  app_service_id = azurerm_windows_web_app.umbraco_app.id
  subnet_id      = azurerm_subnet.app_subnet.id
}

# Key Vault for secrets
resource "azurerm_key_vault" "umbraco_kv" {
  name                        = "umbraco-kv-${random_string.unique.result}"
  location                    = azurerm_resource_group.umbraco_rg.location
  resource_group_name         = azurerm_resource_group.umbraco_rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                   = "standard"
  
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
  
  tags = var.tags
}

# Key Vault Access Policy for App Service
resource "azurerm_key_vault_access_policy" "app_service_policy" {
  key_vault_id = azurerm_key_vault.umbraco_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_windows_web_app.umbraco_app.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

# CDN Profile for static content
resource "azurerm_cdn_profile" "umbraco_cdn" {
  name                = "umbraco-cdn-${random_string.unique.result}"
  location            = azurerm_resource_group.umbraco_rg.location
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  sku                 = "Standard_Microsoft"
  tags                = var.tags
}

# CDN Endpoint
resource "azurerm_cdn_endpoint" "umbraco_cdn_endpoint" {
  name                = "umbraco-cdn-endpoint-${random_string.unique.result}"
  profile_name        = azurerm_cdn_profile.umbraco_cdn.name
  location            = azurerm_resource_group.umbraco_rg.location
  resource_group_name = azurerm_resource_group.umbraco_rg.name
  
  origin {
    name       = "umbraco-app"
    host_name  = azurerm_windows_web_app.umbraco_app.default_hostname
    http_port  = 80
    https_port = 443
  }
  
  optimization_type = "GeneralWebDelivery"
  
  tags = var.tags
}