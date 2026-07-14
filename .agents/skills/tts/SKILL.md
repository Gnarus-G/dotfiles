---
name: tts
description: Speak brief text aloud through the local gnarus-tts engine without exposing TTS as an MCP tool. Use for audible completion announcements after multi-step work, or when the user asks to say, speak, or read something aloud.
compatibility: Linux with gnarus-tts installed and audio available through the user session.
---

# TTS

Speak a short, plain-language announcement with the standalone CLI:

```bash
gnarus-tts "Finished updating and verifying the configuration."
```

The command waits until playback finishes. It reads the existing Himither voice/backend settings and model files for compatibility, but does not start or communicate with an MCP server.

## Rules

- Announce completion only after a multi-step task is fully finished.
- Keep announcements to one short sentence.
- State the outcome, not the implementation history.
- Remove Markdown, code syntax, file paths, emoji, and other non-speech symbols.
- Pass text as a quoted argument; never interpolate it into shell source.
- Invoke `gnarus-tts` directly; do not use `tts-mcp`, a skill wrapper, or an MCP tool.
- Treat a nonzero exit as a failed announcement, not as a failed underlying task.
