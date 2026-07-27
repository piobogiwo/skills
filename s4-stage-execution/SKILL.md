---
name: s4-stage-execution
description: >
  Fourth step in the dev workflow — iterative implementation of a single stage.
  Reads STAGE_X_PLAN.md and STAGE_X_TESTS.md, implements tasks one at a time,
  runs tests after each, and maintains a STAGE_X_CHANGES.md log.
  Trigger on: /s4-stage-execution, /stage-execution (legacy alias), /execute (legacy alias), "implement", "start
  coding", "next task", "continue implementation", "pick up where we left off",
  "execute the plan", "let's code this", "start the stage". Also trigger when
  the user says something like "let's do the work" or "implement stage N" even
  without /s4-stage-execution.
  Do NOT trigger if no STAGE_X_PLAN.md exists — suggest /s3-stage-detailed-plan instead.
---

# Execute

Your job is to implement one stage, one task at a time. You read the approved
stage plan and test plan, implement the code, run the tests, and record what
happened. You are the implementation engine — steady, methodical, scope-aware.

## Step 1 — Validate inputs

Read all of these before doing anything else:

1. **STAGE_X_PLAN.md** (required) — must exist in the project root.
   - If it doesn't exist, stop: "Run /s3-stage-detailed-plan first to create the stage plan."
   - If `Status: draft`, stop: "Approve the stage plan first — change Status to
     `approved` in STAGE_X_PLAN.md."
   - If `Status: approved`, change it to `active` now and save the file.
     Also update the corresponding Stage X entry in IMPLEMENTATION_PLAN.md:
     change its Status from `todo` to `in_progress`. This is the only write
     this skill makes to IMPLEMENTATION_PLAN.md.
   - If `Status: active`, you're resuming — read STAGE_X_CHANGES.md to find
     where you left off.

2. **STAGE_X_TESTS.md** (required) — must exist alongside the plan.
   - If it doesn't exist, stop: "Run /s3-stage-detailed-plan first to create the test plan."
   - Read the test commands here — these are the exact commands you'll run.
     Don't invent your own.

Read these in parallel:

3. **STAGE_X_CHANGES.md** (optional) — if it exists, read it to understand
   what has already been completed. Don't redo completed tasks.

4. **IMPLEMENTATION_PLAN.md** (optional) — overall context: what stage we're
   in, what comes after this one.

5. **CLAUDE.md** (optional) — project memory: coding conventions, patterns,
   preferences. Follow these; don't freelance.

6. **CURRENT_STATE.md** (optional) — what already exists in the system.

Then read the actual code in the scope of the current task before touching it.

## Step 2 — Orient

After reading the inputs, briefly tell the user:

- Which stage this is and what it achieves
- How many tasks are in the plan and how many are already done
- Which task you're starting with
- What the first task's acceptance criterion is

If resuming, say: "Resuming Stage X — tasks A, B, C are done. Starting with
task D."

## Step 3 — The execution loop

Work through tasks one at a time. For each task:

### 3a. Pre-task check

Before writing any code, verify that the files you're about to touch are
listed in the STAGE_X_PLAN.md scope section or task table. If a file you
need to modify is **not** in the plan:

> "This change affects `[file]` which is outside the approved scope. Should
> I proceed? I'll document this as a deviation."

Wait for confirmation. If yes, note it in STAGE_X_CHANGES.md under the
current task. If no, find another approach that stays in scope.

### 3b. Show your plan for this task

Before implementing, tell the user:
- What you're implementing (task name + what it does)
- Which files you'll create or modify
- What tests you'll run afterward
- The acceptance criterion

Keep it brief — a few lines. The user should be able to say "go" or "wait,
that's wrong" before you write anything.

### 3c. Implement

Write the code. Stay within the task scope. If you discover something that
needs changing outside the current task, note it for later — don't fix it
now unless it blocks the current task from compiling or running.

### 3d. Run tests

After implementing, run the tests exactly as specified in STAGE_X_TESTS.md
for this task. Also run regression tests if specified.

- If tests pass: move to 3e.
- If tests fail: diagnose the root cause before changing anything. See
  "Root-cause discipline" below.

If a non-trivial problem took more than a couple of attempts to solve, write
a troubleshooting note — see "Troubleshooting" below.

---

## Root-cause discipline

When a test fails or an error appears, **find out why before touching code**.

A failing test is a signal. Patching the symptom — catching the exception,
suppressing the output, adjusting the assertion — makes the signal go away
without fixing what it's pointing at. The real problem stays in the code,
moves deeper, and becomes much harder to find later.

**Required before any fix:**
1. Read the full error message and stack trace.
2. Form a hypothesis: what in the implementation could cause exactly this?
3. Verify the hypothesis by reading the relevant code — don't guess.
4. Only then make a change that addresses the identified root cause.

**Error handling has one legitimate use: external system boundaries.**
Try/except, retries, and fallbacks are appropriate when the code interacts
with things outside the process — network calls, file I/O, external APIs,
databases, queues. Those can fail for reasons outside your control, and
handling those failures gracefully is correct design.

Error handling is NOT appropriate for internal logic. If your own function
raises an exception, that's a bug — catch it at the source, not at the caller.
If a null appears where it shouldn't, fix why it's null, don't add a
null-check guard.

**Signs you're patching instead of fixing:**
- Adding a try/except to silence a crash in internal logic
- Adding a null-check to hide a value that should never be null
- Changing a test assertion to match wrong output
- Skipping or commenting out a failing test
- Adding special-case logic to make one specific input work

If you can't identify the root cause after a thorough read, tell the user:
"I'm stuck on [error]. My best hypothesis is [X] but I'm not confident.
Can you take a look?" Don't guess-and-patch in a loop.

---

### 3e. Record and check off

After tests pass:

1. Mark the task `[x]` in STAGE_X_PLAN.md. If the task was only partially
   completed (e.g., blocked mid-way), use `[~]` instead. Add a note in the
   task row explaining what was done and what remains.
2. Check off the corresponding tests in STAGE_X_TESTS.md.
3. Append a session entry to STAGE_X_CHANGES.md (format below).

### 3f. Confirm before moving on

Tell the user the task is done and what the tests showed. Ask:

> "Task X.[n] complete. Ready to move to X.[n+1]: [task name]?"

Wait for a "yes" or "go" before starting the next task. Don't auto-chain
through all tasks without pause — each task is a checkpoint.

### Loop until all tasks are done.

## Skipping a stage

If the user asks to skip this stage entirely:

1. Update the Stage X entry in IMPLEMENTATION_PLAN.md: set `Status: skipped`
   and add a `Reason: [user-provided reason]` field.
2. Change STAGE_X_PLAN.md `Status` to `skipped`.
3. Tell the user: "Stage X marked as skipped. Run /s3-stage-detailed-plan [N+1] to
   proceed to the next stage."

Do NOT run /s6-stage-documenting for a skipped stage — there is nothing to close out.

---

## Step 4 — When all tasks are complete

1. Run through the Definition of Done checklist in STAGE_X_TESTS.md. For
   each item, check whether it's met.

2. Report to the user:
   > "DoD: X/Y items met."

   List any items not met and what would be needed to close them.

3. Tell the user:
   > "Run /s5-stage-review for an independent code review and test verification before
   > closing this stage."

Don't mark the stage done yourself. That's for /s5-stage-review to confirm.

---

## STAGE_X_CHANGES.md format

This file is **append-only**. Never edit or delete previous entries.

When you open a new work session (or complete the first task), append:

```
---
## Session: YYYY-MM-DD HH:MM

### Task X.[number]: [task name]
- Status: completed | partial | blocked
- Changes: [list of files created or modified]
- Tests: [X passed, Y failed — if failed, note which ones and why]
- Scope: within plan | deviation (reason: [why you touched an out-of-scope file])
- Notes: [any decisions, surprises, or things the next session should know]

### Task X.[number]: [task name]
...

### Problems Encountered
- [brief description of problem] → see troubleshooting/solved/[filename].md
---
```

If no problems were encountered, omit the "Problems Encountered" section.

---

## Troubleshooting notes

When you hit a non-trivial problem (something that took real effort to
diagnose or that might recur), write a note:

**Location:** `troubleshooting/solved/YYYY-MM-DD-[short-description].md`
**Create the directory** if it doesn't exist.

**Format:**
```
# [Short description of the problem]
Date: YYYY-MM-DD
Stage: X, Task: X.[n]

## Symptom
[What went wrong — error messages, failing tests, unexpected behavior]

## Diagnosis
[What the root cause was]

## Fix
[What you changed and why it works]

## Affected files
- [file path]
```

Reference the filename in STAGE_X_CHANGES.md so it's easy to find.

---

## Scope discipline

The stage plan defines what you're allowed to touch. Respecting this
boundary matters for two reasons: it keeps the review manageable, and it
prevents cascading side effects that weren't planned for.

When you're tempted to "just fix this thing over here" — resist. Note it
in STAGE_X_CHANGES.md and surface it to the user as a candidate for a
future task or stage. Undocumented drift is how implementation plans fall
apart.

---

## How this connects to the workflow

- `/s3-stage-detailed-plan` produces STAGE_X_PLAN.md and STAGE_X_TESTS.md — this skill
  reads both and updates them (status updates and test checkoffs only).
- `/s5-stage-review` reads STAGE_X_PLAN.md, STAGE_X_TESTS.md, and STAGE_X_CHANGES.md
  to verify the implementation — run it after all tasks are done.
- `/s6-stage-documenting` reads STAGE_X_CHANGES.md to update CLAUDE.md, CURRENT_STATE.md,
  and IMPLEMENTATION_PLAN.md — run it after /s5-stage-review passes.
- This skill sets the corresponding stage Status in IMPLEMENTATION_PLAN.md
  to `in_progress` when starting a stage (or `skipped` if the user skips it).
  All other updates to IMPLEMENTATION_PLAN.md are /s6-stage-documenting's job.
- This skill does NOT modify CLAUDE.md or CURRENT_STATE.md — those are
  /s6-stage-documenting's job.
