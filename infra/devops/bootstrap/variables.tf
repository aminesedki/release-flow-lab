variable "envs" {
  description = "Environment -> GCP project ID. One state bucket per stack (devops/app) is created in each project."
  type        = map(string)
}

variable "region" {
  description = "Region for the state buckets"
  type        = string
  default     = "europe-west9"
}
