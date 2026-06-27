# ===========================================================================
# Azure Bot Service — Web Chat front end for DevOps Commander.
#
# A secretless, user-assigned managed-identity bot (MicrosoftAppType =
# UserAssignedMSI). It reuses the existing Function App as its messaging
# endpoint (/api/messages) and the existing managed identity as its bot
# identity, so there is no app password to store or rotate.
#
# The messaging endpoint is built from the same name expression as the Function
# App (not a resource reference) on purpose: it lets the Direct Line channel
# secret below flow back into the Function's app_settings without creating a
# function -> channel -> bot -> function dependency cycle.
# ===========================================================================
locals {
  func_hostname    = "func-${local.name_prefix}-${random_string.suffix.result}.azurewebsites.net"
  bot_messages_url = "https://${local.func_hostname}/api/messages"
}

resource "azurerm_bot_service_azure_bot" "this" {
  name                = "bot-${local.name_prefix}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = "global"
  sku                 = "F0"

  microsoft_app_type      = "UserAssignedMSI"
  microsoft_app_id        = azurerm_user_assigned_identity.func.client_id
  microsoft_app_msi_id    = azurerm_user_assigned_identity.func.id
  microsoft_app_tenant_id = azurerm_user_assigned_identity.func.tenant_id

  endpoint = local.bot_messages_url

  tags = local.common_tags
}

# Direct Line channel — what the embedded BotFramework-WebChat widget connects
# through. The Function mints a short-lived Direct Line token from this site key
# (server-side), so the secret never reaches the browser.
resource "azurerm_bot_channel_directline" "this" {
  bot_name            = azurerm_bot_service_azure_bot.this.name
  location            = azurerm_bot_service_azure_bot.this.location
  resource_group_name = azurerm_resource_group.this.name

  site {
    name    = "default"
    enabled = true
  }
}
