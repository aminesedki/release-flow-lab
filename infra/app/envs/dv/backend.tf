terraform {
  backend "gcs" {
    bucket = "aminesedki-rf-dv-tfstate-app"
    prefix = "app"
  }
}
