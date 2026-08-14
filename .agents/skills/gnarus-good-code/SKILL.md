---
name: gnarus-good-code
description: "Produces correct, stable procedural and functional code through explicit contracts, controlled effects, incremental changes, and evidence-backed verification. Use with the simple skill whenever designing, implementing, changing, debugging, or reviewing code where correctness and behavioral stability matter."
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: correctness-stability
---

# Gnarus Good Code

Write correct code whose stability claims are explicit, narrow, and supported by evidence.

## Pair With Simple

Use `simple` to choose a shape that is not complected; use this skill to make that shape correct and keep its observable behavior stable.

1. Apply `simple` before introducing abstractions or splitting functions.
2. Name the required behavior, invariants, and observable compatibility boundary.
3. Prefer procedural code for orchestration and pure functions for decisions and transformations.
4. Keep effects at explicit boundaries; pass values into logic and return values or explicit errors.
5. Make the smallest change that satisfies the contract.
6. Treat every line not needed by the current goal as a cost and a smell; apply YAGNI and do not overshoot.
7. Build the strongest practical evidence for each stability claim.
8. Verify the affected flow end-to-end and report any guarantee that remains conditional.

## Correctness Rules

- Derive behavior from requirements, existing contracts, and observed behavior rather than convention.
- Represent valid states directly when the language makes that practical.
- Keep data flow explicit; avoid hidden mutable state, ambient dependencies, and action at a distance.
- Use exhaustive handling for closed sets of states and fail clearly at untrusted boundaries.
- Preserve error semantics, ordering, timing, persistence, and externally visible side effects unless changing them is required.
- Prefer direct loops and named steps when they are clearer than chained transformations.
- Prefer pure functions when they isolate deterministic policy or computation.
- Add abstraction only after repeated concrete behavior reveals a stable boundary.
- In reviews, report only findings relevant to the stated goal and realistically reachable scenarios; omit speculative corrections and hypothetical failures.

## Stability Evidence

Match evidence to the claim instead of treating a passing test suite as a proof of everything:

- Types and exhaustive checks establish only the properties they encode.
- Example tests establish behavior only for their cases.
- Property tests establish quantified invariants over their generated domain.
- Characterization tests preserve observed legacy behavior, including known defects.
- Integration tests establish behavior across real component boundaries.
- End-to-end execution verifies the affected user or system flow in the exercised environment.
- Formal proof or exhaustive state exploration is required before calling a nontrivial property mathematically guaranteed.

Never claim guaranteed stability beyond the stated assumptions and evidence.

## Change Protocol

1. State the contract and identify failure modes.
2. Reproduce or characterize current behavior when changing existing code.
3. Add the smallest failing check for new or corrected behavior.
4. Implement one coherent change using procedural orchestration and functional computation where each fits.
5. Run focused checks, then the broader relevant suite.
6. Exercise the affected flow end-to-end.
7. Inspect the diff for accidental API, data, timing, error, or side-effect changes.

Read [stability.md](references/stability.md) when choosing evidence or making compatibility claims, and [procedural-functional.md](references/procedural-functional.md) when deciding code shape.

## Output

Report:

- Contract: behavior and invariants established.
- Shape: how procedural orchestration, pure computation, and effect boundaries are arranged.
- Stability: observable behavior preserved or intentionally changed.
- Evidence: checks and end-to-end flow exercised.
- Limits: assumptions or properties not guaranteed.
