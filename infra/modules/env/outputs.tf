output "cloud_run_url" {
  description = "Public URL of the environment service"
  value       = google_cloud_run_v2_service.app.uri
}

output "artifact_registry_url" {
  description = "Artifact Registry repository URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app.repository_id}"
}

output "build_sa_email" {
  description = "Cloud Build deployer service account email"
  value       = google_service_account.build.email
}
