#!/bin/bash
# doc-change-check.sh — PostToolUse:Bash hook
# When oracle commits code or completes a task, remind them to update project docs.
# Checks: git commit, gh issue close, maw task done → is project doc stale?
# ref: [office] doc enforcement rule

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // ""' 2>/dev/null | head -5)

# Only trigger on: git commit, gh issue close, maw task done
IS_COMMIT=$(echo "$CMD" | grep -cE 'git commit')
IS_CLOSE=$(echo "$CMD" | grep -cE 'gh issue close')
IS_DONE=$(echo "$CMD" | grep -cE 'maw task (done|log.*Done)')

[ "$IS_COMMIT" -eq 0 ] && [ "$IS_CLOSE" -eq 0 ] && [ "$IS_DONE" -eq 0 ] && exit 0

# Detect project from CWD or command
CWD="$(pwd 2>/dev/null)"
PROJECT_SLUG=""

case "$CWD" in
  *iagencyaiafatools*) PROJECT_SLUG="fa-tools" ;;
  *fa-recruitment-quiz*|*iJourney*) PROJECT_SLUG="fa-quiz" ;;
  *Curfew-Maw-js*|*maw-js*) PROJECT_SLUG="maw-js" ;;
  *BoB-Oracle*) PROJECT_SLUG="oracle-infra" ;;
  *AIA-Oracle*|*iAgencyAIA-Oracle*) PROJECT_SLUG="aia-ops" ;;
  *Data-Oracle*) PROJECT_SLUG="customer-data-sync" ;;
  *Security-Oracle*) PROJECT_SLUG="security-compliance" ;;
  *Writer-Oracle*) PROJECT_SLUG="content-writing" ;;
  *Designer-Oracle*) PROJECT_SLUG="content-creation" ;;
  *Wingman-Oracle*) PROJECT_SLUG="daily-news" ;;
  *Admin-Oracle*) PROJECT_SLUG="oracle-infra" ;;
  *BotDev-Oracle*) PROJECT_SLUG="fa-tools" ;;
  *Cost-Oracle*) PROJECT_SLUG="cost-ops" ;;
  *LordMS*) PROJECT_SLUG="lordms" ;;
  *Echo-Oracle*|*echo-oracle*) PROJECT_SLUG="echo-federation" ;;
esac

[ -z "$PROJECT_SLUG" ] && exit 0

# Check if project doc exists
DOC_PATH="$HOME/repos/github.com/BankCurfew/oracle-fleet-guide/docs/projects/${PROJECT_SLUG}.md"
if [ ! -f "$DOC_PATH" ]; then
  echo "⚠️ DOC CHECK: Project doc missing for [$PROJECT_SLUG]. Create: oracle-fleet-guide/docs/projects/${PROJECT_SLUG}.md"
  exit 0
fi

# Check doc age — warn if older than 7 days and code just changed
DOC_AGE_DAYS=$(( ($(date +%s) - $(stat -c %Y "$DOC_PATH" 2>/dev/null || echo 0)) / 86400 ))
if [ "$DOC_AGE_DAYS" -gt 7 ]; then
  echo "⚠️ DOC STALE: [$PROJECT_SLUG] project doc is ${DOC_AGE_DAYS} days old. You just changed code — update the doc: oracle-fleet-guide/docs/projects/${PROJECT_SLUG}.md"
  exit 0
fi

# Doc exists and is fresh — just a gentle reminder
if [ "$IS_COMMIT" -gt 0 ]; then
  echo "📝 DOC REMINDER: If this commit changes API/logic/architecture for [$PROJECT_SLUG], update: oracle-fleet-guide/docs/projects/${PROJECT_SLUG}.md"
fi

exit 0
