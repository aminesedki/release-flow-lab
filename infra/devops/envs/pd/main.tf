# App resources come from the app stack remote state (same environment).
data "terraform_remote_state" "app" {
  backend = "gcs"
  config = {
    bucket = "aminesedki-rf-pd-tfstate-app"
    prefix = "app"
  }
}

module "devops" {
  source = "../../modules/devops"

  project_id = "aminesedki-rf-pd"
  region     = "europe-west9"
  env        = "pd"
  branch     = "main"
  watch_tags = true

  app = data.terraform_remote_state.app.outputs.app
}

output "log_bucket" {
  value = module.devops.log_bucket
}

output "triggers" {
  value = [module.devops.branch_trigger, module.devops.tag_trigger]
}
