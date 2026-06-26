# ===========================================================================
# Azure AI Search — merged RAG knowledge base (Step 8)
# ---------------------------------------------------------------------------
# ONE index, `erp-knowledge`, grounds the diagnosis agent through the Foundry
# "Azure AI Search" knowledge tool. A tool can only target a single index, so
# all knowledge lives in this one index, fed from three sources:
#
#   A. curated records   -> pushed by tools/seed_knowledge.py (infra inventory
#                           with IPs, past incidents, implementation history).
#   B. company documents -> uploaded to the blob container `knowledge-docs`
#                           and pulled in by a blob indexer (text extraction).
#   C. previous logs     -> App Insights log snapshots written to the blob
#                           container `knowledge-logs` and pulled in by a JSON
#                           lines indexer.
#
# The indexes/indexers/data sources themselves are created by the seed script
# over the Search REST API (the azurerm provider has no resources for them).
# Foundry queries the index server-side via the project CONNECTION it
# auto-creates for the Search service (key-based); its name is wired through
# var.search_connection_name.
#
# Free tier: $0, 3 indexes / 3 indexers / 3 data sources, 50 MB. We use 1 index
# + 2 indexers + 2 data sources — comfortably inside the Free limits.
# ===========================================================================
resource "azurerm_search_service" "incidents" {
  name                = "srch-${local.name_prefix}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "free"

  # Admin-key auth is what the Foundry project connection and the seed script use.
  local_authentication_enabled = true

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Storage account that holds the uploaded company documents (B) and the
# exported log snapshots (C). The blob indexers read from these containers
# using the storage account key (set server-side in the Search data source,
# never committed). Keyless (managed identity) is the upgrade path on Basic+.
# ---------------------------------------------------------------------------
resource "azurerm_storage_account" "knowledge" {
  name                            = substr("kb${local.short_name}${random_string.suffix.result}", 0, 24)
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = local.common_tags
}

resource "azurerm_storage_container" "docs" {
  name                  = "knowledge-docs"
  storage_account_id    = azurerm_storage_account.knowledge.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "logs" {
  name                  = "knowledge-logs"
  storage_account_id    = azurerm_storage_account.knowledge.id
  container_access_type = "private"
}
