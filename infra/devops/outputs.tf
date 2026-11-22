output "registry_urls" {
  description = "Artifact Registry repository URL per environment"
  value = {
    for env, repo in google_artifact_registry_repository.app :
    env => "${var.region}-docker.pkg.dev/${repo.project}/${repo.repository_id}"
  }
}

output "log_bucket" {
  description = "Cloud Build log bucket URL (devops project)"
  value       = google_storage_bucket.cb_logs.url
}

output "branch_triggers" {
  description = "Branch deploy trigger name per environment"
  value       = { for env, t in google_cloudbuild_trigger.branch : env => t.name }
}

output "tag_triggers" {
  description = "Tag release trigger name per environment (only where watch_tags is true)"
  value       = { for env, t in google_cloudbuild_trigger.tags : env => t.name }
}

output "build_sas" {
  description = "Build service account email per environment (in the devops project)"
  value       = { for env, sa in google_service_account.build : env => sa.email }
}
