---
name: push-skills-to-git
description: "Commits and pushes skills-canonical changes to every configured remote (GitHub, GitLab, or whichever are set up) — not just the first one that works. Use whenever a skill was just edited and needs to be shared with other machines. Trigger on: /push-skills-to-git, 'push skills', 'push this skill change', 'save this to the skills repo', 'commit and push the skill changes'. Manual only — never trigger automatically."
---

# Push Skills To Git

Commit whatever changed in `skills-canonical` and push it to **every**
configured remote — treating one remote's success as "done" would silently
leave the others behind, and nobody would notice until a machine pulling
from the stale one got confused.

## Step 1 — Locate the repo

Check, in order:
1. `~/skills-canonical` (Linux — Spark, Arch)
2. `C:\piotr\skills-canonical` (Windows — Laptop)

If neither exists, there's nothing to push — point the user at the setup
instructions in README.md instead.

## Step 2 — Commit if there's anything to commit

```bash
git -C <repo> status --short
```

If there are uncommitted changes, show them to the user and confirm the
commit message before committing (short, describes what changed and why —
match the style of existing commits: `git -C <repo> log --oneline -5`).
If the working tree is already clean, skip straight to Step 3 — there may
still be local commits that haven't reached every remote yet (e.g. a
previous push partially failed).

## Step 3 — Push to every remote, independently

```bash
git -C <repo> remote          # list configured remotes, don't assume names
```

For **each** remote, push separately and record the outcome — don't stop at
the first failure, and don't let one remote's success mask another's
failure:

```bash
git -C <repo> push <remote> main
```

A push can fail for reasons that have nothing to do with the others — e.g.
a GitLab project needing its default branch set by an Owner/Maintainer
before it accepts any push at all. That's a server-side/permissions issue
outside git's control from here; don't retry it blindly or try workarounds
like force-push to route around a rejection — surface the actual error text
to the user, since it usually says exactly what's needed.

## Step 4 — Report per remote

Summarize plainly, one line per remote:

```
github: pushed (a1b2c3d..e4f5g6h)
gitlab: FAILED — default branch not set yet, needs a Maintainer to configure it
```

If any remote failed, remind the user that `pull-skills-from-git` will
detect the resulting drift on other machines and refuse to silently merge
past it — so it's worth fixing the failing remote before too much
accumulates, but nothing is broken in the meantime.

## Constraints

- **Push to all remotes, always** — never treat the first successful push
  as sufficient.
- **Don't force-push** to work around a rejection. A rejection is
  information, not an obstacle to route around.
- **Don't silently drop a remote** because it failed once — report it every
  time until it's fixed.
