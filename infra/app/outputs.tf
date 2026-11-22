output "app" {
  description = "App resources consumed by the devops stack (triggers), keyed by environment"
  value = {
    for env, svc in google_cloud_run_v2_service.app : env => {
      repo       = google_artifact_registry_repository.app[env].repository_id
      service    = svc.name
      build_sa   = google_service_account.build[env].email
      runtime_sa = google_service_account.runtime[env].email
    }
  }
}

output "cloud_run_urls" {
  description = "Public URL of each environment service"
  value       = { for env, svc in google_cloud_run_v2_service.app : env => svc.uri }
}

output "artifact_registry_urls" {
  description = "Artifact Registry repository URL per environment"
  value       = { for env, repo in google_artifact_registry_repository.app : env => "${var.region}-docker.pkg.dev/${repo.project}/${repo.repository_id}" }
}
