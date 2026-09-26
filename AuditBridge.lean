/-
  AuditBridge -- independent re-encoding and cross-check of the JSP-000690 witness.

  The main proof (JSP690.lean) encodes vertices as `Fin 9` and colourings as
  `List Bool` certificates. This file deliberately re-encodes everything:
  vertices are plain `Nat`, edges are `Nat` triples, and colourings are natural
  numbers decoded in base 2 (two-colourings) and base 3 (three-colourings).

  Nothing here is imported from the main proof's definitions: the edge list and
  the colouring certificates are restated from scratch. The final theorem
  `bridge_matches_main` shows the two independent encodings agree.
-/

import JSP000690

namespace AuditBridge

set_option maxRecDepth 100000
set_option maxHeartbeats 0

/- ---------- independent encoding ---------- -/

def E : List (Nat × Nat × Nat) := [(0, 1, 2), (0, 1, 8), (0, 2, 7), (0, 3, 5), (0, 3, 7), (0, 3, 8), (0, 4, 6), (0, 4, 7), (0, 4, 8), (0, 5, 6), (1, 2, 5), (1, 2, 6), (1, 3, 8), (1, 4, 8), (1, 5, 6), (2, 3, 7), (2, 4, 7), (2, 5, 6), (3, 5, 7), (3, 5, 8), (4, 6, 7), (4, 6, 8)]

def allB {{α : Type}} (l : List α) (p : α → Bool) : Bool :=
  l.foldl (fun acc x => acc && p x) true

def anyB {{α : Type}} (l : List α) (p : α → Bool) : Bool :=
  l.foldl (fun acc x => acc || p x) false

def v1 (e : Nat × Nat × Nat) : Nat := e.1
def v2 (e : Nat × Nat × Nat) : Nat := e.2.1
def v3 (e : Nat × Nat × Nat) : Nat := e.2.2

/-- base-2 digit v of m: the colour of vertex v in the colouring encoded by m -/
def bit (m : Nat) (v : Nat) : Bool := decide ((m / (2 ^ v)) % 2 = 1)

/-- base-3 digit v of m -/
def digit3 (m : Nat) (v : Nat) : Nat := (m / (3 ^ v)) % 3

/- ---------- the properties, recomputed ---------- -/

def uniform3 : Bool :=
  allB E (fun e => (v1 e < 9) && (v2 e < 9) && (v3 e < 9) &&
                   !(v1 e == v2 e) && !(v1 e == v3 e) && !(v2 e == v3 e))

def deg (v : Nat) : Nat :=
  (E.filter (fun e => (v1 e == v) || (v2 e == v) || (v3 e == v))).length

def minDegOK : Bool := allB (List.range 9) (fun v => decide (7 ≤ deg v))

def mono2 (m : Nat) (e : Nat × Nat × Nat) : Bool :=
  (bit m (v1 e) == bit m (v2 e)) && (bit m (v2 e) == bit m (v3 e))

def mono3 (m : Nat) (e : Nat × Nat × Nat) : Bool :=
  (digit3 m (v1 e) == digit3 m (v2 e)) && (digit3 m (v2 e) == digit3 m (v3 e))

def proper2 (m : Nat) : Bool := allB E (fun e => !(mono2 m e))
def proper3 (m : Nat) : Bool := allB E (fun e => !(mono3 m e))

/-- no proper 2-colouring exists (exhaustive over the 512 encodings 0..511) -/
def noProper2 : Bool := !(anyB (List.range 512) (fun m => proper2 m))

/-- the explicit 3-colouring, as a single base-3 number -/
def m3 : Nat := 10458

/-- explicit 2-colouring of E minus edge i, for i = 0..21 -/
def edgeCerts : List Nat := [480, 92, 90, 452, 308, 178, 420, 332, 202, 30, 62, 94, 458, 434, 482, 460, 436, 484, 186, 316, 218, 348]

/-- explicit 2-colouring of E minus vertex v, for v = 0..8 -/
def vertexCerts : List Nat := [480, 480, 480, 452, 420, 452, 420, 308, 92]

def nthDelete (i : Nat) : List (Nat × Nat × Nat) :=
  ((E.zip (List.range 22)).filter (fun q => !(q.2 == i))).map (fun q => q.1)

def vertDelete (v : Nat) : List (Nat × Nat × Nat) :=
  E.filter (fun e => !((v1 e == v) || (v2 e == v) || (v3 e == v)))

def edgeCritOK : Bool :=
  allB ((List.range 22).zip edgeCerts) (fun p => allB (nthDelete p.1) (fun e => !(mono2 p.2 e)))

def vertexCritOK : Bool :=
  allB ((List.range 9).zip vertexCerts) (fun p => allB (vertDelete p.1) (fun e => !(mono2 p.2 e)))

/- ---------- the intended statement, restated from the problem text ---------- -/

/-- there is a 3-uniform hypergraph with min degree >= 7, chi = 3,
    edge-critical and vertex-critical -/
abbrev Intended : Prop :=
  uniform3 = true ∧
  minDegOK = true ∧
  noProper2 = true ∧
  proper3 m3 = true ∧
  edgeCritOK = true ∧
  vertexCritOK = true

theorem bridge_uniform     : uniform3 = true     := by decide
theorem bridge_min_degree  : minDegOK = true     := by decide
theorem bridge_not_2_col   : noProper2 = true    := by decide
theorem bridge_3_col       : proper3 m3 = true   := by decide
theorem bridge_edge_crit   : edgeCritOK = true   := by decide
theorem bridge_vertex_crit : vertexCritOK = true := by decide

/-- the independent re-encoding proves the same statement -/
theorem bridge_intended : Intended := by decide

/-- and it agrees with the submitted proof's own statement -/
theorem bridge_matches_main : Intended ↔ JSP690.WitnessProperty JSP690.H := by decide

#print axioms bridge_intended
#print axioms bridge_matches_main

end AuditBridge
