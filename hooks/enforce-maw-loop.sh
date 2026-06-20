#!/bin/bash
# enforce-maw-loop.sh — PreToolUse:Bash hook
# BLOCKS manual scheduling/polling — must use maw loop add instead.
# Patterns blocked: CronCreate, while+sleep polling, sleep+&&, /schedule
# Allows: sleep <5s (quick waits between commands)
# ref: แบงค์ directive, CLAUDE.md Law #7

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
[ -z "$CMD" ] && exit 0

# Skip maw hey messages — don't match patterns inside message text
echo "$CMD" | grep -qE '^maw hey ' && exit 0

# Skip echo/printf/cat commands — don't match patterns inside output text
echo "$CMD" | grep -qE '^(echo |printf |cat )' && exit 0

# --- Block CronCreate usage (should use maw loop add) ---
echo "$CMD" | grep -qiE 'CronCreate' && {
  echo '{"error":"🚫 BLOCKED: ห้ามใช้ CronCreate — ใช้ maw loop add แทน (Law #7)\n\nตัวอย่าง: maw loop add '\''{ \"id\":\"my-check\", \"schedule\":\"0 9 * * *\", \"prompt\":\"ตรวจ X\", \"enabled\":true }'\''"}'
  exit 2
}

# --- Block while+sleep polling loops ---
echo "$CMD" | grep -qE 'while.*sleep.*done|while.*do.*sleep' && {
  echo '{"error":"🚫 BLOCKED: ห้ามใช้ while+sleep polling loop — ใช้ maw loop add แทน (Law #7)\n\nmaw loop add '\''{ \"id\":\"my-poll\", \"schedule\":\"*/5 * * * *\", \"prompt\":\"check status\", \"enabled\":true }'\''"}'
  exit 2
}

# --- Block sleep+&& delayed execution (>5s) ---
if echo "$CMD" | grep -qE 'sleep [0-9]+ *&&'; then
  SLEEP_SECS=$(echo "$CMD" | grep -oE 'sleep ([0-9]+)' | head -1 | awk '{print $2}')
  if [ "${SLEEP_SECS:-0}" -gt 5 ] 2>/dev/null; then
    echo '{"error":"🚫 BLOCKED: ห้ามใช้ sleep+&& delayed execution (>5s) — ใช้ maw loop add แทน (Law #7)"}'
    exit 2
  fi
fi

# --- Block /schedule (Claude builtin) ---
echo "$CMD" | grep -qE '/schedule' && {
  echo '{"error":"🚫 BLOCKED: ห้ามใช้ /schedule — ใช้ maw loop add แทน (Law #7)\n\nmaw loop add '\''{ \"id\":\"<id>\", \"schedule\":\"<cron>\", \"prompt\":\"<task>\", \"enabled\":true }'\''"}'
  exit 2
}

exit 0
