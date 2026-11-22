#!/usr/bin/env bash
# Release tool: compute next semver from Conventional Commits, update
# CHANGELOG.md + pyproject.toml, tag vX.Y.Z on main, push, create the
# GitHub Release.
#
# Usage: ./scripts/release.sh [VERSION]
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DRY_RUN=0
if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
  shift
fi

branch=$(git rev-parse --abbrev-ref HEAD)
[[ $branch == "main" ]] || { echo "error: run this on main (current: $branch)"; exit 1; }
git fetch --tags --force --quiet
[[ -z $(git status --porcelain) ]] || { echo "error: uncommitted changes"; exit 1; }

# --- last tag + commits since ---------------------------------------------------
if last=$(git describe --abbrev=0 --match 'v[0-9]*' 2>/dev/null); then
  range="$last..HEAD"
else
  last=""
  range="HEAD"
fi
commits=$(git log --pretty=format:'%s' $range)
[[ -n $commits ]] || { echo "error: nothing to release since ${last:-beginning}"; exit 1; }

# --- compute next version ---------------------------------------------------------
breaking=$(echo "$commits" | grep -cE '^[a-z]+(\(.+\))?!:|BREAKING CHANGE' || true)
feat=$(echo "$commits" | grep -cE '^feat(\(.+\))?:' || true)

if [[ -z ${1:-} ]]; then
  if [[ -z $last ]]; then
    version="1.0.0"
  else
    prev=${last#v}
    IFS='.' read -r M m p <<< "$prev"
    if (( breaking > 0 )); then version="$((M + 1)).0.0"
    elif (( feat > 0 )); then version="$M.$((m + 1)).0"
    else version="$M.$m.$((p + 1))"
    fi
  fi
else
  version=$1
  [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "error: version must be MAJOR.MINOR.PATCH"; exit 1; }
fi

tag="v$version"
[[ -z $(git tag --list "$tag") ]] || { echo "error: tag $tag already exists"; exit 1; }
echo "Releasing $tag ($(echo "$commits" | wc -l) commits since ${last:-beginning})"

# --- changelog section ------------------------------------------------------------
today=$(date +%F)
notes_file=$(mktemp)
{
  echo "## [$version] - $today"
  section() {
    local label=$1 pattern=$2
    local lines
    if [[ $pattern == "" ]]; then
      lines=$(echo "$commits" | grep -vE '^(feat|fix)(\(.+\))?:' | grep -vE '^(Merge |rc/|hotfix/)' || true)
    else
      lines=$(echo "$commits" | grep -E "^${pattern}(\(.+\))?:" || true)
    fi
    [[ -z $lines ]] && return
    echo
    echo "### $label"
    echo
    while IFS= read -r line; do echo "- $line"; done <<< "$lines"
  }
  section "Added"   "feat"
  section "Fixed"   "fix"
  section "Changed" ""
} > "$notes_file"

# --- update files -------------------------------------------------------------------
sed -i "s/^version = \".*\"/version = \"$version\"/" pyproject.toml

# keep uv.lock in sync with the new pyproject version (--locked builds fail otherwise)
if command -v uv >/dev/null 2>&1; then
  uv lock
elif python3 -m uv --version >/dev/null 2>&1; then
  python3 -m uv lock
else
  echo "error: uv is required to update uv.lock"; exit 1
fi

changelog=$(mktemp)
{
  echo "# Changelog"
  echo
  cat "$notes_file"
  if [[ -f CHANGELOG.md ]]; then
    sed -e '1,2d' CHANGELOG.md | sed '/./,$!d'
  fi
} > "$changelog"
mv "$changelog" CHANGELOG.md

if (( DRY_RUN )); then
  echo "--- DRY RUN: would release $tag with this changelog section ---"
  cat "$notes_file"
  echo "--- DRY RUN: no files changed, no tag created ---"
  rm -f "$notes_file" "$changelog" 2>/dev/null || true
  git checkout -- CHANGELOG.md pyproject.toml 2>/dev/null || true
  exit 0
fi

git add CHANGELOG.md pyproject.toml uv.lock
git commit -m "chore(release): $tag"

# --- tag, push, GitHub release --------------------------------------------------------
git tag -a "$tag" -m "Release $version"
git push origin main --follow-tags
gh release create "$tag" --title "$version" --generate-notes || {
  echo "warn: could not create GitHub release; the tag is pushed"
}

echo "Done: $tag released."
