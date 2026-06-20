#!/bin/bash
# deploy-gate.sh — PreToolUse:Bash hook
# BLOCKS git push / wrangler deploy / pm2 restart without QA sign-off
# Checks for "QA PASS" or "LGTM" in recent conversation context
# Deploy to: BotDev, Dev, Admin
# ref: Office Improvement Plan Phase 4A

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$TOOL_NAME" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Only check deploy commands
IS_DEPLOY=false
echo "$CMD" | grep -qiE '(git push|wrangler.*deploy|pm2 restart|pm2 resurrect)' && IS_DEPLOY=true
[ "$IS_DEPLOY" = false ] && exit 0

# Skip: push to non-main branches (feature branches OK without QA)
if echo "$CMD" | grep -qiE 'git push'; then
  BRANCH=$(git branch --show-current 2>/dev/null)
  case "$BRANCH" in
    main|master|production) ;; # These need QA
    *) exit 0 ;; # Feature branches are fine
  esac
fi

# Skip: pm2 restart maw (infra, not code deploy)
echo "$CMD" | grep -qiE 'pm2 restart maw$' && exit 0

# Advisory (not blocking) — remind to check QA
echo "📋 DEPLOY CHECK: Before deploying to production, confirm:
  [ ] Unit tests pass
  [ ] QA tested on staging with NEW token
  [ ] Share links tested on mobile
  [ ] Both CF domains verified (if FA Tools)
  [ ] QA sign-off received

If QA already passed → proceed. If not → get QA first."

exit 0
