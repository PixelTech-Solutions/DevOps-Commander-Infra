variable "environment" {
  type        = string
  description = "Deployment environment (dev, prod)"
  default     = "prod"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "eastus"
}

variable "project_name" {
  type        = string
  description = "Project name used in resource naming"
  default     = "devops-commander"
}

variable "python_version" {
  type        = string
  description = "Python runtime version for the Function App"
  default     = "3.11"
}

# ---------------------------------------------------------------------------
# Live observability — official remote MCP servers (Datadog + Grafana). The URLs
# are non-secret endpoints; auth is supplied by Foundry "Custom keys" project
# connections (referenced by name), so NO secret lives in TF, git, or state.
# ---------------------------------------------------------------------------
variable "datadog_mcp_url" {
  type        = string
  description = "Datadog hosted MCP endpoint (US5). Empty disables the Datadog tool."
  default     = "https://mcp.us5.datadoghq.com"
}

variable "grafana_mcp_url" {
  type        = string
  description = "Grafana Cloud hosted MCP endpoint, e.g. https://<stack>.grafana.net/api/mcp. Empty disables the Grafana tool."
  default     = ""
}

variable "datadog_mcp_connection" {
  type        = string
  description = "Name of the Foundry 'Custom keys' connection holding the Datadog MCP headers (DD-API-KEY, DD-APPLICATION-KEY)."
  default     = "datadog-mcp"
}

variable "grafana_mcp_connection" {
  type        = string
  description = "Name of the Foundry 'Custom keys' connection holding the Grafana MCP header (Authorization = Bearer <token>)."
  default     = "grafana-mcp"
}

# ---------------------------------------------------------------------------
# Azure OpenAI (Foundry) — the project + GPT-4o deployment are created in the
# Foundry portal (ai.azure.com). Terraform references the resulting AIServices
# account to grant the Function App keyless access.
# ---------------------------------------------------------------------------
variable "foundry_resource_name" {
  type        = string
  description = "Name of the Azure AI Foundry (AIServices) resource created in the portal"
  default     = "devops-commanderv1"
}

variable "foundry_project_name" {
  type        = string
  description = "Name of the Foundry project that hosts the agents (ai.azure.com)"
  default     = "devops-commander"
}

variable "foundry_resource_group" {
  type        = string
  description = "Resource group that contains the Foundry resource. Defaults to this stack's RG; override in tfvars if the portal placed it elsewhere."
  default     = "rg-devops-commander-prod"
}

variable "gpt_deployment_name" {
  type        = string
  description = "Name of the GPT-4o model deployment in the Foundry project"
  default     = "gpt-4o"
}

variable "search_connection_name" {
  type        = string
  description = "Foundry project connection that fronts the Azure AI Search service. Foundry auto-creates this when the Search resource is provisioned and the name cannot be edited in the portal, so default to that generated name (override in tfvars if it differs)."
  default     = "srchdevopscommanderpr349a5k"
}

variable "gpt_api_version" {
  type        = string
  description = "Azure OpenAI API version the Function will request"
  default     = "2024-10-21"
}

