# Changelog

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
