# 07 — Verification Checklist

## Routing Test

```bash
# Test maw hey routes to correct session for ALL oracles
for oracle in dev qa writer hr botdev researcher security creator echo \
  fa fe pa recruiter cost aia editor admin designer data doccon \
  wingman trader pulse scalper iagencyaia videoeditor; do

  result=$(maw hey $oracle "cc: routing test" 2>&1)
  if echo "$result" | grep -q "sent"; then
    target=$(echo "$result" | grep -oP '→ \K\S+')
    echo "✅ $oracle → $target"
  else
    echo "❌ $oracle: $(echo $result | head -c 60)"
  fi
done
```

### Known Routing Bugs (fixed in 2026-06-18)

The `find-window.ts` in maw-js uses substring matching for tmux sessions. Without the fix:
- `dev` matches `botdev` (substring)
- `aia` matches `iagencyaia` (substring)
- `editor` matches `videoeditor` (substring)
- `pa` matches `0-overview` (substring)

**Fix**: `find-window.ts` now tries strict session match (exact + oracle-name) BEFORE substring matching. If routing is wrong after migration, check this file.

## MCP Verification

```bash
# Check each oracle's MCP config for broken paths
for dir in ~/repos/github.com/BankCurfew/*-Oracle; do
  name=$(basename "$dir")
  mcp="$dir/.mcp.json"
  [ -f "$mcp" ] || continue

  errors=""
  # Check all paths in MCP config
  for path in $(python3 -c "
import json
d = json.load(open('$mcp'))
for s in d.get('mcpServers', {}).values():
    for a in s.get('args', []):
        if '/' in a: print(a)
    cmd = s.get('command', '')
    if '/' in cmd: print(cmd)
" 2>/dev/null); do
    [ -f "$path" ] || errors="$errors $path"
  done

  if [ -n "$errors" ]; then
    echo "❌ $name: broken paths:$errors"
  else
    echo "✅ $name"
  fi
done
```

## Thread Communication Test

```bash
# Test /talk-to creates threads successfully
# From BoB's session, use arra_thread MCP tool to create test threads
# Then verify oracles can read them
```

## Service Health

```bash
# PM2
pm2 list | grep "online" | wc -l  # Should be 6

# MQTT
mosquitto_pub -t test -m "ping" && echo "MQTT: OK"

# maw server
curl -s http://localhost:3456/health && echo "maw: OK"

# arra-api
curl -s http://localhost:47779/health && echo "arra: OK"
```

## Full Fleet Status

```bash
# All oracles running Claude
for s in $(tmux list-sessions -F '#{session_name}' | grep -v "cloudflared\|0-overview\|01-bob\|shell"); do
  line=$(tmux capture-pane -t "$s:0" -p 2>/dev/null | tail -1)
  if echo "$line" | grep -q "bypass permissions"; then
    echo "✅ $s"
  else
    echo "❌ $s"
  fi
done

# All oracles in correct repos
for s in $(tmux list-sessions -F '#{session_name}' | grep -v "cloudflared\|0-overview\|01-bob\|shell"); do
  cwd=$(tmux display-message -t "$s:0" -p '#{pane_current_path}' 2>/dev/null)
  echo "$s → $cwd"
done

# All oracles have ψ/ memories
for dir in ~/repos/github.com/BankCurfew/*-Oracle; do
  name=$(basename "$dir")
  count=$(find "$dir/ψ" -name '*.md' 2>/dev/null | wc -l)
  echo "$name: $count memory files"
done
```
