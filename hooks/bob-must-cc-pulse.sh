#!/bin/bash
# bob-must-cc-pulse.sh — PreToolUse:Bash hook (BoB-Oracle ONLY)
# BLOCKS BoB's task dispatches unless Pulse was cc'd first.
# Uses marker file with 5min TTL — cc Pulse once, dispatch freely for 5min.
# ref: [office] #138

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Only check maw hey dispatches (not to bob/pulse themselves)
echo "$CMD" | grep -qE 'maw hey ' || exit 0

TARGET=$(echo "$CMD" | grep -oE 'maw hey [^ ]*' | awk '{print $NF}' | tr '[:upper:]' '[:lower:]')

# Messages TO pulse set the marker (BoB just cc'd Pulse)
case "$TARGET" in
  pulse|pulse-oracle) touch /tmp/.bob-cc-pulse; exit 0 ;;
  bob|bob-oracle) exit 0 ;;
esac

# Skip: short pings/acks
MSG=$(echo "$CMD" | sed 's|.*maw hey [^ ]* ||' | tr -d "\"'" | head -c 500)
[ "${#MSG}" -lt 10 ] && exit 0
echo "$MSG" | grep -qiE '^(ping|ACK|OK|yes|no|done|test|status|confirm|รับทราบ)' && exit 0

# Skip: non-task messages (cc: status reports without task verbs)
if echo "$MSG" | grep -qiE '^cc:'; then
  if ! echo "$MSG" | grep -qiE '(TASK:|BUG:|FEATURE:|assigned:|ทำ.*ให้|ให้.*ทำ|do this|fix this|build|create|implement|deploy)'; then
    exit 0
  fi
fi

# Check marker — was Pulse cc'd recently?
MARKER="/tmp/.bob-cc-pulse"
MARKER_TTL=30

if [ -f "$MARKER" ]; then
  AGE=$(( $(date +%s) - $(stat -c %Y "$MARKER" 2>/dev/null || echo 0) ))
  if [ "$AGE" -lt "$MARKER_TTL" ]; then
    exit 0
  fi
fi

# Check if THIS command is cc'ing pulse
if [ "$TARGET" = "pulse" ] || [ "$TARGET" = "pulse-oracle" ]; then
  touch "$MARKER"
  exit 0
fi

echo '{"error":"🚫 BLOCKED: BoB ต้อง cc Pulse ก่อน dispatch task.\n\n1. maw hey pulse \"cc: [project] #ticket — dispatching <task> to <oracle>\"\n2. แล้วค่อย dispatch ให้ oracle อื่น\n\nPulse tracks ทุก dispatch — ถ้าไม่ cc = invisible work."}'
exit 2
