output "state_buckets" {
  description = "State bucket names per environment/stack"
  value       = { for k, b in google_storage_bucket.tfstate : k => b.name }
}
