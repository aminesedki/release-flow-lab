terraform {
  backend "gcs" {
    bucket = "aminesedki-rf-pd-tfstate-app"
    prefix = "app"
  }
}
