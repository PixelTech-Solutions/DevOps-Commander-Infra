locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Storage / Function App names cannot contain hyphens and are length-limited.
  short_name = replace(local.name_prefix, "-", "")

  # RAG knowledge base (Step 8). Holds past incidents, the infrastructure
  # inventory (with IPs), and implementation history. The Foundry project
  # connection is created by Terraform (azapi_resource.search_connection) so the
  # name is deterministic and no portal click is needed. The agent tool
  # references the connection by its full resource id.
  search_index_name      = "erp-knowledge"
  search_connection_name = "erp-knowledge"
  search_connection_id   = azapi_resource.search_connection.id

  # Parent of the connection = the Foundry PROJECT (not the account). The
  # Foundry account/project is pre-existing and lives in its own resource group.
  foundry_project_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.foundry_resource_group}/providers/Microsoft.CognitiveServices/accounts/${var.foundry_resource_name}/projects/${var.foundry_project_name}"

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Stack       = "devops-commander"
  }
}
