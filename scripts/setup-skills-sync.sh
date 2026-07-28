#!/usr/bin/env bash
# Sets up skills-canonical as the single source of truth for skills on this
# machine (Linux only - Ubuntu/Spark and Arch). For Windows/Laptop, see the
# mklink /J commands in README.md instead.
#
# What it does:
#   1. Clones (or updates) skills-canonical to ~/skills-canonical, with both
#      the github and gitlab remotes configured
#   2. Symlinks ~/.claude/skills -> ~/skills-canonical (backs up the old
#      folder first if it exists and isn't already a symlink)
#   3. Symlinks each skill individually into ~/.codex/skills/<name>, without
#      touching Codex's own .system/ and vendor_imports/ content
#   4. Leaves Hermes and Kilo-Code alone for now - see README.md
#
# Safe to re-run: existing symlinks are left as-is, nothing is overwritten
# without a backup.

set -euo pipefail

REPO_URL="https://github.com/piobogiwo/skills.git"
GITLAB_URL="https://gitlab.mparagon.pl/src-hurtownia/skills.git"
CANONICAL="$HOME/skills-canonical"

echo "== Step 1: clone or update skills-canonical =="
if [ -d "$CANONICAL/.git" ]; then
  echo "Already cloned at $CANONICAL, pulling latest..."
  git -C "$CANONICAL" pull
else
  git clone "$REPO_URL" "$CANONICAL"
fi

if ! git -C "$CANONICAL" remote get-url gitlab >/dev/null 2>&1; then
  git -C "$CANONICAL" remote add gitlab "$GITLAB_URL"
  echo "Added gitlab remote ($GITLAB_URL)"
fi

echo "== Step 2: link Claude Code skills =="
CLAUDE_SKILLS="$HOME/.claude/skills"
if [ -L "$CLAUDE_SKILLS" ]; then
  echo "~/.claude/skills is already a symlink - leaving it alone"
elif [ -e "$CLAUDE_SKILLS" ]; then
  backup="$HOME/.claude/skills-backup-$(date +%Y%m%d)"
  mv "$CLAUDE_SKILLS" "$backup"
  echo "Backed up existing ~/.claude/skills to $backup"
  ln -s "$CANONICAL" "$CLAUDE_SKILLS"
  echo "Linked ~/.claude/skills -> $CANONICAL"
else
  mkdir -p "$HOME/.claude"
  ln -s "$CANONICAL" "$CLAUDE_SKILLS"
  echo "Linked ~/.claude/skills -> $CANONICAL"
fi

echo "== Step 3: link Codex skills (per-skill, leaves .system/vendor_imports alone) =="
CODEX_SKILLS="$HOME/.codex/skills"
if [ -d "$CODEX_SKILLS" ]; then
  for skill_dir in "$CANONICAL"/*/; do
    name=$(basename "$skill_dir")
    target="$CODEX_SKILLS/$name"
    if [ -e "$target" ]; then
      echo "  $name already exists in ~/.codex/skills - skipping"
    else
      ln -s "$skill_dir" "$target"
      echo "  linked $name"
    fi
  done
else
  echo "No ~/.codex/skills found - skipping Codex linking"
fi

echo
echo "Done. To pull future updates, run the pull-skills-from-git skill, or:"
echo "  git -C $CANONICAL fetch --all && git -C $CANONICAL merge --ff-only origin/main"
echo "Changes show up immediately in Claude Code / Codex - no extra copy step."
echo "To push a change, use the push-skills-to-git skill (pushes to both remotes)."
