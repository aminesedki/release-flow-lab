# App resources (repo, service name, service accounts) come from the app
# stack remote state of the same environment.
data "terraform_remote_state" "app" {
  for_each = var.envs

  backend = "gcs"
  config = {
    bucket = "${each.value.project_id}-tfstate-app"
    prefix = "app"
  }
}

locals {
  app = {
    for env, state in data.terraform_remote_state.app : env => state.outputs.app[env]
  }
}

# ------------------------------------------------------------------
# Cloud Build API
# ------------------------------------------------------------------
resource "google_project_service" "cloudbuild" {
  for_each = var.envs

  project            = each.value.project_id
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

# ------------------------------------------------------------------
# Cloud Build log bucket (one per environment, owned by the devops stack)
# ------------------------------------------------------------------
resource "google_storage_bucket" "cb_logs" {
  for_each = var.envs

  name          = "${each.value.project_id}-build-logs"
  project       = each.value.project_id
  location      = var.region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

# Cloud Build requires bucket-level admin for the build service account
resource "google_storage_bucket_iam_member" "cb_logs" {
  for_each = var.envs

  bucket = google_storage_bucket.cb_logs[each.key].name
  role   = "roles/storage.admin"
  member = "serviceAccount:${local.app[each.key].build_sa}"
}

# ------------------------------------------------------------------
# Cloud Build trigger: deploy on push to the environment branch
# ------------------------------------------------------------------
resource "google_cloudbuild_trigger" "branch" {
  for_each = var.envs

  project         = each.value.project_id
  name            = "deploy-${var.app_name}-${each.key}"
  location        = var.region
  service_account = "projects/${each.value.project_id}/serviceAccounts/${local.app[each.key].build_sa}"

  github {
    owner = var.github_owner
    name  = var.github_repo

    push {
      branch = "^${each.value.branch}$"
    }
  }

  filename = "cloudbuild.yaml"

  substitutions = {
    _ENV         = each.key
    _SERVICE     = local.app[each.key].service
    _REGION      = var.region
    _REPO        = local.app[each.key].repo
    _RUNTIME_SA  = local.app[each.key].runtime_sa
    _LOGS_BUCKET = google_storage_bucket.cb_logs[each.key].url
  }

  depends_on = [google_project_service.cloudbuild]
}

# Optional second trigger: deploy tagged releases (vX.Y.Z) to this environment
resource "google_cloudbuild_trigger" "tags" {
  for_each = { for env, e in var.envs : env => e if e.watch_tags }

  project         = each.value.project_id
  name            = "release-${var.app_name}-${each.key}"
  location        = var.region
  service_account = "projects/${each.value.project_id}/serviceAccounts/${local.app[each.key].build_sa}"

  github {
    owner = var.github_owner
    name  = var.github_repo

    push {
      tag = "^v[0-9]+\\.[0-9]+\\.[0-9]+$"
    }
  }

  filename = "cloudbuild.yaml"

  substitutions = {
    _ENV         = each.key
    _SERVICE     = local.app[each.key].service
    _REGION      = var.region
    _REPO        = local.app[each.key].repo
    _RUNTIME_SA  = local.app[each.key].runtime_sa
    _LOGS_BUCKET = google_storage_bucket.cb_logs[each.key].url
  }

  depends_on = [google_project_service.cloudbuild]
}
