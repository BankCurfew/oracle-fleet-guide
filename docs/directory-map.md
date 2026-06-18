# Directory Map — Full Path Reference

## Home Directory Structure

```
/home/<user>/
├── .bun/bin/bun                          # Bun binary
├── .local/bin/
│   ├── bun-linux → ~/.bun/bin/bun        # CRITICAL symlink (MCP depends on this)
│   ├── check-clipboard-image             # Hook: clipboard image detection
│   ├── check-cc-bob-on-stop              # Hook: ensure cc bob before stop
│   └── check-talk-to-cc                  # Hook: talk-to + cc tracking
├── .nvm/versions/node/v24.*/             # Node.js via nvm
├── .claude/
│   ├── CLAUDE.md                         # Global oracle rules (12 Golden Rules)
│   ├── RTK.md                            # RTK usage guide
│   ├── settings.json                     # Global Claude settings (hooks, model)
│   ├── settings.local.json               # Local overrides
│   ├── hooks/
│   │   └── rtk-rewrite.sh               # RTK token savings hook
│   ├── skills/                           # Shared skills
│   │   ├── recap/                        # /recap skill
│   │   ├── talk-to/                      # /talk-to skill
│   │   ├── dig/                          # /dig skill
│   │   └── ...
│   └── projects/                         # Claude project memory (auto-generated)
├── .config/maw/
│   └── maw.config.json                   # Fleet configuration (XDG location)
├── .oracle/
│   ├── SYSTEM_PLAYBOOK.md                # Boot protocol for all oracles
│   ├── cost-optimization.md              # Token cost optimization notes
│   ├── directory/INDEX.md                # Central directory of repos
│   ├── security/                         # Vault credential .env files
│   │   ├── supabase.env
│   │   ├── discord.env
│   │   ├── line.env
│   │   └── ...
│   ├── hooks/                            # Shared oracle hooks
│   │   ├── pulse-ticket-check.sh
│   │   ├── enforce-maw-hey.sh
│   │   ├── feed-activity.sh
│   │   ├── force-rrr-at-80.sh
│   │   ├── maw-hey-gate.sh
│   │   ├── pre-close-psi-check.sh
│   │   ├── on-task-complete.sh
│   │   ├── on-subagent-stop.sh
│   │   └── pulse-auto-cc.sh
│   ├── tools/
│   │   ├── pw-cli.sh                    # Playwright CLI wrapper
│   │   └── PLAYWRIGHT_CLI.md
│   ├── feed.log                          # Activity feed (dashboard reads this)
│   └── inbox/pending/                    # Items waiting for แบงค์ approval
├── .maw/inbox/                           # Incoming maw messages (images, files)
├── .pm2/                                 # PM2 process data
├── .cache/ms-playwright/                 # Playwright browser data
│   ├── chromium-*/                       # Shared chromium install
│   └── mcp-chrome-<oracle>/             # Per-oracle browser profile
└── repos/github.com/
    ├── BankCurfew/                       # All org repos (64+)
    │   ├── BoB-Oracle/                   # BoB's repo
    │   ├── Dev-Oracle/                   # Dev's repo
    │   ├── maw-js/                       # Maw CLI + server
    │   │   ├── ecosystem.config.cjs      # PM2 config
    │   │   ├── maw.config.json           # Fleet config (repo copy)
    │   │   ├── rooms.json                # Dashboard room layout
    │   │   └── src/
    │   │       ├── find-window.ts        # Session routing (routing fix here)
    │   │       ├── routing.ts            # Target resolution
    │   │       └── commands/             # CLI commands
    │   ├── office-v2/                    # Dashboard frontend
    │   ├── oracle-dashboard/             # Dashboard config
    │   ├── oracle-fleet-guide/           # THIS GUIDE
    │   └── ...
    └── Soul-Brews-Studio/
        └── arra-oracle-v3/               # Oracle MCP server (the brain)
            └── src/index.ts              # MCP entry point
```

## Oracle Repo Structure (each oracle)

```
<Oracle-Name>/
├── CLAUDE.md                             # Oracle identity, rules, behavior
├── CLAUDE_*.md                           # Extended rules (safety, workflows, etc.)
├── .claude/
│   └── settings.json                     # Per-oracle hooks and settings
├── .mcp.json                             # MCP server config (oracle-v2, playwright)
├── ψ/                                    # Oracle brain
│   ├── inbox/
│   │   ├── handoff/                      # Session handoff files
│   │   ├── focus.md                      # Current focus
│   │   └── tracks/                       # Work tracks
│   ├── memory/
│   │   ├── learnings/                    # Lessons learned
│   │   └── retrospectives/              # Session retros
│   ├── writing/                          # Content drafts
│   ├── lab/                              # Experiments, tools
│   └── active/                           # Ephemeral working files
└── ...                                   # Oracle-specific code/content
```

## Key Config Files to Update During Migration

| File | Location | What to Change |
|------|----------|----------------|
| maw.config.json | `~/.config/maw/` | `node`, all paths |
| .mcp.json | Each oracle repo root | All `/home/<old>` → `/home/<new>` |
| settings.json | `~/.claude/` + each oracle's `.claude/` | Hook paths |
| ecosystem.config.cjs | maw-js repo | Working directory paths |
| rooms.json | maw-js repo | Usually no change needed |
| .env files | `~/.oracle/security/` | Usually no change needed |
| feed.log paths | `~/.oracle/hooks/` | Log file paths |

## Quick Path Fix Command

```bash
OLD="/home/olduser"
NEW="/home/newuser"

# Fix all .mcp.json files
find ~/repos/github.com/BankCurfew -name ".mcp.json" -exec sed -i "s|$OLD|$NEW|g" {} \;

# Fix all settings.json files
find ~/repos/github.com/BankCurfew -path "*/.claude/settings.json" -exec sed -i "s|$OLD|$NEW|g" {} \;

# Fix maw.config.json
sed -i "s|$OLD|$NEW|g" ~/.config/maw/maw.config.json

# Fix maw-js source
find ~/repos/github.com/BankCurfew/maw-js/src -name "*.ts" -exec sed -i "s|$OLD|$NEW|g" {} \;

# Fix office-v2 source
find ~/repos/github.com/BankCurfew/office-v2/src -name "*.ts" -exec sed -i "s|$OLD|$NEW|g" {} \;

# Verify no old paths remain in runtime code
grep -r "$OLD" ~/repos/github.com/BankCurfew/maw-js/src/ 2>/dev/null
grep -r "$OLD" ~/repos/github.com/BankCurfew/office-v2/src/ 2>/dev/null
```
