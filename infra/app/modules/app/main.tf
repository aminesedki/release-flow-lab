# ------------------------------------------------------------------
# APIs needed by the application stack
# ------------------------------------------------------------------
resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# ------------------------------------------------------------------
# Artifact Registry
# ------------------------------------------------------------------
resource "google_artifact_registry_repository" "app" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.app_name}-images"
  format        = "DOCKER"
  description   = "Docker images for ${var.app_name} (${var.env})"

  depends_on = [google_project_service.apis]
}

# ------------------------------------------------------------------
# Service accounts
# ------------------------------------------------------------------
resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = "rt-${var.app_name}"
  display_name = "${var.app_name} runtime (${var.env})"
}

resource "google_service_account" "build" {
  project      = var.project_id
  account_id   = "cb-${var.app_name}"
  display_name = "${var.app_name} build/deploy service account (${var.env})"
}

resource "google_project_iam_member" "build_roles" {
  for_each = toset([
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.writer",
    "roles/logging.logWriter",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.build.email}"
}

# ------------------------------------------------------------------
# Cloud Run service (FastAPI app, port 8000, public)
# ------------------------------------------------------------------
resource "google_cloud_run_v2_service" "app" {
  name                = var.app_name
  location            = var.region
  project             = var.project_id
  deletion_protection = false

  template {
    service_account = google_service_account.runtime.email

    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello:latest" # replaced by the first Cloud Build deploy

      ports {
        container_port = 8000
      }

      env {
        name  = "APP_VERSION"
        value = "bootstrap"
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  name     = google_cloud_run_v2_service.app.name
  location = var.region
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}
