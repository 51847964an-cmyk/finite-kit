import Lake
open Lake DSL

package «jsp690» where
  version := v!"0.1.0"

/-- The submitted proof: witness H and the JSP-000690 target theorem.
    Lean core only: no mathlib, no external dependencies. -/
@[default_target]
lean_lib «JSP690» where

/-- Independent re-encoding and cross-check of the same statement. -/
lean_lib «AuditBridge» where
