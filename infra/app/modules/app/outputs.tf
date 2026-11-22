output "app" {
  description = "App resources consumed by the devops stack (triggers)"
  value = {
    repo       = google_artifact_registry_repository.app.repository_id
    service    = google_cloud_run_v2_service.app.name
    build_sa   = google_service_account.build.email
    runtime_sa = google_service_account.runtime.email
  }
}

output "cloud_run_url" {
  description = "Public URL of the environment service"
  value       = google_cloud_run_v2_service.app.uri
}

output "artifact_registry_url" {
  description = "Artifact Registry repository URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app.repository_id}"
}
