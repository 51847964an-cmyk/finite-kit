# NOTES · retrospective on the Justin Sun Prize attempt

This project was started as an attempt to win the Lean-formalisation role
(30% of the award, with the 70% mathematical-solver role held by Ruiliang
Li) on **JSP-000690** in the Justin Sun Prize problem bank. The work is
complete and self-consistent, but as a *prize claim* it never had a chance:
by the time we finished the Lean proof, another submitter had filed a
cleaner claim six days earlier.

What follows is what we learned, written down so the next attempt does not
repeat the same mistakes.

## What we did right

- **Pure-kernel verification, no `native_decide`.** First version of the
  Lean file used `native_decide` and compiled, but `#print axioms` would
  have surfaced `nativeDecide`. The replacement uses only `by decide`, with
  32 explicit certificates and a 512-element exhaustive sweep for the one
  negative claim. End state: `#print axioms` reports `[propext]` only.
- **Independent re-encoding (AuditBridge).** Two unrelated Lean definitions
  of every predicate, neither importing the other. The cost (≈ 1.5× build
  time, no dependencies) is trivial compared to the trustworthiness gain.
- **Generator as part of the trust chain.** `tools/gen.py` and
  `tools/gen_bridge.py` *assert* every certificate before emitting Lean
  source. Lean never sees raw witness data; it sees only what the Python
  generator wrote. `tools/verify.py` is the third, independent path.
- **Official audit.py self-check.** The repository ships a
  `skills/lean-verify/scripts/audit.py` that runs `lake build`, scrapes
  axioms, and writes a structured report. Running it produced exit 0 with
  `standard_axioms_only` on all 9 declared targets. The captured output
  is in `tools/audit/result.json`.

## What we did wrong

- **Skipped step 1 of the contribution flow.** The official
  `docs/award-process.md` step 1 is "before opening a PR, check for existing
  submissions for the same problem and contribution type." We went straight
  to formalisation. Result: zjukop3 had already filed
  [issue #2186](https://github.com/TheJustinSunPrize/awards/issues/2186)
  and [PR #2185](https://github.com/TheJustinSunPrize/awards/pull/2185)
  six days earlier, with a v1.0 release and an independent competitor audit
  showing our work would have been third in line.
- **Didn't realise `native_decide` was banned until after the fact.** The
  prize rules say proofs must be kernel-verifiable. We had a working
  version with `native_decide` before we found the rule. We were lucky the
  rewrite was straightforward; the wasted time was not.
- **Picked a problem whose `Lean formalization` and `Mathematical solution`
  roles are filled by different people.** JSP-000690 has an explicit
  construction (Li, 2025, arXiv:2512.24850) for the solver role. That role
  is separate from the Lean-formalisation role we were trying to claim. In
  the official 70 / 30 split, the maximum we could ever have received was
  30% — and the committee has full discretion on the non-top-tier amounts.
- **Didn't ship a v1.0 release.** Priority under the prize rules requires
  "independently checkable public history". Even if we had been first, the
  lack of a tagged release at our priority anchor would have weakened the
  claim. Easy to fix, easy to forget.
- **Git author mismatch.** First commit was authored by the local machine's
  global git config (`Anxi <ab@tpr.wales>`), not by the GitHub account that
  would submit the claim. Pushing without fixing this would have flagged
  the submission for attribution review.

## What the prize actually is, in numbers

(As of 2026-09-26, ten days after the prize was announced.)

| Quantity | Value |
|---|---|
| Open Award claim issues | 99 |
| Problems in `candidates/` (公示区) | 6 |
| Problems in `awards/` (confirmed, paid) | 0 |
| Highest-tier bounty ever disbursed | $0 (OpenAI's $1M was rejected) |
| Most prolific individual claim filer | zjukop3 (~6 problems) |
| Days until first 14-day public review closes | 7 (2026-10-03) |

The Lean formalisation community is fast: zjukop3, aqin1996, Wouter van
Doorn, Yanyang Li, and Quanyu Tang all filed claims within four days of the
prize launching. For most of the *Lean-friendly* problems
(explicit-construction verifications like JSP-000690), the role is already
taken.

## What to do instead

The work in this repository is reusable. The patterns — exhaustive
verification via `by decide`, certificate-based positive claims,
independent re-encoding, generator-as-trust-chain, official audit.py
integration — apply to any finite combinatorial problem. Possible
destinations:

- **Mathlib PR.** Several open Mathlib issues ask for finite enumerations
  (Ramsey-number lower bounds, small-case hypotheses for infinite
  conjectures, exhaustive case splits in combinatorial proofs). A
  contribution that supplies a finite verification + audit.py result would
  be welcome.
- **Lean textbook formalisations.** Standard textbook theorems ("every
  finite tree has a perfect matching", "the Petersen graph is not
  planar", etc.) are finite and verifiable. They have real pedagogical
  value and a permanent home in a Mathlib-style library.
- **Other formal-verification contests.** Some contests allow
  `native_decide`. Some have larger prize pools. Some focus on a different
  class of problem (e.g. CS algorithms, cryptography).

## Closing thought

The Justin Sun Prize is a real formal-verification benchmark with real
prizes attached. It is also a marketing vehicle for a cryptocurrency
project, and the gap between announcement and disbursement is real. Lean
formalisation is good work regardless of who pays for it; this repository
is useful regardless of whether the prize ever pays out.

If the maintainers ever confirm a JSP-000690 award, the audit trail here
will let a second submitter (us, or anyone else with this repository)
argue for a fractional split. That is the best outcome available under
the rules — and it is more than enough reason to keep the work public and
the build green.