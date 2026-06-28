# ===========================================================================
# Azure Communication Services — Email (human visibility for alerts)
# ---------------------------------------------------------------------------
# When an alert fires, the Function notifies a human by email (and, in parallel,
# proactively via the Teams bot). ACS Email is the Azure-native, low-cost way to
# send mail without an SMTP server or third-party API key. We use an
# Azure-managed domain (free, provisioned instantly) so the system can send from
# DoNotReply@<random>.azurecomm.net with no DNS verification step.
#
# The connection string is read from the resource and injected as an app
# setting (consistent with how storage keys are already handled) — no secret in
# git or workflow logs.
# ===========================================================================
resource "azurerm_communication_service" "this" {
  name                = "acs-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.this.name
  data_location       = var.acs_data_location
  tags                = local.common_tags
}

resource "azurerm_email_communication_service" "this" {
  name                = "ecs-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.this.name
  data_location       = var.acs_data_location
  tags                = local.common_tags
}

# Azure-managed sender domain — free, instant, no DNS records to verify.
resource "azurerm_email_communication_service_domain" "this" {
  name              = "AzureManagedDomain"
  email_service_id  = azurerm_email_communication_service.this.id
  domain_management = "AzureManaged"
  tags              = local.common_tags
}

# Bind the email domain to the Communication Service so it can send from it.
resource "azurerm_communication_service_email_domain_association" "this" {
  communication_service_id = azurerm_communication_service.this.id
  email_service_domain_id  = azurerm_email_communication_service_domain.this.id
}
