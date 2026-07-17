#!/usr/bin/env bash
# install-local.sh — install the studio for LOCAL use across all your projects.
#
# Adds the marketplace and installs studio-core at USER scope, so the shared
# agents and skills are available in every local project without per-repo setup.
# (For cloud / Claude Code on the web, commit the snippet in
#  templates/consumer-settings.snippet.json into each consuming repo instead —
#  ephemeral containers do not keep a user-scope install.)

set -euo pipefail

MARKETPLACE="${STUDIO_MARKETPLACE:-nilpost/claude-code-studio}"

if ! command -v claude >/dev/null 2>&1; then
  echo "The 'claude' CLI was not found on PATH. Install Claude Code first." >&2
  exit 1
fi

echo "Adding marketplace: $MARKETPLACE"
claude plugin marketplace add "$MARKETPLACE"

echo "Installing studio-core at user scope"
claude plugin install "studio-core@claude-code-studio" --scope user

echo
echo "Done. Verify with:  claude plugin marketplace list"
echo "Update later with:  claude plugin marketplace update claude-code-studio"
