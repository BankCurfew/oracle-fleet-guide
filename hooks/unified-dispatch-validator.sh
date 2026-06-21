#!/bin/bash
# unified-dispatch-validator.sh — PreToolUse:Bash hook
# REPLACES: pulse-ticket-check + dispatch-needs-issue + validate-project-prefix (for BoB)
# Single pass: checks ALL dispatch rules at once, gives ONE error with exact fix
# ref: Designer + Wingman retro — "3-4 hooks fire per maw hey, 4 retries for 1 message"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Only check maw hey commands
echo "$CMD" | grep -qE 'maw hey ' || exit 0

# Only BoB needs unified validation — other oracles communicate freely
ORACLE_LOWER=$(echo "${ORACLE_NAME:-}" | tr '[:upper:]' '[:lower:]')
case "$ORACLE_LOWER" in
  bob|bob-oracle) ;;
  *) exit 0 ;;
esac

# Extract target and message
TARGET=$(echo "$CMD" | grep -oE 'maw hey [^ ]*' | awk '{print $NF}' | tr '[:upper:]' '[:lower:]')
MSG=$(echo "$CMD" | sed 's|.*maw hey [^ ]* ||' | tr -d "\"'" | head -c 1000)

# Skip: messages to bob/pulse (self-log, not dispatch)
case "$TARGET" in
  bob|bob-oracle|pulse|pulse-oracle) exit 0 ;;
esac

# Skip: very short pings/acks
[ "${#MSG}" -lt 10 ] && exit 0
echo "$MSG" | grep -qiE '^(ping|ACK|OK|yes|no|done|test|status|confirm|รับทราบ|ขอบคุณ)' && exit 0

# Skip: cc: status reports without task verbs
if echo "$MSG" | grep -qiE '^cc:'; then
  if ! echo "$MSG" | grep -qiE '(TASK:|BUG:|FEATURE:|URGENT|assigned:|ทำ.*ให้|fix this|build|create|implement|deploy)'; then
    exit 0
  fi
fi

# Skip: follow-up/check/verify
echo "$MSG" | grep -qiE '^(follow|check|verify|confirm|remind|ตามงาน|เช็ค|nudge|status)' && exit 0

# Skip: already has ticket ref
echo "$MSG" | grep -qiE '#[0-9]{1,5}' && exit 0

# --- TASK DETECTED: check ALL rules in one pass ---
IS_TASK=false
echo "$MSG" | grep -qiE '(TASK:|BUG:|FEATURE:|URGENT|fix |build |create |implement|deploy|add |write |design |ทำ|แก้|สร้าง|เพิ่ม)' && IS_TASK=true
[ "$IS_TASK" = false ] && exit 0

# Collect ALL violations
VIOLATIONS=""

# Check 1: [project] prefix
HAS_PREFIX=false
echo "$MSG" | grep -qE '^\[' && HAS_PREFIX=true
$HAS_PREFIX || VIOLATIONS="${VIOLATIONS}\n  ❌ Missing [project] prefix → add [fa-tools] or [office]"

# Check 2: #ticket reference
HAS_TICKET=false
echo "$MSG" | grep -qiE '#[0-9]{1,5}' && HAS_TICKET=true
$HAS_TICKET || VIOLATIONS="${VIOLATIONS}\n  ❌ Missing #ticket → create: gh issue create --repo BankCurfew/<repo> --title \"...\""

# Check 3: WHAT/WHERE/DONE-WHEN (spec gate)
HAS_WHAT=false; HAS_WHERE=false; HAS_DONE=false
echo "$MSG" | grep -qiE '(WHAT:|fix |build |create |add |implement|deploy|write |แก้|สร้าง|เพิ่ม)' && HAS_WHAT=true
echo "$MSG" | grep -qiE '(WHERE:|\.ts|\.tsx|\.js|\.md|\.sh|src/|supabase/|api-gateway|/api/|repo|file|endpoint)' && HAS_WHERE=true
echo "$MSG" | grep -qiE '(DONE.WHEN:|done|verify|QA|test|cc BoB|deploy|ทดสอบ|ตรวจ)' && HAS_DONE=true
$HAS_WHAT || VIOLATIONS="${VIOLATIONS}\n  ❌ Missing WHAT → what to do (verb + object)"
$HAS_WHERE || VIOLATIONS="${VIOLATIONS}\n  ❌ Missing WHERE → which file/repo/endpoint"
$HAS_DONE || VIOLATIONS="${VIOLATIONS}\n  ❌ Missing DONE-WHEN → how to verify (QA/deploy/cc BoB)"

# No violations → pass
[ -z "$VIOLATIONS" ] && exit 0

# Show ALL violations at once with fix example
echo "{\"error\":\"⚠️ DISPATCH VALIDATOR: Task dispatch missing requirements:${VIOLATIONS}\n\n✅ Correct format:\nmaw hey dev \\\"[fa-tools] #119 — WHAT: fix share link. WHERE: GapCardV2.tsx:73. DONE-WHEN: QA verify + deploy BOTH. cc BoB.\\\"\"}"
exit 2
