#!/bin/bash
# bob-monitor-needs-loop.sh — PostToolUse:Bash hook (BoB-Oracle ONLY)
# Warns when BoB says "monitoring/awaiting/รอ" but hasn't set a maw loop.
# ref: [office] #139

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
[ -z "$CMD" ] && exit 0

# If BoB just ran maw loop add → set marker
if echo "$CMD" | grep -qE 'maw loop add'; then
  touch /tmp/.bob-loop-set
  exit 0
fi

# Skip non-maw-hey commands (only check BoB's outgoing messages)
echo "$CMD" | grep -qE '^maw hey ' || exit 0

# Extract message
MSG=$(echo "$CMD" | sed 's|.*maw hey [^ ]* ||' | tr -d "\"'")

# Check for monitoring keywords in the message
echo "$MSG" | grep -qiE '(monitoring|awaiting|follow.?up|ติดตาม|รอ.*ผล|waiting for|will check|จะเช็ค|track.?ing)' || exit 0

# Monitoring keyword found — check if maw loop was set
MARKER="/tmp/.bob-loop-set"
if [ -f "$MARKER" ]; then
  AGE=$(( $(date +%s) - $(stat -c %Y "$MARKER" 2>/dev/null || echo 0) ))
  [ "$AGE" -lt 1800 ] && exit 0
fi

echo '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"⚠️ BOB MONITOR CHECK: พูดว่า monitoring/awaiting แต่ยังไม่มี maw loop add — ตั้ง loop ก่อน:\n  maw loop add '\''{ \"id\":\"monitor-X\", \"schedule\":\"*/15 * * * *\", \"prompt\":\"check status of X\", \"enabled\":true }'\''\nไม่ใช่แค่พูดว่า monitoring แล้วลืม (Law #7)"}}'
exit 0
