#!/usr/bin/env bash
# Append a one-line, timestamped journal entry to a Docket task's "Agent log" tab.
#
#   docket-log.sh -a claude-code-cli_opus5.5 -t 93 "mr_commit: \`52661c9\` Ignore skill dirs"
#   docket-log.sh -a claude-code-cli_opus5.5 "tests pass (12)"   # reuses the bound task
#
# -t binds the task to the current repo@branch, so later calls (and later
# sessions) on the same branch can omit it. Exits 2 when no task is bound.
set -euo pipefail

usage() { echo "usage: $(basename "$0") -a AGENT [-t TASK_ID] NOTE..." >&2; exit 1; }

agent="" task=""
while getopts "a:t:" opt; do
  case $opt in
    a) agent=$OPTARG ;;
    t) task=$OPTARG ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[[ -n "$agent" && $# -gt 0 ]] || usage

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  repo=$(basename "$(git rev-parse --show-toplevel)")
  branch=$(git branch --show-current 2>/dev/null || true)
else
  repo=$(basename "$PWD")
  branch=""
fi

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/docket-log"
binding="$state_dir/${repo}@${branch:-none}"

if [[ -n "$task" ]]; then
  mkdir -p "$state_dir"
  echo "$task" > "$binding"
elif [[ -f "$binding" ]]; then
  task=$(cat "$binding")
else
  echo "docket-log: no task bound to ${repo}@${branch:-none}; pass -t TASK_ID" >&2
  exit 2
fi

stamp=$(date '+%a %b %-d %-I:%M%p' | sed 's/AM$/am/; s/PM$/pm/')
docket note "$task" --tab "Agent log" --author "$agent" \
  "\`$stamp\` \`$agent@$repo\` — $*"
