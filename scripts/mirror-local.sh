#!/usr/bin/env bash
# mirror-local.sh — make every LOCAL session load the studio straight from this
# working tree, with no marketplace, no install step, and no update command.
#
# Symlinks plugins/studio-core into ~/.claude/skills/. Claude Code loads any
# folder there that has a .claude-plugin/plugin.json as a plugin named
# `<name>@skills-dir`, and — unlike a marketplace install — discovers it IN PLACE
# rather than copying it into the plugin cache. So the plugin *is* your checkout:
# `git pull` (or an uncommitted edit) is reflected in the next session, or
# immediately for SKILL.md edits.
#
# Scope: ~/.claude/skills/ is personal, so it loads in EVERY local project.
# It does not reach Claude Code on the web — cloud containers are ephemeral and
# don't keep ~/.claude. Use scripts/enable-in-repo.sh for those.
#
# Usage:
#   ./scripts/mirror-local.sh                     # mirror studio-core
#   ./scripts/mirror-local.sh --with-cloudflare   # also mirror cloudflare-mcp
#   ./scripts/mirror-local.sh --undo              # remove the symlinks

set -euo pipefail

SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

plugins=("studio-core")
undo=0
for arg in "$@"; do
  case "$arg" in
    --with-cloudflare) plugins+=("cloudflare-mcp") ;;
    --undo)            undo=1 ;;
    -h|--help)
      awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "$0"
      exit 0 ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2 ;;
  esac
done

repo_root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$repo_root" ] || [ ! -f "$repo_root/.claude-plugin/marketplace.json" ]; then
  echo "Run this from a claude-code-studio checkout." >&2
  exit 1
fi

if [ "$undo" -eq 1 ]; then
  removed=0
  for plugin in "${plugins[@]}"; do
    link="$SKILLS_DIR/$plugin"
    if [ -L "$link" ]; then
      rm "$link"; echo "Removed symlink $link"; removed=1
    elif [ -e "$link" ]; then
      echo "Skipping $link — it is a real directory, not a symlink this script made." >&2
    fi
  done
  [ "$removed" -eq 1 ] && echo && echo "Run /reload-plugins (or restart) to unload it."
  exit 0
fi

mkdir -p "$SKILLS_DIR"

for plugin in "${plugins[@]}"; do
  src="$repo_root/plugins/$plugin"
  link="$SKILLS_DIR/$plugin"

  if [ ! -f "$src/.claude-plugin/plugin.json" ]; then
    echo "No plugin manifest at $src — skipping." >&2
    continue
  fi

  if [ -L "$link" ]; then
    current="$(readlink "$link")"
    if [ "$current" = "$src" ]; then
      echo "Already mirrored: $link -> $src"
      continue
    fi
    echo "Repointing $link (was $current)"
    rm "$link"
  elif [ -e "$link" ]; then
    echo "Refusing to replace $link — it exists and is not a symlink." >&2
    echo "Move it aside first if you want this script to manage it." >&2
    exit 1
  fi

  ln -s "$src" "$link"
  echo "Mirrored $link -> $src  (loads as ${plugin}@skills-dir)"
done

echo
echo "Every local project now loads the studio from this checkout."
echo "Run /reload-plugins in an open session, or start a new one."
echo

# A marketplace install of the same plugin would load ALONGSIDE this one under a
# different name, giving you two copies of every agent. Warn if that's the case.
if command -v claude >/dev/null 2>&1; then
  if claude plugin list 2>/dev/null | grep -q "studio-core@claude-code-studio"; then
    echo "Note: studio-core is ALSO installed from the marketplace. Both will load"
    echo "(as @skills-dir and @claude-code-studio), duplicating every agent. Remove"
    echo "the marketplace copy to keep just the mirror:"
    echo "  claude plugin uninstall studio-core@claude-code-studio"
  fi
fi
