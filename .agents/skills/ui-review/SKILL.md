---
name: ui-review
description: Review rendered UI and infer UX semantics against a mandatory documented and encoded design system, using multiple selected vision models, independent scores out of 10, cross-review, and unanimous high-score consensus; optionally verify full UX through observed flows. Use for /ui-review, screenshot or UI/UX critiques, usability and design polish, or requests to keep improving a UI until it is excellent.
---

# UI/UX Review

Invoked as `/ui-review [route, screenshots, or UI/UX description]`.
Run a review-and-improve loop by default. Default to static UI review plus
explicitly labeled UX-semantic inference; require observed flows only for full UX
review or when the user requests interaction/usability testing. If the user asks
for review-only or read-only work, do not edit; report findings and stop after
that review.

## 1. Set the contract and require a design system

- Identify the product brief, users, primary tasks, end-to-end success criteria,
  required states and viewports, and fixed design or product constraints. Use the
  current project and supplied evidence when available. Ask only for information
  that cannot be obtained.
- Use at least two image-capable models. Accept explicit selections as
  `codex:MODEL` and `fx:MODEL`; otherwise use:
  - `fx:inkling-2-small`
  - `fx:deepseek-v4.1-flash`

  For high-stakes or complex interaction review, explicitly add
  `codex:gpt-6.2-astra` for the entire run rather than introducing it midway.

- Default to target **9.0/10** and at most **five review rounds**. Honor an
  explicit target or round limit. Keep the target and other reviewers' scores
  out of reviewer prompts: they are stopping rules, not instructions to inflate.
- Keep the panel, rubric, brief, design-system revision, states, and viewports
  stable between rounds. Do not replace or drop a reviewer because its score is
  low. Ask before changing the panel; changing it makes scores non-comparable.
- Save artifacts under a fresh temporary run directory and tell the user where
  it is. Record the brief, design-system sources, screenshots, each raw review,
  and the synthesis.

### Mandatory design-system gate

Before reviewing or scoring, locate and read both halves of the design system:

- **Documented:** design principles, color and typography roles, spacing and
  layout rules, reusable component guidance, interaction states, motion, and
  accessibility constraints. Read the actual local documents, not just their
  filenames.
- **Encoded:** the tokens, theme/configuration, styles, and reusable components
  that implement those rules. Record their paths and revision. Relevant examples
  include token files, CSS variables, theme objects, framework configuration,
  and component libraries.

Give all reviewers the same relevant documentation and encoded values. If the
documentation and implementation disagree, resolve or explicitly record the
conflict before scoring; do not let each reviewer choose a different authority.

If either half is missing, **stop before reviewing or scoring and demand
design-system work first**. Unless the user already chose an approach, require a
choice between:

1. Create a compact project-specific system from the product brief and existing
   UI, using `/frontend-design` when a new visual direction is needed.
2. Research a suitable public design system and copy or adapt its guidance,
   tokens, and components into the project. Record source URLs, version or
   commit, license, attribution, and local modifications; never copy blindly or
   disregard its license.

At minimum, the result must document its principles and component/state rules
and encode its color, typography, spacing, layout, and interaction tokens. A
token dump alone is not documentation; prose alone is not an encoded system.
Do not silently invent a system, mix unrelated systems, or continue with purely
subjective scores. Resume only when both halves exist; existing UI deviations
from the adopted system become review findings.

## 2. Capture the actual UI and UX

Use the supplied image files or drive the real interface with browser tools.
Capture the same representative states every round, including the primary flow,
mobile and desktop layouts, and relevant empty, error, loading, or open-menu
states. Use deterministic data where possible. Name images by state and viewport.

By default, infer likely UX semantics from visible cues: affordances, hierarchy,
labels, next actions, status meaning, and expected feedback or recovery. Mark
these as inferences tied to visible evidence, not observed behavior.

For optional full UX review, execute the primary flows end-to-end where
permitted. Record the action sequence, user feedback, errors and recovery, and
task-completion evidence for every reviewer. Preserve production records and
obtain consent before consequential actions. Static images cannot establish task
success, learnability, actual interaction efficiency, or recovery. Label a static
run a UI review with inferred UX semantics, not validated UX sign-off.

A model must receive the actual image attachments and applicable interaction
records. Never describe a screenshot in text and then present the response as
visual review. Do not invent findings about unseen states. Verify interaction and
accessibility concerns with interaction or measurements rather than claiming a
screenshot proves keyboard behavior.

## 3. Run independent reviews

Give every reviewer the same brief, rubric, and current images, but no peer
reviews, peer scores, previous scores, or desired target. Run the reviewers
concurrently. For long-running calls, follow the command-handoff instructions
and use a fresh `Whatever:ui-review` tmux window; use `/tmux-processes` when
available. Wait for every process and inspect its exit status and output.

For the default panel, set `ROUND` to the current artifact directory and
`PROMPT` to the reviewer prompt file. Repeat image flags for every captured
state; the two-image examples are illustrative.

```bash
fx ask --model inkling-2-small --effort high --no-save \
  --image "$ROUND/desktop.png" --image "$ROUND/mobile.png" \
  < "$PROMPT" > "$ROUND/fx-inkling-2-small.md"

fx ask --model deepseek-v4.1-flash --effort high --no-save \
  --image "$ROUND/desktop.png" --image "$ROUND/mobile.png" \
  < "$PROMPT" > "$ROUND/fx-deepseek-v4.1-flash.md"
```

Substitute only the model and output name for explicit panel selections. Do not
silently substitute another model. Reviewers must not edit files or run mutating
commands. Retry a failed or malformed review once with the same inputs. Fewer
than two valid visual reviews, or a missing selected reviewer, is not consensus.

### Shared reviewer prompt

```text
You are an independent senior UI/UX reviewer. Inspect every attached image directly.
Review the current rendered UI and any supplied interaction evidence against the
brief below. Infer likely UX semantics from visible affordances, labels, hierarchy,
status cues, and expected next actions; mark those claims as inferences. Do not
use tools, edit files, propose a generic redesign, or speculate about unseen
states. If an image is unavailable, say UNABLE TO REVIEW instead of giving a
numeric score.

BRIEF AND CONSTRAINTS
<product, users, primary tasks, success criteria, observed action/feedback/error
sequence, states, viewports, and fixed constraints>

DOCUMENTED AND ENCODED DESIGN SYSTEM
<principles, token values, component and state rules, accessibility constraints,
and source paths/revisions>

Evaluate compliance with this system. Cite the exact rule or token for every
system-compliance finding, and distinguish those findings from personal taste.
Do not propose replacing or redesigning the system itself.

Score each dimension from 0 to 10, then calculate Overall as the weighted sum,
rounded to one decimal:
- Task flow, interaction efficiency, feedback, and error recovery (inferred from
  visible cues unless observed): 30%
- Visual hierarchy, typography, and legibility: 20%
- Layout and responsive behavior at the supplied viewports: 20%
- Visible accessibility and interaction-state clarity: 15%
- Design-system coherence and visual polish: 15%

Score only the supplied evidence. Without observed flows, Workflow covers
inferred task flow and visible cues only; do not claim measured efficiency,
learnability, actual feedback, or recovery behavior.

Calibration: 9-10 is excellent and has no major shortcomings; 8-8.9 is strong
but still has meaningful improvements; 7-7.9 is usable with visible weaknesses;
below 7 has substantial problems. Judge against this brief, not personal style.

Return exactly:
Overall: <N.N>/10
Workflow: <N>/10
Hierarchy: <N>/10
Layout: <N>/10
Accessibility: <N>/10
Coherence: <N>/10
Findings:
- [major|minor] <image and region> — <observation>; <user consequence>;
  <smallest correction that follows the brief and design system>.
Verdict: <ACCEPT|NOT YET>

Cite image evidence for every finding. Distinguish observed facts from concerns
that need interaction or measurement. Return no more than five findings, ranked
by user impact. ACCEPT only when the UI is excellent for the stated brief and
design system and no major finding remains. Do not change a score to agree with
anyone else.
```

## 4. Synthesize and confer

1. Validate that every score is present and every finding cites an actual
   attachment or recorded interaction evidence. Independently inspect the images,
   interaction records, design system, and relevant code before accepting a
   finding. Discard false positives, claims that misread the design system, and
   out-of-scope redesigns.
2. Merge duplicate findings without losing their evidence. Mark which reviewers
   independently agree, and preserve valid high-impact singleton findings and
   dissent. Agreement is supporting evidence, not proof.
3. If reviewers materially conflict on a finding or score, run **one** focused
   cross-review for that round. Give each reviewer its own initial review, the
   current images, and an anonymized list of the contested observations and
   rebuttals, without model names, peer scores, or the target. Ask each to
   confirm or reject each claim from evidence and independently restate its
   scores. Record both original and revised scores. Never pressure reviewers to
   converge.
4. Report a compact score table and the remaining evidence-backed disagreements.
   Optimize the **lowest** reviewer score first; never average away a low score
   or trade a major regression for a higher mean.

If the user explicitly requests a decision model such as Clef, use Ollama's
System One API as an optional structured gate over the current images, design
system, and synthesized findings. Ask typed questions such as whether the UI
violates a specified rule or whether an accepted major finding remains. It cannot
generate the required narrative critique, so do not count it as a panel reviewer
or let its output override visual evidence. Treat its confidence as probability
concentration, not correctness, and calibrate any thresholds on labeled examples
from the actual UI workflow before relying on them.

## 5. Improve and repeat

Stop immediately when consensus is reached. Otherwise, unless in review-only
mode:

1. Choose the smallest coherent batch of changes that addresses the accepted
   major findings and raises the lowest score. Product requirements, the adopted
   design system, and explicit constraints outrank reviewer taste.
2. Implement only those changes, following the project's conventions and tests.
   Do not commit, merge, deploy, or make unrelated design changes unless asked.
3. Exercise the affected flow and recapture the same states and viewports. Keep
   before/after images. A change is progress only if the lowest score improves,
   or the lowest score holds while accepted major findings decrease without a
   meaningful regression elsewhere.
4. Start the next independent review from current screenshots, applicable
   interaction records, and a neutral list of changed findings, not from peer
   scores. Repeat the synthesis and confer steps before making more changes.

Stop without claiming success after five rounds, after two consecutive rounds
without progress, when a selected reviewer remains unavailable, or when further
movement needs a user design decision. Report the best verified state, remaining
findings, and the blocker.

## Consensus and reporting

Consensus requires all of the following in the same final round:

- at least two selected models returned valid reviews over the same visual and
  applicable interaction evidence;
- every selected reviewer scores the current UI/UX at or above the target;
- every selected reviewer returns `ACCEPT`;
- no accepted major finding remains unresolved.

Do not call an average, a majority, the orchestrator's own score, or a reduced
panel a consensus. Preserve dissent in the final report.

After each round, show concrete results in this form (numbers below are an
example, not evidence):

```text
| Reviewer        | Before | Current | Delta | Verdict |
|-----------------|--------|---------|-------|---------|
| Inkling 2 Small | 8.2    | 9.0     | +0.8  | ACCEPT  |
| DeepSeek Flash  | 7.6    | 8.8     | +1.2  | NOT YET |

Consensus: not reached; lowest score 8.8/10 against the 9.0 target.
Changed: <specific UI/UX correction>; remaining: <finding and evidence>.
```

Finish with the design-system sources and revision, score history, before/after
screenshots and task-flow evidence, changes made, checks run, unresolved dissent,
and the artifact directory. Never manufacture a high score or hide a regression
to terminate the loop.
