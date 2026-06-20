#!/bin/bash
# bob-self-work-ticket.sh — PreToolUse:Bash hook (BoB-Oracle ONLY)
# Warns when BoB does significant work without establishing a ticket first.
# Uses a session marker file — cleared on session start, set when gh issue runs.
# ref: แบงค์ directive, #129

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
[ -z "$CMD" ] && exit 0

MARKER="/tmp/.bob-ticket-active"

# --- If ticket marker exists, all work is allowed ---
[ -f "$MARKER" ] && exit 0

# --- SET MARKER: when BoB creates/references a ticket ---

# gh issue create → set marker
if echo "$CMD" | grep -qE 'gh issue create'; then
  touch "$MARKER"
  exit 0
fi

# gh issue view/comment/close → ticket context exists
if echo "$CMD" | grep -qE 'gh issue (view|comment|close|edit)'; then
  touch "$MARKER"
  exit 0
fi

# maw task (add|start|log) → using project management
if echo "$CMD" | grep -qE 'maw task (add|start|log|done)'; then
  touch "$MARKER"
  exit 0
fi

# Command references issue number → ticket context
if echo "$CMD" | grep -qE '#[0-9]{1,5}'; then
  touch "$MARKER"
  exit 0
fi

# --- SKIP: commands that don't count as "work" ---

# Read-only / diagnostic (never significant work)
echo "$CMD" | grep -qE '^(cat |head |tail |ls |grep |find |wc |date |pwd|which |echo )' && exit 0

# Git read-only
echo "$CMD" | grep -qE '^git (log|status|diff|show|branch|remote|fetch)' && exit 0

# Monitoring / status
echo "$CMD" | grep -qE '^(pm2 (list|ls|show|logs)|maw (project|task|loop|peek|oracle) (ls|show|list)|curl .*/api/|tmux (list|capture|display))' && exit 0

# Heartbeat / feed
echo "$CMD" | grep -qE '(feed\.log|heartbeat)' && exit 0

# Hook/config management
echo "$CMD" | grep -qE '(settings\.json|\.claude/|hooks/|chmod )' && exit 0

# maw hey / talk-to (handled by other hooks)
echo "$CMD" | grep -qE '(maw hey |talk-to )' && exit 0

# Very short commands (<15 chars) — usually trivial
[ "${#CMD}" -lt 15 ] && exit 0

# --- SIGNIFICANT WORK DETECTED without ticket marker ---

echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"⚠️ BOB TICKET CHECK: กำลังทำงานโดยไม่มี ticket — สร้าง issue ก่อน:\n  gh issue create --repo BankCurfew/<repo> --title \"<title>\" --body \"<desc>\"\nหรือ maw task add <project> \"<title>\"\nเมื่อสร้างแล้ว warning นี้จะหายไป (Law #5: No Work Without a Ticket)"}}'

exit 0
