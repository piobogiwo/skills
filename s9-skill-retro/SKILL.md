---
name: s9-skill-retro
description: "Periodic, manually-invoked skill that turns accumulated entries in docs/skills-improvement-ideas.md — logged by s6-stage-documenting, s7-architecture-audit, and s8-security-check — into concrete, proposed edits to the affected dev-workflow skills (s1-s8). It only proposes — it never edits a skill file without explicit approval. Trigger on: /s9-skill-retro, 'process the skill improvement ideas', 'let's review the skills-improvement-ideas file', 'turn our retro notes into skill changes'. Do NOT trigger automatically — explicit invocation only, typically at the end of a project or whenever the user wants to catch up on accumulated ideas."
---

# Skill Retro

Your job is to take the retrospective notes that `/s6-stage-documenting`,
`/s7-architecture-audit`, and `/s8-security-check` have been quietly
accumulating in `docs/skills-improvement-ideas.md` — one small observation
at a time, easy to make and easy to forget — and turn them into something
someone can actually act on: a concrete, ready-to-review change to the skill
file that caused the friction.

**The core rule, same as `/s7-architecture-audit`: you propose, you do not
apply.** A skill file is a shared asset used across many projects and
possibly several machines — editing it silently on the strength of one
project's experience is exactly the kind of change that deserves a second
pair of eyes before it lands.

## Step 1 — Read the ideas file

Look for `docs/skills-improvement-ideas.md` in the project root.

- If it doesn't exist or has no unprocessed entries (see Step 5 for how
  entries get marked processed), tell the user: "No unprocessed skill
  improvement ideas found in this project." and stop.
- Otherwise, read all unprocessed entries. Each has the same shape, whether
  it came from `/s6-stage-documenting` (`## YYYY-MM-DD — Stage X`),
  `/s7-architecture-audit` (`## YYYY-MM-DD — Architecture audit`), or
  `/s8-security-check` (`## YYYY-MM-DD — Security check`):
  ```
  ## YYYY-MM-DD — [Stage X | Architecture audit | Security check]
  Skill(s): [...]
  Observation: [...]
  Suggested improvement: [...]
  ```
  The header's second half tells you *when* the observation was made, not
  which skill it's about — always group by the `Skill(s):` field (Step 2),
  since an entry logged during a security check might still be about
  `s1-architect`, for instance.

## Step 2 — Group by affected skill

Cluster entries by the `Skill(s):` field. Multiple entries about the same
skill are a stronger signal than a single one-off — note when several stages
independently hit the same friction, since that's a better basis for a
change than a single occurrence.

If an entry doesn't clearly name a skill, use judgment from the Observation
text to infer which one it's about; if it's genuinely ambiguous, group it
under "Unclear — needs human triage" rather than guessing.

## Step 3 — Locate each affected skill's actual file

You're running inside one specific tool, so the location is fixed, not a
mystery: check `.claude/skills/<name>/SKILL.md` in the project root first
(a project-local override, if this project has one), otherwise use
`~/.claude/skills/<name>/SKILL.md`. If neither exists, ask the user rather
than guessing further — don't invent a third location.

**This file is the one true copy for this machine and this tool only.**
If the user also keeps this skill in sync across other machines (they may —
ask if unsure) or maintains a parallel version for another tool (e.g. a
Codex equivalent of the same skill), applying a change here does not
propagate there. Say so explicitly when presenting the change in Step 5, so
the user remembers to carry it over manually if they want that.

## Step 4 — Draft a concrete change per affected skill

For each skill with one or more grouped ideas, read its current SKILL.md in
full, then draft the specific text change you'd make — not a paraphrase of
the idea, the actual replacement wording, in context. Think about *why* the
friction happened before proposing wording: an instruction that was ambiguous
needs disambiguation, a step that was missing needs adding, a step that
existed but got skipped needs a stronger reason attached to it (per the
skill-writing principle: explain why, don't just add another MUST).

If an idea's "Suggested improvement" was "not sure — flagging for
discussion," don't force a fix — present the observation and your best
thinking about options, and say so plainly rather than inventing false
confidence.

## Step 5 — Present proposals and get approval

Show the user, one skill at a time:
- Which stage(s)/observation(s) this addresses
- The current text (or the gap, if something's missing)
- The proposed replacement text
- One line on why this should help

Ask explicitly before writing anything:
> "Apply this change to [skill]? (yes / no / edit it first)"

Only write to a SKILL.md after the user confirms that specific change. Skip
or revise per their answer — don't batch-apply everything on one "yes to all"
unless the user explicitly says that's what they want.

After applying, remind the user this only updated the copy at the path found
in Step 3 — if they keep synced copies on other machines or an equivalent
skill for another tool, those need the same change carried over by hand.

After each applied change, mark the corresponding entry(ies) in
`docs/skills-improvement-ideas.md` as processed — append `[Processed:
YYYY-MM-DD → applied to <skill>]` at the end of the entry. Never delete or
rewrite the original entry text; append the marker below it. Entries the
user declined get `[Processed: YYYY-MM-DD → declined, no change made]` so
the next run doesn't re-surface them either.

## Constraints

- **Do not edit any skill file without that specific change being approved.**
- **Do not delete or rewrite unprocessed entries** — only append a processed
  marker once a decision has been made.
- **Do not silently skip an idea because it's inconvenient to locate the
  skill file** — ask the user instead.
- If multiple ideas about the same skill conflict with each other, surface
  the conflict to the user rather than picking one silently.

## How this connects to the workflow

- `/s6-stage-documenting`, `/s7-architecture-audit`, and `/s8-security-check`
  all write to `docs/skills-improvement-ideas.md` — this skill is the only
  consumer of that file.
- This skill can touch any skill in the s1-s8 family (or others) depending
  on what the accumulated ideas point at — it is not tied to a single step.
- Typically run once at the end of a project, or whenever the user wants to
  catch up on accumulated ideas — never automatically.
