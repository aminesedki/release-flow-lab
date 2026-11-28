devops_project_id = "aminesedki-rf2-devops"

envs = {
  dv = {
    project_id   = "aminesedki-rf2-dv"
    branch       = "rc/dv"
    watch_tags   = false
    watch_branch = true
  }
  qa = {
    project_id   = "aminesedki-rf2-qa"
    branch       = "rc/qa"
    watch_tags   = false
    watch_branch = true
    promote_from = "dv"
  }
  np = {
    project_id   = "aminesedki-rf2-np"
    branch       = "rc/np"
    watch_tags   = false
    watch_branch = true
    promote_from = "qa"
  }
}
# pd (aminesedki-rf2-pd) re-added here once its billing link is restored:
#   pd = { project_id = "aminesedki-rf2-pd", branch = "main",
#          watch_tags = true, watch_branch = false }
