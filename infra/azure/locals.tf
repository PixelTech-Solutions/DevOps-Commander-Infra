locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Storage / Function App names cannot contain hyphens and are length-limited.
  short_name = replace(local.name_prefix, "-", "")

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Stack       = "devops-commander"
  }
}
