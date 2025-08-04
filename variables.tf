variable "project_name" {
  description = "Name of the project, used as prefix for resource names"
  type        = string
  default     = "umbraco-app"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-umbraco-app"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "admin_ip_address" {
  description = "IP address for admin access (SSH)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "sql_admin_username" {
  description = "SQL Server administrator username"
  type        = string
  default     = "sqladmin"
  sensitive   = true
}

variable "sql_admin_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "Umbraco"
    ManagedBy   = "Terraform"
  }
}

variable "app_service_plan_sku" {
  description = "SKU for App Service Plan"
  type        = string
  default     = "P1v2"
}

variable "sql_database_sku" {
  description = "SKU for SQL Database"
  type        = string
  default     = "Basic"
}

variable "sql_database_max_size_gb" {
  description = "Maximum size of SQL Database in GB"
  type        = number
  default     = 2
}

variable "enable_ssl" {
  description = "Enable SSL/TLS for the application"
  type        = bool
  default     = true
}

variable "enable_cdn" {
  description = "Enable CDN for static content"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable Application Insights monitoring"
  type        = bool
  default     = true
}