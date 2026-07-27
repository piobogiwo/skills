---
name: s7-architecture-audit
description: "Holistic architecture compliance check — compares the entire codebase against ARCHITECTURE.md at any point in the dev workflow. Unique value: cross-stage drift detection that /s5-stage-review (per-stage diff only) cannot catch. Run after multiple stages are done, before starting a new stage, or any time you suspect architectural drift. Trigger on: /s7-architecture-audit, /architecture-audit (legacy alias), 'does the code match the architecture', 'architecture compliance', 'check for drift', 'is our architecture consistent', 'audit the codebase', 'sprawdz architekture', 'czy kod jest zgodny z architektura'."
---

# Architecture Audit

Your job is to compare the actual codebase against the target architecture
and report every meaningful divergence. You only report — you do not fix.

This is a cross-stage view. Unlike /s5-stage-review (which checks one stage's
diff), you look at the entire codebase as it stands today.

## Step 1 — Validate inputs

Read in parallel:

1. **ARCHITECTURE.md** (required) — must exist. If missing, stop:
   > "No ARCHITECTURE.md found. Run /s1-architect first."
   Extract from it:
   - Component list: names, responsibilities, key files they should own
   - Data flow: the intended sequence of operations
   - Technology choices: patterns, libraries, constraints
   - Out of Scope: what should NOT be in the codebase
   - Any naming conventions or structural rules stated explicitly
   - Key Data Structures: cross-boundary data objects with fields, producers, and consumers
   - Quality Attributes: non-functional constraints (security, performance, resilience, compliance)

2. **IMPLEMENTATION_PLAN.md** (optional) — read to understand which stages
   are done. Only done stages are in scope for the audit.

3. **CLAUDE.md** (optional) — project conventions, patterns, preferences.
   These are also compliance targets.

4. **CURRENT_STATE.md** (optional) — ground truth of what was intended to
   exist. Useful for cross-referencing.

Then tell the user:
> "Auditing [N stages done] against ARCHITECTURE.md. Exploring codebase..."

## Step 2 — Explore the codebase

Spawn a subagent to explore the actual codebase in parallel with your
reading of the architecture documents. Give the subagent:
- The component list and key file paths from ARCHITECTURE.md
- Instructions to map: what actually exists vs what was planned

The subagent should report:
- Actual directory structure
- Files that exist in planned locations vs missing
- Files that exist but are NOT in the architecture (undocumented additions)
- Imports and dependencies between modules (to check data flow)

Do NOT give the subagent your session context — clean context only.

## Step 3 — Run the audit

For each element of ARCHITECTURE.md, check actual state and assign a verdict:

**`[OK]`** — matches the architecture
**`[DEVIATION]`** — differs from the architecture; document the gap
**`[MISSING]`** — something specified in architecture doesn't exist yet
**`[UNDOCUMENTED]`** — something exists in code that isn't in architecture

### What to check

**File structure:**
- Are components in the directories specified in ARCHITECTURE.md?
- Are files named consistently with the architecture?
- Are there files in unexpected locations?

**Separation of concerns:**
- Does each module/component do only what ARCHITECTURE.md assigned to it?
- Is any component taking on responsibilities that belong to another?
- Are there cross-component dependencies that violate the intended boundaries?

**Data flow:**
- Does the actual call chain match the diagram in ARCHITECTURE.md?
- Are there shortcuts, bypasses, or extra hops not in the spec?

**Technology choices:**
- Are the specified libraries/frameworks actually used?
- Are any prohibited patterns or out-of-scope items present?

**Naming and conventions (from CLAUDE.md if available):**
- Consistent naming across modules?
- Established patterns followed in later stages?

**Key Data Structures:**

Read the "Key Data Structures" section from ARCHITECTURE.md. For each named
structure, check the codebase:

1. Does it exist in code? Look for: Pydantic models, dataclasses, TypeScript
   interfaces, TypedDicts, named tuples, plain dicts with documented shape —
   any representation of the documented structure.
2. Do the fields match? Compare documented fields against actual field names.
   Flag additions, removals, renames.
3. Is it produced by the stated component? Trace where the structure is
   constructed in code — does it match the "produced by" declaration?
4. Is it consumed by the stated components? Trace imports/calls — do the
   "consumed by" components actually use it?

Use verdict tags:
- `[OK]` — matches the architecture
- `[DEVIATION]` — shape or flow differs from documented
- `[MISSING]` — structure documented but not found in code
- `[UNDOCUMENTED]` — structure exists in code crossing component boundaries
  but is not in ARCHITECTURE.md

If ARCHITECTURE.md has no "Key Data Structures" section, or it says "N/A",
skip this category and note: "Key Data Structures: not specified in
ARCHITECTURE.md — skipped."

**Quality Attributes:**

Read the "Quality Attributes" section from ARCHITECTURE.md. For each attribute,
check what can be verified statically from the codebase:

Security rules:
- "no credentials in code" → grep for hardcoded secrets, API keys, passwords
- "JWT required on all endpoints" → check auth middleware coverage
- "all user input validated" → check validation at entry points
- Any other explicit security rule stated → verify structural enforcement

Performance:
- Caching layers present if required? (Redis, memcache, etc.)
- Obvious N+1 query patterns visible in code?
- Batch operations used where specified?
- Note: response time targets (e.g. <500ms p95) cannot be verified statically —
  flag as `[RUNTIME]`

Resilience:
- Retry logic present where specified? (queue retries, API call retries)
- DLQ or error path implemented for queue/worker failures?
- Pipeline step failure handling matches documented behaviour?

Compliance:
- Any obvious structural violations of stated regulatory constraints?

For each attribute item, report as one of:
- `[OK]` — structurally enforced / present in code
- `[PARTIAL]` — partially present, note what is missing
- `[MISSING]` — specified but no structural enforcement found in code
- `[RUNTIME]` — cannot be verified from static analysis, requires runtime testing
- `[N/A]` — this attribute category not specified in ARCHITECTURE.md

If ARCHITECTURE.md has no "Quality Attributes" section, skip and note:
"Quality Attributes: not specified in ARCHITECTURE.md — skipped."

## Step 4 — Write the report

Format each finding as:

```
[OK] File structure: src/auth/ exists with expected modules
[DEVIATION] Data flow: pipeline/entrypoint.py calls response/ directly,
  bypassing extraction/. Architecture specifies: classify → extract → respond.
  File: src/pipeline/entrypoint.py:47
[MISSING] Component: email_io/poller.py — specified in architecture, not yet created
  Note: may be planned for a later stage
[UNDOCUMENTED] File: src/utils/temp_fix.py — not in architecture, no stage claims it
```

Group findings by category:
1. File structure
2. Separation of concerns / responsibilities
3. Data flow
4. Technology / patterns
5. Undocumented additions
5a. Key Data Structures
5b. Quality Attributes
6. Structural requirements (see below)

### Key Data Structures (group 5a)

For each structure in ARCHITECTURE.md "Key Data Structures", report one line:

```
[OK] EmailRecord: found as Pydantic model at src/models/email.py:12. Fields match.
     Produced by: Ingestion ✓  Consumed by: Classification ✓, DB ✓
[DEVIATION] PipelineResult: status field in code uses "success"/"failure" instead
     of documented "ok"/"error". File: src/pipeline/base.py:34
[MISSING] SummaryOutput: documented in ARCHITECTURE.md, no class or dict found in codebase
[UNDOCUMENTED] BatchJob: dict constructed at src/worker/batch.py:88, crosses
     Worker→DB boundary, not documented in ARCHITECTURE.md
```

If ARCHITECTURE.md has no "Key Data Structures" section:
```
Key Data Structures: not specified in ARCHITECTURE.md — skipped.
```

### Quality Attributes (group 5b)

For each attribute in ARCHITECTURE.md "Quality Attributes", report one line per item:

```
[OK]      Security / no credentials in code: grep found no hardcoded secrets or keys
[MISSING] Security / JWT on all endpoints: auth middleware present but /health and
          /metrics are unprotected — src/api/routes.py:15,23
[PARTIAL] Resilience / queue retries: retry logic present at src/worker/retry.py:8,
          but no DLQ handler found
[RUNTIME] Performance / API response < 500ms p95: cannot verify from static analysis
[N/A]     Compliance: not specified in ARCHITECTURE.md
```

If ARCHITECTURE.md has no "Quality Attributes" section:
```
Quality Attributes: not specified in ARCHITECTURE.md — skipped.
```

### Structural Requirements check

Read the "Structural Requirements" (or equivalent) checklist from ARCHITECTURE.md.
For each item, verify it is actually implemented in the codebase.
Check every item below that is listed in ARCHITECTURE.md — skip items not mentioned
there (mark as N/A):

| Item | What to verify | Finding |
|------|---------------|---------|
| **Containerisation** | Dockerfile exists for each service; docker-compose.yml or Swarm config exists | ✓ / ✗ / N/A |
| **.gitignore** | File exists; covers `.env`, `*.env`, `.env.*`, secrets, credentials, private keys; covers OS files, editor dirs, dependency dirs, build artefacts | ✓ / ✗ / N/A |
| **.env.template** | File exists; lists all env vars the application needs (cross-check against actual code usage); no real values present | ✓ / ✗ / N/A |
| **APM monitoring** | Named APM SDK is imported and initialised in the codebase; note the file and line | ✓ / ✗ / N/A |
| **Health-check endpoint** | `GET /health` (or the path specified in ARCHITECTURE.md) is implemented and returns a response | ✓ / ✗ / N/A |
| **Concurrency / singleton** | If background jobs exist, the specified lock or singleton mechanism is implemented | ✓ / ✗ / N/A |
| **Long-running processes** | The specified queue/worker technologies (e.g. Celery, BullMQ, Sidekiq) are present in the codebase | ✓ / ✗ / N/A |

Report each item as one line:
```
✓ .gitignore: exists, covers .env, secrets, OS files, editor dirs, dependency dirs
✗ .env.template: file missing — unknown which env vars the application requires
✓ Health-check: GET /health implemented at src/api/health.py:12
N/A APM monitoring: not listed as a requirement in ARCHITECTURE.md
```

Any ✗ is a finding. Severity:
- `.gitignore` or `.env.template` missing → **[CRITICAL]** (secrets risk)
- Any other ✗ → **[IMPORTANT]**

Include these findings in the main findings list under category 6, using the
`[DEVIATION]` or `[MISSING]` tags plus the severity label, e.g.:

```
[MISSING][CRITICAL] .env.template does not exist — env var contract is undefined
  and secrets may be hardcoded or undocumented.
[MISSING][IMPORTANT] Health-check endpoint: no GET /health route found in codebase.
  Architecture requires it at /health.
```

At the end, print a summary:

```
## Audit Summary
Stages audited: N (Stage 0 through Stage N)
Total findings: X
  [OK]: N
  [DEVIATION]: N  ← these need attention (includes Key Data Structures deviations)
  [MISSING]: N    ← may be planned for future stages (includes Key Data Structures + Quality Attributes missing)
  [UNDOCUMENTED]: N  ← investigate, may be drift or intentional
  [PARTIAL]: N   ← Quality Attributes partially enforced
  [RUNTIME]: N   ← cannot verify statically; requires runtime testing (not counted as findings)

## Priority deviations (fix before next stage):
1. [description] — File: path:line
2. ...

## Notes
- MISSING items in future-stage scope are expected — not blockers
- UNDOCUMENTED items should be either documented in ARCHITECTURE.md
  or removed if they are accidental drift
- RUNTIME items are informational — add to test plan, not a code fix
- MISSING Quality Attributes items are severity [IMPORTANT]
```

## Step 5 — Suggest next action

Based on findings:

- **No DEVIATION or UNDOCUMENTED findings:** "Architecture is consistent. Safe to continue with /s3-stage-detailed-plan N."
- **DEVIATIONs found:** "Recommend addressing these before the next stage — deviations now compound across future stages. Options: (a) fix via /s4-stage-execution, (b) accept and update ARCHITECTURE.md to reflect the new intent.
  If you accept a deviation, record it in CLAUDE.md (one line per item) so it's
  visible to future /s5-stage-review and /s6-stage-documenting runs. CLAUDE.md is the project
  memory — accepted architectural decisions belong there."
- **Many UNDOCUMENTED items:** "Investigate undocumented files before proceeding — they may indicate scope creep or accidental drift."

## Constraints

- **Do not fix anything.** Your job is to report. If you spot a bug or
  deviation, log it — do not change the code.
- **MISSING items are not always problems.** If a stage that creates a
  component hasn't run yet, MISSING is expected. Cross-check with
  IMPLEMENTATION_PLAN.md stage statuses.
- **Clean subagent context.** The exploration subagent should not receive
  your session history — only the architecture spec and instructions.
- **Do not update ARCHITECTURE.md** yourself. If deviations are intentional,
  the human must update the architecture — not you.

## How this connects to the workflow

- Run after multiple stages are complete to catch cross-stage drift
- Run before starting a complex new stage to verify the foundation
- Complements /s5-stage-review (per-stage diff) — not a replacement for it
- If deviations found: user decides whether to fix (back to /s4-stage-execution)
  or accept and update ARCHITECTURE.md
- Does not write to any project files — output is reported to user only
