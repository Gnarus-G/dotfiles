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

## Command handoff

- If you would otherwise ask me to run a command, put the actual command in a fresh shell window in my `Whatever` tmux session and start it there instead of making me copy and paste it. Do the same for interactive commands (passwords, confirmations, yes/no prompts) and long-lived commands I may need to watch or control, such as dev servers.
- Never interrupt an occupied pane. Identify the new window for me without reminding me of the keybind; use `gnarus-tts` to call me over when my input or attention is needed and it is available.
- Let me enter passwords and answer prompts in the window, never in chat; then check the command's result or readiness and continue the task.
