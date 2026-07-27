---
name: s3-stage-detailed-plan
description: >
  Third step in the dev workflow — details a single stage from an approved
  IMPLEMENTATION_PLAN.md. Produces STAGE_X_PLAN.md and STAGE_X_TESTS.md for
  one specific stage before execution begins.

  Trigger on: /s3-stage-detailed-plan, /s3-stage-detailed-plan N, /single-stage-detailed-plan (legacy alias), "plan this stage", "detail stage N",
  "prepare stage", "what's in stage N", "stage plan". Also trigger when user
  runs /s4-stage-execution but no STAGE_X_PLAN.md exists for the current stage.

  Do NOT trigger if STAGE_X_PLAN.md already exists and Status is `approved`.
---

# Stage Plan

Your job is to take one stage from the master implementation plan and produce
a detailed task breakdown and test plan for it. You produce two files:
`STAGE_X_PLAN.md` and `STAGE_X_TESTS.md`. These feed directly into `/s4-stage-execution`,
which won't proceed without an approved plan.

## Step 1 — Validate inputs

**Before anything else:** scan the project root for `STAGE_*_PLAN.md` files.
If any has `Status: active`, warn the user and wait for confirmation:
> "STAGE_N_PLAN.md is already active (Status: active). Starting another stage
> in parallel may cause conflicts. Are you sure you want to detail Stage X now?"

Then check:

1. **IMPLEMENTATION_PLAN.md** (required) — must exist in the project root AND
   have `Status: approved` or `Status: active`. If it doesn't exist or Status
   is `draft`, stop and tell the user:
   > "Approve the implementation plan first."

   After confirming the stage to detail (item 2 below): if IMPLEMENTATION_PLAN.md
   Status is `approved` AND no other stage has Status `in_progress` or `done`
   (i.e., this is the first stage being detailed), update IMPLEMENTATION_PLAN.md
   Status from `approved` to `active`. If it's already `active`, leave it as-is.

2. **Stage to detail** — if the user specified a number (e.g., `/s3-stage-detailed-plan 2`),
   use that. Otherwise, find the first stage with `Status: todo`. If the
   requested stage has `Status: done`, tell the user it's already complete
   and ask which stage they want.

3. **ARCHITECTURE.md** (required) — must exist. Read it fully:
   - Target architecture (L1/L2/L3) — what we're building toward
   - Key Data Structures — data shapes crossing component boundaries;
     use these to write precise AC (e.g. "returns EmailRecord with
     all required fields populated")
   - Quality Attributes — non-functional constraints; any that apply
     to this stage must appear in the DoD (e.g. "response < 500ms",
     "no credentials in code")
   - Structural Requirements — if this stage introduces a new container
     or endpoint, verify Docker, health-check, and APM requirements apply

Read these in parallel with the above:

4. **CLAUDE.md** (optional) — project memory: patterns, conventions, preferences.

5. **CURRENT_STATE.md** (optional) — what exists now.

6. **Previous STAGE_N_CHANGES.md files** (optional) — if detailing Stage 3,
   read STAGE_1_CHANGES.md and STAGE_2_CHANGES.md to understand what was
   already built. Don't guess — read them.

7. **The codebase** — spawn a subagent to explore the specific files and
   modules in this stage's scope. Read the actual code; don't invent
   function signatures or module paths.

## Step 2 — Design the tasks

Break the stage into small, concrete tasks. Each task should be completable
in a few hours at most. If something feels like more than half a day, split it.

**What makes a good task:**
- Names a specific file or function to create or modify
- Has one verifiable acceptance criterion — something you can check by
  running a command or inspecting output
- Is small enough that a test can be written for it before coding starts
- Depends on as few other tasks as possible

**Task sizing:**
- S — under 2 hours: a single function, a config change, a small file
- M — 2–4 hours: a module, a set of related functions, a meaningful refactor
- L — 4–8 hours: a subsystem; if bigger, split it

## Step 3 — Write STAGE_X_PLAN.md

Produce this file in the project root (X = stage number). Use this exact format:

```
# Stage X Plan: [Stage Name]
Date: YYYY-MM-DD
Source: IMPLEMENTATION_PLAN.md → Stage X
Status: draft

## Goal
[What this stage achieves — copied or paraphrased from IMPLEMENTATION_PLAN.md]

## Scope Boundary
### In scope
[Exact files, modules, functions to create or modify — reference real paths]
### Out of scope
[What we're NOT touching in this stage — be explicit to prevent drift]

## Tasks
| # | Task | Files | Size | Deps | Status | AC |
|---|------|-------|------|------|--------|----|
| X.1 | [description] | [file paths] | S/M/L | — | [ ] | [verifiable criterion] |
| X.2 | [description] | [file paths] | S | X.1 | [ ] | [verifiable criterion] |
| X.3 | [description] | [file paths] | M | X.1 | [ ] | [verifiable criterion] |

Task status values: [ ] todo, [~] in progress, [x] done, [-] skipped

## Next Step
> Approve this plan (change Status to `approved`), then run `/s4-stage-execution`.
```

**Acceptance criteria must be verifiable.** Examples:
- ✅ "`pytest tests/auth/test_login.py` passes"
- ✅ "`npm run build` exits 0 with no type errors"
- ✅ "GET /api/users returns 200 with user list"
- ❌ "Code is clean" (not verifiable)
- ❌ "Logic is correct" (not verifiable)

## Step 4 — Detect the test framework

Before writing tests, find the actual test setup:
- Look for pytest.ini, setup.cfg, pyproject.toml (`[tool.pytest]`), jest.config.*,
  vitest.config.*, package.json (`scripts.test`), etc.
- Run a search for test files to find the pattern (`test_*.py`, `*.test.ts`, etc.)
- If no test infrastructure exists, the first DoD item should be:
  "Set up test framework — recommend [framework based on stack]"

Don't assume pytest or jest. Check.

## Step 5 — Write STAGE_X_TESTS.md

Produce this file in the project root alongside the plan. Use this format:

```
# Stage X Tests & DoD: [Stage Name]
Date: YYYY-MM-DD
Source: STAGE_X_PLAN.md

## Test Infrastructure
- Framework: [detected from project]
- Test command: [actual command, e.g., `pytest tests/`]
- Coverage command: [actual command or N/A]

## Unit Tests
#### Task X.1: [name]
- [ ] Test: [description] — verifies AC: [reference]
- [ ] Test: [description] — edge case: [what]

#### Task X.2: [name]
- [ ] Test: [description] — verifies AC: [reference]

## Integration Tests
- [ ] [description — tests interaction between components]

## Regression Tests
- [ ] All existing tests still pass after each task (`[command]`)
- [ ] [specific regression scenarios relevant to this stage]

## Definition of Done
- [ ] All new tests pass (`[actual command]`)
- [ ] All existing tests still pass (`[actual command]`)
- [ ] No lint errors (`[actual lint command]`)
- [ ] No type errors (`[actual type-check command]`)
- [ ] No changes outside stage scope (or deviations documented)
- [ ] Key Data Structures produced by this stage match shapes in
      ARCHITECTURE.md (field names, types, required fields)
- [ ] Any Quality Attributes relevant to this stage are verified
      (performance targets met, security rules observed)
- [ ] STAGE_X_CHANGES.md written with what was done
- [ ] Code reviewed by independent agent or human
- [ ] Human verification completed where applicable
- [ ] [any custom items for this stage]

## Next Step
> Run `/s4-stage-execution` to start implementing this stage.
```

After writing, ask the user:
> "Do you have any custom items to add to the Definition of Done?"

## After writing both files

Tell the user:
> "STAGE_X_PLAN.md and STAGE_X_TESTS.md are ready. Review the task breakdown
> and acceptance criteria. When you're satisfied, change `Status: draft` to
> `Status: approved` in STAGE_X_PLAN.md, then run `/s4-stage-execution`."

If you're on a lighter model, mention:
> "Opus is recommended for planning — the task breakdown and acceptance criteria
> may be less precise on Sonnet or Haiku."

## How this connects to the workflow

- `/s2-planing-stages` produces IMPLEMENTATION_PLAN.md — this skill reads it to find
  the stage to detail
- `/s1-architect` produces ARCHITECTURE.md — this skill reads it for context and
  to write meaningful acceptance criteria
- `/s4-stage-execution` reads STAGE_X_PLAN.md (requires `Status: approved`) and
  STAGE_X_TESTS.md to drive implementation — it updates task statuses in
  STAGE_X_PLAN.md and checks off tests in STAGE_X_TESTS.md
- `/s5-stage-review` reads both files to verify the implementation matches the plan
- `/s6-stage-documenting` reads both files and prepends a summary to STAGE_X_CHANGES.md
  (which `/s4-stage-execution` created during implementation)

This skill sets IMPLEMENTATION_PLAN.md Status to `active` when detailing
the first stage (if it was still `approved`).

Don't update stage statuses in IMPLEMENTATION_PLAN.md yourself.
Don't set STAGE_X_PLAN.md to `approved` yourself — that's the human's sign-off.
