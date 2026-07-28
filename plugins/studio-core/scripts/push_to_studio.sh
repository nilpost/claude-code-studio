#!/usr/bin/env bash
# push_to_studio.sh — land a learning in the claude-code-studio repo from ANY
# environment, even when you are not inside a checkout of the studio.
#
# It clones the (public) studio repo to a temp dir, applies the entry with the
# repo's own append scripts, commits on a fresh branch, pushes, and prints how to
# open a PR (using `gh` if available).
#
# Subcommands:
#   push_to_studio.sh learning \
#       --project P --title T [--context C] --lesson L --trigger K
#   push_to_studio.sh agent-lesson --agent NAME --lesson L
#
# Options:
#   --remote URL   Studio git remote (default: $STUDIO_REMOTE or the public HTTPS URL)
#   --dry-run      Do everything except push / open PR; leave the clone for inspection
#
# Auth: cloning a public repo needs no credentials; the *push* uses whatever git
# credentials the environment already has (local credential helper, or the cloud
# session's in-scope GitHub access). If the push fails, the entry is preserved in
# the printed clone path so nothing is lost.

set -euo pipefail

sub="${1:-}"; shift || true
[ -n "$sub" ] || { echo "usage: push_to_studio.sh {learning|agent-lesson} [options]" >&2; exit 2; }

remote="${STUDIO_REMOTE:-https://github.com/nilpost/claude-code-studio.git}"
dry=0
project="" title="" context="" lesson="" trigger="" agent=""

while [ $# -gt 0 ]; do
  case "$1" in
    --remote)  remote="$2";  shift 2 ;;
    --dry-run) dry=1;        shift 1 ;;
    --project) project="$2"; shift 2 ;;
    --title)   title="$2";   shift 2 ;;
    --context) context="$2"; shift 2 ;;
    --lesson)  lesson="$2";  shift 2 ;;
    --trigger) trigger="$2"; shift 2 ;;
    --agent)   agent="$2";   shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

work="$(mktemp -d)"
clone="$work/claude-code-studio"
cleanup() { [ "$dry" -eq 1 ] || rm -rf "$work"; }
trap cleanup EXIT

echo "Cloning studio: $remote"
git clone --depth 1 "$remote" "$clone" >/dev/null 2>&1 \
  || { echo "Clone failed. Is the remote reachable? ($remote)" >&2; exit 1; }

slug="$(printf '%s' "${title:-$agent}" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-' | cut -c1-40)"
branch="learn/$(date +%Y%m%d-%H%M%S)-${slug:-entry}"
git -C "$clone" checkout -b "$branch" >/dev/null 2>&1

case "$sub" in
  learning)
    [ -n "$lesson" ] || { echo "--lesson required" >&2; exit 2; }
    "$clone/plugins/studio-core/skills/capture-learnings/scripts/append_learning.sh" \
      --file "$clone/knowledge/LEARNINGS.md" \
      --project "${project:-unknown}" --title "${title:-untitled}" \
      --context "$context" --lesson "$lesson" --trigger "$trigger"
    commit_path="knowledge/LEARNINGS.md"
    msg="learn: ${title:-captured lesson}"
    ;;
  agent-lesson)
    [ -n "$agent" ] && [ -n "$lesson" ] || { echo "--agent and --lesson required" >&2; exit 2; }
    "$clone/plugins/studio-core/skills/improve-agent/scripts/append_agent_lesson.sh" \
      --file "$clone/plugins/studio-core/agents/$agent.md" --lesson "$lesson"
    commit_path="plugins/studio-core/agents/$agent.md"
    msg="improve($agent): behavioral lesson"
    ;;
  *) echo "unknown subcommand: $sub" >&2; exit 2 ;;
esac

git -C "$clone" add "$commit_path"
git -C "$clone" -c user.name="${GIT_AUTHOR_NAME:-studio-learner}" \
    -c user.email="${GIT_AUTHOR_EMAIL:-studio-learner@users.noreply.github.com}" \
    commit -q -m "$msg"

if [ "$dry" -eq 1 ]; then
  echo
  echo "[dry-run] Would push branch '$branch' to $remote and open a PR."
  echo "[dry-run] Review the staged change here: $clone"
  echo "[dry-run] Diff:"; git -C "$clone" --no-pager show --stat HEAD
  exit 0
fi

echo "Pushing branch: $branch"
if git -C "$clone" push -u origin "$branch" >/dev/null 2>&1; then
  echo "Pushed."
  if command -v gh >/dev/null 2>&1; then
    gh --repo nilpost/claude-code-studio pr create --draft --fill --head "$branch" 2>/dev/null \
      && { echo "Opened a draft PR."; exit 0; }
  fi
  echo "Open a PR for branch '$branch':"
  echo "  https://github.com/nilpost/claude-code-studio/compare/main...$branch?expand=1"
else
  echo "Push failed (no write access from this environment?)." >&2
  echo "The commit is preserved here so nothing is lost: $clone" >&2
  echo "Retry from an environment with write access, or open a PR by hand." >&2
  dry=1  # keep the clone for the user
  exit 1
fi
