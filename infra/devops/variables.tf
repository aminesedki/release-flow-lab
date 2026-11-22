variable "devops_project_id" {
  description = "Dedicated devops project hosting the state, triggers, build SAs and logs"
  type        = string
  default     = "aminesedki-rf-devops"
}

variable "region" {
  description = "Region for all resources"
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

variable "alert_email" {
  description = "Email address receiving the environment uptime alerts"
  type        = string
  default     = "aminesedki.dev@gmail.com"
}

variable "envs" {
  description = "Environments: one GCP project each, with the git branch that deploys to it"
  type = map(object({
    project_id   = string
    branch       = string
    watch_tags   = optional(bool, false)
    watch_branch = optional(bool, true)
    promote_from = optional(string)
  }))
}
