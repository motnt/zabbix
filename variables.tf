variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "umbraco-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
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
  description = "SKU for the App Service Plan"
  type        = string
  default     = "P1v3"
  
  validation {
    condition     = contains(["B1", "B2", "B3", "P1v2", "P2v2", "P3v2", "P1v3", "P2v3", "P3v3", "S1", "S2", "S3"], var.app_service_plan_sku)
    error_message = "App Service Plan SKU must be one of: B1, B2, B3, P1v2, P2v2, P3v2, P1v3, P2v3, P3v3, S1, S2, S3."
  }
}

variable "sql_admin_username" {
  description = "SQL Server administrator username"
  type        = string
  default     = "umbraco_admin"
  sensitive   = true
}

variable "sql_admin_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.sql_admin_password) >= 8
    error_message = "SQL admin password must be at least 8 characters long."
  }
}

variable "azure_ad_admin_object_id" {
  description = "Object ID of the Azure AD user/group to be SQL Server administrator"
  type        = string
  default     = ""
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for SQL Server"
  type        = bool
  default     = true
}

variable "enable_cdn" {
  description = "Enable CDN for static content delivery"
  type        = bool
  default     = true
}

variable "enable_key_vault" {
  description = "Enable Key Vault for secrets management"
  type        = bool
  default     = true
}

variable "enable_application_insights" {
  description = "Enable Application Insights for monitoring"
  type        = bool
  default     = true
}

variable "sql_database_sku" {
  description = "SKU for the SQL Database"
  type        = string
  default     = "Basic"
  
  validation {
    condition     = contains(["Basic", "Standard", "Premium", "GeneralPurpose", "BusinessCritical", "Hyperscale"], var.sql_database_sku)
    error_message = "SQL Database SKU must be one of: Basic, Standard, Premium, GeneralPurpose, BusinessCritical, Hyperscale."
  }
}

variable "sql_database_max_size_gb" {
  description = "Maximum size of the SQL Database in GB"
  type        = number
  default     = 2
  
  validation {
    condition     = var.sql_database_max_size_gb >= 1 && var.sql_database_max_size_gb <= 4096
    error_message = "SQL Database max size must be between 1 and 4096 GB."
  }
}

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Storage account tier must be either Standard or Premium."
  }
}

variable "storage_account_replication" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
  
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_account_replication)
    error_message = "Storage account replication must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "app_subnet_address_prefix" {
  description = "Address prefix for the App Service subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "sql_subnet_address_prefix" {
  description = "Address prefix for the SQL Server subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling for the App Service Plan"
  type        = bool
  default     = false
}

variable "auto_scaling_min_instances" {
  description = "Minimum number of instances for auto scaling"
  type        = number
  default     = 1
  
  validation {
    condition     = var.auto_scaling_min_instances >= 1
    error_message = "Minimum instances must be at least 1."
  }
}

variable "auto_scaling_max_instances" {
  description = "Maximum number of instances for auto scaling"
  type        = number
  default     = 10
  
  validation {
    condition     = var.auto_scaling_max_instances >= var.auto_scaling_min_instances
    error_message = "Maximum instances must be greater than or equal to minimum instances."
  }
}