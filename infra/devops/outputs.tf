output "log_buckets" {
  description = "Cloud Build log bucket URL per environment"
  value       = { for env, b in google_storage_bucket.cb_logs : env => b.url }
}

output "branch_triggers" {
  description = "Branch deploy trigger name per environment"
  value       = { for env, t in google_cloudbuild_trigger.branch : env => t.name }
}

output "tag_triggers" {
  description = "Tag release trigger name per environment (only where watch_tags is true)"
  value       = { for env, t in google_cloudbuild_trigger.tags : env => t.name }
}
