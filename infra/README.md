# IaC layout

Two independent Terraform stacks, one directory per environment:

```
infra/
├── devops/                      # devops-owned resources
│   ├── bootstrap/               # one-time: creates the state buckets
│   ├── modules/devops/          # Cloud Build triggers + Cloud Build log bucket
│   └── envs/{dv,qa,np,pd}/      # one stack per env, state in gs://<project>-tfstate-devops
└── app/                         # application-owned resources
    ├── modules/app/             # Cloud Run (FastAPI), Artifact Registry, service accounts
    └── envs/{dv,qa,np,pd}/      # one stack per env, state in gs://<project>-tfstate-app
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
terraform apply    # creates the 8 state buckets
```

## Applying an environment

```bash
# 1. app stack
cd infra/app/envs/dv && terraform init && terraform apply

# 2. devops stack (same env)
cd infra/devops/envs/dv && terraform init && terraform apply
```

Repeat per environment. The GitHub repository must be connected to each project
via the Cloud Build GitHub App (console → Cloud Build → Triggers → Connect).
