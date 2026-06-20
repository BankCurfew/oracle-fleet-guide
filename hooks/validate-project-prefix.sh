#!/bin/bash
# validate-project-prefix.sh — PreToolUse:Bash hook (BLOCKING)
# BLOCKS maw hey without [project] #ticket prefix.
# exit 2 = block tool execution.
# ref: maw-js#81, แบงค์ directive #135

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Only check maw hey commands
echo "$CMD" | grep -qE 'maw hey ' || exit 0

# Extract message content
MSG=$(echo "$CMD" | sed 's|.*maw hey [^ ]* ||' | tr -d "\"'" | head -c 500)
[ -z "$MSG" ] && exit 0

# Allow very short pings/acks (<10 chars)
[ "${#MSG}" -lt 10 ] && exit 0

# Allow heartbeat/feed logging
echo "$MSG" | grep -qiE '^(ping|ACK|OK|yes|no|done|test|status|confirm|รับทราบ)' && exit 0

# --- Check for [project] prefix ---
PREFIX=$(echo "$MSG" | grep -oE '\[([a-zA-Z0-9_-]+)\]' | head -1 | tr -d '[]' | tr '[:upper:]' '[:lower:]')

if [ -z "$PREFIX" ]; then
  echo '{"error":"🚫 BLOCKED: ต้องมี [project] #ticket prefix ก่อนส่ง message.\n\n1. maw project create <slug> \"<name>\" \"<desc>\"\n2. gh issue create --repo BankCurfew/<repo> --title \"<title>\"\n3. maw project add <slug> #<issue>\n4. แล้วส่ง: maw hey <oracle> \"cc: [project] #ticket — message\""}'
  exit 2
fi

# --- [office] = catch-all, no #ticket needed (แบงค์ approved option 1) ---
if [ "$PREFIX" = "office" ]; then
  exit 0
fi

# --- Check #ticket present ---
TICKET=$(echo "$MSG" | grep -oE '#[0-9]{1,5}' | head -1 | tr -d '#')
if [ -z "$TICKET" ]; then
  echo "{\"error\":\"🚫 BLOCKED: มี [$PREFIX] แต่ไม่มี #ticket number.\n\nใช้ [office] ถ้ายังไม่มี ticket หรือ:\n1. gh issue create --repo BankCurfew/<repo> --title \\\"<title>\\\"\n2. แล้วส่ง: maw hey <oracle> \\\"cc: [$PREFIX] #<number> — message\\\"\"}"
  exit 2
fi

# --- Validate project exists ---
CACHE="/tmp/.maw-project-ids"
CACHE_AGE=300
if [ -f "$CACHE" ] && [ $(($(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0))) -lt $CACHE_AGE ]; then
  PROJECTS=$(cat "$CACHE")
else
  PROJECTS=$(maw project ls 2>/dev/null | grep -oE '\([a-z0-9-]+\)' | tr -d '()' | sort)
  [ -n "$PROJECTS" ] && echo "$PROJECTS" > "$CACHE"
fi

if [ -n "$PROJECTS" ] && ! echo "$PROJECTS" | grep -qxF "$PREFIX"; then
  case "$PREFIX" in
    bob|pulse|dev|qa|hr|admin|designer|writer|researcher|security|editor|doccon|creator|fe|pa|fa|aia|data|botdev|cost) ;; # oracle names OK
    proxy|poster|browser|office) ;; # known aliases
    *) echo "{\"error\":\"🚫 BLOCKED: project [$PREFIX] ไม่มีใน maw project ls.\n\nsร้างก่อน: maw project create $PREFIX \\\"<name>\\\" \\\"<desc>\\\"\"}"
       exit 2 ;;
  esac
fi

exit 0
