# 03 — Configure Fleet

## maw.config.json

Location: `~/.config/maw/maw.config.json`

```json
{
  "node": "<machine-name>",
  "host": "local",
  "port": 3456,
  "ghqRoot": "/home/<user>/repos/github.com",
  "oracleUrl": "http://localhost:47779",
  "federationToken": "<generate-new-token>",
  "namedPeers": [],
  "env": {},
  "preWake": [
    "pm2 resurrect 2>/dev/null || pm2 start ~/repos/github.com/BankCurfew/maw-js/ecosystem.config.cjs",
    "pgrep -f cloudflared || tmux new-session -d -s cloudflared 'cloudflared tunnel run <tunnel>'"
  ],
  "commands": {
    "default": "claude --dangerously-skip-permissions --model \"claude-opus-4-6[1m]\"",
    "*-oracle": "claude --dangerously-skip-permissions --model \"claude-opus-4-6[1m]\"",
    "*-Oracle": "claude --dangerously-skip-permissions --model \"claude-opus-4-6[1m]\""
  },
  "sessions": {},
  "agents": {},
  "rooms": {
    "command": ["bob", "pulse", "shell"],
    "engineering": ["dev", "designer", "qa", "fe"],
    "studio": ["hr", "writer", "researcher", "editor", "doccon"],
    "data-lab": ["data"],
    "aia-office": ["aia", "admin", "botdev", "iagencyaia", "wingman", "recruiter"],
    "academy": ["creator", "videoeditor"],
    "security": ["security"],
    "executive": ["pa", "cost", "fa", "trader", "scalper"],
    "federation": ["echo", "nobi"]
  }
}
```

**CRITICAL**: Update ALL paths from old machine to new machine. `node` field must match the new hostname.

## MCP Config (.mcp.json)

Every oracle repo needs a `.mcp.json` at its root. Template:

```json
{
  "mcpServers": {
    "oracle-v2": {
      "command": "/home/<user>/.local/bin/bun-linux",
      "args": [
        "/home/<user>/repos/github.com/Soul-Brews-Studio/arra-oracle-v3/src/index.ts"
      ],
      "env": {
        "ORACLE_DATA_DIR": "/home/<user>/.oracle",
        "ORACLE_REPO_ROOT": "/home/<user>/repos/github.com/BankCurfew/<Oracle-Repo>"
      }
    },
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--user-data-dir",
        "/home/<user>/.cache/ms-playwright/mcp-chrome-<oracle>"
      ]
    }
  }
}
```

### Batch update all MCP configs

```bash
OLD_HOME="/home/olduser"
NEW_HOME="/home/newuser"

for dir in ~/repos/github.com/BankCurfew/*-Oracle; do
  mcp="$dir/.mcp.json"
  [ -f "$mcp" ] || continue
  sed -i "s|$OLD_HOME|$NEW_HOME|g" "$mcp"
  echo "Fixed: $(basename $dir)"
done
```

### Common MCP pitfalls

- **gmail-mcp**: Requires per-machine setup with OAuth credentials. Remove from configs if not set up.
- **elevenlabs**: Requires `uvx` installed. Remove if not available.
- **supabase**: HTTP type, works anywhere — no path issues.
- **$HOME in paths**: JSON doesn't expand env vars. Always use absolute paths.

## rooms.json (Dashboard)

Location: `~/repos/github.com/BankCurfew/maw-js/rooms.json`

This controls the dashboard room layout. See the repo for the full structure. Key: member names must match the tmux window names with `-Oracle` suffix (e.g., `Dev-Oracle`).

## Vault Setup

```bash
mkdir -p ~/.oracle/security

# Copy credential .env files from backup
# These contain API keys for: Supabase, Discord, LINE, etc.
# GPG keyring needed for vault.enc decryption

# Verify
ls ~/.oracle/security/*.env
```

## Claude User Settings

Location: `~/.claude/settings.json`

Contains hooks (rtk-rewrite, pulse-ticket-check, feed-activity, etc.) and model config. Copy from backup or previous machine.

## Hooks

Location: `~/.oracle/hooks/` and `~/.claude/hooks/`

Key hooks:
- `rtk-rewrite.sh` — token savings
- `pulse-ticket-check.sh` — blocks dispatch without ticket
- `enforce-maw-hey.sh` — ensures maw hey usage
- `feed-activity.sh` — logs activity to feed
- `force-rrr-at-80.sh` — auto retrospective at 80% context

## Skills

Location: `~/.claude/skills/`

Core skills: recap, talk-to, dig, rrr, forward, standup, learn, trace
