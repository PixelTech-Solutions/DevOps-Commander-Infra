# ===========================================================================
# Resource group — separate from the ERP system so we can rebuild independently
# ===========================================================================
resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}

# Random suffix keeps globally-unique names (storage + function app) collision-free
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

# Shared secret used by Datadog/Grafana webhooks (header X-Alert-Token).
# Generated server-side so it never appears in git or workflow logs.
resource "random_password" "alert_secret" {
  length           = 48
  special          = true
  override_special = "_-"
}

# ===========================================================================
# Storage account — required by the Functions runtime for triggers and logs
# ===========================================================================
resource "azurerm_storage_account" "func" {
  name                            = substr("st${local.short_name}${random_string.suffix.result}", 0, 24)
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = local.common_tags
}

# ===========================================================================
# Observability — Log Analytics + Application Insights
# ===========================================================================
resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${local.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_application_insights" "this" {
  name                = "appi-${local.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = local.common_tags
}

# ===========================================================================
# Function App — Consumption plan (Y1), Linux, Python 3.11
# ===========================================================================
resource "azurerm_service_plan" "this" {
  name                = "asp-${local.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = local.common_tags
}

# User-assigned managed identity for the Function App. Used as a separate
# resource (instead of inline system-assigned) so principal_id is known at
# plan time and propagates cleanly into the role assignment below.
resource "azurerm_user_assigned_identity" "func" {
  name                = "id-${local.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_linux_function_app" "this" {
  name                       = "func-${local.name_prefix}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  service_plan_id            = azurerm_service_plan.this.id
  storage_account_name       = azurerm_storage_account.func.name
  storage_account_access_key = azurerm_storage_account.func.primary_access_key
  https_only                 = true
  tags                       = local.common_tags

  # Keyless auth to Azure OpenAI via the user-assigned identity above
  # (granted Cognitive Services OpenAI User on the Foundry resource). No API key.
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.func.id]
  }

  site_config {
    application_insights_connection_string = azurerm_application_insights.this.connection_string
    application_insights_key               = azurerm_application_insights.this.instrumentation_key
    ftps_state                             = "Disabled"
    minimum_tls_version                    = "1.2"

    application_stack {
      python_version = var.python_version
    }

    cors {
      allowed_origins = ["*"]
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    AzureWebJobsFeatureFlags = "EnableWorkerIndexing"

    # The deploy workflow vendors dependencies into .python_packages on the
    # ubuntu runner (correct Linux wheels) and ships a complete package, so the
    # platform must NOT try to build. Server-side Oryx build on Linux
    # Consumption set run-from-package to an un-built zip, which left the worker
    # unable to import azure.functions (0 functions indexed -> 404).
    SCM_DO_BUILD_DURING_DEPLOYMENT = "false"
    ENABLE_ORYX_BUILD              = "false"
    ALERT_SHARED_SECRET            = random_password.alert_secret.result

    # Azure OpenAI (keyless — auth via the user-assigned identity above).
    # Endpoint is the new OpenAI v1 surface exposed by the Foundry resource.
    # AZURE_CLIENT_ID tells DefaultAzureCredential which identity to use.
    AZURE_CLIENT_ID          = azurerm_user_assigned_identity.func.client_id
    AZURE_OPENAI_ENDPOINT    = "https://${var.foundry_resource_name}.services.ai.azure.com/openai/v1"
    AZURE_OPENAI_DEPLOYMENT  = var.gpt_deployment_name
    AZURE_OPENAI_API_VERSION = var.gpt_api_version
  }

  lifecycle {
    ignore_changes = [
      # Don't reset app settings on every apply if the deploy workflow tweaked them
      app_settings["WEBSITE_RUN_FROM_PACKAGE"]
    ]
  }
}

# ===========================================================================
# Azure OpenAI (Foundry) — portal-created resource referenced as data source.
# Grant the Function App's managed identity the role needed to call inference
# (keyless). The Foundry resource is an AIServices Cognitive account.
# ===========================================================================
data "azurerm_cognitive_account" "foundry" {
  name                = var.foundry_resource_name
  resource_group_name = var.foundry_resource_group
}

resource "azurerm_role_assignment" "func_openai_user" {
  scope                = data.azurerm_cognitive_account.foundry.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.func.principal_id
}

