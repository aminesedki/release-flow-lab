terraform {
  backend "gcs" {
    bucket = "aminesedki-rf-np-tfstate-app"
    prefix = "app"
  }
}
