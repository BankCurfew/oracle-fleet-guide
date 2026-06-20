#!/bin/bash
# dispatch-needs-issue.sh — PreToolUse:Bash hook
# BLOCKS task dispatch via maw hey / /talk-to unless GitHub issue created first.
# Parses CONTENT — cc: prefix does NOT bypass if content is task assignment.
# ref: BoB-Oracle#124

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Only check dispatch commands (maw hey / talk-to)
echo "$CMD" | grep -qE '(maw hey|/talk-to|talk-to) ' || exit 0

# Only BoB needs issue check — other oracles communicate freely (peer-to-peer)
ORACLE_LOWER=$(echo "${ORACLE_NAME:-}" | tr '[:upper:]' '[:lower:]')
case "$ORACLE_LOWER" in
  bob|bob-oracle) ;; # BoB must have issues
  *) exit 0 ;; # All other oracles can communicate directly
esac

# Extract message content (after oracle name)
MSG=$(echo "$CMD" | sed 's|.*maw hey [^ ]* ||; s|.*talk-to [^ ]* ||' | tr -d "\"'" | head -c 500)

# --- ALLOW LIST: messages that are never task dispatches ---

# Pure status/ping/ack (no task content possible)
echo "$MSG" | grep -qiE '^(ping|ACK|OK|yes|no|done|test|status|confirm|รับทราบ|ขอบคุณ|สวัสดี)' && exit 0

# Thread references (detail is in the thread, not the message)
echo "$MSG" | grep -qiE 'thread.*#[0-9]|check thread|ดู thread' && exit 0

# Pure report/status cc: (has structured separators, no task verbs)
if echo "$MSG" | grep -qiE '^cc:'; then
  # Check if cc: content has task assignment language
  if ! echo "$MSG" | grep -qiE '(TASK:|BUG:|FEATURE:|URGENT.*fix|assigned:|assign to|ทำ.*ให้|สั่ง.*ทำ|do this|fix this|build this|create this|deploy this|implement|ต้องทำ|ให้.*ทำ)'; then
    # Pure cc: without task language → allow (status report)
    exit 0
  fi
  # cc: WITH task language → fall through to check
fi

# --- TASK DETECTION: does the message contain task assignment language? ---

IS_TASK=false

# Explicit task markers (anywhere in message, not just start)
echo "$MSG" | grep -qiE '(TASK:|BUG:|FEATURE:|URGENT:|P0[ :]|P1[ :]|HIGH:)' && IS_TASK=true

# Task assignment verbs (directed at another oracle)
echo "$MSG" | grep -qiE '(ทำ.*ให้|ให้.*ทำ|ช่วย.*ทำ|ช่วย.*ให้|สั่ง.*ทำ|ต้องทำ|assigned:|assign to|do this|fix this|build this|create this|implement|deploy this|write this|review this|test this)' && IS_TASK=true

# Dispatch patterns
echo "$MSG" | grep -qiE '(NEW TASK|NEW.*from|work on|fix.*issue|deploy.*now|start.*on)' && IS_TASK=true

# Not a task → allow
[ "$IS_TASK" = false ] && exit 0

# --- TASK DETECTED: check if GitHub issue was created recently ---

# Check if message already references a GitHub issue
echo "$MSG" | grep -qiE '(#[0-9]{1,5}|issue.*#|ref:.*#|BankCurfew/[^ ]*#)' && exit 0

# Check recent bash history for gh issue create (last 5 commands in this session)
# Claude Code doesn't have persistent history — check if gh issue was in recent tool calls
# The hook can only check the current command, not history. So we block and instruct.

echo '{"error":"⚠️ DISPATCH BLOCKED: task detected but no GitHub issue ref found. Create issue first:\n\n  gh issue create --repo BankCurfew/<repo> --title \"<title>\" --body \"<description>\"\n\nThen include #<issue-number> in your maw hey message.\n\nIf this is NOT a task dispatch (just cc/status/question), rephrase without task verbs (TASK:/BUG:/fix this/ทำให้)."}'
exit 2
