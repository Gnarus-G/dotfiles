# Actors as concurrent state owners

Use actors when **independent state owners need concurrent progress** and message passing is a good boundary: for example, one actor per active session, device, or workflow. Each actor owns its state and handles one mailbox message at a time; different actors can run concurrently. A single event loop or serialized store is enough if it already provides the needed ownership and ordering. Do not create an actor per request when there is no persistent state or concurrency problem to solve.

Inside an actor, the same contract can apply:

```text
mailbox message / timer / effect outcome -> event
decide(actor_state, event) -> (next_actor_state, intents)
actor shell records state/intents as required, then interprets intents
I/O or another actor's reply -> new message/event
```

The actor provides **serialization and ownership**, not reducer purity automatically: keep `decide` free of sends, I/O, clocks, and mutable external state. The shell sends messages, starts timers, or delegates I/O according to returned intents; it routes results back to the owning actor as events. Keep long-running I/O out of the mailbox handler so other messages can be processed; correlate each result with the initiating intent and reject stale results after state changes.

Choose a key for ownership and state invariants (for example, session ID). Define ordering **within** an actor and the protocol **between** actors: messages from different senders need not have a global order, and a reply may arrive after a timeout or restart. Include message/intent IDs and versions where needed; handle duplicates, late replies, actor replacement, and mailbox overload with explicit policy. Cross-actor invariants require coordination or a shared transactional authority; serial processing by separate actors does not make their combined state atomic.

An actor mailbox is not inherently a durable journal. If recovery matters, persist the transition and pending intents with the chosen authority before dispatch, or use the durable workflow/store already in charge; after a crash, reconcile ambiguous external effects rather than assuming a restarted actor can safely resend them. Runtime-specific guarantees for ordering, delivery, supervision, and backpressure must be checked rather than inferred from the word “actor.”

Erlang processes and OTP `gen_statem` show serialized process-local state and callbacks returning transition actions; Akka's actor guide explains concurrent actors with sequential processing per actor. OTP transition actions such as replies/timeouts are runtime instructions, not automatically durable external-effect intents; see [sources.md](sources.md).
