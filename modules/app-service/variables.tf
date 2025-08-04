variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
}

variable "app_service_name" {
  description = "Name of the App Service"
  type        = string
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

variable "app_settings" {
  description = "Application settings for the App Service"
  type        = map(string)
  default     = {}
}

variable "enable_vnet_integration" {
  description = "Enable VNet integration for the App Service"
  type        = bool
  default     = false
}

variable "app_subnet_id" {
  description = "ID of the subnet for VNet integration"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}