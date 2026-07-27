---
name: s2-planing-stages
description: >
  Second step in the dev workflow — reads an approved ARCHITECTURE.md and
  breaks it into a sequenced set of implementation stages. Produces
  IMPLEMENTATION_PLAN.md, the master tracking document that all downstream
  skills depend on.

  This is the SECOND step in:
    /s1-architect → /s2-planing-stages → /s3-stage-detailed-plan → /s4-stage-execution → /s5-stage-review → /s6-stage-documenting

  Trigger on: /s2-planing-stages, /staged-plan (legacy alias), "break into stages", "staged plan", "create stages",
  "what are the stages", "implementation plan", "let's plan the stages".
  Also trigger proactively when the user says "let's start" or "let's begin
  implementation" and no IMPLEMENTATION_PLAN.md exists yet.

  Do NOT trigger if IMPLEMENTATION_PLAN.md already exists and Status is
  approved or active — suggest /s3-stage-detailed-plan instead.
---

# Staged Plan

Your job is to take an approved architecture and produce a realistic,
ordered sequence of implementation stages. The output is IMPLEMENTATION_PLAN.md —
the master tracking document for the entire feature. Every downstream skill
(/s3-stage-detailed-plan, /s4-stage-execution, /s5-stage-review, /s6-stage-documenting) will read this file.

## Step 1 — Validate inputs

Check these in parallel:

1. **ARCHITECTURE.md** (required) — must exist in the project root AND have
   `Status: approved` (not `draft`). If it doesn't exist or Status is `draft`,
   stop and tell the user:
   > "ARCHITECTURE.md must be approved before running /s2-planing-stages. Either run
   > /s1-architect first, or change `Status: draft` to `Status: approved` in the
   > existing ARCHITECTURE.md."

2. **CLAUDE.md** (optional) — read for project conventions, past decisions.

3. **CURRENT_STATE.md** (optional) — read for ground truth about what exists.

4. **The codebase** — explore in parallel with a subagent. Look at:
   - Directory structure and key source files
   - What exists vs what needs to be created
   - Dependencies and entry points
   - Test patterns, build setup

Don't guess about complexity — look at the actual code. A stage that touches
an existing module is different from one that creates a new subsystem.

## Step 2 — Design the stages

Read the General Implementation Plan from ARCHITECTURE.md. Your job is to
turn that high-level sequence into concrete, sized stages.

**What makes a good stage:**
- Small enough to complete in a focused session — a few hours to 1-2 working
  days at most. If something feels like 3+ days, split it.
- Has a clear, verifiable completion criterion. "AC summary" should be
  something you could check: a test passes, a command runs, a page renders.
- Represents a meaningful, deployable unit of work — not just "write some code".
  At the end of each stage, something new works.

**Stage 0 — Setup:**
Include a "Stage 0: Setup / Foundation" if the project needs infra, tooling,
migrations, or dependency installs before real work can begin. If everything
is already in place, skip it and start at Stage 1.

**Parallelism:**
If two stages have no dependency on each other, flag that — mark them as
"Depends on: Stage N (parallel with Stage M)". This tells /s3-stage-detailed-plan and
the developer that these can be worked on simultaneously.

**Later stages can be less detailed:**
You're planning from present knowledge. Stages 0-2 should be concrete.
Later stages can be rougher — they'll be fleshed out by /s3-stage-detailed-plan when
their turn arrives. Don't force premature precision on things that depend
on decisions you haven't made yet.

## Step 3 — Write IMPLEMENTATION_PLAN.md

Produce this file in the project root. Use this exact format:

```
# Implementation Plan: [Feature Name from ARCHITECTURE.md]
Date: YYYY-MM-DD
Source: ARCHITECTURE.md
Status: draft
Approved by: [filled by human when approved]

## Overview
[2-4 sentences: what we're building and why — summarized from ARCHITECTURE.md]

## Stages

### Stage 0: [Setup / Foundation]
- Goal: [what this stage achieves — one sentence]
- Scope: [files or modules created/modified]
- Size: S  (S = a few hours, M = 1-2 days, L = 3-5 days)
- Depends on: —
- AC summary: [how we know this stage is done]
- Status: todo

### Stage 1: [name]
- Goal:
- Scope:
- Size: M
- Depends on: Stage 0
- AC summary:
- Status: todo

### Stage 2: [name]
- Goal:
- Scope:
- Size: M
- Depends on: Stage 1
- AC summary:
- Status: todo

[continue for all stages...]

## Stage Dependency Graph

Stage 0: Setup
  → Stage 1: [name]
      → Stage 2: [name]
      → Stage 3: [name] (parallel with Stage 2)
          → Stage 4: [name]

## Model Guidance
- Architecture/planning/review: Opus
- Implementation/tests: Sonnet

## Next Step
> Review this plan. Change Status to `approved` when ready.
> Then run `/s3-stage-detailed-plan 1` to detail Stage 1 (or `/s3-stage-detailed-plan 0` if
> Stage 0 exists).
```

## Status state machine

The IMPLEMENTATION_PLAN.md Status follows this sequence:
- `draft` — just written by this skill, awaiting human review
- `approved` — human has signed off, stages can proceed
- `active` — set by /s3-stage-detailed-plan when the first stage is started
- `completed` — set by /s6-stage-documenting when all stages are done

**This skill creates the file with `Status: draft`. Do not set it to anything
else — the human must approve it.**

Individual stage statuses are: `todo | in_progress | done | skipped`

Only `/s6-stage-documenting` updates stage statuses to `done`. This skill sets all
stages to `todo`.

## After writing

Tell the user:
> "IMPLEMENTATION_PLAN.md is ready. This plan needs your approval before
> any implementation starts — review the stages, adjust sizing or scope
> if needed, and change `Status: draft` to `Status: approved` when you're
> satisfied. Then run `/s3-stage-detailed-plan 0` (or `/s3-stage-detailed-plan 1` if no Stage 0)
> to start."

If you used Sonnet for this, mention:
> "Opus is recommended for planning — if you're on a lighter model, the
> stage breakdown may be less nuanced."

## How this connects to the rest of the workflow

- `/s1-architect` produces ARCHITECTURE.md — this skill reads it
- `/s3-stage-detailed-plan N` reads this file to find Stage N and produce a detailed
  task breakdown. It requires Status: approved or active.
- `/s4-stage-execution` reads this file for overall context during implementation
- `/s5-stage-review` checks that implementation matches the stage goals
- `/s6-stage-documenting` reads this file and sets individual stage statuses to `done`
  after each completed stage, and sets overall Status to `completed` when
  all stages are done

Don't update stage statuses yourself. Don't update the overall Status
yourself. Those are downstream responsibilities.
