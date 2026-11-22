output "app" {
  description = "App resources consumed by the devops stack (triggers), keyed by environment"
  value = {
    for env, svc in google_cloud_run_v2_service.app : env => {
      service    = svc.name
      runtime_sa = google_service_account.runtime[env].email
    }
  }
}

output "cloud_run_urls" {
  description = "Public URL of each environment service"
  value       = { for env, svc in google_cloud_run_v2_service.app : env => svc.uri }
}
