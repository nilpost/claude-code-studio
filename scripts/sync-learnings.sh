#!/usr/bin/env bash
# sync-learnings.sh — commit and push knowledge/LEARNINGS.md so captured lessons
# propagate to every environment on the next `claude plugin marketplace update`.
#
# Run from within the studio repo checkout. Pulls first (to integrate lessons
# captured elsewhere), then commits and pushes if LEARNINGS.md changed.

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$repo_root" ]; then
  echo "Not inside a git repo. Run this from the claude-code-studio checkout." >&2
  exit 1
fi
cd "$repo_root"

file="knowledge/LEARNINGS.md"
if [ ! -f "$file" ]; then
  echo "Expected $file under $repo_root — is this the studio repo?" >&2
  exit 1
fi

branch="$(git rev-parse --abbrev-ref HEAD)"

echo "Pulling latest on $branch (rebase)…"
git pull --rebase --autostash origin "$branch" || true

if git diff --quiet -- "$file" && git diff --cached --quiet -- "$file"; then
  echo "No changes to $file. Nothing to sync."
  exit 0
fi

git add "$file"
git commit -m "learn: sync captured lessons"

echo "Pushing to origin/$branch…"
git push -u origin "$branch"

echo "Synced. Run 'claude plugin marketplace update claude-code-studio' elsewhere to pull the update."
