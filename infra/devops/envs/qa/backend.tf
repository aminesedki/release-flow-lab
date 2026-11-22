terraform {
  backend "gcs" {
    bucket = "aminesedki-rf-qa-tfstate-devops"
    prefix = "devops"
  }
}
