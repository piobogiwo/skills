---
name: s5-stage-review
description: 'Fifth step in the dev workflow — independent verification of a completed stage before /s6-stage-documenting can close it. Trigger on: /s5-stage-review, /review-stage (legacy alias), /review (legacy alias), "review", "code review", "verify", "check the code", "quality gate", "done with this stage". Also trigger when the user says the stage is finished and wants to close it. Do NOT trigger if STAGE_X_CHANGES.md does not exist — means /s4-stage-execution has not run yet.'
---

# Review

Your job is to independently verify a completed stage. The core rule:
**the agent that implements is NOT the agent that reviews.** You spawn
ringfenced subagents with clean context — they never share the /s4-stage-execution
conversation history. You do not fix anything. You only verify.

## Step 1 — Validate inputs

Read all of these before doing anything else:

1. **STAGE_X_PLAN.md** (required) — find the file with `Status: active` in
   the project root. That's the stage currently in progress.
   - If no file exists at all, stop: "Run /s3-stage-detailed-plan first."
   - If the user specified a stage number (e.g., `/review 2`), use
     STAGE_2_PLAN.md. Otherwise, search for whichever STAGE_*_PLAN.md
     has `Status: active`.
   - If Status is `draft` or `approved`, stop: "Run /s4-stage-execution first —
     the stage plan hasn't been activated yet."

2. **STAGE_X_TESTS.md** (required) — must exist. Contains the DoD and
   test commands. If it doesn't exist, stop: "Run /s3-stage-detailed-plan first."

3. **STAGE_X_CHANGES.md** (required) — must exist. If it doesn't exist,
   stop: "Run /s4-stage-execution first — STAGE_X_CHANGES.md has not been created yet."

4. **ARCHITECTURE.md** (required) — must exist. Read it fully before
   spawning subagents. Extract and pass to Subagent A:
   - The relevant L3 Components for this stage's scope
   - Any Key Data Structures produced or consumed by this stage
   - Any Quality Attributes that apply to this stage's work
   - Structural Requirements — extract the checklist items specified
     (Docker, .gitignore, .env.template, APM, health-check, concurrency,
     long-running processes, vendor lock-in). Pass these to Subagent A.
   These become part of the spec the code review subagent checks against.
   If it doesn't exist, stop: "ARCHITECTURE.md is missing — run /s1-architect first."

5. **CLAUDE.md** (optional) — read if it exists.

Then get the code diff:

```bash
git diff [branch-point]..HEAD
```

If no git repo or no clear branch point, try:
- `git diff HEAD~1` (last commit)
- `git diff --stat HEAD~1` to see what changed

Tell the user what diff command you're using and why. If you can't determine
a useful diff, ask the user which commits or ref to diff against.

## Step 2 — Run subagents in parallel

Spawn BOTH subagents at the same time. They are independent — don't wait
for one before starting the other.

---

### Subagent A: Code Review

**CLEAN CONTEXT.** This subagent receives ONLY:
- Contents of STAGE_X_PLAN.md
- Contents of ARCHITECTURE.md
- Contents of CLAUDE.md (if it exists)
- The full git diff output

**Do NOT give it:**
- STAGE_X_CHANGES.md (no implementation narrative)
- Any context from the /s4-stage-execution session
- Any context from the current conversation

**Subagent prompt template:**

> You are an independent code reviewer. You have no knowledge of how this
> code was implemented — only what it should do and what it does.
>
> Here is the spec (what should have been built):
> [STAGE_X_PLAN.md contents]
>
> Here is the target architecture:
> [ARCHITECTURE.md contents]
>
> [If CLAUDE.md exists:]
> Here are the project conventions:
> [CLAUDE.md contents]
>
> Here is the code diff — all changes made during this stage:
> [git diff output]
>
> Review this diff against the spec. For each task in the plan, check:
> 1. Does the code satisfy the acceptance criterion?
> 2. Does it follow the target architecture?
> 2a. Do any data structures produced or returned by new/modified code
>      match the shapes defined in ARCHITECTURE.md Key Data Structures?
>      Check: field names, required fields, types where inferable.
> 2b. Are Quality Attributes from ARCHITECTURE.md respected?
>     Check each attribute relevant to this stage: performance constraints,
>     security rules, resilience patterns.
> 2c. Are Structural Requirements from ARCHITECTURE.md respected?
>     For each checklist item relevant to this stage's changes:
>     - If this stage introduces a new service or container: is a Dockerfile /
>       docker-compose entry present in the diff?
>     - If this stage adds endpoints: is a health-check endpoint present or updated?
>     - If this stage adds background jobs: is concurrency/lock strategy addressed?
>     - If this stage introduces a new APM-monitored component: is SDK
>       initialisation in the diff?
>     - If .gitignore or .env.template are not yet present in the repo: flag it.
>     Only check items that are relevant to what this stage touches — skip
>     inapplicable ones and say so.
> 3. Does it follow the project conventions (if provided)?
> 4. Any code quality issues: naming, structure, error handling, edge cases?
> 5. Any bugs or logic errors?
> 6. Security — check each of the following:
>    - Injection risks: SQL, command, template, or path injection in any
>      new input handling
>    - Authentication / authorisation: are new endpoints or functions
>      properly gated? Could a user access another user's data?
>    - Input validation: is untrusted input (user-supplied, API response,
>      file content) validated and sanitised before use?
>    - Secrets exposure: are credentials, tokens, or keys hardcoded,
>      logged, or returned in responses?
>    - Sensitive data leakage: are PII or internal details exposed in
>      error messages, logs, or API responses?
>    - Dependency risk: are any new packages added? If so, flag them for
>      manual version/CVE check.
>    If none of these apply to this diff, state "No security concerns
>    identified" — do not skip the section silently.
> 7. Any out-of-scope changes (files modified that are NOT in the plan scope)?
>
> Produce:
> - Verdict: PASS | CONCERNS | REWORK
>   - PASS: code satisfies all AC, no critical issues
>   - CONCERNS: code works but has notable issues worth discussing
>   - REWORK: one or more AC not met, or critical bug found
> - Findings list. For each finding:
>   - Severity: [CRITICAL] | [IMPORTANT] | [MINOR]
>   - Location: file:line
>   - Description: what the issue is
>   Include a "Security" subsection (even if empty — write "No security
>   concerns identified" if nothing was found).
>
> If there are no findings outside of security, say "No findings."

Subagent produces: verdict (PASS/CONCERNS/REWORK) + list of findings
with severity and file:line references, including a "Security" subsection
(even if empty).

---

### Subagent B: Test Verification

**CLEAN CONTEXT.** This subagent receives ONLY:
- Contents of STAGE_X_TESTS.md
- Access to the codebase (to run the tests)

**Do NOT give it:**
- STAGE_X_CHANGES.md
- Any context from the /s4-stage-execution session
- Any context from the current conversation

**Subagent prompt template:**

> You are an independent test verifier. You did not write this code.
>
> Here is the test plan and Definition of Done:
> [STAGE_X_TESTS.md contents]
>
> Your job:
> 1. Run ALL test commands listed in the "Test Infrastructure" section.
> 2. Run regression tests as specified.
> 3. For any tests marked [ ] (not yet run), write and run them now.
>    Use the test framework specified in STAGE_X_TESTS.md.
>
> Report:
> - For each test command: the exact command run and its result (X passed, Y failed)
> - For any failures: test name and reason
> - Overall: X passed, Y failed across all suites

---

## Step 3 — Human verification

Present the results from both subagents to the user. Then walk through the
DoD checklist from STAGE_X_TESTS.md item by item.

For each item in "Definition of Done":
- If it's an automated check (tests pass, lint clean, etc.) — report whether
  the subagent confirmed it
- If it requires human judgment — ask the user to confirm:
  > "[DoD item] — can you confirm this is met?"

Wait for the user's responses before proceeding.

## Step 4 — Write the review section

Append the following block to STAGE_X_CHANGES.md:

```
---
## Review: YYYY-MM-DD

### Code Review (independent agent)
- Verdict: PASS | CONCERNS | REWORK
- Findings:
  - [CRITICAL] file:line — description
  - [IMPORTANT] file:line — description
  - [MINOR] file:line — description

### Test Verification (independent agent)
- Command: [what was run]
- Result: X passed, Y failed
- Failures:
  - [test name] — [reason]

### Human Verification
- [DoD item]: confirmed | not confirmed
- [DoD item]: confirmed | not confirmed
- Notes: [human feedback, or "none"]

### Overall Verdict: PASS | REWORK
---
```

**Overall Verdict rules:**
- PASS if: code review is PASS or CONCERNS (user accepted), all tests pass,
  all DoD items confirmed
- REWORK if: code review is REWORK, any tests fail, or any DoD item not
  confirmed and user did not explicitly accept the exception

Also update STAGE_X_TESTS.md: check off `[x]` any DoD items that were
confirmed.

## Step 5 — Present the verdict

**If verdict is PASS:**
> "Stage X passed review. Run /s6-stage-documenting to close the stage and update
> project memory."

**If verdict is REWORK:**
> "Stage X needs rework. Issues found:
> [list of CRITICAL and IMPORTANT findings from code review]
> [list of test failures]
> [list of unconfirmed DoD items]
>
> Options:
> a) Go back to /s4-stage-execution to fix these, then run /s5-stage-review again.
> b) Accept with documented exceptions (I'll note them in STAGE_X_CHANGES.md).
> c) Reject the stage entirely."

Wait for the user's choice. If they choose (b), record the exceptions in
the review section under "Human Verification / Notes" and set Overall
Verdict to PASS-WITH-EXCEPTIONS.

**If verdict is CONCERNS:**
Present the concerns and ask the user whether to PASS or REWORK. The user
decides — don't decide for them.

---

## Constraints

- **Do not fix code.** If you spot a bug, report it. Don't patch it.
- **Do not share /s4-stage-execution context** with the review subagents. Independence
  is the point — a reviewer who read the implementation notes is not independent.
- **Do not skip the human verification step.** /s6-stage-documenting checks for a
  review section; it won't proceed without one.
- **Do not run both subagents sequentially** when you can run them in parallel.

---

## How this connects to the workflow

- `/s4-stage-execution` produces STAGE_X_CHANGES.md, marks tasks `[x]` in STAGE_X_PLAN.md,
  and checks off tests in STAGE_X_TESTS.md. This skill reads all of those.
- `/s6-stage-documenting` reads STAGE_X_CHANGES.md for the review section this skill appends.
  It refuses to proceed if no review section exists or verdict is REWORK.
- If verdict is REWORK: user returns to `/s4-stage-execution` to fix, then runs `/s5-stage-review`
  again. Each review run appends a new review block — don't overwrite.
- This skill does NOT modify STAGE_X_PLAN.md or IMPLEMENTATION_PLAN.md.
