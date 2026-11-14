---
name: draft-msg
description: Draft a message for the user to paste into Slack, email or a GitHub issue to a vendor, teammate or boss. Use when told "draft a message", "give me something to send", "write that up for <person>", "a slack message saying…", or "nudge them".
---

# draft-msg

The user pastes the draft directly. Make the draft artifact ready to paste,
nested under a labeled evidence-first item; labels belong outside the artifact.

## Rules

- **Plain text you can copy.** Keep the draft verbatim inside its labeled
  artifact, with no commentary or evidence labels inside the message itself.
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

Put the complete message under a labeled **Conclusion/Claim C1** item as a
proposed draft, citing the user's requirements or verified facts that support
it. Add a labeled Premise for any substantive assumption or a targeted Question
if the user's decision is necessary. Keep these outside the draft artifact.
