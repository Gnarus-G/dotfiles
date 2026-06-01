# Cyclomatic Complexity Reference

Copied reference content from `.agents/skills/cyclomatic-complexity/SKILL.md` for self-contained use by `/simple`.

Measure cyclomatic complexity in Rust before refactoring, then reduce it with behavior-preserving changes and verify the result.

## Goals

- Find the highest-value complexity hotspots instead of chasing global averages.
- Lower branching complexity without changing behavior.
- Prefer refactors that improve readability, testability, and local reasoning.
- Report both the measured delta and any residual risk.

## Workflow

1. Find the crate, workspace layout, and existing `cargo` checks already used by the repo.
2. Measure current complexity with the repo's existing tooling first. If none exists, use a Rust analyzer.
3. Rank hotspots by a combination of highest cyclomatic complexity, business criticality, change frequency, bug density, and fragility.
4. Read the worst offenders before editing. Identify which branches are essential and which are accidental complexity.
5. Add or run characterization tests around the target behavior before large refactors.
6. Refactor incrementally, re-measuring after each meaningful change.
7. Run the narrowest relevant tests first, then broader validation if the change touches shared logic.

## Measurement

Prefer the repository's existing tooling and CI rules. For Rust, the most practical options are:

| Tool | Use |
| --- | --- |
| `rust-code-analysis-cli` | Best direct complexity measurement for Rust source trees |
| `cargo clippy` | Sanity check after refactors; catches control-flow smells and regressions |

## Install

Install only what the repo needs. If CI already provides a tool, match that version or approach locally.

```bash
# Rust toolchain
rustup toolchain install stable
rustup component add clippy

# Preferred analyzer
cargo install rust-code-analysis-cli --locked --registry crates-io
```

Install the CLI crate, not the library crate: `rust-code-analysis` is library-only and `cargo install rust-code-analysis` fails with "there is nothing to install" because it has no binaries. Use `--locked`; without it, `rust-code-analysis-cli v0.0.25` can resolve incompatible `tree-sitter` versions and fail with a `tree_sitter::Language` type mismatch. If `cargo install rust-code-analysis-cli --locked` is too slow or unavailable in the environment, use `cargo clippy` plus tests as the verification baseline.

Useful command patterns:

```bash
# Measure the main source tree
rust-code-analysis-cli --metrics --output-format json --output /tmp/rust-code-analysis --paths src

# Measure a specific file
rust-code-analysis-cli --metrics --output-format json --output /tmp/rust-code-analysis --paths src/lib.rs

# Workspace sanity check after edits
cargo clippy --all-targets --all-features
```

If a repo already enforces thresholds in CI, keep local validation aligned with those thresholds instead of inventing new ones.

## Rust Guidance

In Rust, complexity often hides in nested `match` blocks, repeated `if let` chains, manual error propagation branches, and large functions that mix parsing, validation, and execution.

Prefer these reductions:

- Use early returns with `?` instead of manual `match` on `Result` where the error path is unchanged.
- Replace nested `if let` or `match` trees with combinators when that improves readability: `map`, `and_then`, `filter`, `ok_or_else`.
- Split large `match` arms into named helper functions when each arm implements a distinct behavior.
- Introduce enums for real state transitions instead of coordinating many booleans.
- Use table-driven dispatch with `match` on an enum or command type when the branches are data selection, not control-flow nuance.
- Separate parsing from side effects. A pure parser with unit tests is easier to simplify than a function that also mutates state or performs I/O.
- Be careful with iterator chains: they can reduce visible branching, but do not force a chain if a small loop is clearer.

Rust-specific validation:

- Run `cargo test` for affected crates or packages.
- Run `cargo test -p <crate>` first when only one crate changed, then widen scope if needed.
- Run `cargo clippy --all-targets --all-features` after refactors that change control flow.
- If lifetimes or borrowing become harder to reason about after a refactor, the design likely got worse even if the measured complexity dropped.

## Rust Examples

### Prefer `?` over manual `match`

Before:

```rust
fn load_user_name(id: UserId, repo: &Repo) -> Result<String, Error> {
    let user = match repo.load_user(id) {
        Ok(user) => user,
        Err(err) => return Err(err),
    };

    let profile = match repo.load_profile(user.profile_id) {
        Ok(profile) => profile,
        Err(err) => return Err(err),
    };

    if profile.name.trim().is_empty() {
        return Err(Error::MissingName);
    }

    Ok(profile.name)
}
```

After:

```rust
fn load_user_name(id: UserId, repo: &Repo) -> Result<String, Error> {
    let user = repo.load_user(id)?;
    let profile = repo.load_profile(user.profile_id)?;

    if profile.name.trim().is_empty() {
        return Err(Error::MissingName);
    }

    Ok(profile.name)
}
```

This keeps the same behavior while removing repeated decision points.

### Split a branching `match` by responsibility

Before:

```rust
fn handle_event(event: Event, state: &mut State) -> Result<(), Error> {
    match event {
        Event::Create(cmd) => {
            validate_create(&cmd)?;
            state.insert(cmd.id, build_record(cmd));
            Ok(())
        }
        Event::Update(cmd) => {
            validate_update(&cmd)?;
            let record = state.get_mut(&cmd.id).ok_or(Error::Missing)?;
            apply_update(record, cmd);
            Ok(())
        }
        Event::Delete(cmd) => {
            if state.remove(&cmd.id).is_none() {
                return Err(Error::Missing);
            }
            Ok(())
        }
    }
}
```

After:

```rust
fn handle_event(event: Event, state: &mut State) -> Result<(), Error> {
    match event {
        Event::Create(cmd) => handle_create(cmd, state),
        Event::Update(cmd) => handle_update(cmd, state),
        Event::Delete(cmd) => handle_delete(cmd, state),
    }
}
```

This does not always lower total complexity across the whole module, but it lowers per-function complexity and makes each path easier to test.

### Replace boolean soup with an enum

Before:

```rust
fn next_step(is_admin: bool, is_active: bool, is_suspended: bool) -> Action {
    if is_suspended {
        Action::Reject
    } else if is_admin && is_active {
        Action::Allow
    } else if is_active {
        Action::Review
    } else {
        Action::Reject
    }
}
```

After:

```rust
enum AccountState {
    Suspended,
    AdminActive,
    Active,
    Inactive,
}

fn next_step(state: AccountState) -> Action {
    match state {
        AccountState::Suspended => Action::Reject,
        AccountState::AdminActive => Action::Allow,
        AccountState::Active => Action::Review,
        AccountState::Inactive => Action::Reject,
    }
}
```

This makes the domain model explicit and removes repeated boolean combinations from call sites.

### Replace boolean flag parameters with enums - always

A `bool` parameter that gates behavior inside a function is a hard anti-pattern, not a suggestion. Every `if flag` inside the body is a hidden branch that inflates cyclomatic complexity and makes the function harder to read, test, and extend.

Detect: A function takes a `bool` parameter and the body contains `if flag` / `if !flag` branches conditioned on it. Also applies to `bool` fields on structs or CLI args that scatter `if` checks across the call site.

Fix: Replace the bool with a two-variant enum. Move the divergent behavior into methods on the enum. The calling function becomes branch-free with respect to that mode.

Before:

```rust
fn start_server(listener: TcpListener, use_tls: bool, tls_config: Option<Arc<ServerConfig>>) {
    if use_tls {
        let config = tls_config.unwrap();
        spawn(move || run_tls_server(listener, config));
    } else {
        spawn(move || run_plain_server(listener));
    }
}
```

After:

```rust
enum ServerMode {
    Tls(Arc<ServerConfig>),
    Plain,
}

impl ServerMode {
    fn start(self, listener: TcpListener) {
        match self {
            ServerMode::Tls(config) => spawn(move || run_tls_server(listener, config)),
            ServerMode::Plain => spawn(move || run_plain_server(listener)),
        }
    }
}
```

The enum carries variant-specific data (no `Option` needed), the match is exhaustive (compiler catches missing arms), and the calling function has zero branches for mode selection.

This is not optional. If you introduce a `bool` parameter and the function body branches on it more than once, refactor to an enum before merging. A single `if` may be tolerable for a trivial case; two or more `if flag` checks in the same function is always wrong.

Also applies to wire protocols and configuration: prefer enum-valued headers and fields (`transport: plain | tls`) over boolean ones (`use_tls: true | false`). Boolean encoding is harder to extend and obscures the domain model.

## How To Prioritize

High complexity alone is not enough. Prefer functions that are:

- on hot paths for product behavior
- edited often
- difficult to test
- sources of repeated bugs
- blocking current feature work

In Rust, give extra weight to functions that also show one of these smells:

- deep nesting across `match`, `if let`, and guard conditions
- repeated conversion between `Option` and `Result`
- state coordinated by multiple booleans (always replace with enums - see rule above)
- boolean parameters that scatter `if flag` branches through a function body
- parser or protocol code that mixes decoding with side effects

Deprioritize generated code, macro expansions, parser tables, compatibility shims, and code whose branching is mostly unavoidable unless the user explicitly wants that area cleaned up.

## Refactoring Patterns

Use the smallest change that removes decision paths or isolates them.

- Extract guard clauses to flatten nesting.
- Replace repeated `match` scaffolding with `?` or a small helper when the error path is identical.
- Split one large function into smaller single-purpose helpers.
- Separate parsing, validation, and execution phases.
- Move branching behind enums and focused handler functions when the variation is stable.
- Collapse duplicated conditions by computing a named intermediate boolean or domain enum once.
- Convert sentinel-heavy control flow into explicit state enums when state is the real driver.
- Remove dead branches and obsolete feature-flag paths after confirming they are unused.
- Hoist error handling and early returns so the main path reads straight through.

## What Not To Do

- Do not reduce complexity by inlining opaque boolean expressions that are harder to read.
- Do not split code into tiny helpers if that only hides the same complexity across files.
- Do not replace a clear branch with clever but fragile metaprogramming.
- Do not chase arbitrary thresholds if the resulting design gets worse.
- Do not mix broad rewrites with complexity cleanup unless the user asked for both.

## Verification

After refactoring:

1. Re-run the complexity measurement and capture the before/after numbers for the touched functions.
2. Run tests covering the changed behavior.
3. Check for regressions in error handling, edge cases, and ordering semantics.
4. If thresholds still fail, explain which remaining branches are essential and what the next reduction step would be.

## Reporting

When summarizing the work, include:

- which functions were measured
- the before and after complexity values
- the main refactor used
- what tests or checks were run
- any remaining hotspots or tradeoffs

## Heuristics

- A function with moderate complexity and poor naming may need clarity work before structural work.
- Repeated nested conditionals often indicate missing domain concepts.
- In Rust, repeated `match` arms with similar setup or cleanup often indicate a missing helper or enum-driven abstraction.
- Complexity in parsing or protocol handling may be real; isolate it and test it rather than forcing an artificial reduction.
- If cognitive complexity is available alongside cyclomatic complexity, consider both. Use cyclomatic complexity for path count and cognitive complexity for maintainability pressure.
