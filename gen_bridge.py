"""生成 AuditBridge.lean —— 独立于主证明的重新编码与复核桥接。

主证明用 Fin 9 顶点 + List Bool 证书；这里刻意换一套编码：
顶点用裸 Nat，染色用自然数位解码（2 进制 / 3 进制），边用 Nat 三元组。
两套编码各自独立算出结论，再用 bridge_matches_main 证明二者一致。
"""
import os
from itertools import product

V = 9
E0 = [(0,1,2),(0,1,8),(0,2,7),(0,3,5),(0,3,7),(0,3,8),(0,4,6),(0,4,7),(0,4,8),(0,5,6),
      (1,2,5),(1,2,6),(1,3,8),(1,4,8),(1,5,6),(2,3,7),(2,4,7),(2,5,6),
      (3,5,7),(3,5,8),(4,6,7),(4,6,8)]

def find2(edges):
    for c in product([0, 1], repeat=V):
        if not any(c[a] == c[b] == c[d] for (a, b, d) in edges):
            return list(c)
    return None

def find3(edges):
    for c in product([0, 1, 2], repeat=V):
        if not any(c[a] == c[b] == c[d] for (a, b, d) in edges):
            return list(c)
    return None

c3 = find3(E0)
ew = [find2([e for j, e in enumerate(E0) if j != i]) for i in range(len(E0))]
vw = [find2([e for e in E0 if v not in e]) for v in range(V)]

def enc_base(bits, base):
    return sum(b * (base ** v) for v, b in enumerate(bits))

m3 = enc_base(c3, 3)
ew_nat = [enc_base(w, 2) for w in ew]
vw_nat = [enc_base(w, 2) for w in vw]

edges_lean = ", ".join("(%d, %d, %d)" % e for e in E0)
ew_lean = ", ".join(str(n) for n in ew_nat)
vw_lean = ", ".join(str(n) for n in vw_nat)

TPL = '''/-
  AuditBridge -- independent re-encoding and cross-check of the JSP-000690 witness.

  The main proof (JSP690.lean) encodes vertices as `Fin 9` and colourings as
  `List Bool` certificates. This file deliberately re-encodes everything:
  vertices are plain `Nat`, edges are `Nat` triples, and colourings are natural
  numbers decoded in base 2 (two-colourings) and base 3 (three-colourings).

  Nothing here is imported from the main proof's definitions: the edge list and
  the colouring certificates are restated from scratch. The final theorem
  `bridge_matches_main` shows the two independent encodings agree.
-/

import JSP690

namespace AuditBridge

set_option maxRecDepth 100000
set_option maxHeartbeats 0

/- ---------- independent encoding ---------- -/

def E : List (Nat × Nat × Nat) := [EDGES]

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
def m3 : Nat := M3

/-- explicit 2-colouring of E minus edge i, for i = 0..21 -/
def edgeCerts : List Nat := [EW]

/-- explicit 2-colouring of E minus vertex v, for v = 0..8 -/
def vertexCerts : List Nat := [VW]

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
'''

out = (TPL.replace("[EDGES]", edges_lean)
          .replace("M3", str(m3))
          .replace("[EW]", ew_lean)
          .replace("[VW]", vw_lean))

p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "repo", "AuditBridge.lean")
os.makedirs(os.path.dirname(p), exist_ok=True)
open(p, "w").write(out)
print("written", p)
print("m3 =", m3, " edgeCerts[0..2] =", ew_nat[:3])
