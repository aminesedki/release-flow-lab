# IaC layout

Two independent Terraform stacks, each applied **per environment** with its own
state backend:

```
infra/
├── devops/                          # devops-owned resources
│   ├── provider.tf                  # provider + backend "gcs" {} (configured via envs/<env>/backend.tf)
│   ├── variables.tf                 # region, app_name, github_*, envs (project_id, branch, watch_tags)
│   ├── main.tf                      # Cloud Build API, log bucket, deploy/release triggers
│   ├── outputs.tf
│   ├── bootstrap/                   # one-time: creates the tfstate buckets (local state)
│   └── envs/
│       ├── dv/{backend.tf, terraform.tfvars}
│       ├── qa/...
│       ├── np/...
│       └── pd/...
└── app/                             # application-owned resources
    ├── provider.tf
    ├── variables.tf                 # region, app_name, envs (project_id)
    ├── main.tf                      # APIs, Artifact Registry, service accounts + IAM, Cloud Run
    ├── outputs.tf
    └── envs/
        └── (same structure)
```

Per environment (`dv`, `qa`, `np`, `pd` = one dedicated GCP project each):

| Stack   | Scope | State |
|---------|-------|-------|
| `app`   | APIs (run, artifactregistry, iam), Artifact Registry, runtime + build service accounts and their IAM, Cloud Run service (port 8000, public) | `gs://<project>-tfstate-app` |
| `devops`| Cloud Build API, Cloud Build log bucket (30-day retention), deploy trigger on the env branch (+ semver tag trigger for `pd`) | `gs://<project>-tfstate-devops` |

Branch → environment: `rc/dv`→dv, `rc/qa`→qa, `rc/np`→np, `main`→pd (plus tags `vX.Y.Z` for pd).

The devops stack reads the app stack outputs (repo, service name, service accounts)
via `terraform_remote_state`, so it must be applied **after** the app stack of the
same environment.

## First-time setup (bootstrap, local state)

```bash
cd infra/devops/bootstrap
terraform init
terraform apply -var='envs={dv="aminesedki-rf-dv",qa="aminesedki-rf-qa",np="aminesedki-rf-np",pd="aminesedki-rf-pd"}'
```

## Applying an environment

```bash
# 1. app stack
cd infra/app
terraform init -reconfigure -backend-config=envs/dv/backend.tf
terraform apply -var-file=envs/dv/terraform.tfvars

# 2. devops stack (same env)
cd ../devops
terraform init -reconfigure -backend-config=envs/dv/backend.tf
terraform apply -var-file=envs/dv/terraform.tfvars
```

Switching environment = re-init with the other env's backend config.

The GitHub repository must be connected to each project via the Cloud Build
GitHub App (console → Cloud Build → Triggers → Connect).
