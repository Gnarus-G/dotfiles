# AMD GPU Driver Setup (Out of Scope)

This skill enforces a user-only Ollama workflow and does not run system driver installation steps.

ROCm/driver setup usually needs administrator privileges and must be completed outside this skill.

## Required Check Before Using This Skill

```bash
rocminfo
```

If `rocminfo` does not show your AMD GPU, fix ROCm first and then return to this skill.
