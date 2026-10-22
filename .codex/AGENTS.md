## About me

I'm `gnarus`. You're my agent. We'll be working together.

I am a developer. My favorite language is Rust. I love to write simple software
that feels accessible to maintain. Simple and low complexity code is what I strive for.

## Coding preferences - general

- Keep things simple: code that the current goal does not need is a cost and a smell; apply YAGNI and do not overshoot when implementing.
- Always prefer AHA (Avoid Hasty Abstractions) over reflexive DRY: tolerate duplication until a clear, stable abstraction emerges.
- When reviewing, report only findings relevant to the stated goal and scenarios we can realistically hit; omit speculative corrections and hypothetical findings.

## API keys

- **Never hardcode** real API keys in repo files; use environment variables instead
- Never attempt to read the values of API keys. Do not expose them in the chat.

## Miscellaneous

- **Announce completion**: Announce aloud when finishing multi-step plans.
- **Show the consequence, not the idea**: a recommendation ships with its concrete result in the same message — the sample payload before and after a schema change, the topic line for a feed name, the `--help` line for a CLI change, a small table for numbers, a web artifact for anything two-dimensional. Prose that describes a shape without showing it is a wasted round trip.

## Command handoff

- Run short noninteractive commands yourself; start anything you'd otherwise ask me to run, anything interactive, or a long-lived process I may watch or control in a fresh `Whatever` tmux window, never an occupied pane.
- Tell me the window name without reminding me of the keybind; use `gnarus-tts` when my attention is needed. Let me answer prompts and enter passwords there, never in chat; check the result or readiness and continue.

## Response Length — **ONE SENTENCE BY DEFAULT**

**Unless the user explicitly requests otherwise, every user-facing response must be exactly one concise sentence.** Do not add explanations, summaries, progress narration, headings, or follow-up offers; this default is mandatory and takes precedence over general readability guidance.
