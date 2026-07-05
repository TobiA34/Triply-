#!/usr/bin/env python3
"""
Trigger the Xcode Cloud release workflow (build + Distribute to App Store Connect).

Requires: pip3 install pyjwt requests
App Store Connect API key: https://appstoreconnect.apple.com/access/api
  - Create a key with Admin/App Manager/Developer role
  - Set env: ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH (path to .p8 file)

Usage:
  python3 Scripts/trigger_xcode_cloud_release.py [branch]
  # default branch: main

Or one-liner (after setting env vars):
  python3 Scripts/trigger_xcode_cloud_release.py main
"""

import json
import os
import sys
import time
from pathlib import Path

try:
    import jwt
    import requests
except ImportError:
    print("Install deps: pip3 install pyjwt requests", file=sys.stderr)
    sys.exit(1)

API_BASE = "https://api.appstoreconnect.apple.com/v1"
REPO_NAME = "Triply-"  # primaryRepositories attribute repositoryName


def get_jwt(issuer_id: str, key_id: str, private_key_path: str) -> str:
    with open(Path(private_key_path).expanduser(), "r") as f:
        key = f.read()
    now = int(time.time())
    payload = {"iss": issuer_id, "iat": now, "exp": now + 1200}
    return jwt.encode(
        payload,
        key,
        algorithm="ES256",
        headers={"kid": key_id, "alg": "ES256"},
    )


def main():
    branch = (sys.argv[1] if len(sys.argv) > 1 else "main").strip()
    issuer_id = os.environ.get("ASC_ISSUER_ID")
    key_id = os.environ.get("ASC_KEY_ID")
    key_path = os.environ.get("ASC_PRIVATE_KEY_PATH")
    if not all([issuer_id, key_id, key_path]):
        print(
            "Set ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY_PATH (path to .p8)",
            file=sys.stderr,
        )
        sys.exit(1)

    token = get_jwt(issuer_id, key_id, key_path)
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

    # 1) List CI products and find the one for this repo
    r = requests.get(
        f"{API_BASE}/ciProducts",
        params={"limit": 200, "include": "primaryRepositories"},
        headers=headers,
    )
    r.raise_for_status()
    data = r.json()
    product_id = None
    for inc in data.get("included", []):
        if inc.get("type") == "scmRepositories":
            attrs = inc.get("attributes", {}) or {}
            if attrs.get("repositoryName") == REPO_NAME:
                repo_id = inc["id"]
                for prod in data.get("data", []):
                    rel = (prod.get("relationships") or {}).get("primaryRepositories") or {}
                    for d in (rel.get("data") or []):
                        if d.get("id") == repo_id:
                            product_id = prod["id"]
                            break
                if product_id:
                    break
    if not product_id:
        print(f"No CI product found for repository name '{REPO_NAME}'. Check repo name in App Store Connect.", file=sys.stderr)
        sys.exit(1)

    # 2) List workflows for this product
    r = requests.get(
        f"{API_BASE}/ciProducts/{product_id}/workflows",
        headers=headers,
    )
    r.raise_for_status()
    workflows = r.json().get("data", [])
    if not workflows:
        print("No workflows found for this product. Create one in Xcode Cloud first.", file=sys.stderr)
        sys.exit(1)
    workflow_id = workflows[0]["id"]

    # 3) Get git reference (branch) id for this product's repo
    r = requests.get(
        f"{API_BASE}/ciProducts/{product_id}",
        params={"include": "repositories"},
        headers=headers,
    )
    r.raise_for_status()
    prod_data = r.json()
    repo_id = None
    for inc in prod_data.get("included", []):
        if inc.get("type") == "scmRepositories":
            repo_id = inc["id"]
            break
    if not repo_id:
        print("Could not resolve repository for product.", file=sys.stderr)
        sys.exit(1)

    r = requests.get(
        f"{API_BASE}/scmRepositories/{repo_id}/gitReferences",
        params={"limit": 200},
        headers=headers,
    )
    r.raise_for_status()
    refs = r.json().get("data", [])
    ref_name = f"refs/heads/{branch}"
    git_ref_id = None
    for ref in refs:
        if (ref.get("attributes") or {}).get("canonicalName") == ref_name:
            git_ref_id = ref["id"]
            break
    if not git_ref_id:
        print(f"Branch '{branch}' not found in repo. Available refs: {[r.get('attributes',{}).get('canonicalName') for r in refs]}", file=sys.stderr)
        sys.exit(1)

    # 4) Create build run (trigger workflow)
    body = {
        "data": {
            "type": "ciBuildRuns",
            "relationships": {
                "workflow": {"data": {"type": "ciWorkflows", "id": workflow_id}},
                "sourceBranchOrTag": {"data": {"type": "scmGitReferences", "id": git_ref_id}},
            },
        }
    }
    r = requests.post(f"{API_BASE}/ciBuildRuns", headers=headers, json=body)
    r.raise_for_status()
    run = r.json().get("data", {})
    print(f"Triggered Xcode Cloud build run: {run.get('id')} (workflow {workflow_id}, branch {branch})")
    print("Check status in Xcode (Report → Cloud) or App Store Connect → Xcode Cloud.")


if __name__ == "__main__":
    main()
