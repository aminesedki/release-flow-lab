# Changelog

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
