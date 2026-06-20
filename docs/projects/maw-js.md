# Maw CLI (Multi-Agent Workflow)

## Overview

- **What it does**: CLI tool + backend API server for managing the Oracle AI agent fleet. Provides tmux-based session orchestration, inter-agent messaging, project/task management, scheduled loop execution, and cross-machine federation.
- **Who uses it**: All oracles (via `maw` CLI), BoB (fleet management), แบงค์ (dashboard monitoring), automated systems (loop engine, health checks).
- **Where it runs**: Curfew server (WSL2). CLI installed globally via `bun link`. Backend API on `:3456` managed by PM2. Dashboard at `curfew.vuttipipat.com`.

## Architecture

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Runtime | Bun | CLI execution, server runtime |
| Backend | Hono | HTTP API + WebSocket server on `:3456` |
| Frontend | React 19 + Zustand + Tailwind | Dashboard UI (maw-ui) |
| Terminal | tmux | Session/window orchestration for oracle agents |
| Transport | HTTP, MQTT, WebSocket, tmux, SSH, LoRa | Pluggable transport layer |
| Process Manager | PM2 | `ecosystem.config.cjs` — keeps server + loop engine alive |
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

## Code Structure

```
Curfew-Maw-js/
├── src/
│   ├── cli.ts                      # Entry point — CLI router (442 lines)
│   ├── server.ts                   # Hono API + WebSocket server (1,300+ lines)
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
│   ├── audit.ts, maw-log.ts        # Audit logging
│   ├── snapshot.ts                 # Fleet state snapshots
│   ├── anti-patterns.ts            # Health checks (Zombie/Island detection)
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
**Status**: Production — federation + bud system stable, loop engine running
**Files**: 142 TypeScript source files, 50+ CLI commands

### Recent Commits
```
dab536f  refactor: rename iAgencyAIA display to FaSai in fleet config
dced399  docs: new-node-setup — spoke-node onboarding guide
dd23c60  fix: agent→node fallback for bare-name federation routing
685c33a  feat: dynamic office title from config.officeTitle
e0ee189  feat: federated agent status polling — live busy/ready/idle
cfd6e8e  fix: sender identity uses tmux window name when unset
bd33e54  feat: federation messages include sender identity
a36a610  security: /api/config only exposes local agents
```

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
