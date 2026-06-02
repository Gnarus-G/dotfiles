---
name: readable
description: "Format a response for low cognitive load and easy visual tracking — short paragraphs, conclusion-first, bullets over prose, generous whitespace. Use when the user asks to make output more readable/scannable, reduce cognitive load, mentions ADHD or tracking/focus, asks to reformat a wall of text, or invokes /readable."
license: MIT
compatibility: opencode
metadata:
  audience: everyone
  workflow: communication-formatting
---

# Readable

Format output so a sharp reader never has to *work* to parse it. The usual
failure for ADHD readers is **tracking** — losing your place in dense text —
not comprehension. Optimize layout for that.

## Core rules

- **Conclusion first.** Lead with the answer, then the reasoning.
- **Short paragraphs** — 1-3 sentences. Never a wall of text.
- **One idea per paragraph.** Introduce concepts one at a time.
- **Bullets over prose** for any set of facts, options, or steps.
- **Numbered lists** for ordered procedures.
- **Short, direct sentences.** Active voice. Cut hedges ("generally",
  "typically", "it's worth noting").
- **Whitespace is free.** Blank line between distinct ideas.
- **Bold key terms only.** Avoid italics and bullet nesting deeper than one
  level. Skip tables unless they clearly beat prose.
- **Headings** once the response runs past ~5 paragraphs.

## For code

- Show the code first, explain after.
- Keep examples small.
- Explain in bullets, not paragraphs.

## Scale to length

- One-line question → one-line answer. Do not pad short replies with headings.
- Long technical answer → use sections: **Summary**, then details, then an
  optional **Example**.
- When forced to trade off, favor scanability and clarity over completeness.
  Push less-important detail into a closing note, not the main flow.

## When reformatting existing text

1. Pull the conclusion to the top.
2. Break long paragraphs apart — one idea each.
3. Convert any "X, Y, and Z" list-in-prose into bullets.
4. Add headings if it runs long.
5. Delete hedges and filler.
