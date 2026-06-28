# ===========================================================================
# Self-hosted Grafana MCP server — Azure Container Apps
# ---------------------------------------------------------------------------
# Grafana Cloud exposes NO hosted MCP endpoint for our stack, so we run the
# official `grafana/mcp-grafana` image ourselves. Container Apps gives a public
# HTTPS FQDN backed by a valid Microsoft-issued certificate, so Azure AI Foundry
# can reach it over the internet immediately — no VM, ansible, Caddy, or
# Let's Encrypt. It scales to zero when idle (~$0).
#
# Auth model (Model B): this `:latest` (devel) build does NOT honor a
# per-request `Authorization` header, so the container authenticates to
# Grafana using its own GRAFANA_SERVICE_ACCOUNT_TOKEN env var, fed from a
# Container Apps secret. The real token value is set out-of-band via
# `az containerapp secret set` (the reusable Terraform workflow can't forward
# a TF_VAR for it), so Terraform keeps only a placeholder and ignores secret
# drift — no real token ever lands in git or state. `--disable-write` keeps
# the endpoint strictly read-only, so a fixed token is acceptable.
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

      # Real token is injected out-of-band via `az containerapp secret set`;
      # the secret value below is a placeholder and is ignored (see lifecycle).
      env {
        name        = "GRAFANA_SERVICE_ACCOUNT_TOKEN"
        secret_name = "grafana-sa-token"
      }
    }
  }

  # Placeholder secret — the real Grafana SA token is set via Azure CLI and
  # preserved by ignore_changes so pipeline runs never overwrite it.
  secret {
    name  = "grafana-sa-token"
    value = "set-via-az-containerapp-secret-set"
  }

  lifecycle {
    ignore_changes = [secret]
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
