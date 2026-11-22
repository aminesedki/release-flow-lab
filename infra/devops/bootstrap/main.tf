# One-time bootstrap: creates the Terraform state buckets, one per stack and
# per environment. Runs with a LOCAL state (this stack is applied once and its
# state is not needed afterwards).
resource "google_storage_bucket" "tfstate" {
  for_each = {
    for pair in flatten([
      for env, project_id in var.envs : [
        { env = env, stack = "devops", project_id = project_id },
        { env = env, stack = "app", project_id = project_id },
      ]
    ]) : "${pair.env}-${pair.stack}" => pair
  }

  name          = "${each.value.project_id}-tfstate-${each.value.stack}"
  project       = each.value.project_id
  location      = var.region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }
}
