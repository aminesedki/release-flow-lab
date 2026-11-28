# IaC layout

Dedicated **devops project** (`aminesedki-rf2-devops`) owns everything platform-related:
Terraform states, Cloud Build triggers, build service accounts, the Cloud Build log
bucket, and it manages the per-env Artifact Registry repositories. The four
environment projects (`aminesedki-rf2-dv/qa/np/pd`) only run the app: Cloud Run
service + runtime service account.

```
infra/
├── devops/                      # ONE stack in the devops project, all envs
│   ├── provider.tf              # backend: gs://aminesedki-rf2-devops-tfstate (prefix devops)
│   ├── main.tf                  # triggers, build SAs, cross-project IAM, log bucket, registries
│   ├── terraform.tfvars         # the 4 envs (project, branch, watch_tags, watch_branch)
│   └── bootstrap/               # one-time: devops project + central tfstate bucket (local state)
└── app/                         # per-env stacks in the env projects
    ├── provider.tf / variables.tf / main.tf / outputs.tf
    └── envs/{dv,qa,np,pd}/      # terraform.tfvars + backend.tf (prefix app/<env>)
```

| Stack   | Scope | State |
|---------|-------|-------|
| `app`   | Cloud Run APIs, runtime SA, Cloud Run service (per env project) | `gs://aminesedki-rf2-devops-tfstate/app/<env>` |
| `devops`| Cloud Build API + triggers (devops project), build SAs, log bucket, Artifact Registry repos (env projects), cross-project IAM | `gs://aminesedki-rf2-devops-tfstate/devops` |

## First-time setup (bootstrap, local state)

```bash
cd infra/devops/bootstrap
terraform init
terraform apply -var=devops_project_id=aminesedki-rf2-devops \
  -var=billing_account=XXXXXX-XXXXXX-XXXXXX -var=org_id=ORG_DIGITS
```

## Applying

```bash
# app stack, per environment
cd infra/app
terraform init -reconfigure -backend-config=envs/dv/backend.tf
terraform apply -var-file=envs/dv/terraform.tfvars

# devops stack: one apply for all four environments
cd ../devops
terraform init -reconfigure
terraform apply -var-file=terraform.tfvars
```

The devops stack reads the app stack outputs via terraform_remote_state — apply
the app stack of an env before the devops stack.

The GitHub repository must be connected to the devops project with the Cloud
Build GitHub App (console > Cloud Build > Triggers > Connect, project
aminesedki-rf2-devops). Build logs: `gs://cloudbuild-logs-aminesedki-rf2-devops`.
Legacy per-env buckets (`*-tfstate-app`, `*-tfstate-devops`, `*-build-logs`)
are kept as archives of the states and logs that migrated to the devops
project.
