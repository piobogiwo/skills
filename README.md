# skills-canonical

Single source of truth for shared Claude Code / Codex skills, synced across
Laptop (Windows), Spark (Ubuntu), and Arch (Arch Linux) via this repo.

## How it works

Each machine clones this repo to `~/skills-canonical` (on Windows:
`C:\PIOTR\skills-canonical`), and the tool-specific skill folders become
links pointing at it - not copies. Pulling here updates every tool at once,
with no separate copy step.

- Claude Code: `~/.claude/skills` -> symlink/junction -> `~/skills-canonical`
- Codex: each skill individually symlinked into `~/.codex/skills/<name>`
  (Codex's own bundled `.system/` and `vendor_imports/` are left untouched)
- Hermes: not yet wired up - likely `~/.hermes`, needs verifying on Spark/Arch
- Kilo-Code: not yet wired up - no confirmed skills/rules convention found

## Setup on a new machine

**Linux (Spark, Arch):**
```bash
curl -fsSL https://raw.githubusercontent.com/piobogiwo/skills/main/scripts/setup-skills-sync.sh | bash
```
(or clone the repo first and run `scripts/setup-skills-sync.sh` directly)

**Windows (Laptop):** no admin rights or Developer Mode needed - `mklink /J`
(directory junction) works on the same drive without elevation.
```
git clone https://github.com/piobogiwo/skills.git C:\PIOTR\skills-canonical
ren "C:\Users\<you>\.claude\skills" skills-backup-YYYYMMDD
mklink /J "C:\Users\<you>\.claude\skills" "C:\PIOTR\skills-canonical"
```

## Updating

Manual, on purpose - no background auto-pull. Whenever you want the latest:
```bash
git -C ~/skills-canonical pull
```
or just ask Claude to run the `sync-skills` skill (`/sync-skills`), which
does the same pull and reports what changed.

## Making changes

Edit skills directly under `~/skills-canonical` (or `C:\PIOTR\skills-canonical`
on Windows), then commit and push from whichever machine you're on:
```bash
cd ~/skills-canonical
git add -A && git commit -m "..." && git push
```
Pull on the other machines to pick it up.

## History

See `DEDUP_MANIFEST.md` in `skills-do-uporzadkowania-archiwum` (sibling
folder to this repo on the Laptop) for how this set was originally
consolidated from three divergent per-machine copies.
