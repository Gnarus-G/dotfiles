"""Preview intended dotfile links without reading or changing a machine.

The caller supplies a proposed inventory, observed targets (omitted means
absent), and optionally the sources known to exist. Managed observations mean
links owned by this installer; Unmanaged observations are obstacles that must
not be replaced. Link and Remove carry the previously observed source as an
execution precondition. Preserve stages local state before retiring a directory
link; conflicts suppress all effects for that plan. Retiring a directory link
requires a complete contents snapshot.

PROPOSED is a machine-specific inventory; the existing dev script remains
unchanged until the new installer has been exercised separately.
"""

from collections.abc import Collection, Iterable, Mapping
from dataclasses import dataclass
from pathlib import PurePosixPath

from machine_bundle import bundle_source

MACHINES = frozenset({"remote", "home", "work"})


@dataclass(frozen=True)
class Spec:
    source: str
    target: str
    machines: frozenset[str]


@dataclass(frozen=True)
class Managed:
    source: str


@dataclass(frozen=True)
class Unmanaged:
    description: str


@dataclass(frozen=True)
class Remove:
    target: str
    previous: str


@dataclass(frozen=True)
class Preserve:
    target: str
    source: str


@dataclass(frozen=True)
class Link:
    target: str
    source: str
    previous: str | None = None


@dataclass(frozen=True)
class Conflict:
    target: str
    found: str


def _beneath(target: str, parents: Collection[str]) -> bool:
    return any(target.startswith(parent + "/") for parent in parents)


# Machine-specific sources live alongside the existing shared sources.
DESKTOP = frozenset({"home", "work"})
CORE = MACHINES
WORK = frozenset({"work"})
OPENCODE_LOCAL_STATE = frozenset(
    {
        ".config/opencode/bun.lock",
        ".config/opencode/node_modules",
        ".config/opencode/package-lock.json",
        ".config/opencode/package.json",
    }
)
PROPOSED = (
    Spec(".config/opencode", ".config/opencode", frozenset()),
    Spec(".agents/skills", ".agents/skills", frozenset()),
    Spec(".claude/skills", ".claude/skills", frozenset()),
    Spec(".config/nvim", ".config/nvim", CORE),
    Spec(".claude/hooks", ".claude/hooks", DESKTOP),
    Spec(".claude/statusline-command.sh", ".claude/statusline-command.sh", CORE),
    Spec(".claude/output-styles", ".claude/output-styles", CORE),
    Spec(".codex/agents/commit.toml", ".codex/agents/commit.toml", CORE),
    Spec(".pi/agent/extensions", ".pi/agent/extensions", frozenset()),
    Spec(".pi/agent/extensions/commit.ts", ".pi/agent/extensions/commit.ts", CORE),
    Spec(
        ".pi/agent/extensions/ollama-websearch.ts",
        ".pi/agent/extensions/ollama-websearch.ts",
        CORE,
    ),
    Spec(
        ".pi/agent/extensions/tmux-panes.ts",
        ".pi/agent/extensions/tmux-panes.ts",
        DESKTOP,
    ),
    Spec(
        ".pi/agent/extensions/tmux-panes-lib.mjs",
        ".pi/agent/extensions/tmux-panes-lib.mjs",
        DESKTOP,
    ),
    Spec(".pi/agent/models.json", ".pi/agent/models.json", CORE),
    Spec(".zshrc", ".zshrc", CORE),
    Spec(".local/bin/git-ac", ".local/bin/git-ac", CORE),
    Spec(
        ".local/bin/git-prune-old-branches", ".local/bin/git-prune-old-branches", CORE
    ),
    Spec(".local/bin/git-wt", ".local/bin/git-wt", CORE),
    Spec(
        ".local/bin/ollama-websearch-mcp.py", ".local/bin/ollama-websearch-mcp.py", CORE
    ),
    Spec(
        ".config/systemd/user/ollama.service",
        ".config/systemd/user/ollama.service",
        DESKTOP,
    ),
    Spec(".config/herdr/config.toml", ".config/herdr/config.toml", DESKTOP),
    Spec(".tmux.conf.local", ".tmux.conf.local", DESKTOP),
    Spec(".local/bin/clip", ".local/bin/clip", DESKTOP),
    Spec(".local/bin/getfonts.sh", ".local/bin/getfonts.sh", DESKTOP),
    Spec(".config/opencode/.gitignore", ".config/opencode/.gitignore", CORE),
    Spec(".config/opencode/agent", ".config/opencode/agent", CORE),
    Spec(".config/opencode/command", ".config/opencode/command", CORE),
    Spec(
        ".config/opencode/plugins/commit-model.ts",
        ".config/opencode/plugins/commit-model.ts",
        CORE,
    ),
    Spec(
        ".config/opencode/plugins/worktree.ts",
        ".config/opencode/plugins/worktree.ts",
        DESKTOP,
    ),
    Spec(
        ".config/opencode/plugins/worktree",
        ".config/opencode/plugins/worktree",
        DESKTOP,
    ),
    Spec(
        ".config/opencode/plugins/herdr-agent-state.js",
        ".config/opencode/plugins/herdr-agent-state.js",
        DESKTOP,
    ),
    Spec(
        ".config/opencode/plugins/tmux.ts", ".config/opencode/plugins/tmux.ts", DESKTOP
    ),
    Spec(".config/opencode/herdr-opencode", ".config/opencode/herdr-opencode", DESKTOP),
    Spec(
        ".config/opencode/herdr-tui-session.js",
        ".config/opencode/herdr-tui-session.js",
        DESKTOP,
    ),
    Spec(".config/opencode/tui.jsonc", ".config/opencode/tui.jsonc", DESKTOP),
    Spec(".config/opencode/tui.json", ".config/opencode/tui.json", CORE),
    Spec(
        ".config/opencode/browser-plugin-setup.md",
        ".config/opencode/browser-plugin-setup.md",
        DESKTOP,
    ),
    Spec(
        ".config/opencode/skills/.gitignore", ".config/opencode/skills/.gitignore", CORE
    ),
    Spec(".agents/skills/tts", ".agents/skills/tts", DESKTOP),
    Spec(".agents/skills/tts", ".claude/skills/tts", DESKTOP),
    Spec(".agents/skills/tts", ".config/opencode/skills/tts", DESKTOP),
    Spec(".config/himither", ".config/himither", DESKTOP),
    Spec(
        ".agents/skills/tmux-processes",
        ".agents/skills/tmux-processes",
        DESKTOP,
    ),
    Spec(
        ".agents/skills/tmux-processes",
        ".claude/skills/tmux-processes",
        DESKTOP,
    ),
    Spec(
        ".config/opencode/skills/tmux-plugin",
        ".config/opencode/skills/tmux-plugin",
        DESKTOP,
    ),
    Spec(
        ".config/opencode/tools/screenshot.ts",
        ".config/opencode/tools/screenshot.ts",
        DESKTOP,
    ),
    Spec(".config/hypr", ".config/hypr", DESKTOP),
    Spec(".config/waybar", ".config/waybar", DESKTOP),
    Spec(".config/awesome", ".config/awesome", DESKTOP),
    Spec(".config/dunst", ".config/dunst", DESKTOP),
    Spec(".config/gtk-3.0", ".config/gtk-3.0", DESKTOP),
    Spec(".config/gtk-4.0/settings.ini", ".config/gtk-4.0/settings.ini", DESKTOP),
    Spec(".config/fontconfig/fonts.conf", ".config/fontconfig/fonts.conf", DESKTOP),
    Spec(
        ".config/ghostty/config",
        ".config/ghostty/config",
        DESKTOP,
    ),
    Spec(".wezterm.lua", ".wezterm.lua", DESKTOP),
    Spec(".config/maccel", ".config/maccel", DESKTOP),
    Spec(".local/bin/maccel-profile", ".local/bin/maccel-profile", DESKTOP),
    Spec(".local/bin/tmux-remote-paste", ".local/bin/tmux-remote-paste", frozenset()),
    Spec(".local/bin/tmux-center-toggle", ".local/bin/tmux-center-toggle", DESKTOP),
    Spec(".local/bin/ghostty", ".local/bin/ghostty", WORK),
    Spec(
        "profiles/work/.codex/AGENTS.override.md",
        ".codex/AGENTS.override.md",
        frozenset(),
    ),
    Spec(
        "profiles/work/.claude/rules/jbcontext.md",
        ".claude/rules/jbcontext.md",
        frozenset(),
    ),
    Spec(
        ".local/share/applications/com.mitchellh.ghostty.desktop",
        ".local/share/applications/com.mitchellh.ghostty.desktop",
        WORK,
    ),
)

# Check these against dev's projection in tests so a new shared skill is not
# silently omitted from the future inventory.
SHARED_SKILLS = (
    "commit",
    "context7",
    "frontend-design",
    "fsm-events-actions-style",
    "gnarus-good-code",
    "machine-config",
    "ollama-gpu-installation",
    "one-sentence",
    "simple",
    "syllogism",
    "systematic-debugging",
    "tdd",
)
CLAUDE_SKILLS = (
    "codex-computer-use",
    "codex-implement",
    "codex-review",
    "codex-second-opinion",
    "commit",
)
PROPOSED += (
    tuple(
        Spec(f".agents/skills/{name}", f".agents/skills/{name}", CORE)
        for name in SHARED_SKILLS
    )
    + tuple(
        Spec(f".agents/skills/{name}", f".claude/skills/{name}", CORE)
        for name in SHARED_SKILLS
        if name != "commit"
    )
    + tuple(
        Spec(f".agents/skills/{name}", f".config/opencode/skills/{name}", CORE)
        for name in SHARED_SKILLS
    )
    + tuple(
        Spec(f".claude.only/skills/{name}", f".claude/skills/{name}", CORE)
        for name in CLAUDE_SKILLS
    )
    + (
        Spec(
            ".codex.only/skills/claude-implement",
            ".agents/skills/claude-implement",
            CORE,
        ),
    )
)
PROPOSED += tuple(
    Spec(bundle_source(machine, name), target, frozenset({machine}))
    for machine in ("remote", "home", "work")
    for name, target in (
        ("claude.md", ".claude/CLAUDE.md"),
        ("codex.md", ".codex/AGENTS.md"),
        ("pi.md", ".pi/agent/APPEND_SYSTEM.md"),
        ("claude-settings.json", ".claude/settings.json"),
        ("opencode.json", ".config/opencode/opencode.json"),
    )
)


def _retirement_effects(
    observed: Mapping[str, Managed | Unmanaged],
    known: set[str],
    wanted: set[str],
    retired: set[str],
    inspected: Collection[str],
) -> tuple[list[Preserve], list[Conflict]]:
    preservation = []
    conflicts = []
    for parent in sorted(retired):
        if not any(_beneath(target, {parent}) for target in wanted):
            continue
        if parent not in inspected:
            conflicts.append(Conflict(parent, "contents not inspected"))
            continue
        for target in sorted(observed):
            if not target.startswith(parent + "/"):
                continue
            if (
                target in OPENCODE_LOCAL_STATE
                and isinstance(observed[target], Unmanaged)
                and observed[target].description
                in ("existing file", "existing directory")
            ):
                preservation.append(
                    Preserve(target, observed[parent].source + target[len(parent) :])
                )
                continue
            if not any(
                target == known_target or _beneath(target, {known_target})
                for known_target in known - {parent}
            ) and not any(
                known_target.startswith(target + "/") for known_target in known
            ):
                conflicts.append(Conflict(target, "unaccounted contents"))
    return preservation, conflicts


def _link_effect(
    item: Spec,
    observed: Mapping[str, Managed | Unmanaged],
    retired: set[str],
    available_sources: Collection[str] | None,
) -> Link | Conflict | None:
    foreign_parent = next(
        (
            str(parent)
            for parent in PurePosixPath(item.target).parents
            if isinstance(observed.get(str(parent)), (Managed, Unmanaged))
            and str(parent) not in retired
            and not _beneath(str(parent), retired)
        ),
        None,
    )
    if foreign_parent is not None:
        current_parent = observed[foreign_parent]
        reason = (
            f"unmanaged parent {foreign_parent}: {current_parent.description}"
            if isinstance(current_parent, Unmanaged)
            else f"managed parent {foreign_parent} is not retired"
        )
        return Conflict(item.target, reason)
    if available_sources is not None and item.source not in available_sources:
        return Conflict(item.target, f"missing source: {item.source}")
    # A child observed through a departing directory symlink disappears
    # with the parent; linking it must happen into the new real directory.
    current = None if _beneath(item.target, retired) else observed.get(item.target)
    if current is None:
        return Link(item.target, item.source)
    if isinstance(current, Managed) and current.source != item.source:
        return Link(item.target, item.source, current.source)
    if isinstance(current, Unmanaged):
        return Conflict(item.target, current.description)
    return None


def plan(
    machine: str,
    inventory: Iterable[Spec],
    observed: Mapping[str, Managed | Unmanaged],
    available_sources: Collection[str] | None = None,
    inspected: Collection[str] = (),
) -> tuple[Preserve | Link | Remove | Conflict, ...]:
    if machine not in MACHINES:
        raise ValueError(f"unknown machine: {machine}")
    inventory = tuple(inventory)
    known = {item.target for item in inventory}
    wanted = set()
    for item in inventory:
        if machine not in item.machines:
            continue
        if item.target in wanted:
            raise ValueError(f"duplicate target for {machine}: {item.target}")
        wanted.add(item.target)
    retired = {
        target
        for target, current in observed.items()
        if target in known and target not in wanted and isinstance(current, Managed)
    }
    preservation, actions = _retirement_effects(
        observed, known, wanted, retired, inspected
    )
    for item in inventory:
        if machine in item.machines:
            effect = _link_effect(item, observed, retired, available_sources)
            if effect is not None:
                actions.append(effect)
    conflicts = tuple(action for action in actions if isinstance(action, Conflict))
    if conflicts:
        return conflicts
    removals = [
        Remove(target, observed[target].source)
        for target in retired
        if not _beneath(target, retired)
    ]
    removals.sort(key=lambda item: item.target)
    return tuple(preservation + removals + actions)
