# App resources come from the app stack remote state (same environment).
data "terraform_remote_state" "app" {
  backend = "gcs"
  config = {
    bucket = "aminesedki-rf-np-tfstate-app"
    prefix = "app"
  }
}

module "devops" {
  source = "../../modules/devops"

  project_id = "aminesedki-rf-np"
  region     = "europe-west9"
  env        = "np"
  branch     = "rc/np"
  watch_tags = false

  app = data.terraform_remote_state.app.outputs.app
}

output "log_bucket" {
  value = module.devops.log_bucket
}

output "triggers" {
  value = [module.devops.branch_trigger, module.devops.tag_trigger]
}
