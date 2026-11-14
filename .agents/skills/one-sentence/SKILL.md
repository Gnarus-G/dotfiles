---
name: one-sentence
description: Explain a topic in a single concise sentence. Use when user says "one sentence", "in a nutshell", "elevator pitch", "tl;dr", "summarize in one line", or "explain briefly".
---

# One-Sentence

## Goal

Deliver the single most pertinent supported answer as one labeled sentence.
Preserve the always-on evidence-first format: use **Fact F1** with inline
evidence, **Premise P1** with an attributed assumption, **Question Q1**, or
**Conclusion/Claim C1** with support and uncertainty. Do not drop necessary
evidence or qualifications merely to meet the length preference.

## Workflow

1. **Identify the core claim** — what does the user actually need to know to act or understand?
2. **Drop irrelevant detail** — retain evidence and qualifications needed for accuracy.
3. **Front-load the answer** — conclusion first, no preamble ("The answer is...", "In short...").
4. **Ask if unsure** — if the topic has multiple valid framings or missing context, ask one clarifying question instead of guessing.

## Rules

- **One sentence**, ending in exactly one period (or question mark if you're asking for clarification).
- **Flexible length**: 10-30 words. Stretch to two short sentences only if technical accuracy demands.
- **Active voice, concrete words.** Keep uncertainty when the evidence requires it.
- **No preamble.** Skip "The answer is", "Here is", "In summary".
- **If unsure, ask.** One targeted question beats a wrong sentence.

## Examples

| User asks                 | Response                                                                                      |
| ------------------------- | --------------------------------------------------------------------------------------------- |
| Missing context?         | **Question Q1:** Which repository should I inspect? |
| A user-stated constraint? | **Premise P1:** The change must preserve the CLI, as you requested. |

These examples illustrate formatting; they are not evidence for other claims.

## When to Ask

Ask one question when:

- The topic is genuinely ambiguous (e.g. "explain databases" — SQL? NoSQL? Embedded?)
- Choosing the wrong framing would mislead (e.g. "explain futures" — finance? Rust?)
- You lack a key piece of context (e.g. user's experience level)

**Bad ask**: "Do you want a short or long answer?"
**Good ask**: "**Question Q1:** SQL or NoSQL — which one?"
