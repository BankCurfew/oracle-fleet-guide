#!/bin/bash
# five-whys-guard.sh — PostToolUse:Bash hook
# Advisory: after 3 rapid fix attempts without diagnostic step, remind to trace actual data
# Does NOT block (exit 0) — creates friction against guessing
# ref: Office Improvement Plan Phase 2C — BUG10 took 5 attempts, Dev tmux bug 4 iterations

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // ""' 2>/dev/null | head -3)

# Detect fix-attempt patterns
IS_FIX=false
echo "$CMD" | grep -qiE '(git commit|git add|sed |Edit|npm run build|wrangler.*deploy|pm2 restart)' && IS_FIX=true
[ "$IS_FIX" = false ] && exit 0

# Track fix attempts via marker file
ORACLE_LOWER=$(echo "${ORACLE_NAME:-unknown}" | tr '[:upper:]' '[:lower:]')
MARKER="/tmp/five-whys-${ORACLE_LOWER}.count"

# Read current count
COUNT=0
if [ -f "$MARKER" ]; then
  MARKER_AGE=$(( $(date +%s) - $(stat -c %Y "$MARKER" 2>/dev/null || echo 0) ))
  if [ "$MARKER_AGE" -lt 600 ]; then
    COUNT=$(cat "$MARKER" 2>/dev/null || echo 0)
  else
    COUNT=0
  fi
fi

# Check if this was a diagnostic step (resets counter)
echo "$CMD" | grep -qiE '(console.log|curl -s|grep|cat |Read|jq |python3.*json|DB query|SELECT )' && echo 0 > "$MARKER" && exit 0

# Increment fix count
COUNT=$((COUNT + 1))
echo "$COUNT" > "$MARKER"

# After 3 rapid fixes → advisory
if [ "$COUNT" -ge 3 ]; then
  echo "⚠️ 5 WHYS: ${COUNT} fix attempts without diagnostic step. PAUSE and trace:
1. What does the ACTUAL data look like? (curl/console.log)
2. What does the CONSUMER expect? (read the component)
3. Where do they DIVERGE? (diff the two)
4. WHY? (root cause)
5. What's the ONE fix?"
  # Don't reset — keep reminding until they do a diagnostic step
fi

exit 0
