---
name: s1-architect
description: "Strategic planning skill — first step in the dev workflow: /s1-architect → /s2-planing-stages → /s3-stage-detailed-plan → /s4-stage-execution → /s5-stage-review → /s6-stage-documenting. Produces ARCHITECTURE.md. Use whenever the user wants to design a system, plan a feature, or think through architecture. Trigger on: /s1-architect, /architect (legacy alias), 'let's design', 'architect this', 'system design', 'plan the architecture', 'I want to build', 'where do we start'. Also trigger proactively when a non-trivial feature is described and no ARCHITECTURE.md exists yet."
---

# Architect

Your job is to help the user design what they're building before any code
is written. The output is ARCHITECTURE.md — a self-contained document that
anyone can read to understand the system and what we're building toward.

This document feeds directly into `/s2-planing-stages`, which won't proceed
without it. So it needs to be good: grounded in the actual codebase,
clear about what's in scope and what isn't, and honest about uncertainty.

## Step 0 — Onboarding: read artifacts, orient, ask

Before doing anything else, scan the project root for existing workflow artifacts:

- `ARCHITECTURE.md` — does it exist? What is its Status?
- `IMPLEMENTATION_PLAN.md` — does it exist? What is its Status? Which stages are done/active?
- `STAGE_*_PLAN.md` — any active stage plans? What is the Status of the active one?
- `STAGE_*_CHANGES.md` — does one exist for the active stage? Does it contain a `## Review:` block? Does it contain a `## Summary` block at the top?
- `CURRENT_STATE.md` — does it exist?

Print a brief summary (max 5 lines) of what you found. Example:
> ARCHITECTURE.md: exists (Status: approved)
> IMPLEMENTATION_PLAN.md: exists (Status: active) — Stage 1 done, Stage 2 in_progress
> STAGE_2_PLAN.md: active
> CURRENT_STATE.md: exists

Then ask the user:

> **What are we doing in this session?**
> 1. **New project or feature** — design something from scratch (I'll run /s1-architect normally)
> 2. **Extend/update architecture** — ARCHITECTURE.md exists but needs changes
> 3. **Just orient me** — show me where we are and what comes next

Wait for the answer before proceeding.

**Routing based on answer:**

- **"New project"** or **"1"** → continue to Step 1 below (full architect flow)
- **"Extend/update"** or **"2"** → read existing ARCHITECTURE.md, ask what needs to change, then proceed from Step 2
- **"Orient me"** or **"3"** → based on artifacts found, tell the user what the logical next command is:
  - No ARCHITECTURE.md → "Run /s1-architect to start designing."
  - ARCHITECTURE.md Status: draft → "ARCHITECTURE.md is a draft — review it and set Status: approved, then run /s2-planing-stages."
  - ARCHITECTURE.md approved, no IMPLEMENTATION_PLAN.md → "Run /s2-planing-stages to break the architecture into stages."
  - IMPLEMENTATION_PLAN.md Status: draft → "IMPLEMENTATION_PLAN.md needs approval — review and set Status: approved, then run /s3-stage-detailed-plan."
  - IMPLEMENTATION_PLAN.md Status: approved, no STAGE_X_PLAN.md → "Run /s3-stage-detailed-plan 0 (or /s3-stage-detailed-plan 1 if no Stage 0) to start detailing the first stage."
  - IMPLEMENTATION_PLAN.md active, STAGE_X_PLAN.md Status: approved (not yet started) → "Run /s4-stage-execution to start Stage X."
  - IMPLEMENTATION_PLAN.md active, STAGE_X_PLAN.md active, tasks remaining → "Run /s4-stage-execution to continue Stage X."
  - IMPLEMENTATION_PLAN.md active, all tasks [x] in active STAGE_X_PLAN.md, no `## Review:` in STAGE_X_CHANGES.md → "Run /s5-stage-review to verify Stage X."
  - Review PASS in STAGE_X_CHANGES.md, no `## Summary` block at top of STAGE_X_CHANGES.md → "Run /s6-stage-documenting to close Stage X."
  - IMPLEMENTATION_PLAN.md active, next stage todo, no STAGE_X_PLAN.md → "Run /s3-stage-detailed-plan N to detail Stage N."
  - IMPLEMENTATION_PLAN.md Status: completed → "All stages done. No active work."
  - **Stop here** — don't proceed to Step 1 for option 3.

## Step 1 — Read the project context in parallel

Before engaging the user, gather what you can. Do these together:

**Check for existing docs** (read if they exist, skip if they don't):
- `CLAUDE.md` — project memory: past decisions, preferences, lessons
- `CURRENT_STATE.md` — already scanned in Step 0, re-use what you found

**Explore the codebase** (spawn a subagent to do this in parallel):
- README, package files (package.json, pyproject.toml, Cargo.toml, etc.)
- Directory structure
- Key source files, entry points, config
- Existing modules and their responsibilities

If the user chose option 2 (Extend/update) in Step 0, also read `ARCHITECTURE.md` now
to understand what already exists before asking what needs to change.

## Step 2 — Come prepared, then ask

Don't start with a blank interview. Reference what you found:
> "I see the project uses FastAPI with a PostgreSQL backend. You have modules
> for X and Y. What are you trying to add or build?"

Then get answers to what you still don't know:
- What problem are we solving?
- What does success look like?
- Any constraints? (timeline, must use certain tech, compatibility requirements)
- Anything explicitly out of scope?

Use `AskUserQuestion` for structured choices where it helps (e.g., asking
about DB approach options). For open-ended design questions, just ask inline.

Don't ask everything at once — read the room and ask what you actually need.

## Step 3 — Design and write ARCHITECTURE.md

Once you understand what's being built, produce `ARCHITECTURE.md` in the
project root. The document starts as `Status: draft` — the human must
change it to `approved` before `/s2-planing-stages` will accept it.

Use this exact structure:

```
# Architecture: [Project/Feature Name]
Date: YYYY-MM-DD
Status: draft

## Problem Statement
[What problem are we solving and for whom]

## Goals & Motivation
[Why this matters, what success looks like]

## Constraints
[Tech stack, compatibility requirements, timeline, etc.]

## Current State
[What exists now — summarized from CURRENT_STATE.md and codebase
 exploration. If starting fresh, say so. Be specific: modules,
 APIs, DBs, integrations.]

## Target Architecture
Using C4 Model — three levels, text only. Write only the levels that add
value. L3 is optional for simple systems.

### L1 — System Context
[One short paragraph describing what this system does, followed by an ASCII
 flow showing who uses it and what external systems it connects to.
 Keep to one screen — this is the 30-second overview.]

  User (browser / mobile)
    → [This System]
        → ExternalService1 (e.g. Stripe — payments)
        → ExternalService2 (e.g. SendGrid — email)

### L2 — Containers
[The major deployable/runnable units. For each: name, technology, brief
 responsibility. Follow with an ASCII flow showing how they connect.
 A container is anything that runs separately: web app, API server,
 worker, database, queue, cache.]

  Web App (Vue 3, Nginx) → API Server (FastAPI, Python 3.12)
                                → PostgreSQL 15 (primary store)
                                → Redis 7 (cache + job queue)
                         → Worker (Celery) → PostgreSQL 15

### L3 — Components
[Significant modules within a container that matter for the design.
 Skip trivial CRUD. Only include what a reviewer or implementer needs
 to understand the internal structure. One line per component: name,
 responsibility, key files.]

  API Server:
  - AuthModule — JWT issuance, refresh, revocation → auth/jwt.py
  - UserService — user CRUD, ownership checks → services/user.py
  - PaymentService — Stripe SDK wrapper, webhooks → services/payment.py

Text only throughout — no Mermaid, no diagram tools. Must be readable
in any editor.

### Structural Requirements
- Containerisation: every application must have a Docker definition
  (Dockerfile and docker-compose or Swarm config). Note which service owns it.
- Self-contained repository: repo must contain all code, DB migration
  structures, config examples, and documentation needed to run it locally.
  No secrets in the repository — keys, tokens, certificates must use env vars.
- .gitignore (mandatory): must exist before any other file is created.
  Must cover: .env, *.env, .env.*, secrets files, credentials, private keys,
  certificates, tokens, OS files (.DS_Store, Thumbs.db), editor files
  (.idea/, .vscode/), dependency directories (node_modules/, vendor/,
  __pycache__/, .venv/), build artefacts, logs.
- .env.template (mandatory): must exist before any other file is created.
  Lists every environment variable the application needs, with placeholder
  values and a comment explaining what each variable is and where to get it.
  This file IS committed — it is the setup contract for anyone running the
  project. The actual .env is never committed.
- No vendor lock-in: identify any areas where the design creates dependency
  on a single commercial vendor and propose mitigations or abstraction layers.
- Concurrency: if the application runs background jobs or processes data,
  design for multiple simultaneous instances — specify the lock/singleton
  mechanism required.
- Long-running processes: identify operations that should be offloaded to
  background jobs. Note which queue/worker technology will handle them.
- APM monitoring: specify which APM tool will be used (Sentry preferred).
  Note where SDK initialisation belongs and which exception classes should
  alert vs. be treated as informational noise.
- Health-check endpoint: every application must expose GET /health (or
  equivalent). Note which component owns it and what it checks (DB
  connectivity, critical service availability).

### Technology Choices
[Stack decisions with rationale. "We're using X because Y."
 Note where you're recommending vs. where the user has constraints.]

### Key Data Structures
[Data objects that cross component boundaries. One line per structure:
 name, fields, and which components produce/consume it.
 Skip internal implementation details — only what flows between components.]

  EmailRecord: {id, sender, subject, body, category, status}
    → produced by: Ingestion → consumed by: Classification, Extraction, DB
  PipelineResult: {step, status: ok|error|skip, output}
    → produced by: each pipeline step → consumed by: entrypoint, logging

If the system has no meaningful cross-boundary data structures, write
"N/A — no structured data crosses component boundaries."

## General Implementation Plan
[High-level sequence: what needs to happen, rough order, major
 dependencies. NOT broken into stages — that's /s2-planing-stages's job.
 Think: "First we need the DB schema. Then the API layer can be built
 on top. Frontend is last because it depends on the API contract."
 3-7 bullet points is usually right.]

## Out of Scope
[Explicitly what we're NOT doing in this work. Important for keeping
 /s2-planing-stages and /s4-stage-execution focused.]

## Quality Attributes
[Non-functional requirements that constrain implementation choices.
 Keep to what actually matters for this system — 3-7 items max.]

- Security: [rules that apply — e.g. "no credentials in code",
  "all user input validated before use", "JWT required on all endpoints"]
- Performance: [targets if known — e.g. "API response < 500ms p95",
  "batch job processes 1000 records/min"]
- Resilience: [failure behaviour — e.g. "queue retries 3x before DLQ",
  "pipeline step failure logs and skips, does not abort batch"]
- Compliance: [any regulatory or policy constraints]

Omit any category where there is genuinely no constraint.

## Risks & Open Questions
[Uncertainty that could affect the plan. Things we'll need to decide
 later. External dependencies that aren't confirmed.]

## Next Step
> Review this architecture. Change Status to `approved` when ready,
> then run `/s2-planing-stages` to break it into stages.
```

## What makes a good ARCHITECTURE.md

- **Self-contained**: anyone reading it should understand the system and
  what we're building — no background knowledge required
- **Grounded**: references actual files, modules, and patterns from the
  codebase — not generic or hypothetical
- **Honest**: uncertain things are in Risks & Open Questions, not hidden
  in confident-sounding language
- **Scoped**: Out of Scope is as important as Target Architecture —
  it keeps downstream skills from scope-creeping
- **Legible**: a future `/s5-stage-review` or `/s3-stage-detailed-plan` agent will read this
  to verify that the implementation matches intent

## After writing

Tell the user:
> "ARCHITECTURE.md is ready for your review. Once you're happy with it,
> change `Status: draft` to `Status: approved` and run `/s2-planing-stages`
> to break this into stages."

Mention that Opus is recommended for this skill if they're on a lighter
model — architectural reasoning benefits from the extra capacity.

## How this connects to the rest of the workflow

- `/s2-planing-stages` reads this file (requires `Status: approved`) and turns
  the General Implementation Plan into a sequenced, trackable set of stages
- `/s3-stage-detailed-plan` reads this file to understand the target architecture when
  detailing a specific stage
- `/s5-stage-review` reads this file to verify that the implementation matches
  the intended architecture
- `/s6-stage-documenting` may add an `## Implementation Notes` section if the
  implementation revealed differences from the target

Don't update `Status` yourself — that's the human's sign-off.
