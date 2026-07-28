#!/usr/bin/env bash
# update-studio.sh — pull the latest studio agents/skills/commands into a LOCAL
# install.
#
# The marketplace source is the GitHub repo with no pinned ref, so this always
# fetches the current `main`. Cloud (Claude Code on the web) sessions do not need
# this: they clone and install fresh at session start, so a new cloud session is
# already on the latest.
#
# NOTE: SKILL.md edits apply immediately; agents, commands, hooks, and .mcp.json
# do not. After this script runs, use /reload-plugins in an open session (or
# restart) to pick those up.
#
# Usage:
#   ./scripts/update-studio.sh                    # update studio-core
#   ./scripts/update-studio.sh --with-cloudflare  # also update cloudflare-mcp

set -euo pipefail

MARKETPLACE_NAME="claude-code-studio"

plugins=("studio-core")
for arg in "$@"; do
  case "$arg" in
    --with-cloudflare) plugins+=("cloudflare-mcp") ;;
    -h|--help)
      awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "$0"
      exit 0 ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2 ;;
  esac
done

if ! command -v claude >/dev/null 2>&1; then
  echo "The 'claude' CLI was not found on PATH. Install Claude Code first." >&2
  exit 1
fi

echo "Refetching marketplace: $MARKETPLACE_NAME"
claude plugin marketplace update "$MARKETPLACE_NAME"

for plugin in "${plugins[@]}"; do
  echo "Updating $plugin"
  claude plugin update "${plugin}@${MARKETPLACE_NAME}"
done

echo
echo "Up to date. Current install:"
claude plugin list || true
echo
echo "Run /reload-plugins in an open session to pick up the updated agents and commands."
