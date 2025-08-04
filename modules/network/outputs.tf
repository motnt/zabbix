output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

output "app_subnet_id" {
  description = "ID of the App Subnet"
  value       = azurerm_subnet.app_subnet.id
}

output "database_subnet_id" {
  description = "ID of the Database Subnet"
  value       = azurerm_subnet.database_subnet.id
}

output "app_nsg_id" {
  description = "ID of the App Network Security Group"
  value       = azurerm_network_security_group.app_nsg.id
}

output "database_nsg_id" {
  description = "ID of the Database Network Security Group"
  value       = azurerm_network_security_group.database_nsg.id
}