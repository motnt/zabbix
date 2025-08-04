# Application Gateway
resource "azurerm_application_gateway" "main" {
  count               = var.enable_application_gateway ? 1 : 0
  name                = local.app_gateway_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # SKU configuration
  sku {
    name     = var.environment == "prod" ? "WAF_v2" : "Standard_v2"
    tier     = var.environment == "prod" ? "WAF_v2" : "Standard_v2"
    capacity = var.environment == "prod" ? 2 : 1
  }

  # Autoscaling for production
  dynamic "autoscale_configuration" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      min_capacity = 2
      max_capacity = 10
    }
  }

  # Zones for high availability in production
  zones = var.environment == "prod" ? ["1", "2", "3"] : null

  # Gateway IP configuration
  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.gateway[0].id
  }

  # Frontend port for HTTP
  frontend_port {
    name = "http-port"
    port = 80
  }

  # Frontend port for HTTPS
  frontend_port {
    name = "https-port"
    port = 443
  }

  # Frontend IP configuration
  frontend_ip_configuration {
    name                 = "frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.app_gateway[0].id
  }

  # Backend address pool
  backend_address_pool {
    name  = "app-service-backend-pool"
    fqdns = ["${azurerm_linux_web_app.main.name}.azurewebsites.net"]
  }

  # Backend HTTP settings
  backend_http_settings {
    name                                = "app-service-http-settings"
    cookie_based_affinity               = "Disabled"
    path                                = "/"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 60
    pick_host_name_from_backend_address = true
    
    # Health probe
    probe_name = "app-service-health-probe"
  }

  # Health probe
  probe {
    name                                      = "app-service-health-probe"
    protocol                                  = "Https"
    path                                      = "/umbraco/api/health"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
    
    match {
      status_code = ["200-399"]
    }
  }

  # HTTP listener (redirect to HTTPS)
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  # HTTPS listener
  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name             = "https-port"
    protocol                       = "Https"
    ssl_certificate_name           = "app-ssl-cert"
  }

  # SSL certificate (self-signed for demo - replace with real certificate)
  ssl_certificate {
    name     = "app-ssl-cert"
    data     = filebase64("${path.module}/certificates/app-cert.pfx")
    password = "P@ssw0rd123!"
  }

  # Request routing rule for HTTP to HTTPS redirect
  request_routing_rule {
    name                       = "http-redirect-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    redirect_configuration_name = "http-to-https-redirect"
    priority                   = 100
  }

  # Request routing rule for HTTPS
  request_routing_rule {
    name                       = "https-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "app-service-backend-pool"
    backend_http_settings_name = "app-service-http-settings"
    priority                   = 200
  }

  # Redirect configuration for HTTP to HTTPS
  redirect_configuration {
    name                 = "http-to-https-redirect"
    redirect_type        = "Permanent"
    target_listener_name = "https-listener"
    include_path         = true
    include_query_string = true
  }

  # WAF configuration for production
  dynamic "waf_configuration" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      enabled          = true
      firewall_mode    = "Prevention"
      rule_set_type    = "OWASP"
      rule_set_version = "3.2"
      
      # Disabled rules (customize as needed)
      disabled_rule_group {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
        rules           = [920300, 920440]
      }
    }
  }

  # Custom error pages
  custom_error_configuration {
    status_code           = "HttpStatus403"
    custom_error_page_url = "https://${azurerm_storage_account.main.name}.blob.core.windows.net/static/403.html"
  }

  custom_error_configuration {
    status_code           = "HttpStatus502"
    custom_error_page_url = "https://${azurerm_storage_account.main.name}.blob.core.windows.net/static/502.html"
  }

  tags = local.common_tags

  depends_on = [
    azurerm_subnet.gateway,
    azurerm_public_ip.app_gateway,
    azurerm_linux_web_app.main
  ]
}

# Create self-signed certificate for demo (replace with real certificate in production)
resource "null_resource" "create_ssl_cert" {
  count = var.enable_application_gateway ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.module}/certificates
      openssl req -x509 -newkey rsa:4096 -keyout ${path.module}/certificates/app-key.pem -out ${path.module}/certificates/app-cert.pem -days 365 -nodes -subj "/CN=${var.custom_domain != "" ? var.custom_domain : "${local.app_service_name}.azurewebsites.net"}"
      openssl pkcs12 -export -out ${path.module}/certificates/app-cert.pfx -inkey ${path.module}/certificates/app-key.pem -in ${path.module}/certificates/app-cert.pem -password pass:P@ssw0rd123!
    EOT
  }

  triggers = {
    domain = var.custom_domain != "" ? var.custom_domain : "${local.app_service_name}.azurewebsites.net"
  }
}