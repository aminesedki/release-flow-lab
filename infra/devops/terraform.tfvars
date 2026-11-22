devops_project_id = "aminesedki-rf-devops"

envs = {
  dv = {
    project_id   = "aminesedki-rf-dv"
    branch       = "rc/dv"
    watch_tags   = false
    watch_branch = true
  }
  qa = {
    project_id   = "aminesedki-rf-qa"
    branch       = "rc/qa"
    watch_tags   = false
    watch_branch = true
    promote_from = "dv"
  }
  np = {
    project_id   = "aminesedki-rf-np"
    branch       = "rc/np"
    watch_tags   = false
    watch_branch = true
    promote_from = "qa"
  }
  pd = {
    project_id   = "aminesedki-rf-pd"
    branch       = "main"
    watch_tags   = true
    watch_branch = false
  }
}
