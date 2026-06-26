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

output "function_app_principal_id" {
  description = "User-assigned managed identity of the Function App (granted Cognitive Services OpenAI User on the Foundry resource)."
  value       = azurerm_user_assigned_identity.func.principal_id
}

# ---------------------------------------------------------------------------
# Azure AI Search (RAG, Step 8). Use these to create the Foundry project
# connection ONCE in the portal: Management center > Connected resources >
# New connection > Azure AI Search > Enter manually > API key. The connection
# NAME must be exactly `search_connection_name` below.
# ---------------------------------------------------------------------------
output "search_endpoint" {
  description = "Azure AI Search endpoint — paste into the Foundry connection."
  value       = "https://${azurerm_search_service.incidents.name}.search.windows.net"
}

output "search_admin_key" {
  description = "Admin key for the Search service — paste into the Foundry connection (API key auth)."
  value       = azurerm_search_service.incidents.primary_key
  sensitive   = true
}

output "search_index_name" {
  description = "Index name the seed script creates and the agent queries."
  value       = local.search_index_name
}

output "search_connection_name" {
  description = "Name the Foundry project connection MUST use (must match the index name)."
  value       = local.search_connection_name
}

# ---------------------------------------------------------------------------
# Knowledge storage (B = company docs, C = exported logs). The seed script and
# the `az storage blob upload` step use these. The connection string is also
# what the seed script puts into the Search blob data sources (server-side).
# ---------------------------------------------------------------------------
output "knowledge_storage_account" {
  description = "Storage account holding the knowledge-docs and knowledge-logs containers."
  value       = azurerm_storage_account.knowledge.name
}

output "knowledge_storage_connection_string" {
  description = "Connection string for the knowledge storage account (used by the Search blob data sources)."
  value       = azurerm_storage_account.knowledge.primary_connection_string
  sensitive   = true
}
