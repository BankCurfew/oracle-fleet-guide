#!/bin/bash
# gh-rate-guard.sh — Source this before gh commands to avoid rate limit exhaustion.
# Usage: source ~/.oracle/hooks/gh-rate-guard.sh && gh_guard && gh issue create ...
# Or:    gh_check_rate  (just check, print status, no block)
#
# Caches rate limit for 60s to avoid burning API calls on the check itself.
# Uses REST API (core) for the check — separate 5000 limit from GraphQL.
# ref: [office] แบงค์ rate limit order 2026-06-20

GH_RATE_CACHE="/tmp/.gh-rate-limit"
GH_RATE_CACHE_AGE=60
GH_RATE_MIN_GRAPHQL=100
GH_RATE_MIN_REST=200

# Get cached or fresh rate limit (uses REST endpoint, not GraphQL)
_gh_rate_fetch() {
  local NOW
  NOW=$(date +%s)
  if [ -f "$GH_RATE_CACHE" ] && [ $((NOW - $(stat -c %Y "$GH_RATE_CACHE" 2>/dev/null || echo 0))) -lt $GH_RATE_CACHE_AGE ]; then
    cat "$GH_RATE_CACHE"
    return
  fi
  local DATA
  DATA=$(gh api rate_limit --jq '{gql_remaining: .resources.graphql.remaining, gql_reset: .resources.graphql.reset, rest_remaining: .resources.core.remaining, rest_reset: .resources.core.reset}' 2>/dev/null || echo '{}')
  [ -n "$DATA" ] && [ "$DATA" != '{}' ] && echo "$DATA" > "$GH_RATE_CACHE"
  echo "$DATA"
}

# Check and print status (non-blocking)
gh_check_rate() {
  local DATA GQL_REM REST_REM GQL_RESET
  DATA=$(_gh_rate_fetch)
  GQL_REM=$(echo "$DATA" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('gql_remaining','?'))" 2>/dev/null || echo "?")
  REST_REM=$(echo "$DATA" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('rest_remaining','?'))" 2>/dev/null || echo "?")
  GQL_RESET=$(echo "$DATA" | python3 -c "import sys,json; import datetime; r=json.loads(sys.stdin.read()).get('gql_reset',0); print(datetime.datetime.fromtimestamp(r).strftime('%H:%M') if r else '?')" 2>/dev/null || echo "?")
  echo "GH Rate: GraphQL=$GQL_REM/5000 REST=$REST_REM/5000 (GQL resets $GQL_RESET)"
}

# Guard — returns 0 if OK, 1 if rate limited (blocks the caller)
gh_guard() {
  local DATA GQL_REM REST_REM
  DATA=$(_gh_rate_fetch)
  GQL_REM=$(echo "$DATA" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('gql_remaining',5000))" 2>/dev/null || echo "5000")
  REST_REM=$(echo "$DATA" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('rest_remaining',5000))" 2>/dev/null || echo "5000")

  if [ "$GQL_REM" -lt "$GH_RATE_MIN_GRAPHQL" ] 2>/dev/null; then
    local GQL_RESET
    GQL_RESET=$(echo "$DATA" | python3 -c "import sys,json,datetime; r=json.loads(sys.stdin.read()).get('gql_reset',0); print(datetime.datetime.fromtimestamp(r).strftime('%H:%M'))" 2>/dev/null || echo "?")
    echo "⚠️ GH GraphQL rate limit LOW: ${GQL_REM}/5000 (resets ${GQL_RESET}). Delay or use REST API." >&2
    return 1
  fi
  return 0
}

# Guard specifically for GraphQL-heavy commands (gh issue create, gh pr create)
gh_guard_strict() {
  local DATA GQL_REM
  DATA=$(_gh_rate_fetch)
  GQL_REM=$(echo "$DATA" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('gql_remaining',5000))" 2>/dev/null || echo "5000")

  if [ "$GQL_REM" -lt 500 ] 2>/dev/null; then
    local GQL_RESET
    GQL_RESET=$(echo "$DATA" | python3 -c "import sys,json,datetime; r=json.loads(sys.stdin.read()).get('gql_reset',0); print(datetime.datetime.fromtimestamp(r).strftime('%H:%M'))" 2>/dev/null || echo "?")
    echo "⚠️ GH GraphQL rate limit at ${GQL_REM}/5000 — batch operations should wait until ${GQL_RESET}." >&2
    return 1
  fi
  return 0
}
