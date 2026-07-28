#!/usr/bin/env bash
# check-plugin-versions.sh — CI gate: a PR that changes files under plugins/<name>/
# must (1) bump that plugin's version in BOTH plugins/<name>/.claude-plugin/plugin.json
# and its entry in .claude-plugin/marketplace.json, and (2) add a CHANGELOG.md entry.
#
# Why: Claude Code uses the plugin's version as its update cache key. A consumer's
# `claude plugin update` fetches nothing new if the version string is unchanged —
# new commits alone are invisible to already-installed copies. See
# CONTRIBUTING.md#versioning--release for the bump criteria (PATCH/MINOR/MAJOR).
# CHANGELOG.md exists so that staying current is worth doing — an update nobody can
# read the reason for is easy to skip.
#
# Also checks, independent of what changed: every plugin listed in
# marketplace.json has a version that matches its own plugin.json, at HEAD.
#
# Usage: check-plugin-versions.sh <base-ref>
# Diffs <base-ref>...HEAD. Exits non-zero if any check fails.

set -uo pipefail

base="${1:?usage: $0 <base-ref>}"
fail=0

version_of() { # version_of <ref> <path-to-plugin.json>
  git show "$1:$2" 2>/dev/null | python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("version", ""))
except Exception:
    print("")
'
}

marketplace_version_of() { # marketplace_version_of <ref> <plugin-name>
  git show "$1:.claude-plugin/marketplace.json" 2>/dev/null | python3 -c "
import json, sys
name = '$2'
try:
    data = json.load(sys.stdin)
except Exception:
    data = {}
for p in data.get('plugins', []):
    if p.get('name') == name:
        print(p.get('version', ''))
        break
"
}

changed_plugins=$(git diff --name-only "$base"...HEAD -- plugins/ \
  | sed -E 's#^plugins/([^/]+)/.*#\1#' | sort -u)

echo "Plugins with changed files in this diff: ${changed_plugins:-(none)}"

if [ -n "$changed_plugins" ]; then
  if ! git diff --name-only "$base"...HEAD -- CHANGELOG.md | grep -q .; then
    echo "::error file=CHANGELOG.md::Plugin(s) changed (${changed_plugins}) but CHANGELOG.md was not. Add an entry — see CONTRIBUTING.md#versioning--release."
    fail=1
  fi
fi

for name in $changed_plugins; do
  manifest="plugins/$name/.claude-plugin/plugin.json"

  if ! git show "HEAD:$manifest" >/dev/null 2>&1; then
    echo "::notice::plugins/$name has no manifest at HEAD (removed) — skipping bump check."
    continue
  fi
  if ! git show "$base:$manifest" >/dev/null 2>&1; then
    echo "New plugin '$name' — no bump required."
    continue
  fi

  head_pv=$(version_of HEAD "$manifest")
  base_pv=$(version_of "$base" "$manifest")
  if [ "$head_pv" = "$base_pv" ]; then
    echo "::error file=$manifest::'$name' has changed files under plugins/$name/ but its 'version' was not bumped (still '$head_pv'). Consumers running 'claude plugin update' will not receive this change. See CONTRIBUTING.md#versioning--release."
    fail=1
  fi

  head_mv=$(marketplace_version_of HEAD "$name")
  base_mv=$(marketplace_version_of "$base" "$name")
  if [ "$head_mv" = "$base_mv" ]; then
    echo "::error file=.claude-plugin/marketplace.json::'$name' entry version was not bumped (still '$head_mv')."
    fail=1
  fi
done

echo
echo "Checking plugin.json / marketplace.json version agreement at HEAD..."
all_names=$(git show "HEAD:.claude-plugin/marketplace.json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
for p in data.get("plugins", []):
    print(p.get("name", ""))
')

for name in $all_names; do
  manifest="plugins/$name/.claude-plugin/plugin.json"
  if ! git show "HEAD:$manifest" >/dev/null 2>&1; then
    echo "::error::marketplace.json lists '$name' but $manifest does not exist at HEAD."
    fail=1
    continue
  fi
  pv=$(version_of HEAD "$manifest")
  mv=$(marketplace_version_of HEAD "$name")
  if [ "$pv" != "$mv" ]; then
    echo "::error file=$manifest::'$name' version mismatch: plugin.json='$pv' marketplace.json='$mv'. They must match."
    fail=1
  fi
done

if [ "$fail" -eq 1 ]; then
  echo
  echo "FAILED — see errors above."
  exit 1
fi

echo "OK — all plugin versions consistent."
