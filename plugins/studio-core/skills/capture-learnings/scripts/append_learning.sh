#!/usr/bin/env bash
# append_learning.sh — append one structured entry to the studio LEARNINGS.md.
#
# Usage:
#   append_learning.sh --project P --title T --context C --lesson L --trigger K [--file PATH]
#
# The new entry is inserted directly beneath the
#   <!-- Captured entries below. Newest first. -->
# marker so entries stay in reverse-chronological order. If that marker is not
# found, the entry is appended to the end of the file.
#
# Resolving the target file (first match wins):
#   1) --file PATH argument
#   2) $STUDIO_LEARNINGS_FILE
#   3) knowledge/LEARNINGS.md walking up from $CLAUDE_PROJECT_DIR / CWD
#   4) $CLAUDE_PLUGIN_ROOT/../../knowledge/LEARNINGS.md (in-plugin copy)

set -euo pipefail

project="" title="" context="" lesson="" trigger="" file=""

while [ $# -gt 0 ]; do
  case "$1" in
    --project) project="$2"; shift 2 ;;
    --title)   title="$2";   shift 2 ;;
    --context) context="$2"; shift 2 ;;
    --lesson)  lesson="$2";  shift 2 ;;
    --trigger) trigger="$2"; shift 2 ;;
    --file)    file="$2";    shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

find_up() {
  # Walk up from $1 looking for knowledge/LEARNINGS.md
  local dir="$1"
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    if [ -f "$dir/knowledge/LEARNINGS.md" ]; then
      printf '%s\n' "$dir/knowledge/LEARNINGS.md"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

if [ -z "$file" ]; then
  if [ -n "${STUDIO_LEARNINGS_FILE:-}" ]; then
    file="$STUDIO_LEARNINGS_FILE"
  elif file="$(find_up "${CLAUDE_PROJECT_DIR:-$PWD}")"; then
    :
  elif [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "$CLAUDE_PLUGIN_ROOT/../../knowledge/LEARNINGS.md" ]; then
    file="$CLAUDE_PLUGIN_ROOT/../../knowledge/LEARNINGS.md"
  else
    echo "Could not locate knowledge/LEARNINGS.md. Pass --file or set STUDIO_LEARNINGS_FILE." >&2
    exit 1
  fi
fi

: "${project:=unknown}"
: "${title:=untitled}"
: "${context:=}"
: "${lesson:=}"
: "${trigger:=}"

date_str="$(date +%Y-%m-%d)"

entry="$(cat <<EOF

## ${date_str} — ${project} — ${title}
- **Context:** ${context}
- **Lesson:** ${lesson}
- **Trigger:** ${trigger}
EOF
)"

marker="<!-- Captured entries below. Newest first. -->"

if grep -qF "$marker" "$file"; then
  # Insert entry immediately after the marker line.
  #
  # The entry is multi-line, so it is passed to awk via a temp file rather than
  # `-v entry="$entry"`. GNU awk tolerates a literal newline in a -v assignment,
  # but the BWK awk shipped as /usr/bin/awk on macOS rejects it with
  # "awk: newline in string ... at source line 1" and writes nothing.
  tmp="$(mktemp)"
  entry_file="$(mktemp)"
  trap 'rm -f "$tmp" "$entry_file"' EXIT
  printf '%s\n' "$entry" > "$entry_file"

  awk -v marker="$marker" -v entry_file="$entry_file" '
    { print }
    !inserted && index($0, marker) {
      while ((getline line < entry_file) > 0) print line
      close(entry_file)
      inserted = 1
    }
  ' "$file" > "$tmp"

  # Refuse to clobber the knowledge base with a truncated or empty rewrite.
  if [ ! -s "$tmp" ]; then
    echo "append_learning.sh: refusing to write empty result to $file" >&2
    exit 1
  fi
  cat "$tmp" > "$file"
else
  printf '%s\n' "$entry" >> "$file"
fi

echo "Appended learning to: $file"
