# Release flow

```
feat/*, fix/*, docs/*, chore/*, ... ─PR→ rc/dv ─PR→ rc/qa ─PR→ rc/np ─PR→ main
        (deploy dv via Cloud Build)   (qa)     (np)      (pd + tags)
```

## Build once, promote the image

The dv build is the only image build in the promote chain. When `rc/qa` or
`rc/np` is pushed, the Cloud Build trigger runs `cloudbuild-promote.yaml`
(`scripts/cb-promote.sh`): it reads the image **currently serving the previous
environment** and deploys that exact image, without rebuilding. Promotions
always carry the validated artifact, and every deploy ends with a smoke test
(`scripts/cb-smoke.sh`: `/health` must return `status: ok`, `/version` a
non-empty version; a failure reddens the commit check).

Production releases still rebuild from the tag source with `APP_VERSION=X.Y.Z`
baked in (same code, version metadata only).

## Monitoring

Each environment has a Cloud Monitoring uptime check on `/health` (60 s
interval, 3 regions) and an email alert for 5 minutes of failed checks.
Artifact Analysis vulnerability scanning is enabled for images pushed to the
environment registries (`containerscanning` API).

## Tooling

- `./scripts/release.sh --dry-run` — preview the computed version and changelog
  without committing or tagging.
- `./scripts/rollback.sh <dv|qa|np|pd> <X.Y.Z>` — roll an environment to a
  released image `app:X.Y.Z` and verify `/version`.
- Terraform static checks run on PRs touching `infra/**`:
  `terraform fmt -check -recursive` + `terraform validate` per stack
  (no cloud credentials in CI; applies stay human-run).

## Branches

| Branch       | Role                                    | Deployed to | Cloud Build trigger |
|--------------|-----------------------------------------|-------------|---------------------|
| `rc/dv`      | integration of work branches            | dv          | push to `rc/dv`     |
| `rc/qa`      | promotion of dv (release candidate QA)  | qa          | push to `rc/qa`     |
| `rc/np`      | promotion of qa (pre-prod)              | np          | push to `rc/np`     |
| `main`       | production release source               | pd          | tags `vX.Y.Z` only  |
| `hotfix/*`   | urgent fixes proposed directly to main  | none directly | merged to main, then released by tag |

## Merge rules (enforced by CI + GitHub rulesets)

| Into   | Allowed from |
|--------|--------------|
| `rc/dv`| `feat/*`, `fix/*`, `docs/*`, `chore/*`, `refactor/*`, `perf/*`, `ci/*`, `test/*`, `build/*`, `dependabot/*` |
| `rc/qa`| `rc/dv` only |
| `rc/np`| `rc/qa` only |
| `main` | `rc/np` only (plus `hotfix/*`) |

- PR titles follow Conventional Commits: `feat(scope): summary`
- 1 approving review, stale review dismissal, no force push
- CI must pass (`branch-policy`, `pr-title`, `tests`)

## Versions and tags

Semver `MAJOR.MINOR.PATCH`:

- `BREAKING CHANGE` or `!` → bump MAJOR
- `feat:` → bump MINOR
- anything else (`fix:`, `docs:`, `chore:`, ...) → bump PATCH

The bump considers all commits since the previous tag. If an unreleased
`feat:` is already on `main`, a hotfix release can still be a MINOR bump rather
than a PATCH bump.

### Releasing

From `main`, up to date and with a clean tree:

```bash
./scripts/release.sh            # computes next version from commits
./scripts/release.sh 1.2.3      # or force a version
```

The script:

1. computes the next semver from Conventional Commits since the last tag
2. updates `pyproject.toml`, `uv.lock` and `CHANGELOG.md`
3. creates annotated tag `vX.Y.Z` on `main` and pushes
4. creates the GitHub Release with the changelog section as notes

Tag push also triggers the **prod Cloud Build build** (`release-…-pd`),
so `pd` runs the exact tagged version. Prod deploys **tagged releases only**
(no deploy on plain `main` pushes). Create tags with `scripts/release.sh`; only
`vMAJOR.MINOR.PATCH` tags trigger production, and release tags cannot be deleted
through normal pushes.

## Hotfixes

Bypass the rc chain for urgent fixes:

1. `git switch -c hotfix/<ticket>-<desc> main`
2. commit the fix (+ test updates), push, PR `hotfix/*` -> `main`
   (the only allowed targets for `hotfix/*` are `main`)
3. after CI passes and merge: `./scripts/release.sh` — a `fix:` bumps PATCH
   when there are no unreleased `feat:` or breaking commits since the last tag;
   tag and release to `pd`

## Rollback

Release images are pushed twice: `app:<short-sha>` and `app:<X.Y.Z>` (tag
builds). `APP_VERSION` is baked into the image, so a rollback reports the
rolled-back version.

```bash
# roll pd back to a previous release
gcloud run deploy release-flow-lab \
  --image europe-west9-docker.pkg.dev/aminesedki-rf2-pd/release-flow-lab-images/app:X.Y.Z \
  --project aminesedki-rf2-pd --region europe-west9

# list available versions
gcloud artifacts docker images list \
  europe-west9-docker.pkg.dev/aminesedki-rf2-pd/release-flow-lab-images/app \
  --include-tags --project aminesedki-rf2-pd
```

Roll forward by re-deploying the newer `app:X.Y.Z` image. Never
`terraform apply` the app stack to change images — Cloud Build owns them
(terraform ignores the image field).
