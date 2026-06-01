# Simple Playbook

Detailed operating guidance for the `simple` skill. Use with the `simple-made-easy` and `cyclomatic-complexity` source skills loaded as needed.

## Composite Workflow

1. Name the artifact goal: what should become easier to reason about after the change?
2. Separate user-facing problem complexity from implementation complexity.
3. Identify concerns that vary independently but are currently represented together.
4. Inspect decision paths where those concerns appear: branches, flags, state reads, effect calls, matches, handlers, and validation blocks.
5. Decide whether each branch is inherent domain complexity or accidental implementation complexity.
6. Add or run behavior checks before changing meaningful control flow.
7. Unbraid one concern at a time.
8. Re-run tests and re-measure complexity when tooling exists.
9. Report the tradeoff honestly: simplicity can make code less familiar or less compact.

## Complexity Map

Use this table to translate simplicity findings into concrete code moves.

| Symptom | Likely Complection | Better Shape |
| --- | --- | --- |
| Boolean mode flags | Policy plus control flow plus call-site intent | Distinct functions, enum variants, or policy data |
| Large `match` or `switch` | Selection plus execution plus validation | Dispatch to focused handlers or table-driven rules |
| Nested conditionals | Ordering plus policy plus error handling | Guard clauses, explicit states, or separated decisions |
| Stateful service method | Identity plus time plus effects plus logic | Value-in/value-out core behind an effect boundary |
| Repeated condition clusters | Scattered policy | Named predicate, rule table, or domain type |
| Parser that mutates state | Representation plus validation plus effects | Parse to values, validate, then execute effects |
| Hidden globals or clocks | Time/location plus business logic | Explicit parameters, snapshots, clocks, or events |

## Review Questions

- What must be understood together to safely change this code?
- Which condition exists because the domain needs it, and which exists because concerns are interleaved?
- Can policy vary independently from parsing, persistence, transport, UI, or effects?
- Does the same input produce different output because hidden time or state is involved?
- Are tests guarding a design that remains hard to reason about?
- Did a refactor reduce branches while making data flow, ownership, or lifetimes harder to understand?

## Refactoring Examples

Boolean flag:

```text
Instead of simplifying by adding another flag, split the mode into named variants or functions. This makes call-site intent explicit and prevents policy from leaking into every branch.
```

Branch-heavy function:

```text
Before extracting helpers, identify whether branches represent validation, domain choice, transport concerns, or effects. Extract along those boundaries, not by line count.
```

Rust match:

```text
A large match over an enum may be simple if it is the one closed domain decision. It becomes complex when each arm also parses inputs, mutates state, performs I/O, and applies policy.
```

## Anti-Goals

- Do not optimize for fewer lines if the result hides policy, state, or effects.
- Do not split functions mechanically by size; split along independent reasons to change.
- Do not celebrate lower cyclomatic complexity when coordination moved into naming, shared state, macros, or hidden callbacks.
- Do not replace explicit domain decisions with generic abstractions unless they remove irrelevant detail.
