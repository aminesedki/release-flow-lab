terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # backend is configured per environment at init time:
  #   terraform init -backend-config=envs/<env>/backend.tf
  backend "gcs" {}
}

provider "google" {
  region = var.region
}
