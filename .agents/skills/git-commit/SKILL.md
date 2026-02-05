---
name: git-commit
description: Generate high-quality commit messages for staged changes. Use when committing code, creating commits, or when the user asks to commit changes. Always confirms with user before committing.
---

# Git Commit

Generate well-structured commit messages for staged changes following best practices.

## Mandatory Confirmation

**CRITICAL: You MUST ask the user for confirmation before EVERY commit.** There are no exceptions to this rule. Never commit without explicit user approval, even if the user previously said "commit this" - always present the generated message and ask for confirmation first.

## Commit Message Format

Follow these rules strictly:

- **Subject line**: Maximum 50 characters, imperative verb (e.g., "Add frontend unit tests")
- **NO type prefixes**: Do not use "feat:", "fix:", "refactor:", "chore:", etc.
- **Body**: Explain "what" and "why", not "how", wrapped at 72 characters
- **Footer**: References like "Fixes #123", "Closes #456", or "BREAKING CHANGE: ..." (only if applicable)

### Format Template

```
<subject line - max 50 chars, imperative verb>

<body - what changed and why, wrapped at 72 chars>

<footer - issue references or breaking changes, if applicable>
```

## Process

### Step 1: Check for Staged Changes

```bash
git diff --staged --quiet && echo "No staged changes" || echo "Changes staged"
```

If no staged changes exist, inform the user and ask if they want to stage changes first.

### Step 2: Analyze the Diff

```bash
# View staged changes
git diff --staged

# Also check recent commits for context and style
git log --oneline -5
```

Understand:
- What files are modified
- The nature of changes (new feature, bug fix, refactor, etc.)
- Any patterns in recent commit messages

### Step 3: Generate Commit Message

Based on the diff analysis, generate a commit message following the format rules:

1. Write a clear subject line (max 50 chars, imperative mood, no type prefix)
2. Add a body explaining what changed and why (wrapped at 72 chars)
3. Include footer references if the changes relate to issues/tickets

### Step 4: Present and Confirm

**This step is mandatory.** Present the generated message to the user:

```
I've generated this commit message:

---
<subject>

<body>

<footer if applicable>
---

Should I commit with this message?
```

Wait for explicit user approval. Accept responses like:
- "yes", "y", "commit", "looks good", "go ahead" → Proceed to commit
- "no", "n", "cancel", "abort" → Do not commit
- Edits or suggestions → Incorporate feedback, then ask again

### Step 5: Execute Commit

Only after receiving explicit approval:

```bash
git commit -m "<subject>" -m "<body>" -m "<footer>"
```

Or for messages without footer:

```bash
git commit -m "<subject>" -m "<body>"
```

Verify the commit succeeded:

```bash
git log -1 --oneline
```

## Examples

### Good Commit Messages

**Simple bug fix:**
```
Fix null pointer in user authentication

The login handler assumed user.email was always present, but OAuth
providers don't always return an email. Added null check and fallback
to username for display purposes.

Fixes #234
```

**New feature:**
```
Add CSV export for analytics dashboard

Users can now export their analytics data as CSV files. The export
includes all metrics visible in the current view with proper date
formatting and handles large datasets through streaming.
```

**Refactoring:**
```
Extract validation logic to shared module

Moves duplicate input validation from three API endpoints into a
reusable validator class. No behavior change, but reduces code
duplication and makes validation rules easier to maintain.
```

**Documentation:**
```
Document API rate limiting behavior

Adds rate limit headers and error responses to API documentation.
Includes examples for handling 429 responses with exponential backoff.
```

### Bad Commit Messages (Avoid These)

```
feat: update code          # Has type prefix, vague
Fixed stuff                 # Past tense, vague
WIP                        # Not descriptive
asdfasdf                   # Meaningless
Update user.js             # Describes file, not change
```

## Guidelines

- **Atomic commits**: Each commit should represent one logical change
- **Present tense, imperative mood**: "Add feature" not "Added feature" or "Adds feature"
- **No periods in subject line**: Save the period for the body
- **Blank line between subject and body**: Required for proper formatting
- **Wrap body at 72 characters**: Standard convention for readability
- **Reference issues in footer**: Use "Fixes #123" or "Closes #456" format

## When to Split Commits

If the staged changes include multiple unrelated modifications, suggest splitting into separate commits:

```bash
# Unstage everything
git reset HEAD

# Stage related changes interactively
git add -p

# Commit the first logical unit
# ... then repeat for remaining changes
```

## Integration with PR Workflow

After committing, if the user wants to create a PR, invoke the create-pr skill:

```
skill({ name: "create-pr" })
```
