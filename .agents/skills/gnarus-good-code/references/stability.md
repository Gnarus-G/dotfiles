# Stability

Stability means a named observable property continues to hold under named conditions; it is not a synonym for tests passing.

## Define The Claim

Specify:

- the behavior that must hold;
- the input and state domain where it must hold;
- the externally observable boundary;
- the failures that are allowed;
- the evidence that supports the claim.

Compatibility can include return values, errors, side effects, persistence, ordering, timing, resource use, wire formats, and public APIs; preserve only boundaries that have a concrete consumer or requirement.

## Choose Evidence

- Use types to exclude representable invalid states and exhaustive checks to cover closed alternatives.
- Use unit examples for crisp cases and regressions.
- Use property tests for invariants across a broad generated domain.
- Use model-based or state-machine tests for sequences of transitions.
- Use integration tests at process, database, filesystem, network, and dependency boundaries.
- Use end-to-end execution to observe the actual affected flow.
- Use assertions and runtime validation where assumptions cross an untrusted boundary.
- Use formal methods only when the required guarantee and cost justify them.

Tests sample behavior unless exhaustive over the stated domain; describe what evidence establishes without inflating the claim.

## Existing Code

Before changing code with uncertain behavior:

1. Observe representative success, edge, and failure paths.
2. Add characterization checks around behavior that consumers rely on.
3. Separate defect correction from structural change when practical.
4. Keep each transformation small enough to localize a regression.
5. Verify with real dependencies or the closest safe environment available.

Do not add speculative backward compatibility; require evidence of persisted data, shipped behavior, an external consumer, or an explicit requirement.
