terraform {
  backend "gcs" {
    bucket = "aminesedki-rf-pd-tfstate-devops"
    prefix = "devops"
  }
}
