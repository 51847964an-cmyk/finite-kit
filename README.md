# FiniteKit · Lean 4 toolkit for finite combinatorial formalisation

A small, self-contained Lean 4 project that demonstrates a workflow for
**machine-checking finite combinatorial constructions**. The single worked
example is the [JSP-000690 problem](https://github.com/TheJustinSunPrize/awards/blob/main/problems/catalog-0601-0700.md#JSP-000690)
from the *Justin Sun Prize* problem bank, but the patterns transfer to any
"does there exist an X with these properties" statement that admits a finite
explicit witness.

> **What this is not.** A general-purpose proof assistant. The toolkit only
> handles the narrow class of statements where every predicate reduces to a
> finite Boolean function: hypergraph / graph colourings, tournament scores,
> tilings of finite grids, Ramsey-type witnesses on a fixed vertex set, etc.
> If your problem asks "for all n, …" or "prove that every graph has …" you
> need Mathlib and a real proof, not this.

## What is in here

| File | Purpose |
|---|---|
| `JSP000690.lean` | The main proof: a 3-uniform, 3-chromatic-critical hypergraph on 9 vertices with 22 edges and minimum degree 7. Verified entirely by `by decide`. |
| `AuditBridge.lean` | An independent re-encoding of the same witness using `Nat`-only definitions and base-2 / base-3 numeric colourings. Two unrelated encodings agree → any shared bug would have to repeat. |
| `tools/verify.py` | An independent brute-force check in Python (not Lean). The two-tool cross-check is what makes the result trustworthy. |
| `tools/gen.py` | Generates `JSP000690.lean` from the witness data and the colouring certificates. The generator *asserts* every certificate before emitting Lean, so a buggy Lean file means a buggy generator too. |
| `tools/gen_bridge.py` | Same idea for `AuditBridge.lean`: regenerate it from the witness and check certificates at generation time. |
| `tools/audit/targets.json.example` | Template consumed by `prepare_manifest.py`. |
| `tools/audit/targets.json` | Generated manifest (gitignored). |
| `tools/audit/prepare_manifest.py` | Regenerates `targets.json` against the current `HEAD` SHA. |
| `tools/audit/run.sh` | One-shot wrapper: regenerate manifest, `lake build`, run audit. |
| `tools/audit/result.json` | Output of a passing run of `audit.py`. |
| `TROUBLESHOOTING.md` | Every pitfall we hit, with the fix. |
| `NOTES.md` | Retrospective on the attempt to claim JSP-000690 as a Justin Sun Prize entry. |

## Build and verify

The project pins `leanprover/lean4:v4.34.1` via `lean-toolchain`, so
[elan](https://github.com/leanprover/elan) is enough. There is no Mathlib
dependency; everything is pure Lean 4 kernel.

```bash
# install the toolchain if needed
curl -sSf https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh

# build the two Lean libraries
lake build                  # ~50 s on a laptop

# independent Python cross-check
python3 tools/verify.py
# expects:
#   edges: 22  min degree: 7  degrees: [10, 7, 7, 7, 7, 7, 7, 7, 7]
#   3-uniform: True
#   2-colourable: False (=> chi >= 3)
#   3-colouring exists: True  (2, 1, 1, 1, 1, 0, 0, 0, 0)
#   edges whose removal keeps chi=3 (should be none): []
#   vertices whose removal keeps chi=3 (should be none): []

# regenerate the Lean source from the witness + certificates
python3 tools/gen.py        # writes JSP000690.lean
python3 tools/gen_bridge.py # writes AuditBridge.lean
lake build                  # rebuild from regenerated source
```

## What the proof actually shows

The JSP-000690 problem asks whether there exists a 3-uniform
3-chromatic-critical hypergraph with minimum degree ≥ 7. The answer is
**yes**, with an explicit construction by Li (2025, arXiv:2512.24850).

To verify in Lean:

| Claim | How it is proved |
|---|---|
| 3-uniform | direct check on all 22 edges |
| minimum degree ≥ 7 | count edges per vertex (degree sequence is `[10,7,7,7,7,7,7,7,7]`) |
| `χ(H) ≥ 3` | exhaustive search over all 2⁹ = 512 two-colourings, all rejected |
| `χ(H) ≤ 3` | one explicit 3-colouring, checked on all 22 edges |
| edge-critical | 22 explicit 2-colourings, one for each deleted edge |
| vertex-critical | 9 explicit 2-colourings, one for each deleted vertex |

Total certificates: 1 + 22 + 9 = 32 explicit witnesses, plus the 512-element
exhaustive proof of non-2-colourability. Every theorem closes by kernel reduction:

```text
'JSP690.H_is_witness' depends on axioms: [propext]
'JSP690.jsp690_exists' depends on axioms: [propext]
```

`propext` is part of Lean's own logic; no `sorryAx`, no `native_decide` axiom,
no added trusted code.

## Why the *Bridge* file exists

`AuditBridge.lean` deliberately re-encodes everything: `Nat` instead of `Fin 9`,
colourings as natural numbers decoded in base 2 / base 3, edges as plain
triples, no shared definitions. It re-derives the same Boolean results from
scratch and then proves

```lean
theorem bridge_matches_main : Intended ↔ JSP690.WitnessProperty JSP690.H
```

The two encodings cannot share a typo unless the same typo appears in two
unrelated code paths. This costs ≈ 1.5× the build time and zero dependencies.

## Limits of the approach

- **Exhaustive enumeration only.** Anything bigger than ~2²⁰ cases will not
  finish in `by decide`. The 512-case sweep is comfortable; 10⁶ is not.
- **No Mathlib, no induction, no arithmetic hierarchies.** Everything is a
  flat Boolean function on finite data. This is a feature, not a bug, for
  this class of problems.
- **Witness data has to be hard-coded.** The witness comes from a paper; you
  encode it in `gen.py`, the generator asserts every certificate, and emits
  Lean. Lean never sees the original witness data — it sees only what the
  Python emitter wrote, so the Python script is part of the trust chain.
  `verify.py` is the third independent path that closes the loop.

## Reproducing the official `lean-verify` self-check

The upstream `TheJustinSunPrize/awards` repository ships an audit script
under `skills/lean-verify/scripts/audit.py`. Clone it next to this repo, then:

```bash
# 1. regenerate the audit manifest from the template + current HEAD
python3 tools/audit/prepare_manifest.py

# 2. preflight (file paths, manifest validity)
python3 ../justinsun-awards/skills/lean-verify/scripts/audit.py preflight \
    --out /tmp/audit-preflight tools/audit/targets.json

# 3. full run (compile the proof, check axioms)
python3 ../justinsun-awards/skills/lean-verify/scripts/audit.py run \
    --out /tmp/audit-run \
    --lake $(which lake) \
    --timeout 900 \
    tools/audit/targets.json

# 4. inspect
cat /tmp/audit-run/result.json | jq '.exit_code, .mechanical_status'
```

…or just run the bundled wrapper:

```bash
bash tools/audit/run.sh
```

The wrapper does steps 1–3 in order and prints a per-target table.

The version captured in `tools/audit/result.json` exited 0 with
`mechanical_status: standard_axioms_only` for all 9 declared targets at commit
`f756bf0ed4b247ff2e1ff66d42d2878010f76e87` (HEAD):

| Target | Declaration | Result | Axioms |
|---|---|---|---|
| `main` | `JSP690.jsp690_exists` | standard_axioms_only | `[propext]` |
| `t_uniform` | `JSP690.H_is_three_uniform` | standard_axioms_only | `[propext]` |
| `t_mindeg` | `JSP690.H_min_degree` | standard_axioms_only | `[propext]` |
| `t_chi_lower` | `JSP690.H_not_2_colourable` | standard_axioms_only | `[propext]` |
| `t_chi_upper` | `JSP690.H_is_3_colourable` | standard_axioms_only | `[propext]` |
| `t_edge_crit` | `JSP690.H_edge_critical` | standard_axioms_only | `[propext]` |
| `t_vertex_crit` | `JSP690.H_vertex_critical` | standard_axioms_only | `[propext]` |
| `intended` | `AuditBridge.bridge_intended` | standard_axioms_only | **none** |
| `bridge_match` | `AuditBridge.bridge_matches_main` | standard_axioms_only | `[propext]` |

Note: `AuditBridge.bridge_intended` declares no axioms at all in Lean 4.34.1 —
the entire 22-edge/9-vertex independent re-encoding reduces to `true` without
even needing propositional extensionality.

The `targets.json.example` template ships in the repo; the runtime
`targets.json` is regenerated by `tools/audit/prepare_manifest.py` (see
`tools/audit/`) and references the current `HEAD` SHA. This avoids the
chicken-and-egg between manifest commit and HEAD commit.

## License

Apache 2.0. See `LICENSE`.