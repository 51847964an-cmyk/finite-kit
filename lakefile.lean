import Lake
open Lake DSL

package «finite-kit» where
  version := v!"0.1.0"

/-- Main proof: the JSP-000690 witness.
    A 3-uniform, 3-chromatic-critical hypergraph on 9 vertices with 22 edges,
    minimum degree 7, proved by kernel-decided exhaustive verification.

    Pure Lean 4 core; no Mathlib, no external dependencies. -/
@[default_target]
lean_lib «JSP000690» where

/-- Independent re-encoding and cross-check of the same statement.
    Vertices/edges/colours use a completely independent encoding (plain `Nat`,
    base-2/base-3 numeric colourings) so that any shared bug between the two
    proofs would have to repeat. -/
lean_lib «AuditBridge» where