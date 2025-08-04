# CDN Profile
resource "azurerm_cdn_profile" "main" {
  count               = var.enable_cdn ? 1 : 0
  name                = local.cdn_profile_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.environment == "prod" ? "Premium_Verizon" : "Standard_Microsoft"
  tags                = local.common_tags
}

# CDN Endpoint for static content
resource "azurerm_cdn_endpoint" "main" {
  count               = var.enable_cdn ? 1 : 0
  name                = local.cdn_endpoint_name
  profile_name        = azurerm_cdn_profile.main[0].name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Origin configuration
  origin {
    name      = "app-service-origin"
    host_name = var.enable_application_gateway ? azurerm_public_ip.app_gateway[0].fqdn : "${azurerm_linux_web_app.main.name}.azurewebsites.net"
    https_port = 443
    http_port  = 80
  }

  # Caching rules
  delivery_rule {
    name  = "CacheStaticContent"
    order = 1

    url_file_extension_condition {
      operator         = "Equal"
      negate_condition = false
      match_values     = ["css", "js", "png", "jpg", "jpeg", "gif", "ico", "svg", "woff", "woff2", "ttf", "eot"]
    }

    cache_expiration_action {
      behavior = "Override"
      duration = "7.00:00:00"  # 7 days
    }

    cache_key_query_string_action {
      behavior = "ExcludeAll"
    }
  }

  # Rule for Umbraco media files
  delivery_rule {
    name  = "CacheMediaFiles"
    order = 2

    url_path_condition {
      operator         = "BeginsWith"
      negate_condition = false
      match_values     = ["/media/"]
    }

    cache_expiration_action {
      behavior = "Override"
      duration = "30.00:00:00"  # 30 days
    }
  }

  # Rule for Umbraco backoffice (no caching)
  delivery_rule {
    name  = "NoCache"
    order = 3

    url_path_condition {
      operator         = "BeginsWith"
      negate_condition = false
      match_values     = ["/umbraco/"]
    }

    cache_expiration_action {
      behavior = "Bypass"
    }
  }

  # Global delivery rule for HTTPS redirect
  global_delivery_rule {
    cache_expiration_action {
      behavior = "Override"
      duration = "04:00:00"  # 4 hours default
    }

    cache_key_query_string_action {
      behavior = "IncludeAll"
    }
  }

  # Optimization settings
  optimization_type = "GeneralWebDelivery"

  # Geo-filtering (optional)
  dynamic "geo_filter" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      relative_path = "/"
      action        = "Allow"
      country_codes = ["US", "CA", "GB", "DE", "FR", "AU", "NZ"]
    }
  }

  tags = local.common_tags
}

# Custom domain for CDN (if provided)
resource "azurerm_cdn_endpoint_custom_domain" "main" {
  count           = var.enable_cdn && var.custom_domain != "" ? 1 : 0
  name            = replace(var.custom_domain, ".", "-")
  cdn_endpoint_id = azurerm_cdn_endpoint.main[0].id
  host_name       = "cdn.${var.custom_domain}"

  # HTTPS configuration
  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type    = "ServerNameIndication"
    tls_version      = "TLS12"
  }
}