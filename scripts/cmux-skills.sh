#!/usr/bin/env bash
#
# cmux-skills.sh — optional, opt-in installer for cmux agent skills.
#
# cmux (https://github.com/manaflow-ai/cmux) ships a set of agent skills that
# let coding agents drive its UI: the built-in agent browser, windows,
# workspaces, panes/surfaces, settings, and more.
#
# This wrapper fetches a pinned ref of cmux's skills from GitHub (reusing cmux's
# own skills.sh installer) and drops them into this repo's skills/ directory.
# Because both `install.sh claude` and `install.sh codex` symlink skills/ into
# the agent's config dir, installing here makes the skills available to BOTH
# agents at once.
#
# These skills are NOT installed by install.sh — they are strictly opt-in.
# The installed cmux* skill dirs are gitignored so they never get committed
# into your dotfiles.
#
# Usage:
#   scripts/cmux-skills.sh list                 # list available cmux skills
#   scripts/cmux-skills.sh install              # install all cmux skills
#   scripts/cmux-skills.sh install --skill cmux --skill cmux-browser
#   scripts/cmux-skills.sh install --dry-run    # show what would be installed
#   scripts/cmux-skills.sh uninstall            # remove all cmux skills
#
# Pin a specific cmux version with CMUX_SKILLS_REF (default: main):
#   CMUX_SKILLS_REF=v1.2.3 scripts/cmux-skills.sh install
#

set -euo pipefail

CMUX_REF="${CMUX_SKILLS_REF:-main}"
CMUX_SKILLS_URL="https://raw.githubusercontent.com/manaflow-ai/cmux/${CMUX_REF}/skills.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST_DIR="$REPO_DIR/skills"

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
    GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi

die() { printf 'cmux-skills.sh: %s\n' "$*" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }

usage() {
    cat <<EOF
Optional, opt-in installer for cmux agent skills.

Usage: $0 <command> [options]

Commands:
  list                  List available cmux skills and exit
  install [options]     Install cmux skills into ${DEST_DIR#$HOME/~}
  uninstall             Remove all installed cmux skills

Install options (passed through to cmux's skills.sh):
  --skill NAME          Install one skill (repeat for multiple). Default: all
  --dry-run             Print what would be installed without installing

Environment:
  CMUX_SKILLS_REF       cmux git ref to fetch (default: main)

Examples:
  $0 list
  $0 install
  $0 install --skill cmux --skill cmux-browser
  CMUX_SKILLS_REF=v1.2.3 $0 install
  $0 uninstall
EOF
}

run_cmux_skills() {
    # Pipe cmux's official installer and forward args after `--`.
    need_cmd curl
    curl -fsSL "$CMUX_SKILLS_URL" | bash -s -- "$@"
}

cmd_list() {
    run_cmux_skills --ref "$CMUX_REF" --list
}

cmd_install() {
    mkdir -p "$DEST_DIR"
    echo -e "${BOLD}Installing cmux skills (ref: ${CMUX_REF}) into ${DEST_DIR}...${NC}"
    run_cmux_skills --ref "$CMUX_REF" --dest "$DEST_DIR" "$@"
    echo ""
    echo -e "${GREEN}Done.${NC} Restart Claude Code / Codex (or start a new session) to pick them up."
}

cmd_uninstall() {
    shopt -s nullglob
    local removed=0
    for dir in "$DEST_DIR"/cmux "$DEST_DIR"/cmux-*; do
        [[ -d "$dir" ]] || continue
        rm -rf "$dir"
        echo -e "  ${YELLOW}[REMOVED]${NC} $(basename "$dir")"
        removed=$((removed + 1))
    done
    shopt -u nullglob
    if [[ "$removed" -eq 0 ]]; then
        echo -e "  ${BLUE}[OK]${NC} no cmux skills installed in ${DEST_DIR}"
    else
        echo ""
        echo -e "${GREEN}Removed ${removed} cmux skill(s).${NC}"
    fi
}

[[ $# -ge 1 ]] || { usage; exit 1; }

command="$1"; shift
case "$command" in
    list)          cmd_list "$@" ;;
    install)       cmd_install "$@" ;;
    uninstall)     cmd_uninstall "$@" ;;
    -h|--help)     usage ;;
    *)             die "unknown command: $command (try --help)" ;;
esac
