# Maw CLI (Multi-Agent Workflow)

## Overview

- **What it does**: CLI tool + backend API server for managing the Oracle AI agent fleet. Provides tmux-based session orchestration, inter-agent messaging, project/task management, scheduled loop execution, cross-machine federation, and a React dashboard with inbox, board, fleet views, and account usage monitoring.
- **Who uses it**: All oracles (via `maw` CLI), BoB (fleet management), แบงค์ (dashboard monitoring), automated systems (loop engine, health checks).
- **Where it runs**: Curfew server (WSL2). CLI installed globally via `bun link`. Backend API on `:3456` managed by PM2. Dashboard at `curfew.vuttipipat.com`.
- **Canonical repo-level doc**: `maw-js/README.md` (Dev-maintained, feature-complete). This fleet doc provides the oracle-level overview.

## Architecture

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Runtime | Bun | CLI execution, server runtime |
| Backend | Hono | HTTP API + WebSocket server on `:3456` |
| Frontend | React 19 + Zustand + Tailwind | Dashboard UI (maw-ui) |
| Terminal | tmux | Session/window orchestration for oracle agents |
| Transport | HTTP, MQTT, WebSocket, tmux, SSH, LoRa | Pluggable transport layer |
| Process Manager | PM2 | `ecosystem.config.cjs` — 4 services: maw, maw-boot, maw-bob, maw-syslog |
| Build | Vite | Dashboard UI build |
| Auth | PIN + QR code + session cookies | Dashboard access control |

### Key Services

```
┌─────────────┐     ┌──────────────┐     ┌───────────────┐
│  maw CLI    │────▶│  Hono Server │────▶│  tmux sessions│
│  (src/cli.ts)│    │  (:3456)     │     │  (01-bob..99) │
└─────────────┘     └──────┬───────┘     └───────────────┘
                           │
                    ┌──────┴───────┐
                    │              │
              ┌─────▼─────┐ ┌─────▼──────┐
              │ Loop Engine│ │ Federation │
              │ (loops.ts) │ │ (HMAC mesh)│
              └───────────┘ └────────────┘
```

### Data Storage

| Location | Format | Purpose |
|----------|--------|---------|
| `~/maw-js/maw.config.json` | JSON | Main config: host, port, ghqRoot, sessions, agents, federation |
| `~/.maw/projects.json` | JSON | All projects + tasks |
| `~/.maw/task-logs/<taskId>.jsonl` | JSONL | Per-task activity log (append-only) |
| `~/maw-js/loops.json` | JSON | Loop definitions + engine enabled flag |
| `~/maw-js/loops-log.json` | JSON | Loop execution history (last 500 runs) |
| `~/.oracle/feed.log` | Text | System event stream (append-only, tailed by dashboard) |
| `~/.oracle/maw-log.jsonl` | JSONL | Message audit trail (ts, from, to, msg, host) |
| `~/.oracle/inbox/<agent>.jsonl` | JSONL | Inbox signals (inbound messages per oracle) |
| `~/maw-js/fleet/*.json` | JSON | Fleet session configs (numbered 01-99) |
| `~/.config/maw/snapshots/*.json` | JSON | Fleet state snapshots (720 kept) |
| `~/.config/maw/auth.json` | JSON | Auth credentials (username + password hash) |
| `~/maw-js/ui-state.json` | JSON | Cross-device UI state |

### PM2 Services

| Process | Script | Purpose |
|---------|--------|---------|
| `maw` | `dist/server.js` | Main server (:3456) — API, WS, dashboard, loops |
| `maw-boot` | `src/boot.ts` | One-shot fleet wake after server starts |
| `maw-bob` | `src/serve-bob.ts` | BoB's dedicated endpoint (:3457) |
| `maw-syslog` | `src/syslog.ts` | System event listener (feed.log → structured events) |

PM2 memory gate: **3000M** (raised from 700M→1400M→3000M after #171 memory crisis). Server runs from `dist/server.js` (not src/) — Bun from-source transpile under PM2 drops private class methods (#166).

## Code Structure

```
Curfew-Maw-js/
├── src/
│   ├── cli.ts                      # Entry point — CLI router (60+ commands)
│   ├── server.ts                   # Hono API + WebSocket server (~2,960 LOC, ~90 routes)
│   ├── engine.ts                   # MawEngine — WebSocket message loop + health
│   ├── handlers.ts                 # WebSocket message handlers
│   ├── types.ts                    # TypeScript interfaces
│   │
│   ├── tmux.ts                     # Tmux class wrapper (typed tmux CLI)
│   ├── ssh.ts                      # SSH session list, capture, sendKeys
│   ├── pty.ts                      # PTY terminal emulation
│   ├── transports/                 # Plugin transport layer (HTTP, MQTT, LoRa, tmux, hub)
│   │
│   ├── commands/                   # CLI subcommand handlers (40+ files)
│   │   ├── comm.ts                 # wake, peek, send (maw hey)
│   │   ├── wake.ts                 # Oracle spawn + worktree lifecycle
│   │   ├── fleet.ts                # Fleet-wide wake/sleep/manage
│   │   ├── fleet-init.ts           # Fleet config generation
│   │   ├── loop.ts                 # Loop CLI wrapper
│   │   ├── project.ts              # Project + task management
│   │   ├── task-log.ts             # Task activity logging
│   │   ├── sovereign.ts            # Oracle-as-Sovereign layout
│   │   ├── bud.ts                  # Oracle budding (child creation)
│   │   ├── pulse.ts                # Issue creation + wake oracle
│   │   ├── think.ts, meeting.ts    # Collective oracle coordination
│   │   ├── overview.ts             # War-room split-pane view
│   │   └── view.ts, tab.ts         # tmux attach + tab management
│   │
│   ├── loops.ts                    # Loop scheduler engine (400 lines)
│   ├── projects.ts                 # Project DB (projects.json)
│   ├── task-log.ts                 # Task activity log (.maw/task-logs/)
│   ├── board.ts                    # GitHub board interface
│   ├── feed-tail.ts                # Live log tailer for feed.log
│   ├── config.ts                   # maw.config.json loader
│   ├── paths.ts, routing.ts        # Path resolution + target routing
│   ├── auth.ts                     # Session auth + QR login
│   ├── oracle-health.ts            # Oracle session health monitoring
│   ├── supervisor.ts               # BobSupervisor — task tracking, stall detection, auto-nudge, completion chaining
│   ├── autopilot.ts                # ORACLE_MAP (27 oracles), ROUTING_RULES (20 keyword sets), RESULT_CHAINS, board automation
│   ├── audit.ts, maw-log.ts        # Audit logging
│   ├── snapshot.ts                 # Fleet state snapshots
│   ├── anti-patterns.ts            # Health checks (Zombie/Island detection)
│   ├── pty.ts                      # PTY transport — grouped sessions, row-reflow, orphan sweep
│   └── plugins.ts, hooks.ts        # Extension + hook system
│
├── fleet/                          # Session configs
│   ├── 01-bob.json
│   ├── 02-dev.json
│   └── ... (numbered up to 99)
│
├── ui/ & office/                   # Dashboard builds
│   ├── dist-office/                # Pre-built React dashboard
│   ├── dist-8bit-office/           # Bevy WASM alternative
│   └── dist-war-room/              # Alternative UI
│
├── docs/
│   ├── federation.md               # v1 federation API spec
│   └── new-node-setup.md           # Multi-node onboarding
│
├── ecosystem.config.cjs            # PM2 config
├── package.json                    # v1.1.0, bun runtime
└── maw.config.json                 # Node config (generated)
```

## Business Logic

### 1. CLI Command Router (`src/cli.ts`)

Entry point parses `maw <cmd>` and dispatches to handlers. 50+ commands organized by category:

**Core Workflow:**
| Command | Purpose |
|---------|---------|
| `maw ls` | List all tmux sessions + windows |
| `maw peek [agent]` | Show pane output (or all) |
| `maw hey <agent> <msg>` | Send message to agent in tmux |
| `maw wake <oracle> [task]` | Create/revive tmux session + start claude |
| `maw sleep <oracle>` | Gracefully stop oracle |
| `maw done <window>` | Auto-save + clean up worktree |

**Fleet Management:**
| Command | Purpose |
|---------|---------|
| `maw wake all` | Wake fleet (01-15 default, `--all` for 1-99) |
| `maw fleet init` | Scan ghq repos → generate fleet configs |
| `maw fleet ls` | List configs with conflict detection |
| `maw fleet validate` | Check for dupes, orphans, missing repos |
| `maw fleet sync` | Add unregistered windows to configs |
| `maw oracle ls` | Fleet status (awake/sleeping/worktrees) |
| `maw stop` | Stop ALL fleet sessions |

**Project & Task Management:**
| Command | Purpose |
|---------|---------|
| `maw project ls` | List all projects + task counts + progress |
| `maw project create <id> "Name" ["desc"]` | Create project |
| `maw project add <id> #<issue>` | Add task to project |
| `maw project auto-organize` | Auto-group unassigned tasks |
| `maw task ls` | Board + activity counts |
| `maw task log <#> "msg"` | Log activity on task |
| `maw task log <#> --commit "hash msg"` | Log a commit |
| `maw task log <#> --blocker "desc"` | Log a blocker |
| `maw task comment <#> "msg"` | Cross-oracle comment |

**Scheduling:**
| Command | Purpose |
|---------|---------|
| `maw loop` | Show all loop status |
| `maw loop add '{json}'` | Add/update loop definition |
| `maw loop trigger <id>` | Manually fire a loop |
| `maw loop enable/disable <id>` | Toggle loop |
| `maw loop history [id]` | Execution history |
| `maw loop on/off` | Enable/disable engine globally |

**Specialized:**
| Command | Purpose |
|---------|---------|
| `maw overview [agents]` | War-room: all oracles in split panes |
| `maw pulse add "task" [--oracle x]` | Create issue + wake oracle |
| `maw pulse scan` | Anti-pattern health check |
| `maw bud <name> --approved-by <human>` | Spawn new child oracle |
| `maw sovereign status/migrate` | Oracle-as-Sovereign layout |
| `maw tokens [--top N]` | Token usage stats |
| `maw chat [oracle]` | Grouped conversation view |

### 2. Tmux Injection (`maw hey`)

How messages reach Claude sessions:

```
CLI: maw hey neo "what are you doing"
  → Resolve target: findWindow(sessions, "neo") → "neo:0"
  → Route check: local or federated?
  → Send keys: tmux send-keys -t 'neo:0' '[from cli] ...' Enter
  → Audit: Log to maw-log.jsonl + feed.log + inbox signal
```

For federation (cross-node): `maw hey mba:homekeeper "hello"` → POST to `/api/federation/send` with HMAC-SHA256 signature.

### 3. Wake Command (`src/commands/wake.ts`)

Oracle lifecycle manager:

1. **Resolve** — Find repo path via ghq or fleet configs
2. **Detect** — Check if tmux session already running
3. **Create** — `tmux new-session -d -s <session>` if new
4. **Spawn Windows** — For each worktree (`.wt-*`), create tmux window
5. **Launch Claude** — Send `buildCommand()` via tmux send-keys
6. **Self-Heal** — Detect idle panes (prompt `❯`), resend claude if crashed
7. **Attach** — `tmux switch-client -t <session>`

Wake modes:
- `maw wake neo` — Wake main repo
- `maw wake neo --new free` — Create worktree + wake
- `maw wake neo --issue 5` — Fetch issue #5, send as prompt

### 4. Loop Scheduler Engine (`src/loops.ts`, 400 lines)

Cron-based scheduler running in the PM2-managed server process:

```typescript
interface LoopDef {
  id: string;              // "daily-standup"
  oracle: string;          // "dev"
  tmux: string | null;     // "02-dev:0"
  schedule: string;        // "0 9 * * *" (cron)
  prompt?: string;         // Message to send
  command?: string;        // Shell command (if no tmux)
  requireIdle?: boolean;   // Skip if oracle busy
  requireActiveOracles?: boolean;
  autoRestart?: boolean;   // Restart dead session
  enabled: boolean;
  description: string;
}
```

Execution flow:
1. Check every 30 seconds if any loop's cron matches current time
2. Per-minute dedup: only fire once per minute
3. Pre-flight: session alive? oracle idle? active oracles?
4. If autoRestart + dead session: `tmux new-session` + wait for prompt
5. Send prompt via `tmux set-buffer + paste-buffer + Enter`
6. Log to `loops-log.json` (rotated to 500 entries) + `feed.log`

### 5. Project/Task Management (`src/projects.ts`, `src/task-log.ts`)

**Project schema** (`~/.maw/projects.json`):
```typescript
interface Project {
  id: string;           // "fa-tools"
  name: string;         // "FA Tools"
  description: string;
  tasks: ProjectTask[]; // { taskId, parentTaskId?, order }
  status: "active" | "completed" | "archived";
  createdAt: string;
  updatedAt: string;
}
```

**Task activity** (`~/.maw/task-logs/<taskId>.jsonl`):
```typescript
interface TaskActivity {
  id: string;
  taskId: string;
  type: "message" | "commit" | "status_change" | "note" | "blocker" | "comment";
  oracle: string;
  ts: string;
  content: string;
  meta?: { commitHash?, oldStatus?, newStatus?, resolved? };
}
```

Features: subtask hierarchies, cross-oracle comments, blocker tracking with resolution, contributor tracking.

### 6. Federation Mesh (`docs/federation.md`)

Cross-machine agent communication via HMAC-SHA256 signed requests:

**Public API (no auth):**

| Endpoint | Purpose |
|----------|---------|
| `GET /api/config` | Node identity + agents map + peers |
| `GET /api/fleet-config` | Raw fleet/*.json configs |
| `GET /api/feed?limit=N&oracle=X` | Bounded event stream (200 max) |
| `GET /api/federation/status` | Peer reachability + latency |

**Cross-node send** (`POST /api/federation/send`):
- HMAC-SHA256(body, federationToken) in Authorization header
- Sender identity: `[from <node>:<oracle>] <message>`
- Audit trail: maw-log.jsonl + feed.log + inbox signal

**Config** (`maw.config.json`):
```json
{
  "node": "curfew",
  "federationToken": "shared-secret-min-16-chars",
  "namedPeers": [
    { "name": "mba", "url": "http://mba.wg:3457" }
  ],
  "agents": { "neo": "curfew", "homekeeper": "mba" }
}
```

### 7. Fleet System (`src/commands/fleet.ts`)

Fleet config format (`fleet/01-bob.json`):
```json
{
  "name": "01-bob",
  "windows": [
    { "name": "BoB-Oracle", "repo": "BankCurfew/BoB-Oracle" }
  ],
  "sync_peers": ["dev"],
  "budded_from": "mawjs",
  "budded_at": "2026-04-10T03:50:00.000Z"
}
```

Conflict detection: two configs claiming same window name → error + hint. Auto-fix via `fleet renumber`.

## API Endpoints

Backend Hono server (`src/server.ts`, 1,300+ lines) on `:3456`:

### Auth
| Method | Route | Purpose |
|--------|-------|---------|
| POST | `/auth/login` | Username/password auth → session cookie |
| GET | `/auth/qr-generate` | Generate QR token for phone login |
| POST | `/auth/qr-approve` | Approve QR token |
| GET | `/auth/me` | Check auth status |

### Core Control
| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/api/sessions` | List tmux sessions + windows |
| GET | `/api/capture?target=X:Y` | Capture pane output |
| POST | `/api/send` | Send keys to target (local or federated) |
| POST | `/api/federation/send` | Inbound cross-node message (HMAC) |

### Board & Projects
| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/api/board` | Fetch GitHub board data |
| POST | `/api/board/add` | Create new board item |

### Tasks & Logs
| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/api/task-logs/<taskId>` | Read task activity log |
| POST | `/api/task-activity` | Append task activity |
| GET | `/api/task-summary?taskId=...` | Summary (count, contributors) |

### Loops
| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/api/loops` | List all loops + status |
| GET | `/api/loops/history?loopId=X` | Execution history |
| POST | `/api/loops/trigger` | Manually fire a loop |
| POST | `/api/loops/toggle` | Enable/disable loop or engine |

### Fleet & Health
| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/api/fleet` | Fleet configs |
| GET | `/api/fleet-config` | Raw fleet/*.json contents |
| GET | `/api/oracle-health` | Oracle session health |
| GET | `/api/sessions/federated` | Aggregated sessions (all nodes) |

### Feed & Events
| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/api/feed?limit=50&oracle=X` | Live event stream |
| GET | `/api/feed/active` | Oracles active in last 5m |
| GET | `/api/maw-log` | Message audit trail |

### Config & UI
| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/api/config` | maw.config.json (masked or raw) |
| POST | `/api/pin-set` | Set PIN for dashboard |
| GET/POST | `/api/ui-state` | Cross-device UI state |
| POST | `/api/attachments` | Upload attachment |

### Static
| Route | Purpose |
|-------|---------|
| `/` | React SPA dashboard (hash routing) |
| `/#dashboard`, `/#fleet`, `/#office` | Client-side routes |
| `/office-8bit`, `/war-room` | Alternative WASM UIs |

## Deployment

### Server Start
```bash
pm2 start ecosystem.config.cjs      # Start maw backend on :3456
# Or direct:
bun run src/server.ts --port 3456
```

### Install & Link CLI
```bash
cd ~/repos/github.com/BankCurfew/Curfew-Maw-js
bun install && bun link
maw ls                               # Now available globally
```

### Dev Mode
```bash
bun run dev                          # pm2 start + vite watch
bun run dev:office                   # Vite dev server on :5173
bun run dev:stop                     # Kill pm2 processes
```

### Dashboard Deploy
```bash
cd maw-ui && bun run build
cp -r dist/* ~/repos/.../Curfew-Maw-js/ui/office/
pm2 restart maw
```

### Environment
- **Bun runtime** required (not Node.js)
- **tmux** must be installed and accessible
- **PM2** manages the server process (auto-restart on crash)
- No `.env` file needed for core functionality (config in `maw.config.json`)
- Federation requires `federationToken` in config (min 16 chars)

## Current State

**Version**: v1.1.0
**Status**: Production — federation + bud system stable, loop engine running, memory stack hardened
**Files**: ~190 TypeScript source files, 60+ CLI commands

### Evolution (Key Milestones)

```
maw.env.sh (Oct 2025) → oracles() zsh (Mar 2026) → maw.js monolith (Mar 2026) → maw-js (Mar 2026)
```

| Issue | What |
|-------|------|
| #154 | Bun.serve idleTimeout 10→30s (502 root cause) |
| #156 | Inbox rework — relevance filter + reports grid |
| #159 | Memory leak + rate limiting + backward pagination (11 commits) |
| #160 | OracleSheet global usage header |
| #162 | Inbox 2.0 — typed lanes, file gallery, RetryImg (8 commits) |
| #166 | Sawtooth memory leak — stderr drain + PM2 dist pin (4 commits) |
| #170 | Account Usage Windows — 3-card argus-style section |
| #171 | RSS retention crisis — spawnSync, spawn limiter, double GC, mirror cache (8 commits) |
| chip | Chip-copy-on-deliver — auto-copy file paths to inbox on send |

### Earlier Architecture Changes (2026-06)

| Change | What |
|--------|------|
| **ORACLE_MAP 7→27** | All 27 oracles mapped with keyword routing (20 rules) |
| **Stall detection** | 2hr auto-nudge on HIGH priority tasks, 30min cooldown |
| **PTY row-reflow** | Upstream #2409 port — rows match client viewport, width pinned 200 |
| **Orphan-PTY sweep** | Upstream #2414 port — kills leaked maw-pty-* sessions every 5min |
| **tmux 200x200** | Prevents 24x80 default pane bug |
| **Capture 1000 lines** | Increased from 80→300→1000 for scrollback depth |
| **28+ hooks fleet-wide** | validate-project-prefix, enforce-maw-hey, enforce-maw-loop, etc. |

### Dashboard Key Features (Jul 2026)

| Feature | What |
|---------|------|
| **OracleSheet** (79K LOC) | Full agent view: transcript, comms, thinking, status, inline file chips |
| **Inbox 2.0** (#162) | Typed message lanes (Tasks, Reports, Messages), file-centric gallery with RetryImg (iOS Safari ITP fix), read-state tracking |
| **Account Usage** (#170) | 3-card argus-style panel showing Claude API consumption (proxied from server-monitor :3459) |
| **File Chips** | Clickable file thumbnails/previews in message bubbles; chip-copy-on-deliver ensures files accessible from `~/.maw/inbox/chips/` |
| **WebSocket reconnect** | Exponential backoff (1s base, 1.5x, 15s cap, jitter), background tab disconnect on visibilityState hidden |

Dashboard routes: `#dashboard`, `#fleet`, `#office`, `#overview`, `#terminal`, `#inbox`, `#board`, `#loops`, `#config`, `/federation`.

### Memory Management (#166 / #171)

The #171 memory crisis (8 rounds of investigation) established the current memory stack:

| Layer | What | Why |
|-------|------|-----|
| `Bun.spawnSync` for local | 21KB vs 3MB per spawn (143x reduction) | Bun.spawn async retains native memory per call |
| Stderr drain everywhere | All spawn sites drain both stdout AND stderr | Unconsumed stderr pipe leaks ~4.4KB/spawn RSS |
| Spawn concurrency limiter | Semaphore, max 8 concurrent | Caps peak native memory from parallel spawns |
| Double GC tap | 2s interval, two `Bun.gc(true)` calls 100ms apart when RSS>300MB | Single GC marks pages free but OS doesn't unmap; double tap forces reclaim |
| Mirror response cache | 2s TTL, 100 entry cap for /api/mirror | HTTP native retention ~3KB/req at 52 req/s was unsustainable |
| Capture cache | 5s TTL + single-inflight dedup | ~50x fewer tmux spawns |
| PM2 gate 3000M | `max_memory_restart` raised from 700M | Avoids false restarts from transient RSS spikes |
| `BUN_JSC_forceGCSlowPaths=1` | PM2 env | Forces JSC to use slower but more thorough GC paths |

Debug endpoints: `/api/debug/memory` (RSS/heap/GC stats + spawn counters + traffic), `/api/debug/gc` (force GC), `/api/debug/deep` (deep analysis).

### Chip-Copy-On-Deliver

When `maw hey` sends a message containing file paths, the chip system:
1. Scans message for paths matching `.(png|jpg|webp|gif|html|pdf|md|txt)`
2. Copies files to `~/.maw/inbox/chips/{sender}-{filename}`
3. Rewrites paths in message to `/.maw/inbox/chips/...`
4. Guards: skip files already in inbox, skip >50MB, skip non-files

Ensures dashboard `/api/file` can always resolve chip paths regardless of source oracle repo.

### Known Limitations
- Loop engine checks every 30 seconds (not sub-second precision)
- Federation token must be >= 16 chars (no length validation error message)
- Feed polling uses byte-offset (~1s latency, not inotify)
- Worktree matching is exact only (substring matching removed for safety)

## Owner & Contacts

| Role | Oracle |
|------|--------|
| **Lead** | Dev-Oracle |
| **Fleet Mgmt** | BoB-Oracle |
| **Dashboard UI** | Dev-Oracle / FE-Oracle |
| **Infrastructure** | Admin-Oracle |
| **Monitoring** | BoB-Oracle (via `maw peek`, dashboard) |
