terraform {
  backend "gcs" {
    bucket = "aminesedki-rf-qa-tfstate-app"
    prefix = "app"
  }
}
