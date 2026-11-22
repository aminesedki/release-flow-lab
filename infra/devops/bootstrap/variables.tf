variable "app_name" {
  description = "Application name used as resource prefix"
  type        = string
  default     = "release-flow-lab"
}

variable "devops_project_id" {
  description = "Project ID of the devops project to create"
  type        = string
}

variable "billing_account" {
  description = "Billing account ID linked to the created project"
  type        = string
}

variable "org_id" {
  description = "GCP organization ID (digits only)"
  type        = string
}

variable "region" {
  description = "Region for the central state bucket"
  type        = string
  default     = "europe-west9"
}
