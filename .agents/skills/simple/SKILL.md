---
name: simple
description: "Applies a composite simplicity discipline: Rich Hickey's Simple Made Easy lens plus cyclomatic complexity measurement to unbraid concerns and reduce branch-heavy code. Use when designing, reviewing, or refactoring code for simplicity, accidental complexity, tangled logic, branching hotspots, boolean modes, state/effect coupling, Rust control flow, or when the user invokes /simple."
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: code-review-refactoring
---

# Simple

Make code simpler in the artifact sense: less complected, easier to reason about, and less branch-heavy where branching is accidental.

## Reference Skills

Consult these self-contained references instead of duplicating their guidance in the main file:

- [simple-made-easy.md](references/simple-made-easy.md): design lens, vocabulary, concern unbraiding, and simplicity review questions.
- [cyclomatic-complexity.md](references/cyclomatic-complexity.md): measurement, ranking, refactoring, and validation for branch-heavy code.
- [playbook.md](references/playbook.md): composite workflow, complexity map, examples, and anti-goals.

Treat those references as the source of truth inside `/simple`. This main file only defines how to combine them.

## Operating Principle

Unbraid before extracting. Measure before celebrating.

## Workflow

1. Use `simple-made-easy` to identify what is complected.
2. Use `cyclomatic-complexity` when branching, Rust control flow, or measurable complexity is relevant.
3. Separate inherent domain complexity from accidental implementation complexity.
4. Prefer the smallest behavior-preserving change that unbraids one concern or removes one accidental decision path.
5. Validate with existing tests, characterization tests, and complexity measurement when available.

## Reporting Format

When applying this skill, report findings as:

```md
Simple findings:
- Concern braided: <state/time/policy/control-flow/etc.>
- Branch hotspot: <function/module and observed complexity signal>
- Why it is complex: <what must be understood together>
- Smallest useful change: <behavior-preserving unbraiding/refactor>
- Validation: <tests, checks, or measurements run>
- Tradeoff: <what gets less easy, familiar, or compact>
```

If code is already simple enough, say so and identify the remaining risk instead of inventing refactors.
