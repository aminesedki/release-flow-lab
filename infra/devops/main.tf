# ------------------------------------------------------------------
# Environments and app outputs (remote state, central bucket)
# ------------------------------------------------------------------
data "terraform_remote_state" "app" {
  for_each = var.envs

  backend = "gcs"
  config = {
    bucket = "${var.devops_project_id}-tfstate"
    prefix = "app/${each.key}"
  }
}

locals {
  app = {
    for env, state in data.terraform_remote_state.app : env => state.outputs.app[env]
  }
}

# ------------------------------------------------------------------
# APIs (devops project + artifactregistry in the env projects)
# ------------------------------------------------------------------
resource "google_project_service" "devops_apis" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
  ])

  project            = var.devops_project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_project_service" "env_ar_api" {
  for_each = var.envs

  project            = each.value.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# ------------------------------------------------------------------
# Artifact Registry: one repo per env project, managed from devops
# ------------------------------------------------------------------
resource "google_artifact_registry_repository" "app" {
  for_each = var.envs

  project       = each.value.project_id
  location      = var.region
  repository_id = "${var.app_name}-images"
  format        = "DOCKER"
  description   = "Docker images for ${var.app_name} (${each.key})"

  depends_on = [google_project_service.env_ar_api]
}

# ------------------------------------------------------------------
# Cloud Build log bucket (devops project)
# ------------------------------------------------------------------
resource "google_storage_bucket" "cb_logs" {
  name          = "cloudbuild-logs-${var.devops_project_id}"
  project       = var.devops_project_id
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

  depends_on = [google_project_service.devops_apis]
}

# ------------------------------------------------------------------
# Build service accounts (devops project, one per env)
# ------------------------------------------------------------------
resource "google_service_account" "build" {
  for_each = var.envs

  project      = var.devops_project_id
  account_id   = "cb-${var.app_name}-${each.key}"
  display_name = "${var.app_name} build/deploy (${each.key})"
}

# Cloud Build writes the build logs to the dedicated bucket
resource "google_storage_bucket_iam_member" "cb_logs" {
  for_each = var.envs

  bucket = google_storage_bucket.cb_logs.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.build[each.key].email}"
}

# Cloud Build itself logs build metadata in its own project
resource "google_project_iam_member" "build_logwriter" {
  for_each = var.envs

  project = var.devops_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.build[each.key].email}"
}

# Deploys into the env project: manage the env Cloud Run service (run.admin
# covers run.deploy, revisions, IAM policy of the service)
resource "google_project_iam_member" "build_run_admin" {
  for_each = var.envs

  project = each.value.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.build[each.key].email}"
}

# gcloud calls of the build are billed to the env project
resource "google_project_iam_member" "build_quota" {
  for_each = var.envs

  project = each.value.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${google_service_account.build[each.key].email}"
}

# Pushes images to the env registry
resource "google_artifact_registry_repository_iam_member" "build_writer" {
  for_each = var.envs

  project    = each.value.project_id
  location   = var.region
  repository = google_artifact_registry_repository.app[each.key].repository_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.build[each.key].email}"
}

# A rollout runs the revision as the env runtime SA
resource "google_service_account_iam_member" "build_actas_runtime" {
  for_each = var.envs

  service_account_id = "projects/${each.value.project_id}/serviceAccounts/${local.app[each.key].runtime_sa}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.build[each.key].email}"
}

# The env runtime SA pulls images from its registry
resource "google_artifact_registry_repository_iam_member" "runtime_reader" {
  for_each = var.envs

  project    = each.value.project_id
  location   = var.region
  repository = google_artifact_registry_repository.app[each.key].repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${local.app[each.key].runtime_sa}"
}

# ------------------------------------------------------------------
# Cloud Build triggers (devops project, one per env branch + tags for pd)
# ------------------------------------------------------------------
resource "google_cloudbuild_trigger" "branch" {
  # pd (prod) deploys tagged releases only: watch_branch = false there
  for_each = { for env, e in var.envs : env => e if e.watch_branch }

  project         = var.devops_project_id
  name            = "deploy-${var.app_name}-${each.key}"
  description     = "Deploys ${var.app_name} to ${each.key} on each push to ${each.value.branch}"
  location        = var.region
  service_account = google_service_account.build[each.key].id

  github {
    owner = var.github_owner
    name  = var.github_repo

    push {
      branch = "^${each.value.branch}$"
    }
  }

  filename = "cloudbuild.yaml"

  # the build output shows on the commit check (logs + console link)
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  substitutions = {
    _ENV           = each.key
    _SERVICE       = local.app[each.key].service
    _PROJECT       = each.value.project_id
    _REGION        = var.region
    _REGISTRY_HOST = "${var.region}-docker.pkg.dev/${each.value.project_id}"
    _REPO          = google_artifact_registry_repository.app[each.key].repository_id
    _RUNTIME_SA    = local.app[each.key].runtime_sa
    _LOGS_BUCKET   = google_storage_bucket.cb_logs.url
  }

  tags = ["cd", each.key]

  depends_on = [google_project_service.devops_apis]
}

# Optional second trigger: deploy tagged releases (vX.Y.Z) to this environment
resource "google_cloudbuild_trigger" "tags" {
  for_each = { for env, e in var.envs : env => e if e.watch_tags }

  project         = var.devops_project_id
  name            = "release-${var.app_name}-${each.key}"
  description     = "Releases ${var.app_name} to ${each.key} on each semver tag"
  location        = var.region
  service_account = google_service_account.build[each.key].id

  github {
    owner = var.github_owner
    name  = var.github_repo

    push {
      tag = "^v[0-9]+\\.[0-9]+\\.[0-9]+$"
    }
  }

  filename = "cloudbuild.yaml"

  # the build output shows on the commit check (logs + console link)
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  substitutions = {
    _ENV           = each.key
    _SERVICE       = local.app[each.key].service
    _PROJECT       = each.value.project_id
    _REGION        = var.region
    _REGISTRY_HOST = "${var.region}-docker.pkg.dev/${each.value.project_id}"
    _REPO          = google_artifact_registry_repository.app[each.key].repository_id
    _RUNTIME_SA    = local.app[each.key].runtime_sa
    _LOGS_BUCKET   = google_storage_bucket.cb_logs.url
  }

  tags = ["release", each.key]

  depends_on = [google_project_service.devops_apis]
}
