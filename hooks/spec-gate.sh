#!/bin/bash
# spec-gate.sh — PreToolUse:Bash hook (BoB-Oracle ONLY)
# BLOCKS task dispatch if spec is missing required fields: WHAT, WHERE, DONE-WHEN
# Ensures BoB never sends vague specs that cause 3x rework
# ref: Office Improvement Plan Phase 1A — 22 oracles raised spec completeness as #1 pain

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Only check maw hey dispatch commands (not cc/status)
echo "$CMD" | grep -qE 'maw hey ' || exit 0

# Only BoB needs spec gate
ORACLE_LOWER=$(echo "${ORACLE_NAME:-}" | tr '[:upper:]' '[:lower:]')
case "$ORACLE_LOWER" in
  bob|bob-oracle) ;; # BoB must follow spec rules
  *) exit 0 ;; # Other oracles are free
esac

# Extract target and message
TARGET=$(echo "$CMD" | grep -oE 'maw hey [^ ]*' | awk '{print $NF}' | tr '[:upper:]' '[:lower:]')
MSG=$(echo "$CMD" | sed 's|.*maw hey [^ ]* ||' | tr -d "\"'" | head -c 1000)

# Skip: messages to bob/pulse (self-log, not dispatch)
case "$TARGET" in
  bob|bob-oracle|pulse|pulse-oracle) exit 0 ;;
esac

# Skip: short pings/acks (<15 chars)
[ "${#MSG}" -lt 15 ] && exit 0

# Skip: cc: status reports (not task dispatch)
if echo "$MSG" | grep -qiE '^cc:'; then
  if ! echo "$MSG" | grep -qiE '(TASK:|BUG:|FEATURE:|URGENT|assigned:|ทำ.*ให้|fix this|build|create|implement|deploy)'; then
    exit 0
  fi
fi

# Skip: follow-up/check/verify/remind messages
echo "$MSG" | grep -qiE '^(follow|check|verify|confirm|remind|ตามงาน|เช็ค|nudge|status|ACK)' && exit 0

# Skip: messages that reference an existing ticket (already spec'd)
echo "$MSG" | grep -qiE '#[0-9]{1,5}' && exit 0

# --- SPEC CHECK: does the message contain task dispatch language? ---
IS_TASK=false
echo "$MSG" | grep -qiE '(TASK:|BUG:|FEATURE:|URGENT|fix |build |create |implement|deploy|add |write |design )' && IS_TASK=true
echo "$MSG" | grep -qiE '(ทำ|แก้|สร้าง|เพิ่ม|ออกแบบ|เขียน|ทดสอบ)' && IS_TASK=true

[ "$IS_TASK" = false ] && exit 0

# --- TASK DETECTED: check for required spec fields ---
HAS_WHAT=false
HAS_WHERE=false
HAS_DONE=false

# WHAT: action + object (usually present if it's a task)
echo "$MSG" | grep -qiE '(WHAT:|what:)' && HAS_WHAT=true
# Also accept: clear verb + noun as implicit WHAT
echo "$MSG" | grep -qiE '(fix |build |create |add |implement|deploy|write |แก้|สร้าง|เพิ่ม)' && HAS_WHAT=true

# WHERE: file path, repo, endpoint reference
echo "$MSG" | grep -qiE '(WHERE:|where:|\.ts|\.tsx|\.js|\.md|\.sh|src/|supabase/|api-gateway|/api/|repo|file|endpoint)' && HAS_WHERE=true

# DONE-WHEN: acceptance criteria
echo "$MSG" | grep -qiE '(DONE.WHEN:|done.when:|DONE:|verify|QA|test|cc BoB|deploy BOTH|ทดสอบ|ตรวจ)' && HAS_DONE=true

# If all 3 present → pass
$HAS_WHAT && $HAS_WHERE && $HAS_DONE && exit 0

# Build missing fields message
MISSING=""
$HAS_WHAT || MISSING="${MISSING}\n  - WHAT: ทำอะไร (verb + object)"
$HAS_WHERE || MISSING="${MISSING}\n  - WHERE: ที่ไหน (file/repo/endpoint)"
$HAS_DONE || MISSING="${MISSING}\n  - DONE-WHEN: เสร็จเมื่อไหร่ (verify/QA/deploy)"

echo "{\"error\":\"⚠️ SPEC GATE: Task dispatch detected but spec incomplete.\n\nMissing:${MISSING}\n\nExample:\nmaw hey dev \\\"[fa-tools] #119 — WHAT: fix share link URL. WHERE: GapCardV2.tsx:73. DONE-WHEN: QA verify link opens iPlan correctly. cc BoB.\\\"\"}"
exit 2
