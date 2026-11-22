variable "region" {
  description = "Region for all environments"
  type        = string
  default     = "europe-west9"
}

variable "app_name" {
  description = "Application name used as resource prefix"
  type        = string
  default     = "release-flow-lab"
}

variable "envs" {
  description = "Environments to manage. One entry per apply (each env has its own state)."
  type = map(object({
    project_id = string
  }))
}

locals {
  envs = var.envs
}
