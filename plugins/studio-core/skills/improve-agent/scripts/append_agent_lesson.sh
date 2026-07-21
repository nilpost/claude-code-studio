#!/usr/bin/env bash
# append_agent_lesson.sh — bake a behavioral lesson into a specific agent's
# definition file, under a "## Lessons learned" section.
#
# Usage:
#   append_agent_lesson.sh --agent NAME --lesson "text" [--file PATH] [--date YYYY-MM-DD]
#
# Resolving the agent file (first match wins):
#   1) --file PATH
#   2) $CLAUDE_PLUGIN_ROOT/agents/NAME.md
#   3) walking up from $CLAUDE_PROJECT_DIR / CWD:
#        plugins/studio-core/agents/NAME.md, then .claude/agents/NAME.md

set -euo pipefail

agent="" lesson="" file="" date_str="$(date +%Y-%m-%d)"
while [ $# -gt 0 ]; do
  case "$1" in
    --agent)  agent="$2";    shift 2 ;;
    --lesson) lesson="$2";   shift 2 ;;
    --file)   file="$2";     shift 2 ;;
    --date)   date_str="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

find_agent() {
  local name="$1" dir="${CLAUDE_PROJECT_DIR:-$PWD}"
  if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "$CLAUDE_PLUGIN_ROOT/agents/$name.md" ]; then
    printf '%s\n' "$CLAUDE_PLUGIN_ROOT/agents/$name.md"; return 0
  fi
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    if [ -f "$dir/plugins/studio-core/agents/$name.md" ]; then
      printf '%s\n' "$dir/plugins/studio-core/agents/$name.md"; return 0
    fi
    if [ -f "$dir/.claude/agents/$name.md" ]; then
      printf '%s\n' "$dir/.claude/agents/$name.md"; return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

if [ -z "$file" ]; then
  [ -n "$agent" ] || { echo "--agent or --file required" >&2; exit 1; }
  file="$(find_agent "$agent")" || { echo "Could not find agent '$agent'. Pass --file." >&2; exit 1; }
fi
[ -n "$lesson" ] || { echo "--lesson required" >&2; exit 1; }

section="## Lessons learned"
bullet="- ${date_str}: ${lesson}"

if grep -qF "$section" "$file"; then
  # Insert the bullet immediately after the section header, newest first,
  # so order in the rest of the file does not matter.
  tmp="$(mktemp)"
  awk -v sec="$section" -v b="$bullet" '
    { print }
    index($0, sec) && !done { print b; done=1 }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
else
  printf '\n%s\n\n_Behavioral lessons appended by the improve-agent skill. Keep them terse._\n\n%s\n' "$section" "$bullet" >> "$file"
fi

echo "Recorded lesson on agent file: $file"
