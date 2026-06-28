environment    = "prod"
location       = "eastus"
project_name   = "devops-commander"
python_version = "3.11"

# Foundry resource created in the portal (ai.azure.com). If the portal placed it
# in a different resource group, change foundry_resource_group accordingly.
foundry_resource_name  = "devops-commanderv1"
foundry_resource_group = "devops-commander"
gpt_deployment_name    = "gpt-4o"
gpt_api_version        = "2024-10-21"

# Live observability — official remote MCP endpoints (non-secret URLs only).
# Datadog US5 is the hosted default. Grafana Cloud has NO hosted MCP, so we
# self-host mcp-grafana on Container Apps (grafana_mcp.tf): GRAFANA_MCP_URL is
# derived from that Container App's FQDN automatically. grafana_url is just the
# Grafana stack the container queries; the SA token is injected per-request by
# the Foundry "grafana-mcp" connection, never stored here.
datadog_mcp_url = "https://mcp.us5.datadoghq.com/v1/mcp"
grafana_url     = "https://indigopastry1703.grafana.net"
