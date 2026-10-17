# Technique: deterministic decisions, observable effects

This is an application-level discipline, independent of FP syntax. A mutable OO object, an Erlang `gen_statem` callback, a Rust `match`, and an Elm `update` can all implement the same contract if decisions and effect execution have a clear boundary. Pure functions help because identical state and input yield identical decisions; they are not a substitute for handling failure at the effect boundary.

## 1. Specify the smallest useful machine

For each interaction, write:

| Question | Example: send one browser action |
| --- | --- |
| Who owns state? | One run/selected-tab controller, with serialized actions. |
| What is input? | `ActionRequested`, `ApprovalGranted`, `EffectObserved`, `DeadlineElapsed`. |
| What is state? | `Ready`, `AwaitingApproval`, `PendingDispatch`, `Reconciling`, `Done`. |
| What is output? | `RequestApproval`, `DispatchClick`, `InspectPage`; each bound to an action ID. |
| What is success evidence? | A fresh observation satisfying the stated postcondition, not merely a click acknowledgment. |
| What cannot be known? | Whether a click took effect if the connection failed between dispatch and observation. |

Distinguish facts from proposals: `ClickRequested` is a command/input; `ClickPlanned` is an intent; `ClickAttempted` records the adapter's dispatch attempt; `PageObserved` is evidence; `GoalVerified` is a separate domain judgment. Avoid calling all five `ClickSucceeded`. Preserve the observed tab/target version and other relevant preconditions on an intent; invalidate stale approvals/targets when those facts change. A deadline is represented by a timer event carrying the deadline/ID, not by calling a clock inside `decide`. Begin from a few real scenarios and derive states from **differences in future observable behavior**: if two states respond identically to every relevant future input, they may be redundant; retain distinctions needed for recovery, policy, or evidence.

Example **illustrative** reducer (not a complete persistence or browser implementation):

```rust
enum Phase {
    Ready,
    PendingDispatch { action_id: ActionId },
    AwaitingObservation { action_id: ActionId },
    Reconciling { action_id: ActionId },
}

enum Event {
    ClickRequested { action_id: ActionId, target: Target },
    DispatchStarted { action_id: ActionId },
    PageObserved { action_id: ActionId, changed: bool },
    ObservationLost { action_id: ActionId },
}

enum Intent {
    DispatchClick { action_id: ActionId, target: Target },
    InspectPage { action_id: ActionId },
}

fn decide(state: Phase, event: Event) -> Result<(Phase, Vec<Intent>), InvalidEvent> {
    match (state, event) {
        (Phase::Ready, Event::ClickRequested { action_id, target }) => Ok((
            Phase::PendingDispatch { action_id },
            vec![Intent::DispatchClick { action_id, target }],
        )),
        (Phase::PendingDispatch { action_id }, Event::DispatchStarted { action_id: started })
            if action_id == started => Ok((Phase::AwaitingObservation { action_id }, vec![])),
        (Phase::AwaitingObservation { action_id }, Event::PageObserved { action_id: seen, changed })
            if action_id == seen => {
                if changed { Ok((Phase::Ready, vec![])) }
                else { Ok((Phase::Reconciling { action_id }, vec![])) }
            }
        (Phase::AwaitingObservation { action_id }, Event::ObservationLost { action_id: lost })
            if action_id == lost => Ok((
                Phase::Reconciling { action_id },
                vec![Intent::InspectPage { action_id }],
            )),
        _ => Err(InvalidEvent),
    }
}
```

The `changed` flag above is deliberately weak: for a real workflow, replace it with typed evidence and a domain-specific postcondition; `Ready` here means this action is settled, not that the user's task is complete. The shell must durably record `DispatchStarted` before actually dispatching and must treat either unresolved phase after restart as uncertain; recording the event does **not** prove the call happened. A production shell must also verify target/approval preconditions, account for crashes during `DispatchClick`, and distinguish read-only inspection from a repeat click. Prefer direct code over generalized runtime abstractions until multiple flows reveal the same stable contract.

## 2. Make the shell and durability honest

One workable local loop, with an existing durable store or workflow engine as authority:

```text
receive input / observation -> validate identity, source, order, permissions
load authoritative state -> decide(state, event)
atomically commit next state + any new pending intent(s) where possible
for each committed intent, recheck dispatch preconditions and record attempt
execute once through the appropriate adapter; collect what it can establish
feed result / observation / uncertainty back as a new event
```

The ordering of `record attempt` and `execute` does **not** solve the atomicity gap: a crash after recording may mean no dispatch; a crash after execution may mean the effect happened with no recorded outcome. If an intent is found pending or attempted at restart, classify its retry policy. Reissue only when the destination provides a stable idempotency key with a documented scope, or the operation is demonstrably safe to repeat; otherwise reconcile external state or ask a human. An outbox atomically couples database state and a message intent, but its relay can publish twice. A workflow engine's deterministic replay does not make an activity/browser click exactly-once. A read may also have observable effects (e.g., screenshot downloads); model what matters for the use case.

Give the machine a **step convention**: which owner serializes inputs, what an input batch means, when generated internal events run relative to new external inputs, and whether an effect outcome is handled before the next request. For concurrent/orthogonal substates, define how simultaneous enabled transitions are resolved and prohibit unbounded internal event cycles; do not assume a diagram, queue, or `async` callback implicitly defines this. Distinguish an instantaneous *decision to start work* from a long-running activity that later reports an outcome. Harel's statechart semantics (§§5, 7) make these ambiguities explicit; the runtime still needs a concrete ordering rule.

Do not persist every micro-step by default. Persist precisely what is necessary to prevent incorrect recovery, explain past decisions, and satisfy retention needs. If using event sourcing, version event schemas and transition semantics and define migration/snapshot/replay policy; a snapshot with a compact outcome history is often sufficient. Never accidentally run adapters while rebuilding state.

## 3. Observability as causal evidence

For meaningful interactions, capture an ordered envelope (structured data, not necessarily a full event store): `run_id`, `event_id`/sequence within the owner, `caused_by`, `action_id`, `attempt`, source, event type/schema version, state before/after or a state reference, intent kind, target/precondition reference, adapter result, observation/evidence reference, and outcome category. Record wall time for diagnostics, but use sequence and causal IDs for ordering. Correlate spans across process boundaries; logs/traces are diagnostic views, not the authoritative workflow store. Preserve missing data as missing; do not reconstruct it by guesswork.

Classify outcomes separately: not dispatched; dispatched and observed; dispatched with observation disproving the postcondition; dispatched with outcome unknown; denied/expired/stale; adapter failure with dispatch status unknown. Define observable success independently of the tool's return value and of the human's ultimate goal. Avoid storing page text, tokens, form values, or screenshots by default when a structured observation or restricted reference suffices.

## 4. Verification matrix

- **Reducer:** each legal transition, stale/duplicate/late event, cancellation/timeout race, and invariants such as “no dispatch without current grant.” Check emitted intents and next state, not only final state.
- **Specification:** enumerate input kinds and explicitly choose reject/ignore/defer for unhandled ones. Do not fill in an unspecified transition for convenience and then claim unchanged behavior: Mealy's partially specified machines can admit multiple non-equivalent completions (§4.4).
- **Adapter:** fake or fixture I/O to check that one intent maps to the correct external operation and a typed observation/error; execute the affected real flow end-to-end as practical.
- **Recovery:** inject a stop before the intent commit, between commit and dispatch, immediately after dispatch, and before recording observation. Assert that restart never invents a success or blindly repeats an ambiguous non-idempotent effect.
- **Exploration:** generate sequences of valid and invalid events and shrink failures; report which operations/states the generator actually exercised (a passing suite may omit an entire API). First settle sequential discrepancies; then generate parallel histories and look for a legal interleaving when that is the contract. Also check post-run invariants: Hughes found data corruption despite plausible operation results (§4). The model and implementation can share a bug, so compare against an independently stated requirement and an external observation.
- **Replay:** feed recorded inputs to the reducer with effects disabled; compare state and intent sequence for the specified version. Recorded observations can explain a past decision, but cannot recreate the browser/site's prior state or prove a remote action occurred.

See [sources.md](sources.md) for the origins of these practices and where each applies.
