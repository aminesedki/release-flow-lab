#!/usr/bin/env python3
"""Post the deploy commit status on GitHub from a Cloud Build step.

Usage: github_status.py start|finish
Uses GITHUB_TOKEN (from Secret Manager) and COMMIT_SHA (built-in substitution).
Never fails the build for reporting issues.
"""
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone

API = "https://api.github.com"
REPO = "aminesedki/release-flow-lab"

token = os.environ.get("GITHUB_TOKEN", "")
sha = os.environ.get("COMMIT_SHA", "")
env = os.environ.get("_ENV", "")

if not token or not sha:
    print("github_status: skip (missing GITHUB_TOKEN or COMMIT_SHA)")
    sys.exit(0)

region = os.environ.get("_REGION", "europe-west9")
target = "https://console.cloud.google.com/cloud-build/builds;region=%s/%s?project=%s" % (
    region, os.environ.get("BUILD_ID", ""), os.environ.get("PROJECT_ID", ""))


def post(state, desc):
    body = json.dumps({
        "state": state,
        "context": "deploy/" + env,
        "description": desc[:140],
        "target_url": target,
    }).encode()
    req = urllib.request.Request(
        "%s/repos/%s/statuses/%s" % (API, REPO, sha), method="POST", data=body,
        headers={"Authorization": "Bearer " + token, "Accept": "application/vnd.github+json"})
    try:
        with urllib.request.urlopen(req) as r:
            r.read()
        print("github_status: posted %s (%s)" % (state, desc[:60]))
    except urllib.error.HTTPError as e:
        print("github_status: post failed %s: %s" % (e.code, e.read().decode()[:200]))
    except Exception as e:
        print("github_status: post failed: %s" % e)


def build_info():
    # step outcomes are communicated via marker files written by cb-build.sh
    # and cb-deploy.sh (avoids needing gcloud/creds in the reporting step)
    failed = []
    if not os.path.exists("/workspace/docker.ok"):
        failed.append("docker build")
    if not os.path.exists("/workspace/deploy.ok"):
        failed.append("deploy")
    return failed


def iso_z(s):
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except Exception:
        return None


cmd = sys.argv[1] if len(sys.argv) > 1 else ""

if cmd == "start":
    with open("/workspace/ts", "w") as f:
        f.write(str(int(datetime.now(timezone.utc).timestamp())))
    post("pending", "deploy running (Cloud Build)")

elif cmd == "finish":
    failed = build_info()
    dur = "n/a"
    try:
        with open("/workspace/ts") as f:
            start = int(f.read().strip())
        d = max(0, int(datetime.now(timezone.utc).timestamp()) - start)
        dur = "%dm%02ds" % (d // 60, d % 60) if d >= 60 else "%ds" % d
    except Exception:
        pass
    if failed:
        post("failure", "Cloud Build FAILED (%s) in %s" % (", ".join(failed), dur))
    else:
        post("success", "Cloud Build deploy OK in %s" % dur)

else:
    print("github_status: unknown command %r" % cmd)
