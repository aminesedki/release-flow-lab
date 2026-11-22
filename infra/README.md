# GCP infrastructure (Terraform)

Creates **4 GCP projects** (`*-dv`, `*-qa`, `*-np`, `*-pd`, optionally grouped in
a GCP Folder) and, in each of them, the resources needed to build and run the
FastAPI app.

## Requirements

Your `gcloud` user needs:
- `roles/resourcemanager.projectCreator` on the org (or the ability to create projects)
- `roles/billing.user` on the billing account
- Owner/Editor on the projects once created (you are the creator, so you are owner by default)

## What gets created (in each project)

| Resource | Purpose |
|---|---|
| Artifact Registry `release-flow-lab-images` | Docker images |
| Cloud Run `release-flow-lab` | The FastAPI service (port 8000, public) |
| Cloud Build trigger `deploy-release-flow-lab-{env}` | Build + deploy on push to the env branch |
| Service accounts `cb-release-flow-lab` / `rt-release-flow-lab` | Build/deploy + runtime identity |
| APIs | run, cloudbuild, artifactregistry, iam |

Branch → environment mapping (edit via `envs` variable):

| Env | Project (example) | Trigger branch |
|---|---|---|
| dv  | `*-dv` | `rc/dv` |
| qa  | `*-qa` | `rc/qa` |
| np  | `*-np` | `rc/np` |
| pd  | `*-pd` | `main` |

## Usage

1. Copy the example tfvars and fill in the four project IDs:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # edit project IDs / region
   ```

2. Authenticate (Application Default Credentials are enough for Terraform):

   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

   Your user must have `roles/run.admin` (or Owner/Editor) on the four projects.

3. Run:

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

State is stored locally (`terraform.tfstate`) — it is git-ignored.

> **Note:** the triggers watch GitHub pushes (`github_owner` / `github_repo`).
> For them to fire, the **Cloud Build GitHub App** must be installed on the
> repository and connected to each GCP project
> (https://console.cloud.google.com/cloud-build/triggers → *Connect repository*
> if not already connected).
