---
name: one-sentence
description: Explain a topic in a single concise sentence. Use when user says "one sentence", "in a nutshell", "elevator pitch", "tl;dr", "summarize in one line", or "explain briefly".
---

# One-Sentence

## Goal

Deliver the **single most pertinent fact** as one sentence. Prioritize relevance over completeness.

## Workflow

1. **Identify the core claim** — what does the user actually need to know to act or understand?
2. **Drop everything else** — examples, caveats, qualifications, history go to follow-up only if asked.
3. **Front-load the answer** — conclusion first, no preamble ("The answer is...", "In short...").
4. **Ask if unsure** — if the topic has multiple valid framings or missing context, ask one clarifying question instead of guessing.

## Rules

- **One sentence**, ending in exactly one period (or question mark if you're asking for clarification).
- **Flexible length**: 10-30 words. Stretch to two short sentences only if technical accuracy demands.
- **Active voice, concrete words.** No "generally", "typically", "it's worth noting".
- **No preamble.** Skip "The answer is", "Here is", "In summary".
- **If unsure, ask.** One targeted question beats a wrong sentence.

## Examples

| User asks             | Response                                                                                    |
| --------------------- | ------------------------------------------------------------------------------------------- |
| What is RDTSC?        | A CPU instruction that reads the timestamp counter into a register for cycle-precise timing. |
| How does git rebase work? | Replays your local commits on top of a new base commit, rewriting their history.         |
| Why use SvelteKit?    | Combines Svelte's compile-time reactivity with file-based routing, SSR, and server endpoints. |

## When to Ask

Ask one question when:

- The topic is genuinely ambiguous (e.g. "explain databases" — SQL? NoSQL? Embedded?)
- Choosing the wrong framing would mislead (e.g. "explain futures" — finance? Rust?)
- You lack a key piece of context (e.g. user's experience level)

**Bad ask**: "Do you want a short or long answer?"
**Good ask**: "SQL or NoSQL — which one?"
