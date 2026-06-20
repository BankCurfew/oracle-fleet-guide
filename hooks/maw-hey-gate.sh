#!/bin/bash
# maw-hey-gate.sh — PreToolUse hook for MCP thread tools
# ALLOW all oracles to write to threads — threads are the audit trail
# Only LOG the activity for compliance tracking
# Fixed 2026-06-20: was blocking ALL non-BoB oracles, killing the thread system
# Installed by: Dev-Oracle | Ref: Dev-Oracle#58 | Date: 2026-05-26

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)

# Only check MCP thread write tools
case "$TOOL_NAME" in
  mcp__oracle-v2__arra_thread|mcp__oracle-v2__arra_thread_update|mcp__oracle-v2__arra_handoff) ;;
  *) exit 0 ;;
esac

# Check if this is a WRITE (has message/content field) or READ
MESSAGE=$(echo "$INPUT" | jq -r '.tool_input.message // .tool_input.content // ""' 2>/dev/null)
[ -z "$MESSAGE" ] && exit 0  # READ operation — always allowed

# Identify caller oracle
CWD="$(pwd 2>/dev/null)"
if [[ "$CWD" =~ ([^/]+)-[Oo]racle ]]; then
  ORACLE_RAW="${BASH_REMATCH[1]}"
elif [ -n "${ORACLE_NAME:-}" ]; then
  ORACLE_RAW="$ORACLE_NAME"
else
  ORACLE_RAW="$(basename "$CWD" 2>/dev/null)"
fi
ORACLE_LOWER=$(echo "$ORACLE_RAW" | tr '[:upper:]' '[:lower:]' | sed 's/-oracle$//')

# Log to compliance (all writes tracked)
THREAD_ID=$(echo "$INPUT" | jq -r '.tool_input.threadId // .tool_input.thread_id // "?"' 2>/dev/null)
PREVIEW=$(echo "$MESSAGE" | head -c 60)
echo "{\"ts\":\"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\",\"oracle\":\"$ORACLE_LOWER\",\"tool\":\"direct_mcp\",\"thread_id\":\"$THREAD_ID\",\"preview\":\"$PREVIEW\",\"action\":\"allow\"}" >> ~/.oracle/comm-compliance.jsonl 2>/dev/null

# ALLOW — all oracles can use threads (this IS the audit trail)
exit 0
