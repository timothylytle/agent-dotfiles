---
name: docket-log
description: Default interstitial journal for all coding-agent work. Append one-line, timestamped notes to the Docket task being worked on whenever something notable happens (a skill or slash command like mr_commit runs, commits land, tests pass or fail, a PR opens, a decision or blocker). Use in every repo unless the user opts out.
---

# Docket log (interstitial journal)

Keep a running, terse journal of agent work on the user's Docket task. Each
entry is one line answering *what happened, and when* — not prose about how.

Entries are written with the helper script (it adds the timestamp, the
agent stamp and the repo):

```sh
~/.claude/scripts/docket-log.sh -a <agent> [-t <task-id>] "<what happened>"
```

(Codex: `~/.codex/scripts/docket-log.sh`, same script.)

Which renders in the task's `Agent log` tab as:

> `Fri Oct 9 1:15pm` `claude-code-cli_opus5.5@agent-dotfiles` — mr_commit: `52661c9` Ignore locally managed skill directories

## The agent stamp (`-a`)

`<app>_<model>`, lowercase, no spaces. Examples:

- `claude-code-cli_opus5.5`, `claude-code-cli_sonnet5.5`
- `codex-cli_gpt-5.5`

Use the model you are actually running as. The script appends `@<repo>`.

## Finding the task

1. Try logging without `-t`: the script reuses the task bound to the
   current `repo@branch`. Exit code 2 means nothing is bound yet.
2. If the user named a task, use it with `-t <id>`.
3. Otherwise search: `docket tasks --q "<words from the request, branch or repo>"`.
   One clear match → use it. Ambiguous or none → ask the user once:
   "Log this to which Docket task? (id / create new / skip)". Create one
   with `docket create` only when they say so.
4. If the user says skip, or `docket` isn't available or the server is
   down, stop logging for the session. Never let logging block the work or
   spend turns troubleshooting it.

Passing `-t` once binds that task to `repo@branch`, so later calls and later
sessions on the same branch omit it.

## When to log

One entry per event, right after it happens:

- A skill or slash command runs: `mr_commit`, `mr_plan`, `mr_implement_plan`, `address-pr-comments`, …
- Commits: short SHA(s) in backticks + subject(s)
- Tests / lint: pass/fail and counts
- PR opened or updated: number/URL
- A decision, a finding that changes direction, or a blocker
- Work finished (and whether it was verified)

Do not log file reads, searches, or routine steps.

## Style

- One line, ≤ ~120 chars of note. Fragments, not sentences.
- Lead with the action: `mr_commit:`, `tests:`, `PR:`, `decision:`, `blocked:`, `done:`.
- SHAs, ids, file names and commands in backticks.

Examples:

```
mr_commit: `a1b2c3d` feat: add retry metrics; `d4e5f6a` test: cover backoff
tests: 48 pass, 1 skipped (`uv run pytest`)
decision: keep sync in launchd, drop cron fallback
blocked: CircleCI job needs DOCKER_PASS secret
PR: #412 opened "Add retry metrics"
done: retry metrics shipped, verified locally
```

For long write-ups (findings, plans) use the `docket` skill and a separate
tab; this journal stays one-liners.
