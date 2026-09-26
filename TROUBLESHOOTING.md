# TROUBLESHOOTING — pitfalls hit while building this toolkit

A record of every error we hit, the root cause, and the fix. Read this
*before* writing your own Lean finite-formalisation; the same traps will catch
you otherwise.

## Toolchain & installation

### 1. Direct GitHub download is ~30× slower than the mirror

A 538 MB `tar.zst` of the Lean 4 toolchain took ≈ 2 hours over plain
`releases.lean-lang.org` but **3 min 57 s** via `https://ghfast.top/<URL>`. The
local HTTP proxy (127.0.0.1:7890 / ClashX Meta) did not help.

```bash
# fast
curl -L -o lean.tar.zst https://ghfast.top/https://github.com/leanprover/lean4/releases/download/v4.34.1/lean-4.34.1-darwin.tar.zst

# slow
curl -L -o lean.tar.zst https://github.com/leanprover/lean4/releases/download/v4.34.1/lean-4.34.1-darwin.tar.zst
```

### 2. macOS has no `zstd` CLI out of the box

Use the Python `zstandard` package and stream-decompress:

```python
import zstandard, io, tarfile
dctx = zstandard.ZstdDecompressor()
with open(src, "rb") as fh, dctx.stream_reader(fh) as r:
    buf = io.BufferedReader(r)
    with tarfile.open(fileobj=buf, mode="r|") as tf:
        for m in tf: tf.extract(m, dest_dir, filter="data")
```

Do **not** try to `rm -rf` the partially-extracted directory first: the
sandbox will refuse (>50 files triggers a "this is a destructive batch"
warning and the operation aborts). Extract into a fresh directory.

### 3. The toolchain is large and the .lake cache is large

Pin the exact toolchain in `lean-toolchain` (`leanprover/lean4:v4.34.1`) and
add `.lake/` to `.gitignore`. Fresh clones will redownload — that's fine,
it's the cost of isolation.

## Lean source pitfalls

### 4. `def Foo : Prop := …` will not synthesise `Decidable`

If you write

```lean
def WitnessProperty (G : Graph) : Prop := P1 G ∧ P2 G ∧ P3 G
theorem h : WitnessProperty H := by decide   -- error: failed to synthesise Decidable
```

`by decide` needs the right-hand side to compute to a `Bool`; `def : Prop`
stays as an opaque term. Replace with `abbrev` so it unfolds during reduction:

```lean
abbrev WitnessProperty (G : Graph) : Prop := P1 G ∧ P2 G ∧ P3 G ∧ P4 G ∧ P5 G ∧ P6 G
```

### 5. `native_decide` is rejected by some competitions

The Justin Sun Prize rules (and many other formal-verification contests)
require proofs to be kernel-verifiable without trusting Lean native code.
`native_decide` introduces a `nativeDecide` axiom into the proof's
dependency set; **`#print axioms` will surface it**.

For pure exhaustive verification, prefer:

```lean
set_option maxRecDepth 100000
set_option maxHeartbeats 0

def bitAt (m : Nat) (i : Nat) : Bool := (m / (2 ^ i)) % 2 == 1

def allColourings2 : List (Nat → Bool) :=
  (List.range 512).map fun m v => bitAt m v
```

then close `∃ c, ¬ hasMonoEdge c G` with `by decide`. This is what
`AuditBridge.lean` does.

### 6. `List.eraseIdx` and friends over recursion-depth limits

Naively enumerating colourings as `List Bool` will hit `maximum recursion
depth` once you exceed ~30 nested `List.cons`. Use `List.range N` + a
numeric decoding (`bitAt`, `digit3`) instead. Avoid `[a, b, c, ...].flatMap`
for the same reason.

### 7. Lake's `lean_lib` requires the file at the right path

```lean
lean_lib «JSP000690»   -- expects JSP000690.lean at the package root
                        -- or JSP000690/ as a directory
```

Putting `JSP000690/JSP000690.lean` (file under a subdir of the same name)
will fail with `error: package configuration has errors` or `no such file`.
Either keep the .lean at the root, or declare

```lean
lean_lib «JSP000690», rootDir := «JSP000690»
```

and put the source under `JSP000690/`.

### 8. `lakefile.lean` field types are strict

`keywords` expects `Array String`, not `List String`. `defaultTargets` is not
a real field in current Lake. Start from a minimal working `lakefile.lean`
and only add fields whose types you can confirm.

## Python generator pitfalls

### 9. `%` collisions in template strings

If your Lean template contains `% 2` (modulo), `TPL % {...}` will mis-parse.
Use `.replace()` chain instead:

```python
out = TPL
  .replace("EDGES", edges_str)
  .replace("M3", str(m3))
  .replace("EW", ew_str)
  .replace("VW", vw_str)
```

### 10. `[]` stripped by templating

`replace("[EDGES]", edges_str)` will replace nothing if the template variable
is bare `[EDGES]` (no brackets). Be explicit:

```python
template = "... let E : List (Nat × Nat × Nat) := EDGES ..."
out = template.replace("EDGES", "[" + ", ".join(triples) + "]")
```

### 11. Generator should `assert` certificates before emitting

The Python script is part of the trust chain. If you skip the assertion and
just `print` "this looks right", a typo in the witness data will silently
produce a wrong Lean file that compiles happily.

```python
assert find2(E0) is None, "H must not be 2-colourable"
c3 = find3(E0); assert c3 is not None
ew = [find2([e for j, e in enumerate(E0) if j != i]) for i in range(len(E0))]
vw = [find2([e for e in E0 if v not in e]) for v in range(V)]
assert all(w is not None for w in ew + vw), "missing certificate"
```

## Audit / submission pitfalls

### 12. `audit.py preflight` fails with "missing/invalid evidence"

Every requirement in `targets.json` must carry an `evidence` string pointing
the reviewer at the relevant Lean declaration. Skipping the field makes the
script abort before running any compilation.

```json
{
  "id": "chromatic_at_least_3",
  "title": "...",
  "evidence": "JSP690.H_not_2_colourable, proved by exhaustive reduction over 512 two-colourings.",
  ...
}
```

### 13. `audit.py run --out PATH` requires the path to not exist

Pass `--out /tmp/audit-run` (a fresh, non-existent directory). Pre-existing
output dirs cause spurious "file exists" errors. Also avoid making `--out` a
child of the project root.

### 14. GitHub commit author must match the claim author

The Lean repo's first commit's `Author:` field is the canonical identity for
priority. Setting a global git config that is *not* the email you use to
submit the prize will create a verification gap — maintainers will not know
that the GitHub account and the commit author are the same person. Fix:

```bash
cd <repo>
git config user.email "your-github-verified-email@example.com"
git commit --amend --reset-author --no-edit   # HEAD
# for older commits:
git rebase -i HEAD~N --autosquash             # then amend each
```

Then re-run `audit.py` because the SHA changed.

### 15. v1.0 release tag is a hard priority requirement

Per the prize rules, "Commit timestamps alone are insufficient evidence".
You must publish a tagged release (e.g. `git tag -a v1.0 -m "..." && git push
--tags`) and reference it in the claim issue. This is what gives maintainers
an "independently checkable public history" independent of Git.

## Process pitfalls

### 16. Search for existing submissions BEFORE doing the work

The first step of the official contribution flow is "before opening a PR,
check for existing submissions". We skipped it, picked a problem already
claimed six days earlier, and produced six days of waste. The check is two
commands:

```bash
gh search issues "Award claim" --repo <owner>/<repo> --state open --limit 200
gh issue list --repo <owner>/<repo> --state all --limit 200
```

Five minutes of searching is cheaper than five hours of formalisation.

### 17. Submit *early*, before you've spent a week on the proof

Maintainers sometimes reject submissions for stylistic or scope reasons that
have nothing to do with whether the Lean compiles. Opening a draft PR with
the Lean file and a minimal claim issue gives you feedback while you still
have time to act on it.

### 18. The community moves faster than you expect

By the time the award was 4 days old, ~99 problems already had open Award
claim issues, and the most prolific contributor (zjukop3) had filed on at
least 6 of them. If you want a unique claim, treat the problem bank as a
race and refresh the issue list every few hours until you find a target.