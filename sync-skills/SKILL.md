---
name: sync-skills
description: "Pulls the latest skills-canonical repo so Claude Code/Codex see newly added or changed skills right away (skills are linked, not copied, into ~/.claude/skills and ~/.codex/skills). Trigger on: /sync-skills, 'sync skills', 'update my skills', 'pull the latest skills', 'get skill changes from the other machine'. Manual only — never trigger automatically."
---

# Sync Skills

Pull the latest `skills-canonical` and report what changed. Since skills are
linked rather than copied, this `git pull` is the only step needed.

## Step 1 — Locate the repo

Check, in order:
1. `~/skills-canonical` (Linux — Spark, Arch)
2. `C:\piotr\skills-canonical` (Windows — Laptop)

If neither exists, tell the user to run `scripts/setup-skills-sync.sh`
(Linux) or the Windows setup in README.md first — there's nothing to pull yet.

## Step 2 — Check for local changes first

Run `git status --short` in the repo. If it's not clean, stop and ask:
pulling over uncommitted local edits risks a conflict or losing them. Let
the user commit, stash, or discard before continuing.

## Step 3 — Pull and report

```bash
git -C <repo> rev-parse HEAD              # note current commit
git -C <repo> pull
git -C <repo> log <old>..HEAD --oneline   # what changed, if anything
```

If already up to date, say so plainly. If commits arrived, list them —
that's the useful signal, not just "done."

## Step 4 — Mention restart if it matters

New or renamed skills should be usable immediately. If a change touched a
skill's `name` or `description` (the part that decides triggering) and it
doesn't seem to be picked up, suggest starting a fresh session — that
guarantees a clean read.
