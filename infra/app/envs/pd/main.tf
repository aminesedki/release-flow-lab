module "app" {
  source = "../../modules/app"

  project_id = "aminesedki-rf-pd"
  region     = "europe-west9"
  env        = "pd"
}

output "app" {
  value = module.app.app
}

output "cloud_run_url" {
  value = module.app.cloud_run_url
}
