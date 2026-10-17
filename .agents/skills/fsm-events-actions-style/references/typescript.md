# TypeScript: state transitions and effect interpreters

Use discriminated unions for states, incoming events, and intended effects; keep `decide` synchronous and free of I/O. At the boundary, parse/validate untrusted values before constructing events. Use a serial owner for each run so transitions and committed intents have a defined order. This pattern needs only TypeScript; an Effect runtime is optional.

## Plain TypeScript

Example: request a message, dispatch it once, then inspect whether a provider receipt is visible. The receipt is evidence of provider acceptance, **not** proof the recipient read it. This example shows the decision contract; it omits authorization, data validation, storage implementation, and a real provider.

```ts
type State =
  | { tag: "ready" }
  | { tag: "pending"; id: string }
  | { tag: "awaitingReceipt"; id: string }
  | { tag: "uncertain"; id: string }
  | { tag: "receiptObserved"; id: string }

type Event =
  | { type: "Requested"; id: string; target: string }
  | { type: "DispatchStarted"; id: string }
  | { type: "DispatchReturned"; id: string }
  | { type: "DispatchUnknown"; id: string }
  | { type: "ReceiptObserved"; id: string }
  | { type: "InspectionInconclusive"; id: string }

type Intent =
  | { type: "send"; id: string; target: string }
  | { type: "inspect"; id: string }

function decide(state: State, event: Event): readonly [State, readonly Intent[]] {
  if (state.tag === "ready" && event.type === "Requested") {
    return [{ tag: "pending", id: event.id },
      [{ type: "send", id: event.id, target: event.target }]]
  }
  if (state.tag === "pending" && event.type === "DispatchStarted" && state.id === event.id) {
    return [{ tag: "awaitingReceipt", id: event.id }, []]
  }
  if (state.tag === "awaitingReceipt" && event.type === "DispatchReturned" && state.id === event.id) {
    return [state, [{ type: "inspect", id: event.id }]]
  }
  if (state.tag === "awaitingReceipt" && event.type === "DispatchUnknown" && state.id === event.id) {
    return [{ tag: "uncertain", id: event.id }, [{ type: "inspect", id: event.id }]]
  }
  if ((state.tag === "awaitingReceipt" || state.tag === "uncertain") && state.id === event.id) {
    if (event.type === "ReceiptObserved") return [{ tag: "receiptObserved", id: event.id }, []]
    if (event.type === "InspectionInconclusive") return [{ tag: "uncertain", id: event.id }, []]
  }
  throw new Error(`Invalid transition: ${state.tag} + ${event.type}`)
}

interface Provider {
  send(id: string, target: string): Promise<void>
  hasReceipt(id: string): Promise<boolean>
}

async function interpret(intent: Intent, provider: Provider): Promise<Event> {
  if (intent.type === "send") {
    try {
      await provider.send(intent.id, intent.target)
      return { type: "DispatchReturned", id: intent.id }
    } catch {
      // A timeout/rejection cannot establish that the message was not sent.
      return { type: "DispatchUnknown", id: intent.id }
    }
  }
  try {
    const found = await provider.hasReceipt(intent.id)
    return { type: found ? "ReceiptObserved" : "InspectionInconclusive", id: intent.id }
  } catch {
    return { type: "InspectionInconclusive", id: intent.id }
  }
}
```

The shell must **atomically commit the new state and pending intents** before interpreting them when crash recovery matters. Before `provider.send`, durably feed `DispatchStarted` through the same transition path; if that commit fails, do not send. After `interpret`, commit the returned event, which may emit an `inspect` intent. On restart, an unresolved `pending` or `awaitingReceipt` means **reconcile first**: a crash before/after the external call may look identical locally. Never infer that `pending` is safe to re-send. Provide a per-run queue, existing workflow journal, or other single authority rather than relying on module globals; in-memory state is fine only when recovery is not required. This is a lifecycle sketch, not a ready-made exactly-once dispatcher.

## If the project already uses Effect

Keep `decide` unchanged: `Effect` describes and executes **I/O at the shell**, not the decision to do I/O. For Effect **v4**, the `send` branch above can instead be interpreted with `Effect.tryPromise`, with a mapped typed outcome and an optional trace span:

```ts
import { Effect } from "effect"

function sendWithEffect(intent: Extract<Intent, { type: "send" }>, provider: Provider) {
  return Effect.tryPromise({
    try: () => provider.send(intent.id, intent.target),
    catch: () => new Error("dispatch outcome unknown"),
  }).pipe(
    Effect.map((): Event => ({ type: "DispatchReturned", id: intent.id })),
    Effect.catch(() => Effect.succeed<Event>({ type: "DispatchUnknown", id: intent.id })),
    Effect.withSpan("message.dispatch"),
  )
}

// At the application boundary, after durably recording DispatchStarted:
// const outcome = await Effect.runPromise(sendWithEffect(intent, provider))
// Then commit outcome as an input event through decide.
```

`Effect.Effect<Success, Error, Requirements>` tracks expected errors and dependencies and its runtime interprets the program. Services/Layers can substitute adapters when an application already benefits from them; `Effect.withSpan` adds diagnostic correlation. Neither `Effect.runPromise`, a Layer, a span, cancellation, nor `Effect.retry` makes external effects atomic with local state or safe to repeat. Model interrupted/failed dispatches as unknown until reconciled, and do not assume a failed fiber means the provider did nothing. For a small TypeScript app that does not use Effect, `async`/`await` plus an injected `Provider` is enough; avoid installing a framework solely to get this shape.

**Versioned API sources (Effect v4):** [creating effects / `tryPromise`](https://effect.website/docs/v4/getting-started/creating-effects/), [runtime / `runPromise`](https://effect.website/docs/v4/runtime/), [tracing / `withSpan`](https://effect.website/docs/v4/observability/tracing/). Check the project's installed Effect version and its docs before copying an API; v3 and v4 differ in some service/error handling signatures.
