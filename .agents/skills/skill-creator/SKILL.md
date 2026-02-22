---
name: skill-creator
description: Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Claude's capabilities with specialized knowledge, workflows, or tool integrations.
---

## What I do

- Guide users through creating new skills with proper structure and frontmatter
- Provide templates and examples for common skill patterns
- Help validate skill names and descriptions for OpenCode compatibility
- Offer best practices for skill organization and discovery

## When to use me

Use this when you want to:

- Create a new skill for OpenCode
- Update an existing skill with better structure
- Learn about skill discovery and organization
- Understand skill frontmatter requirements

## How to create a skill

1. **Research the topic/tool** - Use `ez-web-search-mcp_search` and `context7-mcp` tools to gather information about the topic or tool the skill will cover. This ensures the skill content is accurate and comprehensive.
   - Use `context7-mcp_resolve-library-id` then `context7-mcp_query-docs` for library/framework documentation
   - Use `ez-web-search-mcp_search` for general web searches about tools, workflows, or concepts
2. **Choose a unique skill name** - Must be lowercase alphanumeric with hyphens, 1-64 chars
3. **Ask the user if it should be global or project local**
4. **Create the directory structure** (prefer `~/.agents/skills/`)
   - Global: `~/.agents/skills/<name>/` (preferred)
   - Project-local: `.agents/skills/<name>/`
   - Alternative global: `~/.config/opencode/skills/<name>/`
   - Alternative project-local: `.opencode/skills/<name>/`
4. **Write frontmatter** - Include `name`, `description`, and optional fields
5. **Add skill content** - Use markdown to document the skill's purpose and usage
6. **Validate the skill** - Ensure proper naming and frontmatter format

## Researching for skill content

When creating a skill, first gather accurate information about the relevant tool or topic:

### Using context7-mcp for library documentation

For skills about specific libraries or frameworks:

```text
1. Call context7-mcp_resolve-library-id with the library name
2. Use the returned library ID with context7-mcp_query-docs to fetch relevant docs
3. Focus queries on the specific aspects the skill should cover
```

Example: For a React skill, resolve the library ID first, then query for "hooks patterns" or "component lifecycle".

### Using ez-web-search-mcp for general research

For broader topics, tools without Context7 coverage, or workflows:

```text
Call ez-web-search-mcp_search with descriptive queries about best practices,
common patterns, or tool usage.
```

### Tips for effective research

- Be specific in queries to get relevant results
- Cross-reference multiple sources for accuracy
- Include version-specific information when relevant
- Note any security considerations or gotchas

## Skill frontmatter requirements

```yaml
---
name: skill-name
description: Brief description (1-1024 chars)
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: skill-creation
---
```

## Skill naming rules

- Must be 1-64 characters
- Lowercase alphanumeric with single hyphen separators
- Cannot start or end with hyphen
- Cannot contain consecutive hyphens
- Must match directory name

## Discovery locations

Skills are discovered in these locations (in order):

### Preferred locations (use these)

1. `~/.agents/skills/<name>/SKILL.md` (global - preferred)
2. `.agents/skills/<name>/SKILL.md` (project-local)

### Alternative locations (supported for compatibility)

3. `~/.config/opencode/skills/<name>/SKILL.md` (global)
4. `.opencode/skills/<name>/SKILL.md` (project-local)
5. `~/.claude/skills/<name>/SKILL.md` (global Claude)
6. `.claude/skills/<name>/SKILL.md` (project Claude)

**Note:** The `~/.agents/` folder is preferred because it's tool-agnostic and works across different AI coding assistants.

## Permission configuration

Skills can be controlled via `opencode.json` permissions:

```json
{
  "permission": {
    "skill": {
      "*": "allow",
      "internal-*": "deny",
      "experimental-*": "ask"
    }
  }
}
```

## Common skill patterns

- **Tool integration** - Skills that wrap external tools or APIs
- **Domain expertise** - Skills focused on specific domains (testing, deployment, etc.)
- **Workflow automation** - Skills that automate multi-step processes
- **Code generation** - Skills that generate boilerplate or templates

## References folder pattern

For skills with extensive content, consider using a `references/` subdirectory to organize documentation. This pattern improves maintainability and discoverability.

### When to use references

Consider using a references folder when your skill has:

- **Multiple distinct topics** (e.g., installation, configuration, deployment)
- **Long command references** that would clutter the main skill file
- **API documentation** with many endpoints or examples
- **Platform-specific guides** (e.g., Linux vs Windows setup)

### Structure

```
<skill-name>/
├── SKILL.md                 # Main skill with overview and quick reference table
└── references/
    ├── installation.md      # Installation instructions
    ├── configuration.md     # Configuration guide
    ├── commands.md          # Command reference
    └── examples.md          # Usage examples
```

### Main SKILL.md pattern

Include a Quick Reference table linking to reference files:

```markdown
## Quick Reference

| Topic | Description | Reference |
|-------|-------------|-----------|
| **Installation** | How to install the tool | [installation.md](references/installation.md) |
| **Configuration** | Setup and configuration | [configuration.md](references/configuration.md) |
| **Commands** | Command reference | [commands.md](references/commands.md) |

## Essential Commands

Brief overview of most common commands...
```

### Benefits

- **Skimmable main file** - Users can quickly see what's available
- **Focused reference files** - Each file covers one topic in depth
- **Easier maintenance** - Update individual topics without touching everything
- **Better search** - Reference files can be discovered independently

## Validation checklist

- [ ] Researched topic using web search and/or context7-mcp
- [ ] Skill name follows naming rules
- [ ] Frontmatter includes required fields
- [ ] Description is specific and helpful
- [ ] Content is well-organized and actionable
- [ ] Skill is placed in correct discovery location
- [ ] Permissions are configured appropriately
- [ ] Considered using references folder for complex skills

## Examples

See other skills in the `~/.agents/skills/` directory for examples of effective skill creation.
