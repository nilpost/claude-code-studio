#!/usr/bin/env bash
# enable-in-repo.sh — wire ANY repo so every session opened on it (local and
# Claude Code on the web) auto-installs and enables the studio plugins.
#
# Merges the studio keys into <repo>/.claude/settings.json, preserving whatever
# is already there. Commit the result: cloud containers are ephemeral and clone
# the repo fresh, so a committed settings file is what makes the studio load in
# every future session of that repo.
#
# Self-contained: this script has no dependency on the rest of the studio repo.
# Save it anywhere (e.g. `curl` it from GitHub) and run it against any repo you
# own — a full studio checkout is convenient but not required.
#
# python3 is used to merge JSON safely when it's available. If it isn't (e.g.
# macOS without the Xcode Command Line Tools), this script can still write a
# brand-new settings file, but refuses to touch an existing one rather than
# risk clobbering it.
#
# Usage:
#   ./scripts/enable-in-repo.sh                     # current repo, studio-core
#   ./scripts/enable-in-repo.sh /path/to/repo       # another repo
#   ./scripts/enable-in-repo.sh --with-cloudflare   # also enable cloudflare-mcp
#   ./scripts/enable-in-repo.sh --dry-run           # print the result, write nothing
#   ./scripts/enable-in-repo.sh --push              # ...and commit + push the result
#
# Why --push? Cloud sessions clone the repo fresh from GitHub. A settings file
# that only exists on your laptop is invisible to them; committed and pushed,
# every future cloud session on that repo installs the plugin at startup.

set -euo pipefail

MARKETPLACE_REPO="${STUDIO_MARKETPLACE:-nilpost/claude-code-studio}"
MARKETPLACE_NAME="claude-code-studio"

target=""
with_cloudflare=0
dry_run=0
do_push=0

for arg in "$@"; do
  case "$arg" in
    --with-cloudflare) with_cloudflare=1 ;;
    --dry-run)         dry_run=1 ;;
    --push)            do_push=1 ;;
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

if [ "$dry_run" -eq 1 ] && [ "$do_push" -eq 1 ]; then
  echo "--dry-run and --push are contradictory. Pick one." >&2
  exit 2
fi

is_git=1
git -C "$target" rev-parse --git-dir >/dev/null 2>&1 || is_git=0
if [ "$is_git" -eq 0 ]; then
  echo "Warning: $target is not a git repository — the settings file only reaches" >&2
  echo "cloud sessions if it is committed and pushed." >&2
  if [ "$do_push" -eq 1 ]; then
    echo "Cannot --push outside a git repository." >&2
    exit 1
  fi
fi

settings="$target/.claude/settings.json"
[ "$dry_run" -eq 1 ] || mkdir -p "$target/.claude"

# Fresh-file fallback for when python3 isn't available (see header).
read -r -d '' FRESH_JSON <<JSON || true
{
  "extraKnownMarketplaces": {
    "$MARKETPLACE_NAME": {
      "source": {
        "source": "github",
        "repo": "$MARKETPLACE_REPO"
      }
    }
  },
  "enabledPlugins": {
    "studio-core@$MARKETPLACE_NAME": true$( [ "$with_cloudflare" -eq 1 ] && printf ',\n    "cloudflare-mcp@%s": true' "$MARKETPLACE_NAME" )
  }
}
JSON

changed=0

if command -v python3 >/dev/null 2>&1; then
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

else
  echo "Note: python3 not found, so this script cannot merge JSON." >&2
  if [ -e "$settings" ]; then
    echo "ERROR: $settings already exists and I will not overwrite it blindly." >&2
    echo "Install python3 (on macOS: xcode-select --install) and re-run, or merge" >&2
    echo "these keys into that file by hand:" >&2
    echo >&2
    echo "$FRESH_JSON" >&2
    exit 1
  fi
  if [ "$dry_run" -eq 1 ]; then
    echo "--- would write $settings ---"
    echo "$FRESH_JSON"
  else
    echo "$FRESH_JSON" > "$settings"
    echo "Wrote $settings"
    changed=1
  fi
fi

[ "$dry_run" -eq 1 ] && exit 0

if [ "$do_push" -eq 1 ]; then
  if [ "$changed" -eq 0 ] && git -C "$target" diff --quiet -- .claude/settings.json 2>/dev/null; then
    echo "Nothing new to commit."
  else
    branch="$(git -C "$target" rev-parse --abbrev-ref HEAD)"
    echo
    echo "Committing to branch '$branch' and pushing to origin..."
    git -C "$target" add .claude/settings.json
    if git -C "$target" diff --cached --quiet; then
      echo "Nothing staged; already committed."
    else
      git -C "$target" commit -m "chore: enable claude-code-studio plugin"
    fi
    git -C "$target" push -u origin "$branch"
    echo "Pushed. Cloud sessions on this repo will now load the studio."
  fi
elif [ "$changed" -eq 1 ]; then
  echo
  echo "Next: commit and push it so every future session of this repo picks it up."
  echo "  git -C '$target' add .claude/settings.json && git -C '$target' commit -m 'chore: enable claude-code-studio plugins'"
  echo
  echo "(Or re-run this script with --push to do that automatically.)"
fi

if [ "$changed" -eq 1 ]; then
  echo
  echo "Run /reload-plugins in an open session to pick up the agents and commands."
fi
