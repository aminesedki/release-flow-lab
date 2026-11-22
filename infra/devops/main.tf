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

  # public host of each environment service (for uptime checks)
  run_hosts = {
    for env, state in data.terraform_remote_state.app :
    env => regex("https://([^/]+)", state.outputs.cloud_run_urls[env])[0]
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

# automatic vulnerability scanning of every pushed image
resource "google_project_service" "env_scanning_api" {
  for_each = var.envs

  project            = each.value.project_id
  service            = "containerscanning.googleapis.com"
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

# Promoting builds read the image currently serving the source environment
resource "google_project_iam_member" "build_source_viewer" {
  for_each = { for env, e in var.envs : env => e if e.promote_from != null }

  project = var.envs[each.value.promote_from].project_id
  role    = "roles/run.viewer"
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

data "google_project" "envs" {
  for_each = var.envs

  project_id = each.value.project_id
}

# Cross-project image deploy: the Cloud Run service agent of the target env
# pulls the image from the source env registry (see run docs "other projects")
resource "google_artifact_registry_repository_iam_member" "promote_service_agent_reader" {
  for_each = { for env, e in var.envs : env => e if e.promote_from != null }

  project    = var.envs[each.value.promote_from].project_id
  location   = var.region
  repository = google_artifact_registry_repository.app[each.value.promote_from].repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:service-${data.google_project.envs[each.key].number}@serverless-robot-prod.iam.gserviceaccount.com"
}

# The service's runtime SA also pulls the image on container start
resource "google_artifact_registry_repository_iam_member" "promote_runtime_reader" {
  for_each = { for env, e in var.envs : env => e if e.promote_from != null }

  project    = var.envs[each.value.promote_from].project_id
  location   = var.region
  repository = google_artifact_registry_repository.app[each.value.promote_from].repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${local.app[each.key].runtime_sa}"
}

# Promoting builds pull the image from the source environment's registry
resource "google_artifact_registry_repository_iam_member" "promote_source_reader" {
  for_each = { for env, e in var.envs : env => e if e.promote_from != null }

  project    = var.envs[each.value.promote_from].project_id
  location   = var.region
  repository = google_artifact_registry_repository.app[each.value.promote_from].repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.build[each.key].email}"
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

  # dv builds the image; qa/np promote the image validated by the previous env
  filename = each.value.promote_from == null ? "cloudbuild.yaml" : "cloudbuild-promote.yaml"

  # the build output shows on the commit check (logs + console link)
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  substitutions = merge(
    {
      _ENV           = each.key
      _SERVICE       = local.app[each.key].service
      _PROJECT       = each.value.project_id
      _REGION        = var.region
      _REGISTRY_HOST = "${var.region}-docker.pkg.dev/${each.value.project_id}"
      _REPO          = google_artifact_registry_repository.app[each.key].repository_id
      _RUNTIME_SA    = local.app[each.key].runtime_sa
      _LOGS_BUCKET   = google_storage_bucket.cb_logs.url
    },
    each.value.promote_from == null ? {} : {
      _SOURCE_ENV     = each.value.promote_from
      _SOURCE_PROJECT = var.envs[each.value.promote_from].project_id
    }
  )

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

# ------------------------------------------------------------------
# Monitoring: uptime check + alert per environment
# ------------------------------------------------------------------
resource "google_project_service" "env_monitoring_api" {
  for_each = var.envs

  project            = each.value.project_id
  service            = "monitoring.googleapis.com"
  disable_on_destroy = false
}

resource "google_monitoring_notification_channel" "email" {
  for_each = var.envs

  project      = each.value.project_id
  display_name = "Release flow on-call email (${each.key})"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_uptime_check_config" "env" {
  for_each = var.envs

  project      = each.value.project_id
  display_name = "release-flow-lab-${each.key}"
  period       = "60s"
  timeout      = "10s"

  http_check {
    path         = "/health"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      host       = local.run_hosts[each.key]
      project_id = each.value.project_id
    }
  }

  selected_regions = ["EUROPE", "USA", "ASIA_PACIFIC"]

  depends_on = [google_project_service.env_monitoring_api]
}

resource "google_monitoring_alert_policy" "env_uptime" {
  for_each = var.envs

  project      = each.value.project_id
  display_name = "release-flow-lab ${each.key}: service down"
  combiner     = "OR"

  conditions {
    display_name = "Uptime check failing for 5 minutes"
    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/v3/uptime_check_metrics/check_passed\" AND resource.type=\"uptime_url\""
      comparison      = "COMPARISON_LT"
      threshold_value = 0.99
      duration        = "300s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email[each.key].id]
  documentation {
    content   = "The /health endpoint of release-flow-lab (${each.key}) is failing. Check the Cloud Run service: https://console.cloud.google.com/run/detail/europe-west9/release-flow-lab?project=${each.value.project_id}"
    mime_type = "text/markdown"
  }

  depends_on = [google_project_service.env_monitoring_api]
}
