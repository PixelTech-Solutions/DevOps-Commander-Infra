# ===========================================================================
# Self-hosted Grafana MCP server — Azure Container Apps
# ---------------------------------------------------------------------------
# Grafana Cloud exposes NO hosted MCP endpoint for our stack, so we run the
# official `grafana/mcp-grafana` image ourselves. Container Apps gives a public
# HTTPS FQDN backed by a valid Microsoft-issued certificate, so Azure AI Foundry
# can reach it over the internet immediately — no VM, ansible, Caddy, or
# Let's Encrypt. It scales to zero when idle (~$0).
#
# Auth model (no secret stored here): the container holds only GRAFANA_URL.
# mcp-grafana runs in streamable-http mode and authenticates to Grafana
# per request using the `Authorization: Bearer <SA token>` header injected by
# the Foundry "grafana-mcp" Custom-keys connection. So the public endpoint is
# useless without a valid Grafana service-account token, and no secret ever
# lands in git or Terraform state. `--disable-write` keeps it strictly
# read-only.
# ===========================================================================
resource "azurerm_container_app_environment" "mcp" {
  name                       = "cae-${local.name_prefix}"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  tags                       = local.common_tags
}

resource "azurerm_container_app" "grafana_mcp" {
  name                         = "ca-grafana-mcp-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.mcp.id
  resource_group_name          = azurerm_resource_group.this.name
  revision_mode                = "Single"
  tags                         = local.common_tags

  template {
    min_replicas = 0 # scale to zero when idle — near-zero cost
    max_replicas = 1

    container {
      name   = "mcp-grafana"
      image  = var.grafana_mcp_image
      cpu    = 0.25
      memory = "0.5Gi"

      # The image entrypoint is the mcp-grafana binary (defaults to stdio).
      # Switch to streamable-http and bind 0.0.0.0 so ACA's ingress can reach
      # it (the default localhost:8000 only listens on loopback). The endpoint
      # path defaults to /mcp. --disable-write keeps it strictly read-only.
      # (This image build has no --allowed-hosts/--allowed-origins flags, so
      # there is no DNS-rebinding host check to configure.)
      args = [
        "-t", "streamable-http",
        "--address", "0.0.0.0:8000",
        "--disable-write",
      ]

      env {
        name  = "GRAFANA_URL"
        value = var.grafana_url
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "http" # ACA terminates TLS; container speaks plain HTTP

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
