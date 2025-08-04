variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "umbraco"
}

variable "sql_admin_username" {
  description = "SQL Server administrator username"
  type        = string
  default     = "sqladmin"
}

variable "app_service_sku" {
  description = "App Service Plan SKU"
  type        = string
  default     = "P1v3"
  validation {
    condition = contains([
      "B1", "B2", "B3",
      "S1", "S2", "S3",
      "P1v2", "P2v2", "P3v2",
      "P1v3", "P2v3", "P3v3"
    ], var.app_service_sku)
    error_message = "App Service SKU must be a valid Azure App Service Plan SKU."
  }
}

variable "sql_database_sku" {
  description = "SQL Database SKU"
  type        = string
  default     = "S2"
}

variable "enable_application_gateway" {
  description = "Enable Application Gateway for advanced routing and SSL termination"
  type        = bool
  default     = true
}

variable "enable_cdn" {
  description = "Enable Azure CDN for static content delivery"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable backup for App Service and SQL Database"
  type        = bool
  default     = true
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access the application"
  type        = list(string)
  default     = []
}

variable "custom_domain" {
  description = "Custom domain name for the application"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Umbraco"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}