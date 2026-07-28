#!/usr/bin/env bash
# enable-in-repo.sh — wire ANY repo so every session opened on it (local and
# Claude Code on the web) auto-installs and enables the studio plugins.
#
# Merges the studio keys into <repo>/.claude/settings.json, preserving whatever
# is already there. Commit the result: cloud containers are ephemeral and clone
# the repo fresh, so a committed settings file is what makes the studio load in
# every future session of that repo.
#
# Usage:
#   ./scripts/enable-in-repo.sh                     # current repo, studio-core
#   ./scripts/enable-in-repo.sh /path/to/repo       # another repo
#   ./scripts/enable-in-repo.sh --with-cloudflare   # also enable cloudflare-mcp
#   ./scripts/enable-in-repo.sh --dry-run           # print the result, write nothing

set -euo pipefail

MARKETPLACE_REPO="${STUDIO_MARKETPLACE:-nilpost/claude-code-studio}"
MARKETPLACE_NAME="claude-code-studio"

target=""
with_cloudflare=0
dry_run=0

for arg in "$@"; do
  case "$arg" in
    --with-cloudflare) with_cloudflare=1 ;;
    --dry-run)         dry_run=1 ;;
    -h|--help)
      # Print the leading comment block (everything after the shebang).
      awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "$0"
      exit 0 ;;
    -*)
      echo "Unknown option: $arg" >&2
      exit 2 ;;
    *)
      if [ -n "$target" ]; then
        echo "Only one repo path may be given (got '$target' and '$arg')." >&2
        exit 2
      fi
      target="$arg" ;;
  esac
done

target="${target:-.}"

if [ ! -d "$target" ]; then
  echo "Not a directory: $target" >&2
  exit 1
fi
target="$(cd "$target" && pwd)"

if [ ! -d "$target/.git" ]; then
  echo "Warning: $target is not a git repository — the settings file only reaches" >&2
  echo "cloud sessions if it is committed and pushed." >&2
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to merge JSON safely but was not found on PATH." >&2
  echo "Merge templates/consumer-settings.snippet.json by hand instead." >&2
  exit 1
fi

settings="$target/.claude/settings.json"
mkdir -p "$target/.claude"

rc=0
MARKETPLACE_REPO="$MARKETPLACE_REPO" \
MARKETPLACE_NAME="$MARKETPLACE_NAME" \
SETTINGS_PATH="$settings" \
WITH_CLOUDFLARE="$with_cloudflare" \
DRY_RUN="$dry_run" \
python3 <<'PY' || rc=$?
import json, os, sys

path = os.environ["SETTINGS_PATH"]
name = os.environ["MARKETPLACE_NAME"]
repo = os.environ["MARKETPLACE_REPO"]
with_cf = os.environ["WITH_CLOUDFLARE"] == "1"
dry_run = os.environ["DRY_RUN"] == "1"

if os.path.exists(path):
    with open(path) as fh:
        raw = fh.read().strip()
    try:
        settings = json.loads(raw) if raw else {}
    except json.JSONDecodeError as exc:
        sys.exit(f"{path} is not valid JSON ({exc}). Fix it first, then re-run.")
    if not isinstance(settings, dict):
        sys.exit(f"{path} must contain a JSON object at the top level.")
else:
    settings = {}

before = json.dumps(settings, sort_keys=True)

marketplaces = settings.setdefault("extraKnownMarketplaces", {})
if not isinstance(marketplaces, dict):
    sys.exit("extraKnownMarketplaces must be a JSON object.")
existing = marketplaces.get(name)
# Don't clobber a deliberate local 'directory' source (used by the studio repo
# itself to dogfood uncommitted changes).
if not (isinstance(existing, dict)
        and existing.get("source", {}).get("source") == "directory"):
    marketplaces[name] = {"source": {"source": "github", "repo": repo}}

plugins = settings.setdefault("enabledPlugins", {})
if not isinstance(plugins, dict):
    sys.exit("enabledPlugins must be a JSON object.")
plugins[f"studio-core@{name}"] = True
if with_cf:
    plugins[f"cloudflare-mcp@{name}"] = True

out = json.dumps(settings, indent=2) + "\n"

if json.dumps(settings, sort_keys=True) == before:
    print(f"Already up to date: {path}")
    sys.exit(3)  # signals "no change" to the shell wrapper

if dry_run:
    print(f"--- would write {path} ---")
    print(out, end="")
    sys.exit(0)

with open(path, "w") as fh:
    fh.write(out)
print(f"Updated {path}")
PY

case "$rc" in
  0) changed=1 ;;   # written (or printed, under --dry-run)
  3) changed=0 ;;   # nothing to do
  *) exit "$rc" ;;  # real error, message already printed
esac

if [ "$dry_run" -eq 0 ] && [ "$changed" -eq 1 ]; then
  echo
  echo "Next: commit and push it so every future session of this repo picks it up."
  echo "  git -C '$target' add .claude/settings.json && git -C '$target' commit -m 'chore: enable claude-code-studio plugins'"
  echo
  echo "Agents and slash-commands register at session start — open a NEW session to use them."
fi
