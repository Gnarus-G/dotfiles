# Procedural And Functional Shape

Use procedural code to make effects and order visible; use functional code to make decisions and transformations deterministic.

## Procedural Orchestration

Prefer a direct sequence when the work is inherently ordered:

1. Parse input.
2. Validate values.
3. Compute decisions.
4. Perform effects.
5. Return an explicit result.

Keep state local, give mutations one clear owner, and make transitions visible; a straightforward loop is often simpler than a pipeline that allocates intermediate collections or hides control flow.

## Functional Computation

Use value-in/value-out functions for policy, validation, parsing, calculation, and transformation; pass dependencies as values, return explicit errors, and compose functions only when the composition makes the domain flow clearer.

Immutability is valuable when it removes temporal coupling, but local mutation with single ownership can be simpler and more efficient than copying or an elaborate immutable representation.

## Boundaries

Keep clocks, randomness, environment, storage, network, logging, and process state outside deterministic computation; take snapshots or explicit dependency values at the boundary, compute from them, then apply the resulting effects in a visible order.

Avoid generic frameworks, clever higher-order machinery, and point-free transformations unless they remove more complexity than they introduce.
