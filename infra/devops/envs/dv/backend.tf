terraform {
  backend "gcs" {
    bucket = "aminesedki-rf-dv-tfstate-devops"
    prefix = "devops"
  }
}
