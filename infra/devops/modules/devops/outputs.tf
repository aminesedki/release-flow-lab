output "log_bucket" {
  description = "Cloud Build log bucket URL"
  value       = google_storage_bucket.cb_logs.url
}

output "branch_trigger" {
  description = "Branch deploy trigger name"
  value       = google_cloudbuild_trigger.branch.name
}

output "tag_trigger" {
  description = "Tag release trigger name (null when watch_tags is false)"
  value       = var.watch_tags ? google_cloudbuild_trigger.tags[0].name : null
}
