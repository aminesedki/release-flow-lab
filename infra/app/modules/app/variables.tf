variable "project_id" {
  description = "GCP project dedicated to this environment"
  type        = string
}

variable "region" {
  description = "Region for the environment resources"
  type        = string
  default     = "europe-west9"
}

variable "app_name" {
  description = "Application name used as resource prefix"
  type        = string
  default     = "release-flow-lab"
}

variable "env" {
  description = "Environment short name (dv, qa, np, pd)"
  type        = string
}
