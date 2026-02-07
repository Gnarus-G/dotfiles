---
name: functional-programming
description: Comprehensive functional programming guide covering core principles and patterns across multiple languages (Python, Rust, TypeScript, Lua, C). Use when OpenCode or Claude needs to write any code.
---

# Functional Programming Skill

This skill guides you in applying Functional Programming (FP) principles to any language, even imperative ones.

**For full multi-language code examples (Python, Rust, TypeScript, Lua, C), see [references/guide.md](references/guide.md).**

## Core Guidelines

### 0. No Global State

**Rule**: Never use global variables or mutable shared state. Pass dependencies explicitly through parameters or dependency injection.
**Pattern**: Use Actors or Dependency Injection to manage state.

### 1. Pure Functions Only

**Rule**: All functions must depend _only_ on their input arguments. They must never mutate shared state or perform I/O.
**Why**: Ensures determinism and testability.

### 2. Isolate Side Effects

**Rule**: I/O, randomness, database access, and system calls must be in a separate "shell" layer, never mixed with business logic.
**Pattern**: "Functional Core, Imperative Shell".

### 3. Functional Core, Imperative Shell

**Rule**: Write all business logic as pure functions. Only the outer layers (main, controllers, handlers) perform effects and orchestrate data flow.

### 4. Monadic Error Handling

**Rule**: Use `Result` or `Option` types to handle failures and optional values.
**Don't**: Do not use exceptions for control flow. Exceptions should only be for unrecoverable crashes.

### 5. Composable Concurrency

**Rule**: Use `async`/`await`, `Task`, or `Future` wrappers.
**Don't**: Avoid raw threading or locking mutexes manually if possible. Use message passing.

### 6. Actor Model

**Rule**: Encapsulate mutable state within Actors that communicate via message passing.
**Pattern**: Actors process messages one at a time, ensuring no concurrent mutation of internal state.

### 7. Request-Reply Actor Pattern

**Rule**: For request-response interactions, embed a "reply channel" in the request message.
**Benefit**: Enforces type safety and correlation between requests and responses.

## Quick Reference

**Do:**

- Write pure, deterministic functions.
- Model effects explicitly (`Result`, `Option`).
- Keep side effects at the boundaries of your application.
- Encapsulate concurrency with actors.

**Don't:**

- Share mutable state between components.
- Mix I/O with computation in the same function.
- Use `isinstance` checks (use pattern matching instead).
- Use exceptions for expected errors.

## Implementation Details

The referenced guide `references/guide.md` contains detailed implementations for:

- **Dependency Injection** (Python, Rust, TS)
- **Pure Functions** (Python, C, Rust, Lua)
- **Effect Isolation** (Python, C, Rust, Lua)
- **Functional Core/Imperative Shell** (Python, C, Rust, Lua)
- **Monadic Error Handling** (Python, C, Rust, Lua)
- **Actor Model** (Python, TS, Rust, Lua)
- **Request-Reply Pattern** (Python, TS, Rust, Lua)

When implementing these patterns, check the reference guide to ensure you are using the idiomatic approach for the target language.
