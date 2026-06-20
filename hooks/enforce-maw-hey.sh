#!/bin/bash
# enforce-maw-hey.sh — PreToolUse hook (matcher: .*)
# ENFORCES structured maw hey communication (BoB-Oracle#121):
#   Every maw hey MUST contain WHAT + WHY at minimum.
#   cc: messages must follow Rule #8 contract (what · why · next).
#   Long messages (100+ chars) without thread ref → warn to use threads.
# Exempt: BoB, Pulse (orchestrators). Messages TO bob/pulse always allowed.

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)

[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

echo "$CMD" | grep -qE 'maw hey ' || exit 0

# Identify caller
CWD="$(pwd 2>/dev/null)"
if [[ "$CWD" =~ ([^/]+)-[Oo]racle ]]; then
  ORACLE_RAW="${BASH_REMATCH[1]}"
elif [ -n "${ORACLE_NAME:-}" ]; then
  ORACLE_RAW="$ORACLE_NAME"
else
  ORACLE_RAW="$(basename "$CWD" 2>/dev/null)"
fi
ORACLE_LOWER=$(echo "$ORACLE_RAW" | tr '[:upper:]' '[:lower:]' | sed 's/-oracle$//')

# Exempt BoB and Pulse
case "$ORACLE_LOWER" in
  bob|pulse) exit 0 ;;
esac

# Allow messages to bob/pulse (always OK — they're orchestrators)
TARGET=$(echo "$CMD" | grep -oE 'maw hey [^ ]*' | awk '{print $NF}' | tr '[:upper:]' '[:lower:]')
case "$TARGET" in
  bob|bob-oracle|pulse|pulse-oracle) exit 0 ;;
esac

# Extract message content
MSG=$(echo "$CMD" | sed 's/.*maw hey [^ ]* //' | tr -d "\"'" | head -c 500)
MSG_LEN=${#MSG}

# Allow empty/very short (pings, acks <10 chars)
[ "$MSG_LEN" -lt 10 ] && exit 0

# Allow status checks, pings, acks
echo "$MSG" | grep -qiE '^(ping|ACK|OK|yes|no|done|test|status|confirm|check|peek|follow)' && exit 0

# cc: messages — require Rule #8 structured format (what · why · next)
if echo "$MSG" | grep -qiE '^cc:'; then
  if echo "$MSG" | grep -qE '·.*·'; then
    # Has separators → structured → check length for thread warning
    if [ "$MSG_LEN" -ge 100 ] && ! echo "$MSG" | grep -qiE 'thread.*#[0-9]|#[0-9].*thread|THREAD:'; then
      echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"⚠️ COMM PROTOCOL: ข้อความยาวเกิน 100 ตัวอักษร — ควรโพสต์รายละเอียดใน /talk-to thread ก่อน แล้วใช้ maw hey แจ้งว่า \"ดู thread #X\" เท่านั้น. Pattern: 1) /talk-to <oracle> \"full details\" → get thread# 2) maw hey <oracle> \"cc: check thread #X for details\""}}'
    fi
    exit 0
  fi
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"⚠️ cc: ต้องมี structured format (Rule #8) — cc: <what> · <why/source> · <next>. ตัวอย่าง: cc: fixed RLS bug · src: Security#5 · next: deploy"}}'
  exit 0
fi

# Non-cc messages — require WHAT + WHY
HAS_WHAT=false
HAS_WHY=false

# WHAT: explicit label OR action verb at start OR "RE:" response
echo "$MSG" | grep -qiE '(WHAT:|^(fix|add|update|remov|deploy|port|send|creat|review|test|check|audit|merg|push|clos|done|start|block|stuck|need|request|RE:|STATUS|DECISION|URGENT|BUG|SECURITY))' && HAS_WHAT=true

# WHY: explicit label OR source ref OR issue number
echo "$MSG" | grep -qiE '(WHY:|src:|ref:|reason:|because|per |from |issue|#[0-9]|thread|THREAD:)' && HAS_WHY=true

# Structured · separator = both WHAT and WHY present
echo "$MSG" | grep -qE '·.*·' && HAS_WHAT=true && HAS_WHY=true

if [ "$HAS_WHAT" = false ] || [ "$HAS_WHY" = false ]; then
  MISSING=""
  [ "$HAS_WHAT" = false ] && MISSING="WHAT (ทำอะไร)"
  [ "$HAS_WHY" = false ] && { [ -n "$MISSING" ] && MISSING="$MISSING + "; MISSING="${MISSING}WHY (ทำไม/ref)"; }
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"⚠️ maw hey ต้องมี $MISSING — format: maw hey <oracle> \\\"<what> · <why/ref> · <next>\\\" หรือ \\\"WHAT: X · WHY: Y\\\"\"}}"
  exit 0
fi

# Long messages without thread ref → warn
if [ "$MSG_LEN" -ge 100 ] && ! echo "$MSG" | grep -qiE 'thread.*#[0-9]|#[0-9].*thread|THREAD:'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"⚠️ COMM PROTOCOL: ข้อความยาวเกิน 100 ตัวอักษร — ควรโพสต์รายละเอียดใน /talk-to thread ก่อน แล้วใช้ maw hey แจ้งว่า \"ดู thread #X\" เท่านั้น."}}'
fi

exit 0
