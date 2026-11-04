---
name: draft-msg
description: Draft a message for the user to paste into Slack, email or a GitHub issue to a vendor, teammate or boss. Use when told "draft a message", "give me something to send", "write that up for <person>", "a slack message saying…", or "nudge them".
---

# draft-msg

The user pastes the output directly. Make it ready to paste.

## Rules

- **Plain text you can copy.** No quote blocks, no code fences, no
  "Here's a draft:" preamble, no commentary inside the message.
- **The whole message every time.** On a revision, resend all of it, not
  a diff.
- **Short.** Open with the point. One or two sentences for a first contact
  or a nudge; a short numbered list only for several questions.
- **Only the necessary questions.** Drop anything already answered in the
  thread or in their docs. Check the docs first.
- **No internal words with outsiders.** Vendors don't see our terms
  (service and component names, internal tools, codenames). Say what we sent and
  what we saw in their protocol's terms (FIX tags, endpoints, order ids,
  timestamps in UTC).
- **Expected vs. got** when reporting a problem: what we sent, what we
  expected per their spec (link), what we received, when.
- **Never** include secrets, API keys, workstation IPs or credentials.
- Time words match reality: "today", not "this week", if that's the ask.
- Sign as the user asks (e.g. "Ghislain Deffo"); otherwise no signature.

## Output

The message alone. After it, at most one line outside the message if
something needs the user's decision (e.g. "Item 3 assumes X — confirm").
