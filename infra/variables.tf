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

variable "github_owner" {
  description = "GitHub owner of the repository watched by the Cloud Build triggers"
  type        = string
  default     = "aminesedki"
}

variable "github_repo" {
  description = "GitHub repository name watched by the Cloud Build triggers"
  type        = string
  default     = "release-flow-lab"
}

variable "org_id" {
  description = "GCP organization ID (digits only). Leave null to create projects without organization (no folder)."
  type        = string
  default     = null
}

variable "billing_account" {
  description = "Billing account ID (XXXXXX-XXXXXX-XXXXXX) linked to the created projects"
  type        = string
}

variable "folder_display_name" {
  description = "Folder that groups the four environment projects (requires org_id)"
  type        = string
  default     = "release-flow-lab"
}

variable "project_deletion_policy" {
  description = "google_project deletion_policy: ABANDON (safe) or DELETE (destroys projects on terraform destroy)"
  type        = string
  default     = "ABANDON"
}

variable "envs" {
  description = "Environments. Each env has its own GCP project; `branch` is the git branch whose push triggers a Cloud Build deploy to that env."
  type = map(object({
    project_id = string
    branch     = string
  }))
  default = {
    dv = { project_id = "REPLACE_ME-dv", branch = "rc/dv" }
    qa = { project_id = "REPLACE_ME-qa", branch = "rc/qa" }
    np = { project_id = "REPLACE_ME-np", branch = "rc/np" }
    pd = { project_id = "REPLACE_ME-pd", branch = "main" }
  }
}
