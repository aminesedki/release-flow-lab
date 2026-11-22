provider "google" {
  region = var.region
}

# ------------------------------------------------------------------
# Folder + projects
# ------------------------------------------------------------------
resource "google_folder" "envs" {
  count        = var.org_id == null ? 0 : 1
  display_name = var.folder_display_name
  parent       = "organizations/${var.org_id}"
}

resource "google_project" "env" {
  for_each = var.envs

  name            = "${var.app_name}-${each.key}"
  project_id      = each.value.project_id
  billing_account = var.billing_account
  folder_id       = var.org_id == null ? null : google_folder.envs[0].id
  deletion_policy = var.project_deletion_policy
}

# ------------------------------------------------------------------
# One module instance (one dedicated GCP project) per environment
# ------------------------------------------------------------------
module "env" {
  source   = "./modules/env"
  for_each = var.envs

  project_id = google_project.env[each.key].project_id
  env        = each.key
  branch     = each.value.branch

  region       = var.region
  app_name     = var.app_name
  github_owner = var.github_owner
  github_repo  = var.github_repo
  watch_tags   = each.key == "pd"
}
