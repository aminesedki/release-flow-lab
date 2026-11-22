# Changelog

## [1.2.1] - 2026-11-22

### Fixed

- fix(app): include deployed version in greeting response

### Changed

- test(app): cover greeting endpoint
## [1.2.0] - 2026-11-22

### Added

- feat(app): add greeting endpoint
- feat(ci): tag release images with their version
- feat(ci): tag release images with their version
- feat(ci): tag release images with their version
- feat(ci): github deployments per env driven by cloud build checks
- feat(ci): github deployments per env driven by cloud build checks
- feat(ci): github deployments per env driven by cloud build checks
- feat(ci): show build logs as a commit check via include_build_logs
- feat(ci): show build logs as a commit check via include_build_logs
- feat(ci): show build logs as a commit check via include_build_logs
- feat(ci): cloud build posts commit status with duration and console link
- feat(ci): cloud build posts commit status with duration and console link
- feat(ci): cloud build posts commit status with duration and console link

### Fixed

- fix(infra): prod deploys tagged releases only
- fix(infra): prod deploys tagged releases only
- fix(infra): prod deploys tagged releases only
- fix(infra): prod deploys tagged releases only (no pd branch trigger)
- fix(ci): read deploy urls from vars context
- fix(ci): read deploy urls from vars context
- fix(ci): read deploy urls from vars context
- fix(ci): json payload for deployment creation
- fix(ci): skip required contexts on deployment creation
- fix(ci): typed json and empty handling in deployments workflow
- fix(ci): typed json and empty handling in deployments workflow
- fix(ci): typed json and empty handling in deployments workflow
- fix(ci): strip ansi codes from build logs
- fix(ci): strip ansi codes from build logs
- fix(ci): strip ansi codes from docker build output
- fix(ci): force uv no color in image build
- fix(ci): disable ANSI colors in build logs (NO_COLOR)
- fix(ci): pass token and ids to status steps
- fix(ci): python image for reporting steps
- fix(ci): pin ubuntu 22.04 for reporting steps
- fix(ci): ubuntu image for status steps, marker-based outcome
- fix(ci): sync cloud build pipeline files from rc/dv
- fix(ci): sync cloud build pipeline files from rc/dv
- fix(ci): set APP_VERSION env on cloud run deploy
- fix(ci): expose built-in substitutions to build steps
- fix(ci): dedicated logs buckets for cloud build
- fix(ci): use regional user-owned logs bucket
- fix(ci): move cloud build logic into scripts to avoid substitution parsing
- fix(ci): drop invalid logging option in cloudbuild config

### Changed

- chore(ci): remove obsolete deploy-status workflow
- refactor(infra): standard root layout, per-env app states, single devops state
- refactor(infra): standard root layout, per-env app states, single devops state
- refactor(infra): standard root layout, per-env app states, single devops state
- chore(ci): verify single-state devops
- refactor(infra): split iac into devops and app stacks with per-env gcs backends
- refactor(infra): split iac into devops and app stacks with per-env gcs backends
- refactor(infra): split iac into devops and app stacks with per-env gcs backends
- chore(ci): restructure iac into devops and app stacks
- chore(ci): full dv pipeline test
- chore(ci): retrigger dv build
- chore(ci): note applied infra in release docs
## [1.1.0] - 2026-11-22

### Added

- feat(ci): tag release images with their version
- feat(ci): github deployments per env driven by cloud build checks

### Fixed

- fix(app): report service identity in health endpoint
- fix(ci): read deploy urls from vars context
- fix(ci): handle missing deployment in finish job
- fix(ci): typed json for deployment auto_merge

### Changed

- test(app): match new health response contract
## [1.0.0] - 2026-11-22

### Added

- feat(ci): show build logs as a commit check via include_build_logs
- feat(ci): cloud build posts commit status with duration and console link
- feat(release): rc branch flow with ci rules, changelog and release script
- feat(infra): gcp cloud run + cloud build iac for dv/qa/np/pd projects

### Fixed

- fix(release): regenerate uv.lock on version bump
- fix(ci): strip ansi codes from build logs
- fix(ci): sync cloud build pipeline files from rc/dv

### Changed

- refactor(infra): standard root layout, per-env app states, single devops state
- refactor(infra): split iac into devops and app stacks with per-env gcs backends
- chore: initial FastAPI app with uv and release workflows
All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project adheres to [Semantic Versioning](https://semver.org/):
`MAJOR.MINOR.PATCH`.

Release candidates are tagged `vMAJOR.MINOR.PATCH-rc.N` and final releases
`vMAJOR.MINOR.PATCH` (see [docs/RELEASE_FLOW.md](docs/RELEASE_FLOW.md)).

## [Unreleased]

### Added

- FastAPI service (`/health`, `/version`) packaged with uv and Docker
- GCP IaC: one project per environment (dv, qa, np, pd) with Cloud Run,
  Artifact Registry, Cloud Build triggers and service accounts
- Release flow: `rc/dv` → `rc/qa` → `rc/np` → `main` with branch rulesets
- Release tooling: `scripts/release.sh` (semver bump, changelog, tags)
