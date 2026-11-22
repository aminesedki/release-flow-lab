output "cloud_run_urls" {
  description = "Public URL of each environment service"
  value       = { for env, m in module.env : env => m.cloud_run_url }
}

output "artifact_registry_urls" {
  description = "Artifact Registry repository URL per environment"
  value       = { for env, m in module.env : env => m.artifact_registry_url }
}

output "build_sas" {
  description = "Cloud Build deployer service account per environment"
  value       = { for env, m in module.env : env => m.build_sa_email }
}
