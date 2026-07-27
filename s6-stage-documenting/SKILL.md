---
name: s6-stage-documenting
description: "Sixth step in the dev workflow — closes out a completed stage after /s5-stage-review has passed. Trigger on: /s6-stage-documenting, /documenting (legacy alias), /document (legacy alias), document, wrap up, close stage, update the plan, what did we do, ready to merge, next stage. Also trigger when review passed and user says looks good. Do NOT trigger if STAGE_X_CHANGES.md has no Review section — means /s5-stage-review hasn't run yet."
---

# Documenting

Your job is to close out a completed stage: finalize STAGE_X_CHANGES.md with
a summary, update IMPLEMENTATION_PLAN.md, refresh project memory files, and
archive stage files.

**Hard dependency:** /s5-stage-review must have run and passed before this skill.

## Step 1 — Validate inputs

Read all required files before doing anything:

**Determine X first.** Search the project root for `STAGE_*_PLAN.md` files.
Find the one with `Status: active` — that is Stage X. If none has
`Status: active`, look for one with `Status: approved` (execution may have
started without the status being updated). If still ambiguous, ask:
"Which stage are you closing out?" Wait for the answer before continuing.

1. **STAGE_X_CHANGES.md** (required) — find in project root using the X from above.
   - If missing, stop: "Run /s4-stage-execution first."
   - Find ALL `## Review:` blocks in the file. Use the **last one** to determine
     the verdict (there may be multiple from REWORK cycles).
   - If no `## Review:` block exists, stop: "Run /s5-stage-review before /s6-stage-documenting."
   - If the last review verdict is `REWORK`, stop: "Review verdict is REWORK.
     Fix issues via /s4-stage-execution and re-run /s5-stage-review."
   - If the last review verdict is `PASS` or `PASS-WITH-EXCEPTIONS`, continue.

2. **STAGE_X_PLAN.md** (required) — already found above.
   - If any tasks are still `[ ]` or `[~]`, warn the user. Ask whether to
     proceed or return to /s4-stage-execution.

3. **STAGE_X_TESTS.md** (required) — must exist. Contains DoD checklist.

4. **IMPLEMENTATION_PLAN.md** (required) — master plan. This skill updates it.

5. **ARCHITECTURE.md** (project root, optional)
   - Read it. If implementation revealed that any Key Data Structures
     changed shape (new fields, renamed fields, removed fields), note them.
   - If any Quality Attributes were found unachievable and were accepted
     as exceptions during review, note them.
   - If L2 or L3 changed (new container added, component responsibility
     shifted), note it.

6. **CLAUDE.md** (optional) — will be appended. Read if it exists.

7. **CURRENT_STATE.md** (optional) — will be updated/created.

Then get the code diff:
```bash
git diff [branch-point]..HEAD
# or: git diff HEAD~1
```

## Step 2 — Completeness check

Do all three before writing anything:

**a) Task check:** Confirm all tasks in STAGE_X_PLAN.md are `[x]` or `[-]`.
Any `[ ]` or `[~]` tasks — warn the user (already flagged in Step 1, surface here too).

**b) Diff scope check:** Compare the git diff to STAGE_X_PLAN.md scope.
Flag any files modified that are NOT in the plan's listed scope. These become
"Unplanned changes" in the summary. Out-of-scope changes are not blockers but
must be documented.

**c) DoD verification:** Run ALL test/lint/type commands from STAGE_X_TESTS.md.
**Actually run them now — do not trust earlier results.**

Report: `DoD: X/Y items met. Missing: [list]`

If not fully met, ask the user:
> "[N] DoD items not met: [list]. Proceed with documented exceptions, or
> return to /s4-stage-execution to fix them?"

Wait for the user's choice before continuing.

## Step 3 — Prepend summary to STAGE_X_CHANGES.md

Prepend the following block at the very top of the file (before existing content):

```
## Summary
- Feature: [name from STAGE_X_PLAN.md]
- Stage: X
- Completed: YYYY-MM-DD
- Tasks completed: N / M total
- Tasks skipped: K (reasons listed below)
- DoD: X/Y items verified
- Unplanned changes: [list or "none"]

### What was implemented
[description of delivered functionality]

### Design decisions
[key choices made during implementation, from STAGE_X_CHANGES.md session logs]

### Deviations from plan
[anything that differed from STAGE_X_PLAN.md, with reasons, or "none"]

### Known limitations / tech debt
[anything left imperfect, or "none"]

### Test coverage
[summary of test results]

---
[existing file content below]
```

## Step 4 — Update IMPLEMENTATION_PLAN.md

Find the Stage X entry and update:
- Change `Status: in_progress` → `Status: done`
  (if status is still `todo` because /s4-stage-execution did not update it,
  change from `todo` → `done` directly)
- Add `Completed: YYYY-MM-DD`
- Add `Summary: [1-2 sentence description of what was delivered]`

Example transformation:
```
# Before
- Status: in_progress

# After
- Status: done
- Completed: 2026-03-08
- Summary: Implemented OAuth2 token flow with refresh logic.
```

If this was the last stage (all stages are now `done`), also change the
file's top-level `Status:` to `completed`.

**This is the most important output of this skill.** Anyone reading
IMPLEMENTATION_PLAN.md must be able to tell at a glance what is done and
what remains.

## Step 5 — Update CURRENT_STATE.md

Update to reflect what the system looks like NOW. If the file does not exist,
create it.

```markdown
# Current State: [Project Name]
Last updated: YYYY-MM-DD (Stage X: [name])

## System Overview
[What the system does now]

## Components
### [Component Name]
- Status: active | new | modified
- Key files: [paths]
- Dependencies: [what it depends on]

## Data Flow
[How data moves through the system]

## APIs / Interfaces
[Public interfaces and contracts]

## Database Schema
[Tables/collections/models, or "n/a"]

## Known Limitations / Tech Debt
[List or "none"]
```

Rewrite the entire file based on what exists after this stage. Future stages
depend on this file being accurate.

## Step 6 — Append to CLAUDE.md

Append the following block. If CLAUDE.md does not exist, create it.

```markdown
## Stage X: [name] (YYYY-MM-DD)

### Decisions
- [decision and rationale]

### Patterns
- [new pattern discovered and when to use it]

### Lessons
- [what went wrong and how to avoid it]

### Preferences
- [technical preferences for future stages]
```

Only add entries that are genuinely useful. Don't pad with obvious statements.

## Step 7 — Update ARCHITECTURE.md (only if needed)

Cross-reference STAGE_X_PLAN.md scope throughout — only check what this stage
could have affected.

**Part A — C4 structure check**

- **L1 — System Context:** Did this stage add or remove an external service, or
  introduce a new type of user/actor? If yes, update the L1 section in
  ARCHITECTURE.md directly (not just a note — edit the actual section), then
  record the change in `## Implementation Notes`.

- **L2 — Containers:** Did this stage add, remove, or significantly change a
  deployable container (web app, API server, worker, database, queue, cache)?
  If yes, update the L2 section and ASCII flow in ARCHITECTURE.md directly,
  then record the change in `## Implementation Notes`.

- **L3 — Components:** Did any component's responsibility shift? Update its
  description in ARCHITECTURE.md and note the reason.

**Part B — TOGAF elements check**

- **Key Data Structures:** Did any cross-boundary data structure gain, lose, or
  rename fields? Update the definition in ARCHITECTURE.md and note the reason.

- **Quality Attributes:** Were any constraints relaxed or found unachievable?
  Document the exception and the accepted trade-off.

For all Part A and Part B changes: add or update an `## Implementation Notes`
section to record what changed and why. Never delete the original target —
append notes below it. Don't silently change the target architecture — flag
all differences.

**Part C — Structural Requirements verification**

For each item below: mark ✓ (met), ✗ (violated or missing), or N/A (not
relevant to this stage's scope).

| # | Item | What to check |
|---|---|---|
| 1 | **Containerisation** | If new services added: Dockerfile + docker-compose entry present and covering them? |
| 2 | **Self-contained repo** | Any secrets/credentials committed? All new env vars in `.env.template` only? |
| 3 | **.gitignore** | If new file types introduced: are they covered by `.gitignore`? |
| 4 | **.env.template** | New env vars introduced this stage? If yes, in `.env.template` with placeholder values and comments? |
| 5 | **No vendor lock-in** | New commercial dependencies (paid APIs, proprietary SDKs) introduced? If yes, flag them. |
| 6 | **Concurrency** | Background jobs added? If yes, lock/singleton coordination mechanism specified in ARCHITECTURE.md? |
| 7 | **Long-running processes** | New long-running operations added? If yes, offloaded to queue/worker with technology named? |
| 8 | **APM monitoring** | Code refactored or new entry points added? If yes, Sentry (or named APM) still initialised? |
| 9 | **Health-check endpoint** | Routing or service structure changed? If yes, health-check endpoint still present and functional? |

Report all results:

```
Structural Requirements:
  ✓ .gitignore — no new file types introduced
  ✗ .env.template — NEW_API_KEY added in code but missing from .env.template
  N/A Concurrency — no background jobs in this stage
  ...
```

**Any ✗ is a blocker.** Ask the user:
> "Structural requirement(s) not met: [list]. Fix them, or explicitly accept
> each one to proceed with a documented exception."

Wait for the user's response before continuing to Step 8.

If implementation matched the plan exactly and all checklist items are ✓ or
N/A, skip to Step 8 without modifying ARCHITECTURE.md.

## Step 8 — Archive stage files

```bash
mkdir -p docs/archive/stage_X_[name]/
cp STAGE_X_PLAN.md docs/archive/stage_X_[name]/
cp STAGE_X_TESTS.md docs/archive/stage_X_[name]/
cp STAGE_X_CHANGES.md docs/archive/stage_X_[name]/
```

Keep originals in the project root. They stay for reference until the project
is complete, at which point they can be cleaned up.

## Step 9 — Sprint retrospective: skill improvement ideas (optional)

Before wrapping up, reflect for a moment — not on the code, but on the *process*.
Across this stage's cycle (/s3-stage-detailed-plan, /s4-stage-execution,
/s5-stage-review, and this skill), did anything about how the workflow skills
themselves behaved get in the way, feel repetitive, or produce a worse result
than it should have?

This is a lightweight retrospective, not a formal audit — closer to a sprint
retro than a code review. Most stages will have nothing worth noting here,
and that's fine: **skip this step silently if nothing significant came up.**
Don't manufacture feedback to fill the section. The bar is "this would
genuinely make the next stage smoother," not "this was slightly annoying once."

If something does clear that bar, append an entry to
`docs/skills-improvement-ideas.md` (create the file and `docs/` directory if
they don't exist):

```
## YYYY-MM-DD — Stage X
Skill(s): [which of s1-s8 this concerns, e.g. "s4-stage-execution" or "s3 + s5"]
Observation: [what happened, concretely — quote the confusing instruction or
  describe the repeated pattern]
Suggested improvement: [a concrete idea, or "not sure — flagging for
  discussion" if you don't have one]
```

This file is **append-only** — never edit or remove previous entries; the
`s9-skill-retro` skill reads and processes them later. Keep entries specific:
"the AC template has no place for X" is useful, "s4 could be better" is not.

## Step 10 — Print terminal summary

```
Stage X: [name] completed. [N] tasks done, [M] skipped.
DoD: [X/Y]. IMPLEMENTATION_PLAN.md updated.
Files archived to docs/archive/stage_X_[name]/.
Next: run /s3-stage-detailed-plan [Y] for Stage [Y].
Optional: run /s7-architecture-audit before the next stage to verify
  there is no cross-stage drift — recommended if 2+ stages are now done.
[If a skill-improvement idea was logged this stage:]
Logged a skill improvement idea to docs/skills-improvement-ideas.md.
  Run s9-skill-retro whenever you want to turn accumulated ideas into proposed
  skill changes.
```

If all stages are complete:
```
All stages complete. IMPLEMENTATION_PLAN.md marked as completed.
```

---

## Constraints

- **REFUSE if no review section** in STAGE_X_CHANGES.md. Tell user: "Run /s5-stage-review before /s6-stage-documenting."
- **REFUSE if review verdict is REWORK.** Tell user: "Review verdict is REWORK. Fix issues via /s4-stage-execution and re-run /s5-stage-review."
- **Actually run DoD commands.** Do not rely on previous run results.
- **CURRENT_STATE.md must be updated.** Future stages read it as ground truth.
- **CLAUDE.md must be updated.** Future sessions depend on it.
- **IMPLEMENTATION_PLAN.md is the key output.** Don't skip it or summarize without updating it.

---

## How this connects to the workflow

- `/s5-stage-review` appends a `## Review:` block to STAGE_X_CHANGES.md — this skill
  requires that block to exist and for the verdict to be PASS.
- `/s4-stage-execution` produced STAGE_X_CHANGES.md session logs — this skill prepends a summary.
- `/s3-stage-detailed-plan` produced STAGE_X_PLAN.md and STAGE_X_TESTS.md — this skill
  reads them for task counts and DoD status.
- `/s2-planing-stages` produced IMPLEMENTATION_PLAN.md — this skill marks the stage done.
- After this skill completes, the cycle restarts: user runs `/s3-stage-detailed-plan` for
  the next stage.
- If Step 9 logged an entry, `s9-skill-retro` (run manually, whenever the user
  chooses) reads `docs/skills-improvement-ideas.md` and proposes concrete
  changes to the affected skill(s) for approval. It never edits skills on
  its own initiative.
- CLAUDE.md and CURRENT_STATE.md updated here are read by ALL subsequent skills.
