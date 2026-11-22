# Release Flow Lab

A small FastAPI service used to demonstrate a protected, multi-environment Git release strategy. GitHub pull requests promote changes through development, QA and pre-production; version tags deploy releases to production.

## Application

The FastAPI app exposes:

| Endpoint | Purpose |
|---|---|
| `GET /health` | Health check and service identity |
| `GET /version` | Version baked into the deployed image |
| `GET /greeting` | Example greeting endpoint |

### Run locally

Requirements: Python 3.13+ and [uv](https://docs.astral.sh/uv/).

```bash
uv sync --locked
uv run uvicorn app.main:app --reload
```

Then open `http://127.0.0.1:8000/docs` or test the endpoints:

```bash
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8000/version
curl http://127.0.0.1:8000/greeting
```

Run tests with:

```bash
uv run pytest -q
```

Build the container locally with:

```bash
docker build --build-arg APP_VERSION=local -t release-flow-lab:local .
docker run --rm -p 8000:8000 release-flow-lab:local
```

## Release flow

```text
feat/*, fix/*, docs/*, chore/*, ... -> rc/dv -> rc/qa -> rc/np -> main --tag vX.Y.Z--> pd
                                           deploy dv    deploy qa   deploy np             deploy release

hotfix/* ---------------------------------------------------------------------> main
```

| Environment | Project | Deploy source |
|---|---|---|
| `dv` | `aminesedki-rf-dv` | push to `rc/dv` |
| `qa` | `aminesedki-rf-qa` | push to `rc/qa` |
| `np` | `aminesedki-rf-np` | push to `rc/np` |
| `pd` | `aminesedki-rf-pd` | SemVer tag `vMAJOR.MINOR.PATCH` only |

Every change enters through a PR. The CI checks enforce branch direction, conventional PR titles and tests. The promotion branches only accept their predecessor (`rc/dv` to `rc/qa`, `rc/qa` to `rc/np`, `rc/np` to `main`). `hotfix/*` may target `main` for urgent fixes.

Release from a clean, up-to-date `main` branch:

```bash
./scripts/release.sh --dry-run  # preview without changing files
./scripts/release.sh          # calculate the next SemVer version
./scripts/release.sh 1.3.0    # or specify a version explicitly
```

The script updates `CHANGELOG.md`, `pyproject.toml` and `uv.lock`, creates an annotated `vX.Y.Z` tag and a GitHub Release. `feat` bumps MINOR, `fix` and maintenance changes bump PATCH, and `BREAKING CHANGE` bumps MAJOR.

For urgent production fixes, branch from `main` as `hotfix/<ticket>-<desc>`, PR into `main`, merge, then run the release script. Merge the fix back into the normal release flow afterward.

### Build and deployment visibility

Cloud Build runs in the dedicated `aminesedki-rf-devops` project. The dv trigger builds and pushes the image once; qa and np promote the image currently serving the previous environment without rebuilding it. A `vX.Y.Z` tag builds the production release image and deploys it to pd. Every deployment runs smoke checks against `/health` and `/version`.

Each build appears as a native GitHub check run with status, start/end times, build-log output and a Cloud Build console link. The GitHub Deployments page records the environment, deployment status, live service URL and build link. Release images are tagged `app:X.Y.Z` to support rollbacks.

Cloud Monitoring checks `/health` every minute from three regions and emails the configured address if an environment is down for five minutes. Artifact Analysis vulnerability scanning is enabled for pushed images.

## Infrastructure

Terraform is split into two stacks:

- `infra/devops/`: one stack managing all environments from the devops project. It owns the central Terraform state bucket, Cloud Build triggers, build service accounts, log bucket, and manages the per-environment Artifact Registry repositories and cross-project IAM.
- `infra/app/`: one app stack per environment. It owns the environment's Cloud Run service, runtime service account and required APIs. Its state uses a per-environment prefix in the central devops bucket.

See [`infra/README.md`](infra/README.md) for bootstrap, backend and apply instructions. The operational guide is [`docs/RELEASE_FLOW.md`](docs/RELEASE_FLOW.md); the printable manual is [`docs/RELEASE_HANDBOOK.pdf`](docs/RELEASE_HANDBOOK.pdf).

## Useful links

- [Changelog](CHANGELOG.md)
- [Release flow guide](docs/RELEASE_FLOW.md)
- [Release handbook PDF](docs/RELEASE_HANDBOOK.pdf)
- [Infrastructure guide](infra/README.md)
