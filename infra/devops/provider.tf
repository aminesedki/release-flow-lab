terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # devops is a single state managing all four environments
  backend "gcs" {
    bucket = "aminesedki-rf-devops-tfstate"
    prefix = "devops"
  }
}

provider "google" {
  region = var.region
}
