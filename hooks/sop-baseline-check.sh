#!/bin/bash
# sop-baseline-check.sh — PreToolUse:Bash hook
# Warns on git push if oracle repo is missing minimum SOP files
# Required: CLAUDE_safety.md, CLAUDE_workflows.md, CLAUDE_lessons.md
# ref: Office Improvement Plan Phase 4C — HR found 4 oracles with ZERO SOPs

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Only check git push
echo "$CMD" | grep -qiE 'git push' || exit 0

# Check for required SOP files in current repo
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
MISSING=""

[ ! -f "$ROOT/CLAUDE_safety.md" ] && MISSING="${MISSING}\n  - CLAUDE_safety.md"
[ ! -f "$ROOT/CLAUDE_workflows.md" ] && MISSING="${MISSING}\n  - CLAUDE_workflows.md"
[ ! -f "$ROOT/CLAUDE_lessons.md" ] && MISSING="${MISSING}\n  - CLAUDE_lessons.md"

[ -z "$MISSING" ] && exit 0

# Advisory — warn but don't block
echo "⚠️ SOP BASELINE: This repo is missing required SOP files:${MISSING}

Every oracle must have these 3 files. Create them before next push.
See: ~/.oracle/docs/OFFICE-OPERATIONS-SOP.md for reference."

exit 0
