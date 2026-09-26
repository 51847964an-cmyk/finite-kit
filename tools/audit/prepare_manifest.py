#!/usr/bin/env python3
"""Generate tools/audit/targets.json from tools/audit/targets.json.example
plus the current HEAD.

Usage: python3 tools/audit/prepare_manifest.py

The script writes tools/audit/targets.json which is .gitignored (it cannot
live in the repo because the commit SHA inside the manifest would change the
SHA of the commit that contains the manifest).
"""
import json, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
TEMPLATE = Path(__file__).resolve().parent / "targets.json.example"
OUTPUT = Path(__file__).resolve().parent / "targets.json"


def main() -> int:
    if not TEMPLATE.exists():
        print(f"ERROR: {TEMPLATE} not found", file=sys.stderr)
        return 1

    # Make sure the repo HEAD matches the working tree.
    status = subprocess.check_output(["git", "status", "--porcelain"],
                                     cwd=ROOT).decode().strip()
    if status:
        print("WARNING: working tree has uncommitted changes:")
        print(status)
        if not "--allow-dirty" in sys.argv:
            print("Commit first, or pass --allow-dirty to ignore.")
            return 2

    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT
                                  ).decode().strip()

    # Try to read the remote; fall back to a placeholder.
    try:
        repo = subprocess.check_output(
            ["git", "remote", "get-url", "origin"], cwd=ROOT
        ).decode().strip()
    except subprocess.CalledProcessError:
        repo = "https://github.com/OWNER/finite-kit"

    manifest = json.loads(TEMPLATE.read_text())
    manifest["project"]["commit"] = head
    manifest["project"]["repository"] = repo

    OUTPUT.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"wrote {OUTPUT} (commit={head[:12]}, repo={repo})")
    return 0


if __name__ == "__main__":
    sys.exit(main())