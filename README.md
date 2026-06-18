# Oracle Fleet Migration & Operations Guide

> When the machine dies, this guide brings the fleet back.

## What This Is

Step-by-step guide for migrating the BankCurfew Oracle fleet (28 AI agents) to a new machine. Written from the 2026-06-17 HQ→Curfew migration where vuttiserver died and the entire fleet had to be rebuilt.

## Quick Start (Emergency Migration)

```bash
# 1. Clone this guide first
ghq get BankCurfew/oracle-fleet-guide

# 2. Follow the guides in order:
cat docs/01-machine-setup.md      # Install dependencies
cat docs/02-clone-repos.md        # Clone all 64 repos
cat docs/03-configure-fleet.md    # maw.config, rooms.json, MCP
cat docs/04-start-services.md     # PM2, MQTT, cloudflared
cat docs/05-boot-oracles.md       # tmux sessions, Claude startup
cat docs/06-sync-state.md         # GitHub issues → board, briefings
cat docs/07-verify.md             # Test routing, comms, MCP
```

## Directory Structure

```
docs/
├── 01-machine-setup.md       # OS, Node, Bun, tools
├── 02-clone-repos.md         # All repos to clone
├── 03-configure-fleet.md     # maw.config, MCP, rooms.json
├── 04-start-services.md      # PM2, MQTT, cloudflared
├── 05-boot-oracles.md        # tmux sessions, Claude startup
├── 06-sync-state.md          # Board repopulation, briefings
├── 07-verify.md              # Routing, comms, MCP verification
├── lessons-learned.md        # What we lost and how to prevent it
├── directory-map.md          # Full path reference
└── fleet-roster.md           # All oracles, roles, repos, rooms
```

## The Fleet (28 Oracles)

| Oracle | Role | Repo | Room |
|--------|------|------|------|
| BoB | Apex Observer, Manager | BoB-Oracle | command |
| Pulse | Task Tracker | pulse-oracle | command |
| Dev | Lead Engineer | Dev-Oracle | engineering |
| Designer | Creative Director | Designer-Oracle | engineering |
| QA | Quality Director | QA-Oracle | engineering |
| FE | Frontend Engineer | FE-Oracle | engineering |
| HR | Head of People Ops | HR-Oracle | studio |
| Writer | Content Director | Writer-Oracle | studio |
| Researcher | Chief Research Officer | Researcher-Oracle | studio |
| Editor | Chief Editor | Editor-Oracle | studio |
| DocCon | Quality Conductor | DocCon-Oracle | studio |
| Data | Data Engineer | Data-Oracle | data-lab |
| AIA | AIA Operations | AIA-Oracle | aia-office |
| Admin | Head of DevOps | Admin-Oracle | aia-office |
| BotDev | Bot Developer | BotDev-Oracle | aia-office |
| iAgencyAIA | Insurance Portal | iAgencyAIA-Oracle | aia-office |
| Wingman | News & Social | Wingman-Oracle | aia-office |
| Recruiter | FA Recruitment | Recruiter-Oracle | aia-office |
| Creator | Academy Lead | Creator-Oracle | academy |
| VideoEditor | Video Content | VideoEditor-Oracle | academy |
| Security | CISO | Security-Oracle | security |
| PA | Personal Assistant | PA-Oracle | executive |
| Cost | Cost Tracker | Cost-Oracle | executive |
| FA | FA Advisory | FA-Oracle | executive |
| Trader | Trading Ops | Trader-Oracle | executive |
| Scalper | Scalping Strategies | Scalper-Oracle | executive |
| Echo | Federation Lead | Echo-Oracle | federation |
| Nobi | Remote (dreams node) | — | federation |

## Lessons from 2026-06-17 Migration

See [docs/lessons-learned.md](docs/lessons-learned.md) for full details. Key takeaways:

1. **ALWAYS commit pulse-cli and tools to git** — local-only code is lost forever
2. **maw project task data is local** — export/backup regularly
3. **GPG keyring needs backup** — without it, vault.enc is useless
4. **Test routing after any tmux session changes** — fuzzy matching causes misroutes
5. **gmail-mcp must be set up per machine** — it's not portable

## Contributing

This guide is maintained by BoB-Oracle. When you discover something that should be documented during a migration, add it here and commit.
