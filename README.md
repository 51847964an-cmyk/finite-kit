# JSP-000690 — a machine-checked witness (Lean 4)

**Problem (The Justin Sun Prize, JSP-000690 / Erdős–Lovász, chromatic interpretation):**

> Is there a three-uniform, three-chromatic-critical hypergraph with minimum degree at least seven?

**Answer: yes.** This repository contains an explicit witness — a 3-uniform hypergraph on
9 vertices with 22 edges — together with a **complete Lean 4 formal proof** that the witness
has all the required properties.

**Status: verified.** `lake build` succeeds with Lean 4.34.1; `#print axioms` reports
`[propext]` only — no `sorry`, no `native_decide` trusted axiom, no external libraries
(Lean core + standard library only).

## The witness

Vertices `0 … 8`. Edges (22):

```
(0,1,2) (0,1,8) (0,2,7) (0,3,5) (0,3,7) (0,3,8) (0,4,6) (0,4,7) (0,4,8) (0,5,6)
(1,2,5) (1,2,6) (1,3,8) (1,4,8) (1,5,6)
(2,3,7) (2,4,7) (2,5,6)
(3,5,7) (3,5,8)
(4,6,7) (4,6,8)
```

Degree sequence: `[10, 7, 7, 7, 7, 7, 7, 7, 7]` → minimum degree **7**.

| Property | Value | How it is certified |
|---|---|---|
| 3-uniform | yes | direct computation |
| minimum degree ≥ 7 | yes (exactly 7) | direct computation |
| χ ≥ 3 (not 2-colourable) | yes | **exhaustive** over all 2⁹ = 512 two-colourings |
| χ ≤ 3 (3-colourable) | yes | **explicit** 3-colouring `psi` checked on all 22 edges |
| edge-critical (χ(H−e) ≤ 2 ∀ edge e) | yes | **explicit** 2-colouring for each of the 22 deletions |
| vertex-critical (χ(H−v) ≤ 2 ∀ vertex v) | yes | **explicit** 2-colouring for each of the 9 deletions |

The mathematical solution was published by Ruiliang Li,
[*On an Erdős–Lovász problem: 3-critical 3-graphs of minimum degree 7*](https://arxiv.org/abs/2512.24850) (arXiv:2512.24850, 2025).
This repository contributes the **Lean formalization**: the witness and every property above
are re-verified from scratch inside the Lean kernel, independently of the paper's own scripts.

## How the proof works

Everything is a computable `Bool` function over finite data, so the kernel decides each
statement by reduction (`by decide`). To keep kernel reduction cheap, only the *negative*
claim is exhaustive; every *positive* claim carries an explicit certificate:

- **χ ≥ 3** is the only genuinely exhaustive part: `allColourings2` enumerates the 512
  two-colourings via bit-decoding of `0 … 511` (`bitAt m i`), so no deep list recursion is
  needed, and `twoColourable H` reduces to `false`.
- **χ ≤ 3**: one explicit 3-colouring `psi = c3Of [0,0,1,0,0,1,2,1,1]`, checked on 22 edges.
- **edge / vertex criticality**: `edgeDelColours` (22 lists) and `vertexDelColours` (9 lists)
  give a proper 2-colouring of each deleted subgraph; `edgeCritical` / `vertexCritical`
  zip those certificates against the deletions and check them.

Two options are set in the file: `set_option maxRecDepth 100000` and
`set_option maxHeartbeats 0`, because the 512-colouring sweep exceeds Lean's defaults.
Neither introduces axioms.

## Main statements (`JSP690.lean`)

```lean
abbrev WitnessProperty (G : Graph) : Prop :=
  threeUniform G = true ∧            -- 3-uniform
  minDegree G ≥ 7 ∧                  -- minimum degree at least seven
  twoColourable G = false ∧          -- chi(G) >= 3   (exhaustive)
  proper3 psi G = true ∧             -- chi(G) <= 3   (explicit certificate)
  edgeCritical G = true ∧            -- chi(G - e) <= 2 for every edge e
  vertexCritical G = true            -- chi(G - v) <= 2 for every vertex v

theorem H_is_witness : WitnessProperty H := by decide
theorem jsp690_exists : ∃ G : Graph, WitnessProperty G := ⟨H, H_is_witness⟩

-- finer-grained facts, each separately kernel-checked
theorem H_is_three_uniform : threeUniform H = true   := by decide
theorem H_min_degree       : minDegree H = 7         := by decide
theorem H_not_2_colourable : twoColourable H = false := by decide
theorem H_is_3_colourable  : proper3 psi H = true    := by decide
theorem H_edge_critical    : edgeCritical H = true   := by decide
theorem H_vertex_critical  : vertexCritical H = true := by decide
theorem H_has_22_edges     : H.length = 22           := by decide
theorem H_degrees : (vertices.map (degree H)) = [10,7,7,7,7,7,7,7,7] := by decide

#print axioms H_is_witness   -- prints: depends on axioms: [propext]
#print axioms jsp690_exists  -- prints: depends on axioms: [propext]
```

`propext` (propositional extensionality) is part of Lean's own logic and is not an
added assumption. In particular there is **no `sorryAx`** and **no `native_decide` axiom** —
an earlier version used `native_decide`, which does introduce a trusted axiom
(`H_is_witness._native.native_decide.ax_1_1`); the current version avoids it entirely.

## Build and reproduce

```bash
# 1. Lean toolchain — https://lean-lang.org/lean4/doc/setup.html
curl -sSf https://elan.lean-lang.org/elan-init.sh | sh -s -- -y --default-toolchain leanprover/lean4:v4.34.1

# 2. Build (single dependency-free package)
lake build
```

Observed on macOS x86_64, Lean 4.34.1:

```
ℹ [2/3] Built JSP690 (22s)
info: JSP690.lean:207:0: 'JSP690.H_is_witness' depends on axioms: [propext]
info: JSP690.lean:208:0: 'JSP690.jsp690_exists' depends on axioms: [propext]
Build completed successfully (3 jobs).
```

Single-file alternative (no lake):

```bash
lean JSP690.lean
```

## Regenerating the file

`../gen_lean.py` recomputes all 31 explicit colouring certificates in Python, asserts that
`H` is indeed not 2-colourable, and emits `JSP690.lean`. The Lean source is generated so the
certificates cannot drift from the Python cross-check.

## Independent cross-check (Python, not part of the proof)

`../witness.py` re-derives every property by brute force in Python, independently of Lean and
independently of the paper's own verification script:

```
edges: 22  min degree: 7  degrees: [10,7,7,7,7,7,7,7,7]
3-uniform: True
2-colourable: False
3-colouring exists: True
edges whose removal keeps chi=3:    []
vertices whose removal keeps chi=3: []
```

## Files

```
lakefile.lean        -- package definition (no dependencies)
lean-toolchain       -- leanprover/lean4:v4.34.1
JSP690.lean          -- definitions, witness, certificates, theorems
../gen_lean.py       -- generator: computes certificates, emits JSP690.lean
../witness.py        -- independent Python brute-force check
../search3.py        -- simulated-annealing search for alternative (independent) witnesses
```

## License

Code: MIT. Documentation and data: see the upstream repository's `LICENSE-CONTENT`.
