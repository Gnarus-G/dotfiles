# Simple Made Easy Reference

Copied reference content from `.agents/skills/simple-made-easy/SKILL.md` for self-contained use by `/simple`.

Use this reference to make "simple" precise: simple means **not interleaved**. Easy means **near at hand, familiar, or near current capability**. Prefer simple over merely easy when long-term reliability, debugging, and change matter.

Source lens: Rich Hickey, "Simple Made Easy" (Strange Loop 2011), video `https://www.youtube.com/watch?v=SxdOUGdseq4`, public transcript `https://github.com/matthiasn/talk-transcripts/blob/master/Hickey_Rich/SimpleMadeEasy.md`.

## Core Definitions

- **Simple:** one fold, one braid; a thing with focused responsibility and no unnecessary interleaving with other concerns.
- **Complex:** braided together; concerns must be understood together because they are coupled.
- **Easy:** nearby; available, familiar, or within current capability. Easy is relative to a person or team.
- **Complect:** to interleave concerns so they cannot be reasoned about independently.
- **Compose:** to place independent parts together through stable abstractions.

Do not accept "simple" as a synonym for "short", "familiar", "popular", "few files", "one class", "one function", or "quick to write".

## Workflow

1. State the user-facing problem complexity separately from implementation complexity.
2. Identify which concerns are braided together: state, time, identity, policy, ordering, location, effects, representation, validation, transport, persistence, UI, authorization.
3. Ask whether each braid is inherent to the problem or incidental from chosen constructs.
4. Prefer constructs that keep concerns independent: values, functions, data, namespaces, protocols/interfaces, queues, declarative queries, transactions.
5. Push state and effects to explicit boundaries. Keep the core as value-in/value-out logic where possible.
6. Review abstractions with `who`, `what`, `when`, `where`, `why`, and `how`; separate them when they can vary independently.
7. Validate with tests, but do not treat tests as a substitute for reasoning. Tests are guardrails, not steering.

## Coding Practices

Prefer:

- Immutable values over mutable objects when identity over time is not required.
- Pure functions over methods that implicitly depend on object state.
- Plain data over syntax-heavy or class-heavy representations.
- Small interfaces/protocols that describe `what`, not concrete `how`.
- Dependency injection or explicit parameters over hidden global access.
- Declarative data manipulation over imperative traversal when order is not semantically required.
- Queues or streams over actors when the actor identity is incidental.
- Transactions and value snapshots over eventually inconsistent mutable reads where correctness matters.
- Rules/tables/configured policies over scattered conditionals when policy varies independently.

Avoid or challenge:

- State that leaks through APIs as different results for the same inputs.
- Objects that bundle identity, mutable state, behavior, and persistence.
- Inheritance hierarchies used to share behavior or coordinate type decisions.
- Large pattern matches or switches that centralize many closed pairs of `who` and `what`.
- ORM mappings that bind storage shape, object identity, query behavior, and lifecycle.
- Boolean flags that combine multiple modes in one function.
- Incidental ordering constraints hidden inside loops or folds.
- Convenience APIs that are short to call but create hidden coupling in the artifact.

## Review Questions

- What must be understood together to safely change this?
- Which parts can vary independently but are currently represented together?
- Is this easy because it is familiar, or simple because it is unbraided?
- Does this abstraction hide implementation, or does it remove irrelevant detail?
- Can the same input produce different output? If yes, where is time/state represented?
- Are tests compensating for a design that is hard to reason about?
- Did we choose this construct for programmer convenience or artifact reliability?

## Refactoring Moves

- Extract immutable request/response values from stateful services.
- Move parsing, validation, decision, and effect execution into separate steps.
- Replace boolean mode flags with distinct functions, variants, or data-driven rules.
- Replace inheritance with composition plus small interfaces/protocols.
- Replace scattered conditionals with a policy table or rule set when policy is data.
- Move persistence concerns behind query/command boundaries that exchange values.
- Keep time explicit: pass clocks, snapshots, versions, or events instead of reading mutable state everywhere.

## Reporting Format

When applying this reference, report findings as:

```md
Simplicity findings:
- Concern braided: <state/time/policy/etc.>
- Why it is complex: <what must be reasoned about together>
- Practical change: <smallest unbraiding move>
- Tradeoff: <what gets less easy or less familiar>
```

Favor small, behavior-preserving changes. Simplicity work often starts with making one hidden dimension explicit.
