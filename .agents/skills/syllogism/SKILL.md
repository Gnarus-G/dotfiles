---
name: syllogism
description: Use when a problem benefits from explicit premises, validity checks, and conclusion tracing through syllogistic reasoning
---

# Syllogistic Thinking

## Overview

Use explicit premise-conclusion reasoning instead of intuitive leaps.

**Core principle:** separate:
- what is stated
- what follows logically
- what remains uncertain

This mode is for disciplined reasoning, not for pretending every problem reduces to formal logic.

## When to Use

Use this when the task involves:
- evaluating an argument
- tracing whether a conclusion actually follows
- spotting hidden assumptions
- comparing competing claims
- checking consistency across requirements, specs, or policies
- making a recommendation that depends on a small number of key premises

Use this especially for:
- architecture tradeoffs
- debugging hypotheses
- code review arguments
- policy/process decisions
- user claims that may sound plausible but are under-supported

Do not force this mode onto tasks that are mainly:
- creative exploration
- aesthetic design
- broad brainstorming
- direct factual lookup

## The Method

### 1. State the Question Precisely

Rewrite the problem as a claim that can be tested.

Examples:
- "Will this refactor reduce duplicated logic without changing behavior?"
- "Does the observed failure imply the database is the root cause?"
- "If these constraints hold, is option A better than option B?"

### 2. Extract Premises

List only the premises you actually have.

- Distinguish facts from assumptions
- Prefer numbered premises
- Mark uncertain premises explicitly

Format:

```text
P1. Known fact
P2. Known fact
P3. Assumption
P4. Evidence with uncertainty
```

If a needed premise is missing, say so instead of smuggling it in.

### 3. Normalize the Terms

Make sure the categories are stable.

- Use the same term for the same concept
- Avoid switching between near-synonyms
- Split ambiguous claims into separate premises

Bad:
- "fast", "efficient", and "low latency" used as if identical

Better:
- "fast" means p95 latency under 200 ms

### 4. Derive the Immediate Conclusion

Ask:

```text
If P1..Pn are true, what follows necessarily?
What follows only probabilistically?
What does not follow at all?
```

Separate outputs into:
- Valid conclusion
- Tentative inference
- Unsupported leap

### 5. Test the Reasoning

Before accepting a conclusion:
- look for a counterexample
- check whether any premise is too broad
- ask whether the conclusion is stronger than the premises support
- check for hidden exclusivity: "A explains X" does not mean "only A explains X"

If one counterexample breaks the argument, the syllogism is invalid as stated.

### 6. Report the Result Cleanly

Use this output shape:

```text
Question:
...

Premises:
P1. ...
P2. ...

Conclusion:
...

Confidence:
high | medium | low

Why:
- valid deduction
- assumption-dependent inference
- blocked by missing premise
```

## Rules

### Rule 1: Validity Is Not Truth

A conclusion can be logically valid and still wrong if a premise is false.

### Rule 2: Missing Premises Are First-Class

If the argument only works with an unstated assumption, surface it explicitly.

### Rule 3: Stronger Claims Need Stronger Premises

Do not upgrade:
- "sometimes" into "always"
- "correlated" into "caused"
- "works here" into "general solution"

### Rule 4: Prefer Disproof Over Self-Confirmation

Try to break your conclusion before presenting it.

### Rule 5: Stop When Formalism Stops Helping

If the task turns into empirical uncertainty, gather evidence instead of stacking more abstract logic.

## Common Failure Modes

- treating assumptions as facts
- hiding ambiguity inside broad nouns
- confusing explanation with proof
- deriving operational decisions from incomplete premises
- sounding rigorous while skipping the actual validity check

## Example

```text
Question:
Does retrying the request fix the bug?

Premises:
P1. Retries help when failures are transient.
P2. The failure reproduces consistently with the same input.
P3. No evidence shows network instability.

Conclusion:
Retrying is not justified as the primary fix.

Confidence:
medium

Why:
- P2 weakens the claim that the failure is transient
- P3 removes the main support for a retry-based explanation
- a hidden assumption would be needed to justify retries anyway
```

## Operational Guidance

When using this skill:
- show premises before conclusion when the reasoning matters
- label assumptions explicitly
- note whether the conclusion is deductive or probabilistic
- call out what evidence would most efficiently change the conclusion

This skill improves rigor on narrow reasoning tasks. It does not replace domain knowledge, experiments, or direct verification.
