#!/usr/bin/env bash
# Run the official lean-verify audit against the current commit.
#
# Usage: bash tools/audit/run.sh
#
# Side effects: writes /tmp/audit-rerun-<timestamp>/result.json and prints
# a summary. Requires: lake on PATH (or via elan), the toolchain from
# `lean-toolchain`, and the official `skills/lean-verify/scripts/audit.py`
# somewhere accessible. Set LEAN_OFFICE_AUDIT to point at it.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
# Per-run output directory: timestamp suffix avoids "output already exists"
TMP="${TMP:-/tmp/audit-rerun-$(date +%s)}"
LEAN_BIN="${LEAN_BIN:-lake}"
AUDIT_PY="${LEAN_OFFICE_AUDIT:-../../justinsun-awards/skills/lean-verify/scripts/audit.py}"

# 1. regenerate the manifest with the current HEAD (pass --allow-dirty so
#    the wrapper itself doesn't trip over its own freshly-written files)
python3 "$HERE/prepare_manifest.py" --allow-dirty

# 2. clean build (so axiom counting is honest)
rm -rf "$ROOT/.lake/build"
echo "==> lake build"
( cd "$ROOT" && $LEAN_BIN build )

# 3. run the official audit
echo "==> audit.py run"
python3 "$AUDIT_PY" run \
    --out "$TMP" \
    --lake "$(command -v $LEAN_BIN || echo $LEAN_BIN)" \
    --timeout 900 \
    "$HERE/targets.json"

# 4. summarise
python3 - <<PY
import json
d = json.load(open("$TMP/result.json"))
print()
print(f"exit_code         : {d['exit_code']}")
print(f"mechanical_status : {d['mechanical_status']}")
print(f"preflight ready   : {d['preflight']['ready_for_target_checks']}")
print(f"head              : {d['preflight']['head']}")
print()
print(f"targets ({len(d['targets'])}):")
for t in d['targets']:
    ax = t.get('axioms', [])
    print(f"  {t['id']:15} | {t['declaration']:35} | {t['status']:22} | {ax}")
PY