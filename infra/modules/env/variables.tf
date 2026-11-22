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

variable "branch" {
  description = "Git branch whose push triggers a Cloud Build deploy to this environment"
  type        = string
}

variable "github_owner" {
  description = "GitHub owner of the repository"
  type        = string
  default     = "aminesedki"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "release-flow-lab"
}

variable "watch_tags" {
  description = "Also trigger a Cloud Build deploy on semver tags vMAJOR.MINOR.PATCH (used for pd releases)"
  type        = bool
  default     = false
}
