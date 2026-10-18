---
name: fsm-events-actions-style
description: "Use when designing, implementing, debugging, or reviewing event-driven state machines, events-to-actions systems, functional-core/imperative-shell code, durable effects, replay, observable workflows, or their zero-allocation hot paths."
---

# FSM / Events / Actions Style

Make consequential behavior explainable as **input -> decision -> intended effect -> observed result**, with explicit state between steps. Use this style where interactions, timing, retries, or failures matter; keep a straightforward pure calculation or one-off script straightforward.

## Vocabulary and contract

- **Input/event**: a value representing something the program learned (request, observation, timer firing, effect result, human decision). A received request is not evidence that the requested effect occurred. Record provenance.
- **State**: the information required to make the next decision, including pending work, relevant observed identity/preconditions, and uncertainty. Distinguish the application's state from the external world's state, which is only partially observable.
- **Intent/action**: a description of an effect to attempt, with identity, target, prerequisites, and expected observation. It is neither the effect itself nor proof of success.
- **Effect**: actual I/O performed by a narrow boundary: network, browser, filesystem, process, clock, random source, storage, model, or human channel. Reads are effects too; return their observations as events.
- **Outcome**: an event reporting what was actually observed after an attempt, including rejection, timeout, cancellation, and `Unknown`/`Ambiguous`. A successful API response proves only what that API promises.

For a nontrivial interaction, specify a deterministic decision function:

```text
decide(state, event) -> (next_state, effect_intents)
```

The function must not read time, generate IDs, fetch data, log, call an API, or perform effects. The shell supplies time/IDs/observations as inputs and interprets intents in order. Validate input shape, source, and authority at the boundary; handle invalid state transitions, stale, duplicate, and out-of-order events explicitly. An ordinary `match`/`switch` with a few named states is a state machine; no framework, DSL, or event-sourcing database is required.

## How to apply it

1. **Trace the real flow first.** List the inputs, external reads/writes, trust boundaries, existing state ownership, and observable success criteria. Identify one interaction with uncertainty worth modeling; do not remodel the whole codebase at once.
2. **Write the transition contract.** Name states and legal `(state, event)` pairs; state invariants, preconditions, terminal/pause/unknown states, timeouts, cancellation, and what happens to unexpected inputs. Specify whether unhandled input is rejected, ignored, deferred, or outside the contract: a blank transition is not automatically a no-op. Make impossible states hard to express where practical, without exploding into a type per trivial flag.
3. **Separate decisions from execution.** Convert each outside-world read into a typed observation; have the reducer return typed effect intents; let one interpreter execute them and feed back typed outcomes. Human choices, model outputs, and timer firings are untrusted inputs, not shortcuts around policy.
4. **Choose an authority and durability boundary.** In memory is enough for disposable work; for crash recovery, persist the transition and pending intent before dispatch, ideally in one atomic operation or an existing workflow journal. If storage and effect cannot be atomic, represent the gap explicitly. Reuse an existing durable engine when it already owns the workflow; do not create a competing event log/state authority. The purity boundary applies there too: workflow decision logic stays deterministic, while journaled steps, activities, or adapters carry the effects.
5. **Observe after attempts.** Correlate input, decision, intent, dispatch attempt, observation, and resulting state with stable IDs. Do not equate dispatch, acknowledgment, observation, and the user's goal. Preserve `Unknown` when an effect might have happened but confirmation was lost; reconcile before retrying non-idempotent effects.
6. **Verify the contract.** Test reducer transitions and forbidden transitions as tables/sequences; drive a real adapter for the affected flow; inject failure before dispatch, after dispatch, and before observation. Assert state, intents, and externally visible outcome rather than only that mocks were called. For complex interleavings, generate/shrink state-machine sequences or model-check a small invariant; check generator coverage and the model against independent observations.

Read [technique.md](references/technique.md) for the detailed execution, replay, failure, and testing protocol; [actors.md](references/actors.md) when concurrency makes actors a useful state-ownership boundary; [typescript.md](references/typescript.md) for a TypeScript implementation and an optional Effect interpreter; [hot-path.md](references/hot-path.md) when latency/throughput measurements justify an allocation-free hot path; [sources.md](references/sources.md) for research and its precise applicability.

## Design constraints

- Use one serial decision owner per independently ordered workflow/aggregate, or define concurrency control and ordering explicitly. When independent owners need concurrent progress, actors can own their own state and process messages one at a time; each actor's internals may use this event -> state -> intent pattern. Wall-clock timestamps alone do not establish causal order.
- Define whether events arriving together are ordered, batched, or concurrent, and when internally emitted events run; avoid unbounded self-triggering chains and hidden priority between competing transitions.
- An effect intent can be replayed as **data**; an effect must not be executed during state replay. Replay requires the same input events, reducer version/semantics, and ordering; live re-execution against the world is a new run.
- Event-driven design does **not** imply event sourcing: persist only the history and evidence the requirements justify. Tracing/logging alone is not durable state; a durable journal alone is not evidence of what happened in another system.
- Prefer visible local sequencing over an elaborate universal event bus. Add hierarchy, orthogonal states, durable workflows, or formal methods only when real complexity warrants them.
- Record enough to diagnose decisions without logging secrets or indiscriminately copying outside-world content; use references, redacted metadata, and access controls where appropriate.

## Expected result

For design or code work, describe the current and proposed event -> state -> intent -> outcome path, the effect/retry boundary, what can be reconstructed after failure, and the evidence from the affected flow. Cite a source only when it informs a contested design choice; do not claim determinism of the outside world.
