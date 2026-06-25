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
