module "app" {
  source = "../../modules/app"

  project_id = "aminesedki-rf2-dv"
  region     = "europe-west9"
  env        = "dv"
}

output "app" {
  value = module.app.app
}

output "cloud_run_url" {
  value = module.app.cloud_run_url
}
