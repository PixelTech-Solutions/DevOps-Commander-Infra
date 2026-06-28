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
# Datadog US5 is the hosted default. Set grafana_mcp_url to YOUR Grafana Cloud
# stack's MCP endpoint, e.g. https://yourstack.grafana.net/api/mcp (leave empty
# to disable the Grafana tool). The API keys / service-account token are secrets
# injected by the function deploy pipeline, never here.
datadog_mcp_url = "https://mcp.us5.datadoghq.com"
grafana_mcp_url = "https://indigopastry1703.grafana.net/api/mcp"
