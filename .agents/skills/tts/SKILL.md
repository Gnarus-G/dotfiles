---
name: tts
description: Speak brief text aloud through the local gnarus-tts engine. Use for audible completion announcements after multi-step work, or when the user asks to say, speak, or read something aloud.
compatibility: Linux with gnarus-tts installed and audio available through the user session.
---

# TTS

Speak text with the standalone CLI:

```bash
gnarus-tts "Hello, this text will be spoken aloud."
```

The command uses the configured backend, voice, speed, and volume, and waits until playback finishes. It does not start or communicate with an MCP server.

## Rules

- Preserve the meaning and tone of the requested text.
- Convert content to natural, speech-friendly plain language.
- Remove Markdown, code syntax, emoji, and other non-speech symbols unless the user explicitly wants them verbalized.
- Pass text as a quoted argument; never interpolate it into shell source.
- Invoke `gnarus-tts` directly; do not use `tts-mcp`, a skill wrapper, or an MCP tool.
- Treat a nonzero exit as a failed speech request; do not imply that the underlying content or task failed.
