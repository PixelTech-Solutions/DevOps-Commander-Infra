output "resource_group_name" {
  description = "Resource group hosting the Function App"
  value       = azurerm_resource_group.this.name
}

output "function_app_name" {
  description = "Function App name — set this as repo variable FUNCTION_APP_NAME in DevOps-Commander"
  value       = azurerm_linux_function_app.this.name
}

output "function_app_default_hostname" {
  description = "Default *.azurewebsites.net hostname"
  value       = azurerm_linux_function_app.this.default_hostname
}

output "alert_endpoint_url" {
  description = "Public HTTPS URL Datadog / Grafana webhooks should POST to"
  value       = "https://${azurerm_linux_function_app.this.default_hostname}/api/alert"
}

output "application_insights_connection_string" {
  description = "App Insights connection string (already wired into the Function App)"
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "alert_shared_secret" {
  description = "Shared secret Datadog/Grafana must send in header X-Alert-Token. Also visible in Function App > Environment variables > ALERT_SHARED_SECRET."
  value       = random_password.alert_secret.result
  sensitive   = true
}
