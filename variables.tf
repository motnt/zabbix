variable "project_name" {
  description = "Base name used for all resources"
  type        = string
  default     = "umbraco"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region to deploy resources into"
  type        = string
  default     = "westeurope"
}

variable "sql_admin_username" {
  description = "Administrator username for the SQL server"
  type        = string
  default     = "sqladminuser"
}

variable "sql_sku_name" {
  description = "SKU for Azure SQL Database"
  type        = string
  default     = "GP_S_Gen5_2"
}

variable "app_service_plan_sku" {
  description = "SKU of the App Service Plan"
  type        = string
  default     = "P1v3"
}

variable "umbraco_docker_image" {
  description = "Docker image tag for Umbraco CMS"
  type        = string
  default     = "umbraco/umbraco:latest"
}