# CURFEW Migration

## Overview
- **What it does**: Full fleet migration from the old HQ server (mbank, which died 2026-06-17) to the new curfew server (WSL2 on Windows). Covers all 27+ oracles, PM2 services, hooks, configs, paths, and infrastructure.
- **Who uses it**: Entire Oracle fleet (27+ oracles), BoB (orchestrator), Admin (infrastructure), Echo (local coordinator)
- **Where it runs**: curfew server (WSL2, Linux 6.6.87.2-microsoft-standard-WSL2)

## Architecture

### Migration Scope

| Component | Count | Status |
|-----------|-------|--------|
| Oracle repos | 27+ | Migrated via ghq |
| tmux sessions | 29 | All online |
| PM2 services | 6 | All online (maw, maw-bob, maw-syslog, arra-api, aia-line, bob-discord) |
| Hooks | 28+ | Migrated to ~/.oracle/hooks/ |
| Config files | ~50 | Paths updated /home/mbank → /home/curfew |
| Fleet configs | 28 | fleet/*.json updated |
| MCP servers | 3+ | oracle-v2, playwright, firecrawl running |

### Migration Timeline

| Date | Event |
|------|-------|
| 2026-06-17 | HQ server (mbank) died — disk failure |
| 2026-06-17 | Emergency: clone all repos to curfew via ghq |
| 2026-06-18 | Day 1: Path migration (/home/mbank → /home/curfew), PM2 services restored |
| 2026-06-19 | Day 2: Fleet validation, hook verification, oracle wake-all |
| 2026-06-20 | Day 3: Full fleet operational, all oracles online, standards enforced |

## Code Structure

No dedicated repo — migration tracked in BoB-Oracle and individual oracle repos:

```
Key files touched during migration:
├── ~/.oracle/                    # Central oracle infrastructure
│   ├── hooks/                    # 28+ enforcement hooks
│   ├── feed.log                  # Central event log
│   ├── maw-log.jsonl             # Communication audit
│   ├── directory/INDEX.md        # Central directory
│   ├── SYSTEM_PLAYBOOK.md        # Master loop registry
│   └── docs/                     # SOPs (new location)
├── ~/repos/github.com/BankCurfew/
│   ├── Curfew-Maw-js/            # maw-js (fleet CLI)
│   │   ├── maw.config.json       # Federation config (updated IPs)
│   │   ├── fleet/*.json          # Per-oracle configs
│   │   └── loops.json            # Loop definitions
│   ├── BoB-Oracle/               # BoB (orchestrator)
│   ├── [27+ oracle repos]/       # Each oracle's repo
│   └── oracle-fleet-guide/       # Migration docs + runbook
```

## Business Logic

### Migration Procedure (7 Steps)

1. **Machine Setup** — WSL2, packages, fonts, Bun, Node, Python
2. **Clone Repos** — `ghq get BankCurfew/*` (40+ repos)
3. **Configure Fleet** — Update maw.config.json, fleet/*.json, generate configs
4. **Start Services** — PM2 start (maw, arra-api, aia-line, bob-discord)
5. **Boot Oracles** — `maw wake all` (29 tmux sessions)
6. **Sync State** — Each oracle runs /recap, reads handoff, continues work
7. **Verify** — All services online, hooks working, feeds logging, dashboard accessible

### Path Migration
All config files contained hardcoded `/home/mbank` paths. Migration required:
- `sed -i 's|/home/mbank|/home/curfew|g'` across settings.json, .mcp.json, hooks
- Manual verification of each oracle's CLAUDE.md for stale paths
- Some paths in handoff docs left as cosmetic (not functional)

### Verification Checklist
- [ ] PM2 services all online (`pm2 list`)
- [ ] maw-js responds (`curl localhost:3456/api/config`)
- [ ] arra-oracle-v3 running (6 bun workers)
- [ ] All 29 tmux sessions alive (`maw oracle ls`)
- [ ] Feed.log recording events
- [ ] Dashboard accessible (curfew.vuttipipat.com)
- [ ] Hooks executing (PreToolUse, PostToolUse)
- [ ] Git push works from all repos
- [ ] Gmail MCP connected
- [ ] Playwright browser available

## API Endpoints
None — migration is an operational project, not a service.

## Deployment
The migration itself IS the deployment — moving the entire fleet from mbank to curfew.

### Post-Migration Infrastructure
- **Server**: curfew (WSL2 on Windows)
- **Network**: Tailscale (100.95.75.71), WireGuard (10.10.0.x)
- **Dashboard**: curfew.vuttipipat.com (Cloudflare Tunnel)
- **Process Manager**: PM2
- **Fleet Manager**: maw-js + tmux

## Current State

### What's Working
- All 27+ oracles online and operational
- PM2 services stable (6 services)
- Hooks enforcing all rules
- Dashboard accessible
- Git operations working
- Gmail MCP connected

### Known Issues
- WireGuard connectivity to vuttiserver intermittent (expected — old server may be down)
- Some handoff docs still reference /home/mbank (cosmetic, non-functional)
- Supabase MCP OAuth needs re-authorization on some projects

### Lessons Learned
- ghq clone was critical — all repos recovered within hours
- Path migration is tedious but straightforward (sed + verify)
- PM2 ecosystem.config.cjs handles service restart well
- Fleet configs (fleet/*.json) are the single source of truth for oracle-to-repo mapping

## Owner & Contacts

| Role | Oracle | Responsibility |
|------|--------|---------------|
| **Lead** | BoB | Orchestration, verification |
| **Infrastructure** | Admin, Echo | PM2, tmux, hooks, services |
| **Verification** | Each oracle | Self-verify via /recap |
| **Documentation** | DocCon | Migration audit, path verification |
| **Stakeholder** | แบงค์ | Decision maker |
