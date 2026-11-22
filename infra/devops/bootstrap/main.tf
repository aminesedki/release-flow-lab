# One-time bootstrap (local state):
#  - the dedicated devops project (states, registry management, Cloud Build)
#  - the central state bucket in it
# The legacy per-env buckets stay as backups of the migrated states.
resource "google_project" "devops" {
  name            = "${var.app_name}-devops"
  project_id      = var.devops_project_id
  billing_account = var.billing_account
  org_id          = var.org_id
  deletion_policy = "ABANDON"
}

resource "google_storage_bucket" "tfstate" {
  name     = "${var.devops_project_id}-tfstate"
  project  = google_project.devops.project_id
  location = var.region

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }
}
