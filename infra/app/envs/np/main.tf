module "app" {
  source = "../../modules/app"

  project_id = "aminesedki-rf-np"
  region     = "europe-west9"
  env        = "np"
}

output "app" {
  value = module.app.app
}

output "cloud_run_url" {
  value = module.app.cloud_run_url
}
