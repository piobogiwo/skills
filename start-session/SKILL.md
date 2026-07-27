---
name: start-session
description: "Session onboarding for System A dev workflow — reads project artifacts, prints a status summary, asks what to do, and routes to the right skill. Use proactively at the start of any session when the user has not specified which workflow step to run. Trigger on: /start-session, 'where are we', 'what is the status', 'lets start', 'resume', 'pick up where we left off', 'co robimy', 'zaczynamy', 'wrocmy do projektu'."
---

# Start Session

Orient yourself and the user at the beginning of a working session.
Read what exists, print a clear summary, ask what to do, then route to
the right skill.

## Step 1 — Read existing artifacts

Scan the project root. Read each file that exists (skip silently if missing):

1. `CLAUDE.md` — project memory: decisions, patterns, lessons
2. `CURRENT_STATE.md` — ground truth of what exists now
3. `ARCHITECTURE.md` — target architecture, Status field
4. `IMPLEMENTATION_PLAN.md` — master plan, Stage statuses
5. Any `STAGE_*_PLAN.md` files — find the one with `Status: active` if any; check task checkboxes (`[ ]` / `[x]` / `[~]`)
6. `STAGE_X_CHANGES.md` for the active stage (if any) — does it contain a `## Review:` block? Does it contain a `## Summary` block at the top?

Read them in parallel. Don't ask the user anything yet.

## Step 2 — Print a 5-line summary

Format:

```
Project: [name from ARCHITECTURE.md or directory name]
Architecture: [exists: Status | not found]
Implementation plan: [exists: Status, N stages total, M done | not found]
Active stage: [Stage X — name, Status | none]
Last known state: [one sentence from CURRENT_STATE.md, or "no CURRENT_STATE.md"]
```

Example:
```
Project: ksef-alokacje
Architecture: approved (2026-01-15)
Implementation plan: active — 8 stages, 3 done, Stage 4 in_progress
Active stage: Stage 4 — Database migrations (in_progress)
Last known state: OAuth flow complete, DB schema finalized, migration runner pending
```

## Step 3 — Ask about session goal

> **Co robimy w tej sesji?**
> 1. **Kontynuuj** — wróć do aktywnego stage'u i zacznij następne zadanie
> 2. **Zacznij kolejny etap** — szczegółowo zaplanuj i uruchom następny zaplanowany stage
> 3. **Przegląd / audyt** — sprawdź stan projektu bez implementacji
> 4. **Coś innego** — opisz co chcesz zrobić

Wait for the answer.

## Step 4 — Act based on the answer

### "Kontynuuj" (1)

First, determine if there is an active stage (STAGE_X_PLAN.md with Status: active or approved).

**If an active stage exists**, propose based on its current state:

| Situation | Propose |
|-----------|---------|
| STAGE_X_PLAN.md Status: approved, no CHANGES.md | "Run /s4-stage-execution to start Stage X" |
| STAGE_X_PLAN.md active, tasks `[ ]` remaining | "Run /s4-stage-execution — N tasks remain in Stage X" |
| All tasks `[x]`, no `## Review:` in CHANGES.md | "Run /s5-stage-review to verify Stage X" |
| `## Review: PASS` in CHANGES.md, no `## Summary` at top | "Run /s6-stage-documenting to close Stage X" |

**If no active stage exists**, tell the user there's nothing to continue and show where we are:

| Situation | Propose |
|-----------|---------|
| No ARCHITECTURE.md | "Nie ma aktywnej pracy — zacznij od /s1-architect" |
| ARCHITECTURE.md Status: draft | "Nie ma aktywnej pracy — zatwierdź ARCHITECTURE.md i uruchom /s2-planing-stages" |
| ARCHITECTURE.md approved, no IMPLEMENTATION_PLAN.md | "Nie ma aktywnej pracy — uruchom /s2-planing-stages" |
| IMPLEMENTATION_PLAN.md Status: draft | "Nie ma aktywnej pracy — zatwierdź IMPLEMENTATION_PLAN.md i uruchom /s3-stage-detailed-plan" |
| IMPLEMENTATION_PLAN.md Status: approved, no STAGE_X_PLAN.md | "Nie ma aktywnej pracy — uruchom /s3-stage-detailed-plan 0 (lub /s3-stage-detailed-plan 1)" |
| IMPLEMENTATION_PLAN.md active, next stage `todo`, no STAGE_X_PLAN.md | "Nie ma aktywnej pracy — uruchom /s3-stage-detailed-plan N aby zaplanować Stage N" |
| IMPLEMENTATION_PLAN.md Status: completed | "Wszystkie stage'y ukończone — brak aktywnej pracy" |

### "Zacznij kolejny etap" (2)

Find the next stage with `Status: todo` in IMPLEMENTATION_PLAN.md.
Tell the user which stage that is and what its goal is.
Then: invoke `/s3-stage-detailed-plan N` for that stage number.

If no `todo` stages remain — inform the user all stages are planned or complete.

### "Przegląd / audyt" (3)

Ask what kind of review:
- **Zgodność z architekturą** → run `/s7-architecture-audit`
- **Bezpieczeństwo** → run `/s8-security-check`

### "Coś innego" (4)

Listen to the description. Check if it requires changes to the architecture
or plan. Propose an action plan. Don't start coding without a clear goal.

## Step 5 — End of session reminder

At the end of each session (when the user signals they're stopping), prompt:

> "Przed zakończeniem — czy chcesz żebym zaproponował aktualizację
> CURRENT_STATE.md z tym co zrobiliśmy dzisiaj?"

If yes, draft the update and ask for approval before writing.

---

## Rules

- **Never start coding** until the session goal is confirmed
- **CURRENT_STATE.md is the single source of truth** — read it first, update it last
- If artifacts conflict (e.g., IMPLEMENTATION_PLAN says Stage 2 done but STAGE_2_PLAN.md is active) — flag the inconsistency to the user before routing anywhere
- If no artifacts exist at all → suggest `/s1-architect` to start the design phase
