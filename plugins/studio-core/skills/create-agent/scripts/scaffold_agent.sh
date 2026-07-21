#!/usr/bin/env bash
# scaffold_agent.sh — create a NEW studio agent definition from a template.
# Refuses to overwrite an existing agent.
#
# Usage:
#   scaffold_agent.sh --name NAME --description "when to use" \
#     [--tools "Read, Glob, Grep"] [--model claude-sonnet-5] [--dir AGENTS_DIR]

set -euo pipefail

name="" desc="" tools="Read, Glob, Grep" model="claude-sonnet-5" dir=""
while [ $# -gt 0 ]; do
  case "$1" in
    --name)        name="$2";  shift 2 ;;
    --description) desc="$2";  shift 2 ;;
    --tools)       tools="$2"; shift 2 ;;
    --model)       model="$2"; shift 2 ;;
    --dir)         dir="$2";   shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$name" ] || { echo "--name required" >&2; exit 1; }
[ -n "$desc" ] || { echo "--description required" >&2; exit 1; }
case "$name" in *[!a-z0-9-]*) echo "name must be kebab-case (a-z0-9-): '$name'" >&2; exit 1 ;; esac

if [ -z "$dir" ]; then
  if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -d "$CLAUDE_PLUGIN_ROOT/agents" ]; then
    dir="$CLAUDE_PLUGIN_ROOT/agents"
  else
    d="${CLAUDE_PROJECT_DIR:-$PWD}"
    while [ -n "$d" ] && [ "$d" != "/" ]; do
      if [ -d "$d/plugins/studio-core/agents" ]; then dir="$d/plugins/studio-core/agents"; break; fi
      d="$(dirname "$d")"
    done
  fi
fi
[ -n "$dir" ] || { echo "Could not locate an agents dir; pass --dir." >&2; exit 1; }

file="$dir/$name.md"
[ -e "$file" ] && { echo "Agent already exists: $file (refusing to overwrite)" >&2; exit 1; }

cat > "$file" <<EOF
---
name: $name
description: $desc
model: $model
tools: [$tools]
---

You are the \`$name\` agent, distributed via the \`claude-code-studio\` marketplace.
It works the same in every project; project-specific detail comes from that
project's own files, not this prompt.

## When to use
$desc

## Startup
1. Read only what you need to scope the task (the project's \`AGENTS.md\` /
   \`CLAUDE.md\` / \`README.md\`). Do not read every file.
2. If the \`recall-learnings\` skill is available, check for prior lessons whose
   triggers match this task before you start.

## Instructions
<!-- Replace with this agent's real responsibilities, method, and output. -->

## Lessons learned
<!-- Appended by the improve-agent skill as this agent makes and corrects
     mistakes. Keep entries terse and behavioral. -->
EOF

echo "Created agent: $file"
