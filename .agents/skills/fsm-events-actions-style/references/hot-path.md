# Allocation-free hot path for event -> state -> intent systems

Use this variant only for a **measured** latency/throughput-critical path. First state the boundary and budget: e.g., “from an already-decoded event to a published intent, 0 application heap allocations per event, bounded CPU time and memory, under N concurrent producers.” Include decoding, queueing, correlation, and telemetry in the measurement if they are inside that boundary. Startup allocation and slower I/O/reconciliation can occur elsewhere; a “zero allocation” claim about browser/OS/network calls or the entire process is usually false.

## Preserve the behavioral contract

Keep the same accepted events, legal transitions, preconditions, ordering, intent IDs, and `Unknown` outcomes as the regular machine. A hot-path `&mut State` transition may mutate **owned, preallocated** state rather than returning a new heap object; it is still deterministic for the same state and input. Differentially test both representations over the same event sequences and compare states and intents. Do not remove validation or silently retry/drop work to meet a latency target.

```rust
#[derive(Clone, Copy, PartialEq, Eq)]
enum Phase { Ready, Pending, Awaiting, Uncertain, Observed }

#[derive(Clone, Copy)]
struct State { phase: Phase, action_id: u64 }

#[derive(Clone, Copy)]
enum Event {
    Requested { id: u64 },
    DispatchStarted { id: u64 },
    ReceiptObserved { id: u64 },
    OutcomeUnknown { id: u64 },
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum Intent { Dispatch { id: u64 }, Reconcile { id: u64 } }

struct InvalidEvent;

fn step(state: &mut State, event: Event) -> Result<Option<Intent>, InvalidEvent> {
    match (state.phase, event) {
        (Phase::Ready, Event::Requested { id }) => {
            state.phase = Phase::Pending;
            state.action_id = id;
            Ok(Some(Intent::Dispatch { id }))
        }
        (Phase::Pending, Event::DispatchStarted { id }) if state.action_id == id => {
            state.phase = Phase::Awaiting;
            Ok(None)
        }
        (Phase::Awaiting, Event::OutcomeUnknown { id }) if state.action_id == id => {
            state.phase = Phase::Uncertain;
            Ok(Some(Intent::Reconcile { id }))
        }
        (Phase::Awaiting | Phase::Uncertain, Event::ReceiptObserved { id })
            if state.action_id == id => {
                state.phase = Phase::Observed;
                Ok(None)
            }
        _ => Err(InvalidEvent),
    }
}
```

This is the **decision only**, with one optional intent per step. It uses only fixed-size values; it does not perform I/O or allocate a `Vec`, `String`, boxed error, or formatted log per event. A real adapter must still handle failed dispatch and inconclusive inspection explicitly. The caller owns `State` and supplies IDs before the step. Measure this code in a release build rather than assuming the compiler or downstream adapters preserve allocation behavior.

## Bound the surrounding pipeline

1. Allocate fixed-capacity event/intent/trace-record storage before entering the hot loop; pass numeric IDs and fixed-width or borrowed payload views with explicit lifetimes. Specify maximum sizes and what happens to oversized inputs. No per-event `format!`, `to_string`, cloning variable data, `Vec` growth, or heap-owning errors on the hot path.
2. Prefer a single writer per state owner. Process directly on that thread when no cross-thread queue is needed. If crossing threads is measured necessary, use a **proven bounded** queue/ring with preallocated slots and defined publication/visibility order; never overwrite an unconsumed intent or confuse a volatile ring with a durable journal. Cache-line layout and busy-spin vs blocking wait are workload-dependent, not universal defaults.
3. Define full-buffer behavior before coding it: backpressure, reject **before accepting the event**, or explicitly mark a lossy **diagnostic** record dropped with a counter. Accepted effect intents and required recovery evidence cannot simply disappear. A bounded buffer provides bounded memory, not bounded latency if its consumer, storage, or network stalls.
4. Separate fixed-width hot-path records (`seq`, `event_kind`, `state_kind`, `intent_kind`, `action_id`, `outcome`) from formatting/enrichment/export on a slower consumer. Correlate by sequence/ID. If durable intent-before-dispatch is required, gate dispatch on the journal's actual durability acknowledgment, not on publication to a memory ring or sampled trace; this gate may dominate latency, and batching changes acknowledgment semantics.
5. In JS/TypeScript, reuse buffers/typed arrays or preallocated slot objects and move formatting away from the hot callback, **but do not promise zero allocations** across a JS engine, `async`/`await`, or Effect without profiling the exact runtime and version. Rust/C/C++ with fixed-size values make an application-level no-heap boundary easier to specify, but allocations in adapters and system libraries must still be measured.

## Evidence required for a performance claim

- Profile the **real** path before changing representation; report allocation count/bytes per event, throughput, p50/p99/p99.9 latency, CPU, queue depth, and producer/consumer rates under normal and burst load. Run warm-up, release/optimized builds, and a baseline on the same hardware.
- Exercise the worst legal payload, queue-full path, invalid input, slow consumer, and effect-unknown recovery; show that performance work did not change ordering, correctness, or evidence retention. Count allocations over repeated calls **after setup** and inspect profiles; Rust's `GlobalAlloc` documentation warns the compiler may eliminate or merge allocations, so allocator counters alone are not a proof of source-level behavior.
- If tuning cross-thread publication, verify memory ordering and race behavior with the chosen queue's guarantees and concurrency tests. A custom lock-free ring is a separate correctness project. If the allocator count is zero but throughput or tail latency worsens, the optimization did not meet its goal.

**Basis:** [LMAX Disruptor technical paper, §§2–3](https://lmax-exchange.github.io/disruptor/disruptor.html) and [implementers' user guide](https://lmax-exchange.github.io/disruptor/user-guide/) for single-writer ownership, preallocation, bounded sequencing/backpressure, batching and dependency ordering; [Rust `GlobalAlloc` documentation](https://doc.rust-lang.org/std/alloc/trait.GlobalAlloc.html) for measurement limits. Their published benchmarks are workload/hardware-specific; this reference does not promise those numbers for another system.
