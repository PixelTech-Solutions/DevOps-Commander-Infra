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
# Azure OpenAI (Foundry) — the project + GPT-4o deployment are created in the
# Foundry portal (ai.azure.com). Terraform references the resulting AIServices
# account to grant the Function App keyless access.
# ---------------------------------------------------------------------------
variable "foundry_resource_name" {
  type        = string
  description = "Name of the Azure AI Foundry (AIServices) resource created in the portal"
  default     = "devops-commanderv1"
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

variable "gpt_api_version" {
  type        = string
  description = "Azure OpenAI API version the Function will request"
  default     = "2024-10-21"
}

