# ------------------------------------------------------------------
# APIs needed by the application stack (one set per environment)
# ------------------------------------------------------------------
resource "google_project_service" "run_api" {
  for_each = local.envs

  project            = each.value.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam_api" {
  for_each = local.envs

  project            = each.value.project_id
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

# ------------------------------------------------------------------
# Service accounts
# ------------------------------------------------------------------
resource "google_service_account" "runtime" {
  for_each = local.envs

  project      = each.value.project_id
  account_id   = "rt-${var.app_name}"
  display_name = "${var.app_name} runtime (${each.key})"
}

# ------------------------------------------------------------------
# Cloud Run service (FastAPI app, port 8000, public)
# ------------------------------------------------------------------
resource "google_cloud_run_v2_service" "app" {
  for_each = local.envs

  name                = var.app_name
  location            = var.region
  project             = each.value.project_id
  deletion_protection = false

  template {
    service_account = google_service_account.runtime[each.key].email

    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello:latest" # replaced by the first Cloud Build deploy

      ports {
        container_port = 8000
      }

      # APP_VERSION is baked into the image (ARG APP_VERSION) — do not
      # override it here, or rollbacks would report the wrong version.
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
  }

  # the image is managed by Cloud Build deploys — never reset it to the
  # bootstrap image on terraform applies
  lifecycle {
    ignore_changes = [template[0].containers[0].image]
  }

  depends_on = [google_project_service.run_api]
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  for_each = local.envs

  name     = google_cloud_run_v2_service.app[each.key].name
  location = var.region
  project  = each.value.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}
