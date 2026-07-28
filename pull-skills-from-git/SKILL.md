---
name: pull-skills-from-git
description: "Pulls the latest skills-canonical from every configured remote (GitHub, GitLab, or whichever are set up) so Claude Code/Codex see newly added or changed skills right away (skills are linked, not copied, into ~/.claude/skills and ~/.codex/skills). Detects if remotes have drifted apart from each other, not just from local. Trigger on: /pull-skills-from-git, 'pull skills', 'sync skills', 'update my skills', 'get skill changes from the other machine'. Manual only — never trigger automatically."
---

# Pull Skills From Git

Pull the latest `skills-canonical` from all configured remotes and report
what changed. Since skills are linked rather than copied, this is the only
step needed — no separate copy.

## Step 1 — Locate the repo

Check, in order:
1. `~/skills-canonical` (Linux — Spark, Arch)
2. `C:\piotr\skills-canonical` (Windows — Laptop)

If neither exists, point the user at `scripts/setup-skills-sync.sh` (Linux)
or the Windows setup in README.md — there's nothing to pull yet.

## Step 2 — Check for local changes first

Run `git status --short`. If it's not clean, stop and ask: pulling over
uncommitted local edits risks a conflict or losing them. Let the user
commit, stash, or discard before continuing.

## Step 3 — Fetch every remote

```bash
git -C <repo> remote                # list configured remotes, don't assume names
git -C <repo> fetch --all
```

Do this for whatever remotes exist — don't hardcode "origin" or "gitlab" by
name, since which ones are configured can change.

## Step 4 — Check for drift between remotes, not just local vs. remote

Because this repo can be pushed to more than one remote (see
`push-skills-to-git`), a push can succeed on one and fail on another —
leaving them out of sync. Before merging anything into the local branch,
compare each remote's `main` against the others:

```bash
git -C <repo> rev-parse origin/main gitlab/main   # (or whatever remotes exist)
```

- **All remotes agree**: proceed to Step 5 normally.
- **Remotes disagree**: stop and tell the user which one is ahead — e.g.
  "origin/main and gitlab/main have diverged" or "gitlab/main is 2 commits
  behind origin/main." Don't silently pick one; ask which to treat as
  authoritative, or whether to push the lagging remote up to match first
  (that's `push-skills-to-git`'s job, not this skill's).

## Step 5 — Merge and report

```bash
git -C <repo> rev-parse HEAD                       # note current commit
git -C <repo> merge --ff-only <remote>/main         # fast-forward only
git -C <repo> log <old>..HEAD --oneline             # what changed, if anything
```

Use `--ff-only` — if it's not a fast-forward, something unexpected happened
locally; stop and surface it rather than creating a merge commit silently.

If already up to date, say so plainly. If commits arrived, list them —
that's the useful signal, not just "done."

## Step 6 — Mention restart if it matters

New or renamed skills should be usable immediately. If a change touched a
skill's `name` or `description` (the part that decides triggering) and it
doesn't seem to be picked up, suggest starting a fresh session — that
guarantees a clean read.
