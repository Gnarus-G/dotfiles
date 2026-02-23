---
description: Generate commit message for staged changes
---

Analyze the staged git changes and generate a well-structured commit message following these rules:

**Commit Message Format:**
- **Subject line**: Maximum 50 characters, imperative verb (e.g., "Add frontend unit tests")
- **NO type prefixes**: Do not use "feat:", "fix:", "refactor:", "chore:", etc.
- **Body**: Explain "what" and "why", not "how", wrapped at 72 characters
- **Footer**: References like "Fixes #123", "Closes #456", or "BREAKING CHANGE: ..." (only if applicable)

**Format:**
```
<subject line - max 50 chars, imperative verb>

<body - what changed and why, wrapped at 72 chars>

<footer - issue references or breaking changes, if applicable>
```

**Current staged changes:**
!`git diff --staged`

**Recent commit messages for style context:**
!`git log --oneline -5`

**CRITICAL INSTRUCTIONS:**
1. First check if there are staged changes. If `git diff --staged` shows no output, inform the user there are no staged changes and ask if they want to stage files first.
2. Generate the commit message based on the diff analysis.
3. **PRESENT the generated message to the user and ask for explicit confirmation before committing.**
4. Only commit after the user approves with responses like "yes", "y", "commit", "looks good", or "go ahead".
5. If the user provides edits or suggestions, incorporate them and ask again.
6. If the user says "no", "n", "cancel", or "abort", do not commit.

**Guidelines:**
- Atomic commits: Each commit should represent one logical change
- Present tense, imperative mood: "Add feature" not "Added feature"
- No periods in subject line
- Blank line between subject and body
- Wrap body at 72 characters
- Reference issues in footer with "Fixes #123" or "Closes #456" format

If staged changes include multiple unrelated modifications, suggest splitting into separate commits.
