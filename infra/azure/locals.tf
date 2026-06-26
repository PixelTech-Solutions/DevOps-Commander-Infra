locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Storage / Function App names cannot contain hyphens and are length-limited.
  short_name = replace(local.name_prefix, "-", "")

  # RAG knowledge base (Step 8). Holds past incidents, the infrastructure
  # inventory (with IPs), and implementation history.
  #
  # `search_index_name` is the index the seed script creates inside the Search
  # service. `search_connection_name` is the Foundry project connection that
  # fronts the Search service. Foundry AUTO-CREATES this connection when the
  # Search resource is provisioned and its name cannot be changed in the portal,
  # so we reference that auto-generated name here. The agent tool uses the
  # connection id + index name separately, so they do not need to match.
  search_index_name      = "erp-knowledge"
  search_connection_name = var.search_connection_name
  search_connection_id   = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.foundry_resource_group}/providers/Microsoft.CognitiveServices/accounts/${var.foundry_resource_name}/projects/${var.foundry_project_name}/connections/${local.search_connection_name}"

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Stack       = "devops-commander"
  }
}
