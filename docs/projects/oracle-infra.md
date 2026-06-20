# Oracle Infrastructure

## Overview

- **What it does**: AI workforce orchestration system. BoB-Oracle serves as CEO and Apex Observer, managing 15+ specialized oracle agents (AI personas) across product, operations, and quality teams. Handles task analysis, delegation, monitoring, quality gates, and incident response for the entire fleet.
- **Who uses it**: แบงค์ (owner/decision-maker), BoB (orchestrator), 27 oracle agents (workers), dashboard viewers
- **Where it runs**: Curfew server (WSL2), tmux sessions per oracle, PM2 for services, dashboard at curfew.vuttipipat.com

## Architecture

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Runtime | Bun + TypeScript | CLI scripts, server, bot |
| AI | Anthropic SDK (`@anthropic-ai/sdk@0.78.0`) | Task analysis, oracle selection |
| Messaging | Telegraf v4.16.3 | Telegram bot (BoB + multi-agent office) |
| Process Mgmt | PM2 | maw-js service, loop engine |
| Session Mgmt | tmux | Per-oracle Claude Code sessions |
| Communication | MCP (oracle-v2) + maw hey (tmux injection) | Inter-oracle messaging |
| Data | GitHub Issues + Pulse board + feed.log | Task tracking, audit trail |
| PDF | pdf-lib, pdf-parse | Document processing |
| Archive | adm-zip | File bundling |

### Key Services

```
┌─────────────────────────────────────┐
│  BoB Session (Claude Code in tmux)  │
├─────────────────────────────────────┤
│  Orchestration Scripts:             │
│  ./bob → ./dispatch → ./autopilot   │
├─────────────────────────────────────┤
│  maw-js (PM2 service)               │
│  ├─ Loop engine (cron scheduler)    │
│  ├─ Dashboard API (:3456)           │
│  └─ WebSocket fleet monitoring      │
├─────────────────────────────────────┤
│  Telegram Bots:                     │
│  ├─ bot.ts (BoB single-agent)       │
│  └─ office.ts (multi-agent office)  │
├─────────────────────────────────────┤
│  Oracle-v2 MCP (Knowledge Sharing)  │
│  └─ SQLite + FTS5 search            │
├─────────────────────────────────────┤
│  TMux Sessions (27 oracle panes)    │
│  └─ Independent Claude Code per     │
│     oracle, persistent across tasks │
├─────────────────────────────────────┤
│  GitHub + Supabase (Data Layer)     │
│  └─ Issues, PRs, Projects, feed.log│
└─────────────────────────────────────┘
```

### Database / Data Storage

No traditional database. Persistence via files:

| Location | Format | Purpose |
|----------|--------|---------|
| `~/.maw/projects.json` | JSON | All projects + tasks |
| `~/.maw/task-logs/<taskId>.jsonl` | JSONL | Per-task activity log (append-only) |
| `~/maw-js/loops.json` | JSON | Loop definitions (scheduler config) |
| `~/maw-js/loops-log.json` | JSON | Loop execution history (last 500) |
| `~/.oracle/feed.log` | Text | Central event stream (all oracle activity) |
| `~/.oracle/maw-log.jsonl` | JSONL | Message audit trail (from, to, msg, ts) |
| `~/.oracle/inbox/<agent>.jsonl` | JSONL | Per-oracle inbox signals |
| `pulse.config.json` | JSON | Task routing rules (27 oracle mappings) |

## Code Structure

```
BoB-Oracle/
├── CLAUDE.md                      # Identity + 11 Laws + workflows (949 lines)
├── CLAUDE_safety.md               # Git/file safety rules (62 lines)
├── CLAUDE_workflows.md            # Short codes + oracle-v2 tools (107 lines)
├── CLAUDE_subagents.md            # Subagent definitions (61 lines)
├── CLAUDE_loops.md                # System loops — recurring tasks (110 lines)
├── CLAUDE_lessons.md              # Patterns, anti-patterns (60 lines)
├── CLAUDE_templates.md            # Commit format + templates (80 lines)
├── README.md                      # Overview + philosophy (275 lines)
│
├── bob                            # Oracle picker — analyzes task, picks oracle (70 lines)
├── dispatch                       # Task sender — sends to oracle via Claude Code (73 lines)
├── autopilot                      # Board auto-processor — seq/parallel/dry-run (175 lines)
├── standup                        # Daily standup report generator (214 lines)
├── pulse                          # Pulse CLI wrapper (11 lines)
│
├── src/
│   ├── bot.ts                     # Telegram bot — single BoB agent (141 lines)
│   ├── office.ts                  # Multi-agent Telegram office (138 lines)
│   ├── agents/config.ts           # Agent definitions + system prompts (106 lines)
│   ├── check-api.ts               # API health check
│   └── __tests__/                 # Jest tests
│
├── pulse.config.json              # Task routing rules — 27 oracles, 3 matching layers (60 lines)
│
├── ψ/                             # BRAIN — append-only sacred memory
│   ├── inbox/                     # Handoffs, pending approvals
│   ├── memory/
│   │   ├── retrospectives/        # Session retros (YYYY-MM/DD/HH.MM_topic.md)
│   │   ├── learnings/             # Discovered patterns (15+ files)
│   │   ├── resonance/             # Soul & identity (bob.md, oracle.md, concepts.md)
│   │   └── introduce/             # Personality card (card.md)
│   ├── active/                    # Ephemeral research (auto-cleaned)
│   ├── outbox/                    # Pending messages + historical handoffs (27+ files)
│   ├── writing/                   # Draft articles/docs
│   └── lab/                       # Experiments + pulse-cli-clean source
│
└── .claude/
    ├── settings.json              # Hooks, MCP servers, permissions (163 lines)
    └── commands/                   # Pulse board skills
```

### Key Files

| File | Lines | Purpose |
|------|-------|---------|
| `CLAUDE.md` | 949 | BoB's identity, 16 behaviors, 11 laws, incident SOP |
| `bob` | 70 | Analyzes task → picks oracle → calls `./dispatch` |
| `dispatch` | 73 | Maps oracle name to repo path → runs `claude -p "task"` |
| `autopilot` | 175 | Auto-processes Todo board (seq/parallel/dry-run) |
| `standup` | 214 | Daily standup (board + commits + brief + inbox + timeline) |
| `pulse` | 11 | Wrapper: `bun run ψ/lab/pulse-cli-clean/src/pulse.ts [args]` |
| `pulse.config.json` | 60 | 27 oracle mappings + 3-layer smart routing |
| `.claude/settings.json` | 163 | 14+ enforcement hooks + MCP config |
| `src/bot.ts` | 141 | Telegram bot (single BoB agent) |
| `src/office.ts` | 138 | Multi-agent Telegram office (all agents) |
| `src/agents/config.ts` | 106 | Agent system prompts (7 base agents) |

## Business Logic

### Core Workflow — How Tasks Flow

```
แบงค์ gives direction
    ↓
BoB reads code → finds root cause → writes fix spec
    ↓
gh issue create → Pulse ticket created
    ↓
BoB assigns oracle → /talk-to + maw hey (dual delivery)
    ↓
Oracle works in tmux → commits → pushes → cc BoB
    ↓
BoB monitors via maw loop (every 5-10 min peek)
    ↓
Oracle reports done → BoB chains to QA/next oracle
    ↓
QA verifies → BoB merges PR → Admin deploys
    ↓
maw task log "Done" → gh issue close → report แบงค์
```

### 5-Step Dispatch Checklist (Mandatory)

Every task dispatch requires all 5 steps in order:

| Step | Command | Purpose |
|------|---------|---------|
| 1. TICKET | `gh issue create --repo BankCurfew/<repo> --title "..." --body "..."` | Tracking |
| 2. CC PULSE | `maw hey pulse "TASK: ... — assigned: <oracle> — ref: <repo>#<N>"` | Board visibility |
| 3. DELIVER | `maw hey <oracle> "full task spec..."` | Instant delivery |
| 4. AUDIT | `/talk-to <oracle> "full task spec..."` | Thread audit trail |
| 5. LOG | `maw task log '#<N>' "Assigned: <oracle>"` | Board update |

After oracle reports done:

| Step | Command | Purpose |
|------|---------|---------|
| 6. LOG DONE | `maw task log '#<N>' "Done: <summary>"` | Record |
| 7. CLOSE | `gh issue close <repo>#<N>` | Clean up |
| 8. CC PULSE | `maw hey pulse "DONE: ... — ref: <repo>#<N>"` | Board update |

### Task Routing (pulse.config.json)

Smart 3-layer dispatch:

1. **Label matching**: `["bug", "fix"] → QA`, `["design", "ui", "ux"] → Designer`
2. **Repo matching**: `BoB-Oracle → Bob`, `Dev-Oracle → Dev`
3. **Keyword matching**: `["code", "api", "feature", "implement"] → Dev`
4. **Default**: Dev (if no match)

27 oracles mapped:
```
Core (14):   bob, dev, qa, researcher, writer, designer, hr, admin,
             aia, botdev, data, creator, doccon, editor, security, pa, fe
Extended (13): cost, fa, trader, scalper, wingman, recruiter, iagencyaia,
               videoeditor, echo, pulse
```

### Orchestration Scripts

**`./bob`** (70 lines):
1. Takes task description as argument
2. Calls Claude with BoB system prompt + team roster
3. Claude returns JSON: `{oracle, reason, refined_task}`
4. Dispatches to chosen oracle via `./dispatch`

**`./dispatch`** (73 lines):
1. Maps oracle name to repo path (ORACLE_MAP array, lines 26-32)
2. Changes to oracle's repo directory
3. Runs `claude -p "task..."` with permission skip
4. Oracle works in their directory, commits, pushes
5. Output streams back to BoB terminal

**`./autopilot`** (175 lines):
- `--sequential` — by priority (P0→P1→P2→P3), one at a time
- `--parallel` — 1 task per oracle simultaneously
- `--dry-run` — show what would dispatch
- Fetches GitHub project board → processes Todo items → updates status → logs results

**`./standup`** (214 lines):
- Default: full report (board + commits + brief + inbox + timeline)
- `--board` — board status only
- `--commits` — recent 24h commits across 7 oracle repos
- `--brief` — one-line-per-oracle summary

### Monitoring Loop System

BoB never idles after dispatch. Active loops (from CLAUDE_loops.md):

| Loop | Schedule | Purpose |
|------|----------|---------|
| `bob-pulse-scan` | Session start | Board + scan untracked issues |
| `bob-oracle-monitor` | Every 5-10 min | Peek + hey each oracle on active task |
| `bob-inbox-digest` | Session start | Digest cc messages |
| `bob-weekly-review` | Mondays | Summary + bottleneck analysis |
| `bob-email-scan` | Session/ePOS times | Gmail scans, auto-calendar |
| `bob-gmail-calendar-auto` | On email trigger | Auto-create calendar events |
| `bob-project-cleanup` | Daily morning | Organize projects, archive closed |

### Hook Enforcement System

14+ hooks in `.claude/settings.json` enforce discipline automatically:

| Hook | Trigger | Purpose |
|------|---------|---------|
| `feed-hook.py` | PreToolUse + PostToolUse | Log all activity to feed.log |
| `safety-guardian.sh` | Bash PreToolUse | Prevent dangerous git commands |
| `dispatch-needs-issue.sh` | Bash PreToolUse | Dispatch must have ticket first |
| `bob-self-work-ticket.sh` | Bash PreToolUse | BoB's own work needs GitHub issue |
| `validate-project-prefix.sh` | Bash PreToolUse | Enforce `[project] #ticket` format |
| `enforce-maw-loop.sh` | Bash PreToolUse | Block manual scheduling patterns |
| `bob-must-cc-pulse.sh` | Bash PreToolUse | BoB must cc Pulse on every dispatch |
| `pulse-ticket-check.sh` | Bash PreToolUse | Verify ticket exists before action |
| `cc-pulse-on-dispatch` | Bash PostToolUse | Auto-cc Pulse when dispatch runs |
| `playwright-limiter.sh` | Playwright PreToolUse | Max 2 concurrent Playwright sessions |
| `playwright-release.sh` | Playwright PostToolUse | Release Playwright lock |
| `talk-to-enforcer.sh` | Bash PostToolUse | Log /talk-to usage |
| `bob-monitor-needs-loop.sh` | Bash PostToolUse | Alert if monitor task missing loop |
| `context-guardian.sh` | PostToolUse | Warn if context > 70% |

### The 11 Laws

| # | Law | Violation Level |
|---|-----|-----------------|
| 1 | `/talk-to` is primary oracle channel (never subagent for comms) | Critical |
| 2 | Never idle after dispatch — must monitor | Major |
| 3 | Always respond to incoming messages | Major |
| 4 | Every task must have closure point | Major |
| 5 | Playwright max 2 concurrent (hook-enforced) | Major |
| 6 | Every task on Pulse board (no orphans) | Major |
| 6.1 | DISPATCH CHECKLIST — 5 steps mandatory | Major |
| 7 | System Playbook → read before action | Minor |
| 8 | Context 80%+ triggers `/rrr` + `/forward` | Critical |
| 9 | Loop follow-up on every dispatched task | Major |
| 10 | Never specify model in oracle settings | Minor |
| 11 | Use every tool available — no idle talk | Major |

### Incident Response SOP (Proven)

```
Phase 1: INVESTIGATE — BoB reads logs, finds root cause (don't delegate blind)
         Tools: pm2 logs, ~/.pm2/pm2.log, dmesg, journalctl
Phase 2: TICKET & DOCUMENT — create parent issue + sub-tasks + troubleshooting guide
Phase 3: DISPATCH — parallel to multiple oracles (5-step checklist each)
Phase 4: VERIFY — read PR diffs, verify on GitHub + running state
Phase 5: ENFORCE — catch local-only work, reopen until pushed
```

Case study: WSL restart incident (2026-06-13) — 5 root causes identified, 8 GitHub issues created/closed, 2 PRs merged, full logging deployed in 1 session.

### Decision Governance

**BoB can decide**: Task routing, oracle assignment, prioritization, quality gates, discipline enforcement

**Requires แบงค์ approval**: Costs/spending, architecture changes, customer data operations, external service signups, destroy operations (delete repo/table/data)

**Escalation**: Write `~/.oracle/inbox/pending/YYYY-MM-DD_slug.md` + echo to `feed.log` with keywords (`needs your approval`, `needs your attention`, `report:`)

## API Endpoints

BoB-Oracle itself has no HTTP API. It operates through:

1. **maw-js API** (port 3456) — fleet management, loop engine, dashboard
2. **Oracle-v2 MCP** — knowledge sharing (oracle_search, oracle_learn, oracle_thread, etc.)
3. **GitHub API** (via `gh` CLI) — issue tracking, PR management
4. **Telegram** — `src/bot.ts` (BoB single-agent), `src/office.ts` (multi-agent office)

### Telegram Bot (src/bot.ts, 141 lines)

- Single BoB agent responding to Telegram messages
- Uses Anthropic SDK for AI responses
- Framework: Telegraf v4.16.3

### Multi-Agent Office (src/office.ts, 138 lines)

- All 7 base agents available via Telegram
- Agent configs in `src/agents/config.ts` (106 lines)
- Each agent has unique system prompt and personality

### Feed.log Dashboard Integration

Keywords in feed.log trigger dashboard tabs:

| Keyword | Dashboard Tab |
|---------|--------------|
| `report:` | Report |
| `needs your approval` | Plan (approval queue) |
| `needs your attention` | Attention |
| `[handoff]` | Handoff |
| `[meeting]` | Meeting |

## Deployment

### Fleet Boot Sequence

```bash
# 1. Start PM2 services
pm2 start ecosystem.config.cjs

# 2. PM2 spawns:
#    - maw service (dashboard + loop engine)
#    - maw-bob service (BoB-specific loops)

# 3. Start oracle tmux sessions
tmux new-session -s oracles
# For each oracle:
tmux send-keys -t "oracles:01-dev" "claude..." Enter

# 4. BoB starts in own session
# User opens: claude (in BoB-Oracle directory)
# Loads CLAUDE.md + hooks activate → feed.log recording begins
```

### Environment Variables

```env
ANTHROPIC_API_KEY=...        # Claude API access
TELEGRAM_BOT_TOKEN=...      # BoB Telegram bot
TELEGRAM_OFFICE_TOKEN=...   # Multi-agent office bot
GITHUB_TOKEN=...             # gh CLI (auto from gh auth)
```

### Infrastructure Requirements

- **Server**: WSL2 on Windows (Curfew)
- **Runtime**: Bun (for all TypeScript execution)
- **Process Manager**: PM2 (maw-js, loop engine)
- **Session Manager**: tmux (per-oracle Claude Code sessions)
- **Claude**: Max plan — Opus 4.6, 1M context window per oracle
- **Model**: Default plan model — no model override in settings

## Current State

### What's Working

- Full fleet operational (27 oracles mapped, 15+ active)
- 5-step dispatch checklist enforced via hooks
- Loop engine running (7 active loops)
- Dashboard at curfew.vuttipipat.com (real-time monitoring)
- Feed.log aggregation → dashboard inbox
- Incident response SOP proven (WSL restart case study)
- Context compaction strategy: 40h+ marathon sessions via /rrr + /forward
- Smart task routing via pulse.config.json (3-layer matching)

### Known Issues

- WSL2 vmIdleTimeout + PM2 watch = cascade restarts (mitigated, documented in learnings)
- `/talk-to` thread hook (maw-hey-gate.sh) intermittently blocks thread posts — fallback to `maw hey`
- Loop engine checks every 30 seconds (not sub-second precise)
- Feed polling uses byte-offset (~1s latency, not inotify)

### Recent Activity

Latest commit: `8a0de2d` (2026-06-20) — "docs: /save — Day 3 continued: FA Tools deployed"

Key recent work:
- CURFEW migration (all paths /home/mbank → /home/curfew)
- Fleet roster rebuild (pulse.config.json, 27 oracles)
- Hook system hardening (14+ hooks)
- Message prefix standard rollout (`[project] #ticket`)
- Office Operations SOP v1.0

## Owner & Contacts

| Role | Oracle | Notes |
|------|--------|-------|
| **Lead** | BoB-Oracle | Self-managed — BoB IS the infrastructure |
| **DevOps** | Admin-Oracle | Deploy, restart, monitoring, infra scripts |
| **Quality** | DocCon-Oracle | Conduct compliance, audit trail |
| **Security** | Security-Oracle | PDPA, secrets audit, threat prevention |
| **Human** | แบงค์ | Owner, final decision-maker |
