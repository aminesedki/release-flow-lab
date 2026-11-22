# Release flow

```
feat/*, fix/*, docs/*, chore/*, ... ─PR→ rc/dv ─PR→ rc/qa ─PR→ rc/np ─PR→ main
        (deploy dv via Cloud Build)   (qa)     (np)      (pd + tags)
```

## Branches

| Branch       | Role                                    | Deployed to | Cloud Build trigger |
|--------------|-----------------------------------------|-------------|---------------------|
| `rc/dv`      | integration of work branches            | dv          | push to `rc/dv`     |
| `rc/qa`      | promotion of dv (release candidate QA)  | qa          | push to `rc/qa`     |
| `rc/np`      | promotion of qa (pre-prod)              | np          | push to `rc/np`     |
| `main`       | production                              | pd          | push to `main` + tags `vX.Y.Z` |
| `hotfix/*`   | urgent fixes straight to main           | pd          | push to `main`      |

## Merge rules (enforced by CI + GitHub rulesets)

| Into   | Allowed from |
|--------|--------------|
| `rc/dv`| `feat/*`, `fix/*`, `docs/*`, `chore/*`, `refactor/*`, `perf/*`, `ci/*`, `test/*`, `build/*`, `dependabot/*` |
| `rc/qa`| `rc/dv` only |
| `rc/np`| `rc/qa` only |
| `main` | `rc/np` only (plus `hotfix/*`) |

- PR titles follow Conventional Commits: `feat(scope): summary`
- 1 approving review, stale review dismissal, linear history, no force push
- CI must pass (`branch-policy`, `pr-title`, `tests`)

## Versions and tags

Semver `MAJOR.MINOR.PATCH`:

- `BREAKING CHANGE` or `!` → bump MAJOR
- `feat:` → bump MINOR
- anything else (`fix:`, `docs:`, `chore:`, ...) → bump PATCH

### Releasing

From `main`, up to date and with a clean tree:

```bash
./scripts/release.sh            # computes next version from commits
./scripts/release.sh 1.2.3      # or force a version
```

The script:

1. computes the next semver from Conventional Commits since the last tag
2. updates `pyproject.toml` and `CHANGELOG.md`
3. creates annotated tag `vX.Y.Z` on `main` and pushes
4. creates the GitHub Release with the changelog section as notes

Tag push also triggers the **prod Cloud Build build** (`release-…-pd`),
so `pd` runs the exact tagged version. Prod deploys **tagged releases only**
(no deploy on plain `main` pushes).

## Hotfixes

Bypass the rc chain for urgent fixes:

1. `git switch -c hotfix/<ticket>-<desc> main`
2. commit the fix (+ test updates), push, PR `hotfix/*` -> `main`
   (the only allowed targets for `hotfix/*` are `main`)
3. after CI passes and merge: `./scripts/release.sh` — the `fix:` commits
   bump the **patch** version, tag and release to `pd`

## Rollback

Release images are pushed twice: `app:<short-sha>` and `app:<X.Y.Z>` (tag
builds). `APP_VERSION` is baked into the image, so a rollback reports the
rolled-back version.

```bash
# roll pd back to a previous release
gcloud run deploy release-flow-lab \
  --image europe-west9-docker.pkg.dev/aminesedki-rf-pd/release-flow-lab-images/app:X.Y.Z \
  --project aminesedki-rf-pd --region europe-west9

# list available versions
gcloud artifacts docker images list \
  europe-west9-docker.pkg.dev/aminesedki-rf-pd/release-flow-lab-images/app \
  --include-tags --project aminesedki-rf-pd
```

Roll forward by re-deploying the newer `app:X.Y.Z` image. Note: never
`terraform apply` the app stack to change images — Cloud Build owns them
(terraform ignores the image field).

- IaC applied: folder + 4 projects (dv/qa/np/pd), Cloud Run, Artifact Registry, Cloud Build triggers
