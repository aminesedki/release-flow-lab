# ------------------------------------------------------------------
# Cloud Build API
# ------------------------------------------------------------------
resource "google_project_service" "cloudbuild" {
  project            = var.project_id
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

# ------------------------------------------------------------------
# Cloud Build log bucket (one per environment, owned by the devops stack)
# ------------------------------------------------------------------
resource "google_storage_bucket" "cb_logs" {
  name          = "${var.project_id}-build-logs"
  project       = var.project_id
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

  depends_on = [google_project_service.cloudbuild]
}

# Cloud Build requires bucket-level admin for the build service account
resource "google_storage_bucket_iam_member" "cb_logs" {
  bucket = google_storage_bucket.cb_logs.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.app.build_sa}"
}

# ------------------------------------------------------------------
# Cloud Build trigger: deploy on push to the environment branch
# ------------------------------------------------------------------
resource "google_cloudbuild_trigger" "branch" {
  project         = var.project_id
  name            = "deploy-${var.app.service}-${var.env}"
  location        = var.region
  service_account = "projects/${var.project_id}/serviceAccounts/${var.app.build_sa}"

  github {
    owner = var.github_owner
    name  = var.github_repo

    push {
      branch = "^${var.branch}$"
    }
  }

  filename = "cloudbuild.yaml"

  substitutions = {
    _ENV         = var.env
    _SERVICE     = var.app.service
    _REGION      = var.region
    _REPO        = var.app.repo
    _RUNTIME_SA  = var.app.runtime_sa
    _LOGS_BUCKET = google_storage_bucket.cb_logs.url
  }

  depends_on = [google_project_service.cloudbuild]
}

# Optional second trigger: deploy tagged releases (vX.Y.Z) to this environment
resource "google_cloudbuild_trigger" "tags" {
  count = var.watch_tags ? 1 : 0

  project         = var.project_id
  name            = "release-${var.app.service}-${var.env}"
  location        = var.region
  service_account = "projects/${var.project_id}/serviceAccounts/${var.app.build_sa}"

  github {
    owner = var.github_owner
    name  = var.github_repo

    push {
      tag = "^v[0-9]+\\.[0-9]+\\.[0-9]+$"
    }
  }

  filename = "cloudbuild.yaml"

  substitutions = {
    _ENV         = var.env
    _SERVICE     = var.app.service
    _REGION      = var.region
    _REPO        = var.app.repo
    _RUNTIME_SA  = var.app.runtime_sa
    _LOGS_BUCKET = google_storage_bucket.cb_logs.url
  }

  depends_on = [google_project_service.cloudbuild]
}
