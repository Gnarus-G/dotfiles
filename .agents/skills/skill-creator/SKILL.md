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

1. **Choose a unique skill name** - Must be lowercase alphanumeric with hyphens, 1-64 chars
2. **Ask the user if it should be global or project local**
3. **Create the directory structure**
   - Global: `~/.config/opencode/skills/<name>/`
   - Project-local: `.opencode/skills/<name>/`
4. **Write frontmatter** - Include `name`, `description`, and optional fields
5. **Add skill content** - Use markdown to document the skill's purpose and usage
6. **Validate the skill** - Ensure proper naming and frontmatter format

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

1. `.opencode/skills/<name>/SKILL.md` (project-local)
2. `~/.config/opencode/skills/<name>/SKILL.md` (global)
3. `.claude/skills/<name>/SKILL.md` (project Claude)
4. `~/.claude/skills/<name>/SKILL.md` (global Claude)
5. `.agents/skills/<name>/SKILL.md` (project agent)
6. `~/.agents/skills/<name>/SKILL.md` (global agent)

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

## Validation checklist

- [ ] Skill name follows naming rules
- [ ] Frontmatter includes required fields
- [ ] Description is specific and helpful
- [ ] Content is well-organized and actionable
- [ ] Skill is placed in correct discovery location
- [ ] Permissions are configured appropriately

## Examples

See other skills in the `.opencode/skills/` directory for examples of effective skill creation.
