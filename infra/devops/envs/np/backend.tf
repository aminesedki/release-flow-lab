terraform {
  backend "gcs" {
    bucket = "aminesedki-rf-np-tfstate-devops"
    prefix = "devops"
  }
}
