# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  address_space       = local.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# Subnet for App Services
resource "azurerm_subnet" "app" {
  name                 = local.subnet_app_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = local.subnet_app_address

  # Service endpoints
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Sql"
  ]

  # Delegation for App Service
  delegation {
    name = "app-service-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Subnet for Database private endpoints
resource "azurerm_subnet" "db" {
  name                 = local.subnet_db_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = local.subnet_db_address

  # Disable private endpoint network policies
  private_endpoint_network_policies_enabled = false
}

# Subnet for Application Gateway
resource "azurerm_subnet" "gateway" {
  count                = var.enable_application_gateway ? 1 : 0
  name                 = local.subnet_gateway_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = local.subnet_gateway_address
}

# Network Security Group for App Service subnet
resource "azurerm_network_security_group" "app" {
  name                = local.nsg_app_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow HTTPS from Application Gateway
  security_rule {
    name                       = "AllowHTTPSFromAppGateway"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.enable_application_gateway ? local.subnet_gateway_address : []
    destination_address_prefix = "*"
  }

  # Allow HTTP from Application Gateway
  security_rule {
    name                       = "AllowHTTPFromAppGateway"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefixes    = var.enable_application_gateway ? local.subnet_gateway_address : []
    destination_address_prefix = "*"
  }

  # Allow specific IP ranges if provided
  dynamic "security_rule" {
    for_each = var.allowed_ip_ranges
    content {
      name                       = "AllowHTTPSFrom${security_rule.key}"
      priority                   = 200 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = security_rule.value
      destination_address_prefix = "*"
    }
  }

  # Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Network Security Group for Database subnet
resource "azurerm_network_security_group" "db" {
  name                = local.nsg_db_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow SQL from App Service subnet
  security_rule {
    name                       = "AllowSQLFromAppSubnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefixes    = local.subnet_app_address
    destination_address_prefix = "*"
  }

  # Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Associate NSG with App Service subnet
resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# Associate NSG with Database subnet
resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db.id
}

# Public IP for Application Gateway
resource "azurerm_public_ip" "app_gateway" {
  count               = var.enable_application_gateway ? 1 : 0
  name                = "pip-${local.app_gateway_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.environment == "prod" ? ["1", "2", "3"] : null

  tags = local.common_tags
}