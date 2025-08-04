# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = local.log_analytics_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.environment == "prod" ? "PerGB2018" : "Free"
  retention_in_days   = var.environment == "prod" ? 90 : 30
  
  tags = local.common_tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = local.app_insights_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  
  # Sampling settings
  sampling_percentage = var.environment == "prod" ? 100 : 50
  
  tags = local.common_tags
}

# Action Group for alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "ag-${local.name_prefix}-alerts"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "umbraco"

  # Email notifications (configure as needed)
  email_receiver {
    name          = "admin-email"
    email_address = "admin@example.com"  # Replace with actual email
  }

  # Webhook notifications (optional)
  webhook_receiver {
    name        = "webhook"
    service_uri = "https://example.com/webhook"  # Replace with actual webhook URL
  }

  tags = local.common_tags
}

# Metric Alert for high CPU usage
resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "High CPU Usage - ${local.app_service_name}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_web_app.main.id]
  description         = "Alert when CPU usage is consistently high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "CpuPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# Metric Alert for high memory usage
resource "azurerm_monitor_metric_alert" "high_memory" {
  name                = "High Memory Usage - ${local.app_service_name}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_web_app.main.id]
  description         = "Alert when memory usage is consistently high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "MemoryPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# Metric Alert for HTTP 5xx errors
resource "azurerm_monitor_metric_alert" "http_5xx_errors" {
  name                = "HTTP 5xx Errors - ${local.app_service_name}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_web_app.main.id]
  description         = "Alert when there are too many HTTP 5xx errors"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# Metric Alert for response time
resource "azurerm_monitor_metric_alert" "response_time" {
  name                = "High Response Time - ${local.app_service_name}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_web_app.main.id]
  description         = "Alert when response time is consistently high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "AverageResponseTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5  # 5 seconds
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# SQL Database DTU alert
resource "azurerm_monitor_metric_alert" "sql_dtu" {
  name                = "High DTU Usage - ${local.sql_database_name}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_mssql_database.main.id]
  description         = "Alert when SQL Database DTU usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "dtu_consumption_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# Application Insights availability test
resource "azurerm_application_insights_web_test" "main" {
  name                    = "availability-test-${local.app_service_name}"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  application_insights_id = azurerm_application_insights.main.id
  kind                    = "ping"
  frequency               = 300  # 5 minutes
  timeout                 = 30
  enabled                 = true
  retry_enabled           = true
  geo_locations          = ["us-ca-sjc-azr", "us-tx-sn1-azr", "us-il-ch1-azr"]

  configuration = <<XML
<WebTest Name="Umbraco Health Check" Id="ABD48585-0831-40CB-9069-682EA6BB3583" Enabled="True" CssProjectStructure="" CssIteration="" Timeout="30" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale="">
  <Items>
    <Request Method="GET" Guid="a5f10126-e4cd-570d-961c-cea43999a200" Version="1.1" Url="${var.enable_application_gateway ? "https://${azurerm_public_ip.app_gateway[0].fqdn}" : "https://${azurerm_linux_web_app.main.name}.azurewebsites.net"}" ThinkTime="0" Timeout="30" ParseDependentRequests="True" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" />
  </Items>
</WebTest>
XML

  tags = local.common_tags
}

# Availability test alert
resource "azurerm_monitor_metric_alert" "availability" {
  name                = "Low Availability - ${local.app_service_name}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_insights_web_test.main.id, azurerm_application_insights.main.id]
  description         = "Alert when availability drops below threshold"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  enabled             = true

  application_insights_web_test_location_availability_criteria {
    web_test_id           = azurerm_application_insights_web_test.main.id
    component_id          = azurerm_application_insights.main.id
    failed_location_count = 2
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# Dashboard for monitoring
resource "azurerm_portal_dashboard" "main" {
  name                = "dashboard-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  dashboard_properties = jsonencode({
    lenses = {
      "0" = {
        order = 0
        parts = {
          "0" = {
            position = {
              x = 0
              y = 0
              rowSpan = 4
              colSpan = 6
            }
            metadata = {
              inputs = [
                {
                  name = "resourceId"
                  value = azurerm_linux_web_app.main.id
                }
              ]
              type = "Extension/Microsoft_Azure_Monitoring/PartType/MetricsChartPart"
            }
          }
          "1" = {
            position = {
              x = 6
              y = 0
              rowSpan = 4
              colSpan = 6
            }
            metadata = {
              inputs = [
                {
                  name = "resourceId"
                  value = azurerm_mssql_database.main.id
                }
              ]
              type = "Extension/Microsoft_Azure_Monitoring/PartType/MetricsChartPart"
            }
          }
        }
      }
    }
  })

  tags = local.common_tags
}