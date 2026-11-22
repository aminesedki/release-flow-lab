module "app" {
  source = "../../modules/app"

  project_id = "aminesedki-rf-qa"
  region     = "europe-west9"
  env        = "qa"
}

output "app" {
  value = module.app.app
}

output "cloud_run_url" {
  value = module.app.cloud_run_url
}
