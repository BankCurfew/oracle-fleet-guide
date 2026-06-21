#!/bin/bash
# auto-task-done.sh — PostToolUse:Bash hook
# When gh issue close runs successfully, auto-run maw task done
# Fixes: 83 tasks 0 completed — maw task done never called
# ref: Cost + VideoEditor retro — invisible work

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // ""' 2>/dev/null)

# Only trigger on gh issue close
echo "$CMD" | grep -qiE 'gh issue close' || exit 0

# Extract issue number
ISSUE_NUM=$(echo "$CMD" | grep -oE '#[0-9]+|close [0-9]+' | grep -oE '[0-9]+' | head -1)
[ -z "$ISSUE_NUM" ] && exit 0

# Check close was successful (output doesn't contain error)
echo "$OUTPUT" | grep -qiE 'error|failed|not found' && exit 0

# Auto-mark task done
maw task done "#${ISSUE_NUM}" 2>/dev/null

echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"✅ Auto: maw task done #${ISSUE_NUM} (triggered by gh issue close)\"}}"
exit 0
