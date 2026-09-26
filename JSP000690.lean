/-
  JSP-000690 · Erdos-Lovasz problem (chromatic interpretation)
  -------------------------------------------------------------
  Problem: "Is there a three-uniform, three-chromatic-critical hypergraph
            with minimum degree at least seven?"

  Answer:  YES.  Witness H: an explicit 3-uniform hypergraph on 9 vertices
  with 22 edges, minimum degree 7, chromatic number exactly 3, and
  2-colourable after deleting any single edge or any single vertex.

  Verification strategy (fully kernel-checked, no trusted axioms beyond
  Lean's own logic):
    * chi(H) >= 3   : exhaustive over all 2^9 = 512 two-colourings (by decide)
    * chi(H) <= 3   : one explicit 3-colouring, checked on all 22 edges
    * edge-critical : one explicit 2-colouring for each of the 22 deletions
    * vertex-critical: one explicit 2-colouring for each of the 9 deletions
    * 3-uniform / min degree: direct computation
  Every theorem below is closed by kernel reduction (`by decide`);
  `#print axioms` reports nothing beyond `propext`.
-/

namespace JSP690

set_option maxRecDepth 100000
set_option maxHeartbeats 0

abbrev Vertex := Fin 9
abbrev Edge   := Vertex × Vertex × Vertex
abbrev Graph  := List Edge

/- ---------- boolean helpers ---------- -/

def allB {{α : Type}} (l : List α) (p : α → Bool) : Bool :=
  l.foldl (fun acc x => acc && p x) true

def anyB {{α : Type}} (l : List α) (p : α → Bool) : Bool :=
  l.foldl (fun acc x => acc || p x) false

/- ---------- vertices and edges ---------- -/

def vertices : List Vertex :=
  [⟨0, by decide⟩, ⟨1, by decide⟩, ⟨2, by decide⟩,
   ⟨3, by decide⟩, ⟨4, by decide⟩, ⟨5, by decide⟩,
   ⟨6, by decide⟩, ⟨7, by decide⟩, ⟨8, by decide⟩]

def e1 (e : Edge) : Vertex := e.1
def e2 (e : Edge) : Vertex := e.2.1
def e3 (e : Edge) : Vertex := e.2.2

def contains (e : Edge) (v : Vertex) : Bool :=
  (e1 e == v) || (e2 e == v) || (e3 e == v)

def distinct3 (e : Edge) : Bool :=
  !(e1 e == e2 e) && !(e1 e == e3 e) && !(e2 e == e3 e)

def threeUniform (G : Graph) : Bool := allB G distinct3

def degree (G : Graph) (v : Vertex) : Nat :=
  (G.filter (fun e => contains e v)).length

def minDegree (G : Graph) : Nat :=
  vertices.foldl (fun m v => let d := degree G v; if d < m then d else m) G.length

/- ---------- colourings ---------- -/

abbrev Colour2 := Vertex → Bool
abbrev Colour3 := Vertex → Fin 3

/-- bit i of m (2-colourings are encoded by the integers 0 .. 511) -/
def bitAt (m : Nat) (i : Nat) : Bool := (m / (2 ^ i)) % 2 == 1

/-- all 512 two-colourings, encoded numerically (avoids deep list recursion) -/
def allColourings2 : List Colour2 :=
  (List.range 512).map (fun m => fun v => bitAt m v.val)

/-- turn a bit list into a 2-colouring (used for the explicit certificates) -/
def c2Of (l : List Bool) : Colour2 := fun v => l.getD v.val false

/-- turn a digit list into a 3-colouring -/
def c3Of (l : List (Fin 3)) : Colour3 := fun v => l.getD v.val ⟨0, by decide⟩

def mono2 (c : Colour2) (e : Edge) : Bool :=
  (c (e1 e) == c (e2 e)) && (c (e2 e) == c (e3 e))

def mono3 (c : Colour3) (e : Edge) : Bool :=
  (c (e1 e) == c (e2 e)) && (c (e2 e) == c (e3 e))

def proper2 (c : Colour2) (G : Graph) : Bool := allB G (fun e => !(mono2 c e))
def proper3 (c : Colour3) (G : Graph) : Bool := allB G (fun e => !(mono3 c e))

/-- exists a proper 2-colouring (exhaustive over all 512) -/
def twoColourable (G : Graph) : Bool :=
  anyB allColourings2 (fun c => proper2 c G)

/- ---------- deletions ---------- -/

def deleteEdge (G : Graph) (e : Edge) : Graph := G.filter (fun f => !(f == e))
def deleteVertex (G : Graph) (v : Vertex) : Graph := G.filter (fun e => !(contains e v))

/- ---------- the witness H: 9 vertices, 22 edges ---------- -/

def H : Graph := [
    (0, 1, 2),
    (0, 1, 8),
    (0, 2, 7),
    (0, 3, 5),
    (0, 3, 7),
    (0, 3, 8),
    (0, 4, 6),
    (0, 4, 7),
    (0, 4, 8),
    (0, 5, 6),
    (1, 2, 5),
    (1, 2, 6),
    (1, 3, 8),
    (1, 4, 8),
    (1, 5, 6),
    (2, 3, 7),
    (2, 4, 7),
    (2, 5, 6),
    (3, 5, 7),
    (3, 5, 8),
    (4, 6, 7),
    (4, 6, 8)
  ]

/-- explicit 3-colouring of H (witnesses chi(H) <= 3) -/
def psi : Colour3 := c3Of [(0 : Fin 3), (0 : Fin 3), (1 : Fin 3), (0 : Fin 3), (0 : Fin 3), (1 : Fin 3), (2 : Fin 3), (1 : Fin 3), (1 : Fin 3)]

/-- explicit 2-colouring of H minus edge i, for i = 0..21 -/
def edgeDelColours : List (List Bool) := [
    [false, false, false, false, false, true, true, true, true],
    [false, false, true, true, true, false, true, false, false],
    [false, true, false, true, true, false, true, false, false],
    [false, false, true, false, false, false, true, true, true],
    [false, false, true, false, true, true, false, false, true],
    [false, true, false, false, true, true, false, true, false],
    [false, false, true, false, false, true, false, true, true],
    [false, false, true, true, false, false, true, false, true],
    [false, true, false, true, false, false, true, true, false],
    [false, true, true, true, true, false, false, false, false],
    [false, true, true, true, true, true, false, false, false],
    [false, true, true, true, true, false, true, false, false],
    [false, true, false, true, false, false, true, true, true],
    [false, true, false, false, true, true, false, true, true],
    [false, true, false, false, false, true, true, true, true],
    [false, false, true, true, false, false, true, true, true],
    [false, false, true, false, true, true, false, true, true],
    [false, false, true, false, false, true, true, true, true],
    [false, true, false, true, true, true, false, true, false],
    [false, false, true, true, true, true, false, false, true],
    [false, true, false, true, true, false, true, true, false],
    [false, false, true, true, true, false, true, false, true]
  ]

/-- explicit 2-colouring of H minus vertex v, for v = 0..8 -/
def vertexDelColours : List (List Bool) := [
    [false, false, false, false, false, true, true, true, true],
    [false, false, false, false, false, true, true, true, true],
    [false, false, false, false, false, true, true, true, true],
    [false, false, true, false, false, false, true, true, true],
    [false, false, true, false, false, true, false, true, true],
    [false, false, true, false, false, false, true, true, true],
    [false, false, true, false, false, true, false, true, true],
    [false, false, true, false, true, true, false, false, true],
    [false, false, true, true, true, false, true, false, false]
  ]

/-- edge-criticality, certified by the explicit list above -/
def edgeCritical (G : Graph) : Bool :=
  allB (G.zip edgeDelColours) (fun p => proper2 (c2Of p.2) (deleteEdge G p.1))

/-- vertex-criticality, certified by the explicit list above -/
def vertexCritical (G : Graph) : Bool :=
  allB (vertices.zip vertexDelColours) (fun p => proper2 (c2Of p.2) (deleteVertex G p.1))

/- ---------- the property demanded by JSP-000690 ---------- -/

abbrev WitnessProperty (G : Graph) : Prop :=
  threeUniform G = true ∧            -- 3-uniform
  minDegree G ≥ 7 ∧                  -- minimum degree at least seven
  twoColourable G = false ∧          -- chi(G) >= 3
  proper3 psi G = true ∧             -- chi(G) <= 3
  edgeCritical G = true ∧            -- chi(G - e) <= 2 for every edge e
  vertexCritical G = true            -- chi(G - v) <= 2 for every vertex v

/- ---------- theorems (all closed by kernel reduction) ---------- -/

theorem H_is_three_uniform : threeUniform H = true := by decide
theorem H_min_degree       : minDegree H = 7        := by decide
theorem H_not_2_colourable : twoColourable H = false := by decide
theorem H_is_3_colourable  : proper3 psi H = true   := by decide
theorem H_edge_critical    : edgeCritical H = true  := by decide
theorem H_vertex_critical  : vertexCritical H = true := by decide

/-- H satisfies every requirement of JSP-000690. -/
theorem H_is_witness : WitnessProperty H := by decide

/-- Therefore such a hypergraph exists. -/
theorem jsp690_exists : ∃ G : Graph, WitnessProperty G := ⟨H, H_is_witness⟩

/-- basic data about H -/
theorem H_has_22_edges : H.length = 22 := by decide
theorem H_degrees :
    (vertices.map (degree H)) = [10, 7, 7, 7, 7, 7, 7, 7, 7] := by decide

#print axioms H_is_witness
#print axioms jsp690_exists

end JSP690
