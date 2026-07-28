#!/usr/bin/env bash
# install-local.sh — install the studio for LOCAL use across all your projects.
#
# Adds the marketplace and installs studio-core at USER scope, so the shared
# agents and skills are available in every local project without per-repo setup.
# (For cloud / Claude Code on the web, run scripts/enable-in-repo.sh in each
#  consuming repo and commit the result — ephemeral containers do not keep a
#  user-scope install.)
#
# Usage:
#   ./scripts/install-local.sh                    # studio-core only
#   ./scripts/install-local.sh --with-cloudflare  # also install cloudflare-mcp

set -euo pipefail

MARKETPLACE="${STUDIO_MARKETPLACE:-nilpost/claude-code-studio}"
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

echo "Adding marketplace: $MARKETPLACE"
claude plugin marketplace add "$MARKETPLACE"

for plugin in "${plugins[@]}"; do
  echo "Installing $plugin at user scope"
  claude plugin install "${plugin}@${MARKETPLACE_NAME}" --scope user
done

echo
echo "Done. Verify with:  claude plugin list"
echo "Update later with:  ./scripts/update-studio.sh"
echo
echo "Agents and slash-commands register at session start — open a NEW session to use them."
