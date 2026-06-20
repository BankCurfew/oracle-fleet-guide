#!/usr/bin/env bash
# pw-cli.sh — Playwright CLI wrapper for all oracles
# Saves snapshots/screenshots to DISK (not context) = ~4.6x token savings
#
# Usage:
#   pw-cli.sh open                          # open browser
#   pw-cli.sh goto <url>                    # navigate
#   pw-cli.sh snapshot                      # accessibility tree → disk YAML
#   pw-cli.sh screenshot                    # screenshot → disk PNG
#   pw-cli.sh click <ref>                   # click element by ref (e.g. e16)
#   pw-cli.sh fill <ref> <text>             # fill input by ref
#   pw-cli.sh type <text>                   # type into focused element
#   pw-cli.sh state-save <name>             # save cookies/storage for session reuse
#   pw-cli.sh state-load <name>             # restore saved session
#   pw-cli.sh -s=<session> <cmd> [args]     # named session (parallel browsers)
#   pw-cli.sh help                          # show this help
#
# Session names: use -s=<name> (e.g. -s=work, -s=research) for isolated profiles
# State files: saved to ~/.oracle/browser-states/<name>.json
#
# Element refs: run `snapshot` first, then use refs (e.g. e16, e20) in commands
# Refs are accessibility-based = more resilient than CSS selectors
#
# Replaces: cdp.ts (361 lines), Playwright MCP (streams into context)
# Token savings: ~25K vs ~115K per 30 actions (4.6x reduction)

set -euo pipefail

STATES_DIR="$HOME/.oracle/browser-states"
mkdir -p "$STATES_DIR"

# Use Playwright's bundled Chromium — system Chrome segfaults on WSL2
# Find latest bundled chromium in ms-playwright cache
PW_CHROME="$(ls -d "$HOME/.cache/ms-playwright"/chromium-*/chrome-linux64/chrome 2>/dev/null | sort -V | tail -1)"
if [[ -n "$PW_CHROME" && -x "$PW_CHROME" ]]; then
  export CHROME_PATH="$PW_CHROME"
fi

# Resolve playwright-cli path
PWCLI="$(which playwright-cli 2>/dev/null || echo "$HOME/.nvm/versions/node/v22.22.1/bin/playwright-cli")"

if [[ ! -x "$PWCLI" ]]; then
  echo "ERROR: playwright-cli not found. Install: npm install -g @playwright/cli@latest"
  exit 1
fi

# Intercept state-save/state-load to use centralized state directory
CMD="${1:-help}"

case "$CMD" in
  help|-h|--help)
    head -20 "$0" | grep "^#" | sed 's/^# *//'
    echo ""
    echo "All playwright-cli commands also work (50+ commands):"
    "$PWCLI" --help 2>&1 | grep "^  " | head -40
    exit 0
    ;;
  state-save)
    NAME="${2:-default}"
    STATE_FILE="$STATES_DIR/${NAME}.json"
    "$PWCLI" state-save "$STATE_FILE"
    echo "State saved: $STATE_FILE"
    exit 0
    ;;
  state-load)
    NAME="${2:-default}"
    STATE_FILE="$STATES_DIR/${NAME}.json"
    if [[ ! -f "$STATE_FILE" ]]; then
      echo "ERROR: No saved state '$NAME'. Available:"
      ls "$STATES_DIR"/*.json 2>/dev/null | xargs -I{} basename {} .json || echo "  (none)"
      exit 1
    fi
    "$PWCLI" state-load "$STATE_FILE"
    echo "State loaded: $STATE_FILE"
    exit 0
    ;;
  states)
    echo "Saved browser states:"
    ls "$STATES_DIR"/*.json 2>/dev/null | while read f; do
      echo "  $(basename "$f" .json) — $(stat -c '%y' "$f" | cut -d. -f1)"
    done || echo "  (none)"
    exit 0
    ;;
  open)
    # Force bundled chromium — system Chrome not installed on curfew
    shift
    exec "$PWCLI" open --browser chromium "$@"
    ;;
  *)
    # Pass through all other commands directly to playwright-cli
    exec "$PWCLI" "$@"
    ;;
esac
