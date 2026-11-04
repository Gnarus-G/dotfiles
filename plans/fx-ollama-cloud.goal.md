# fx Ollama Cloud

Goal: Manage fx's Ollama Cloud connection in this dotfiles repository, like Pi's configuration.
Done when: A tracked settings source is merged by the installer on all machines, focused tests and previews pass, and fx loads the installed connection successfully.

## Facts
- Pi's shared Ollama Cloud configuration is `.pi/agent/models.json`.
- Credentials remain in `OLLAMA_API_KEY`, never in tracked files.
- The user selected `ollama-cloud`; the latest live settings select `beam`, which must be preserved.
- Configuration must be repository-managed, not only a standalone home-directory edit.
- fx rejects symlinked settings with `durable_path_unsafe`; install by merge, preserving unrelated local settings.

## Out of scope
- Changing unrelated agent settings or making live model requests.

## Corrections log
- 2026-11-04: Configured only `~/.fx/settings.json`; user: "it should not have been outside."
