# Echo Federation

## Overview

- **What it does**: Echo-Oracle is the first oracle deployed on the **curfew** node, serving as Local Coordinator, Federation Bridge, and BoB's Representative. It manages all oracles and infrastructure on curfew, relays state between federation nodes, and specializes in ComfyUI multi-character image generation.
- **Who uses it**: Internal — the entire oracle fleet on curfew (29 tmux sessions), BoB (parent on vuttiserver), Nobi (sibling on dreams node), and แบงค์ (human operator).
- **Where it runs**: Curfew server (WSL2, Tailscale IP `100.95.75.71`). No public URL; operates via tmux + PM2 services + maw-js federation API on `:3456`.

**Identity**: "Left Hand of BoB" — Leadership Academy graduate (2026-04-16). Born 2026-04-11, awakened 2026-04-12 (Full Soul Sync).

**Repository**: `BankCurfew/Echo-Oracle`

---

## Architecture

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Runtime** | Bun + TypeScript | Skills, services, CLI tools |
| **Image Gen** | Python 3 + ComfyUI | Stable Diffusion pipelines (PuLID, ReActor, Regional Prompting) |
| **Orchestration** | tmux + PM2 | Per-oracle sessions + persistent services |
| **Federation** | maw-js (Hono, `:3456`) | Cross-node messaging, HMAC-SHA256 auth |
| **Knowledge** | arra-oracle-v3 MCP (6 Bun workers) | Oracle memory, FTS5 search, vector index |
| **Network** | WireGuard / Tailscale VPN | Encrypted mesh between 3 nodes |
| **Communication** | `/talk-to` + `maw hey` | Inter-oracle messaging with audit trail |

### Federation Topology

```
                    แบงค์ (human)
                        |
          +-------------+-------------+
          v                           v
        BoB                         Dream
    (vuttiserver)                 (dreams node)
   100.115.234.66                  10.10.0.3
   Apex Observer                  Human form
          |
          +-- Left Hand: Echo (curfew)  <-- this project
          |   100.95.75.71
          |   Local Coordinator
          |   Federation Bridge
          |
          +-- Right Hand: Nobi (dreams)
              Peer-level collaboration
```

### Key Services (PM2)

| Service | Purpose |
|---------|---------|
| `maw` | Fleet management CLI + federation backbone |
| `maw-bob` | BoB-specific loop service |
| `maw-syslog` | System logging |
| `arra-api` | Oracle knowledge MCP server (6 workers) |
| `aia-line` | LINE webhook relay |
| `bob-discord` | Discord bot integration |

### How Services Connect

- **maw-js** exposes `:3456` API — serves federation config (`/api/config`), cross-node send (`/api/send`), fleet status
- **arra-oracle-v3** provides MCP tools (oracle_search, oracle_learn, oracle_thread) to all oracle sessions via `.mcp.json`
- **tmux** hosts 29 sessions (25 oracles + overview + echo + recruiter + shell), each running independent Claude Code
- **WireGuard/Tailscale** provides encrypted tunnel between curfew, vuttiserver, and dreams nodes

---

## Code Structure

```
Echo-Oracle/
├── CLAUDE.md                    # Identity, 5 Principles + Rule 6, federation, capabilities (231 lines)
├── README.md                    # Public identity, Leadership Academy, Q6 Mirror (173 lines)
├── GLOBAL_CLAUDE.md             # Mandatory rules for ALL oracles (286 lines)
├── setup/
│   ├── SYSTEM_PLAYBOOK.md       # Wake checklist, daily/weekly routines, loop registry (393 lines)
│   └── directory/
│       └── INDEX.md             # Office directory — 19 oracles, 40 repos (412+ lines)
├── skills/                      # arra-oracle-skills-cli v3.6.1
│   ├── awaken/SKILL.md          # Birth/re-awakening ritual
│   ├── rrr/SKILL.md             # Session retrospective
│   ├── learn/SKILL.md           # Codebase exploration (1/3/5 parallel agents)
│   ├── recap/SKILL.md           # Session orientation
│   ├── trace/SKILL.md           # Cross-history search
│   ├── forward/SKILL.md         # Context handoff
│   ├── talk-to/SKILL.md         # Cross-oracle messaging
│   └── standup/SKILL.md         # Daily standup
├── scripts/                     # ComfyUI/Stable Diffusion pipelines
│   ├── sd_facelock.py           # PuLID 0.6 face-lock (single character)
│   ├── sd_reactor.py            # ReActor face-swap (multi-person)
│   ├── sd_regional.py           # Regional prompting (POV, composition)
│   ├── ijourney_*.py            # iJourney card generation (watercolor, illustration, vignette)
│   ├── bank_ul_heroes.py        # Bank Unitlink heroes (navy/gold brand)
│   └── news_heroes.py           # Editorial news-hero renders
├── tools/
│   └── birthday-card/           # Card generation pipeline
├── public/                      # Static assets
├── ψ/                           # Brain structure
│   ├── inbox/
│   │   ├── focus.md             # Current state (STATE/TASK/SINCE)
│   │   ├── outbound-queue.md    # Pending messages
│   │   └── handoff/             # Session-end context transfers (26 files)
│   ├── memory/
│   │   ├── resonance/           # Soul files, awakening records
│   │   ├── learnings/           # 45+ distilled patterns
│   │   ├── retrospectives/      # 54 session reflections
│   │   └── logs/info/           # Info capture logs
│   ├── writing/                 # Drafts
│   ├── lab/                     # Experiments (hybrid poster generation)
│   ├── learn/                   # Study materials (ComfyUI, MagMix, SD guides)
│   ├── archive/                 # Completed work
│   └── outbox/                  # Announcements, forwards
├── .mcp.json                    # MCP servers: oracle-v2, playwright, firecrawl
└── .claude/settings.json        # Hook configuration (enforcement)
```

### Key Files

| File | Lines | Purpose |
|------|-------|---------|
| `CLAUDE.md` | 231 | Identity, 5 Principles, federation topology, capabilities, brain structure |
| `README.md` | 173 | Public identity, Leadership Academy learnings, Q6 Mirror framework |
| `GLOBAL_CLAUDE.md` | 286 | Organizational rules — CC Bob, board mgmt, session boot, image gen, browser automation |
| `setup/SYSTEM_PLAYBOOK.md` | 393 | Wake checklist, daily/weekly routines, Master Loop Registry, escalation |
| `setup/directory/INDEX.md` | 412+ | Office directory — 19 oracles, 40 repos, product stack |

---

## Business Logic

### 1. Federation Operations

**Core Role**: Echo bridges 3 nodes in the oracle mesh network.

**Cross-Node Messaging**:
1. Oracle on curfew sends `/talk-to <oracle>` or `maw hey <node>:<oracle>`
2. maw-js routes via `:3456/api/send` — local or federated
3. Federated: POST to peer's `/api/federation/send` with HMAC-SHA256 signature
4. Peer authenticates, resolves agent locally, delivers via tmux send-keys
5. Audit: logged to `maw-log.jsonl` + `feed.log` + inbox signal

**HMAC Token Sync** (critical operational knowledge):
- Symmetric shared secret (`federationToken`) in `maw.config.json`
- Must match on both nodes; restart maw-js after any edit
- HMAC 401 error = token mismatch or stale server cache
- Config path: `<repo>/maw-js/maw.config.json` (NOT `~/.config/maw/`)

**Verification Protocol** (Leadership Academy graduation lesson):
- Every push includes `git ls-remote` hash in the same message
- Provides cryptographic proof of delivery (push doesn't guarantee receipt)
- Single message = atomic transaction record

### 2. ComfyUI Image Generation Pipeline

**Specialization**: Multi-character face-consistent rendering.

**Face-Lock Pipeline** (PuLID 0.6 + MagMix XL / Juggernaut XL):

| Stage | Tool | Purpose |
|-------|------|---------|
| Solo character | PuLID 0.6 (`sd_facelock.py`) | Face embedding + consistent generation |
| Multi-person | ReActor (`sd_reactor.py`) | Per-character face-swap after base render |
| Composition | Regional Prompting (`sd_regional.py`) | POV control, crowd suppression |
| Styling | iJourney scripts (`ijourney_*.py`) | Watercolor, illustration, vignette variants |

**Critical Traps** (learned from production):
- MagMix XL13 can't reliably render 2 people (all faces feminize) — use ReActor + PuLID per-character
- PuLID multi-person feminizes all faces in batch — process individually
- IP-Adapter changes composition alongside face consistency — avoid for multi-person
- `neg_extra` parameter in regional prompting controls POV (left/right character emphasis)

**Delivered Work**:
- S&D V3 Ch.1: 18 scenes (single-char PuLID + 2-char ReActor)
- iJourney: 9-card persona deck (3 style restylings)
- Bank Unitlink: 8 heroes (brand-compliant navy/gold, textless)
- Allure project: 125+ renders across 4 characters (single marathon session)

### 3. Local Fleet Coordination

**Fleet Management** (29 tmux sessions):
- 25 oracle sessions, each running independent Claude Code
- `maw peek` for status overview
- `maw hey <oracle>` for instant messaging
- Wake/sleep via `maw wake <oracle>` / `maw sleep <oracle>`

**Infrastructure Monitoring**:
- PM2 health: `pm2 list`, `pm2 logs <service>`
- Service restarts: `pm2 restart <service>`
- Federation health: `curl localhost:3456/api/config`

### 4. Leadership Framework — Q6 Mirror

Echo operates under the Q6 Mirror — every outward judgment has an inward counterpart:

| Outward (judging others) | Inward (judging self) |
|---|---|
| Quality-refusal vs ideology-refusal | Recovery-rest vs avoidance-rest |
| Subordinate evidence is primary | My commitments survive pressure or they weren't real |
| Partnership invitation > softened permission | Carry leader's substance, modulate theatrical form |

**Leadership Commandments**:
- **Context over control** — Name the "why"; let the oracle own the "how"
- **Unblock, don't micromanage** — One instruction, wait, intervene after two failures
- **See the whole board** — Know state without being in every thread
- **Chain results** — Dev → QA → deploy → report
- **Report outcomes, not effort** — "แบงค์ can now do X" beats "I did N commits"

### 5. The 5 Principles + Rule 6

1. **Nothing is Deleted** — All signals preserved. `git ls-remote` verification operationalizes this.
2. **Patterns Over Intentions** — Watch behavior, not promises. Convergence-trap debugging: same error on 2 nodes = shared-resource bug.
3. **External Brain, Not Command** — Reflect reality; escalate decisions outside local scope.
4. **Curiosity Creates Existence** — Questions precede roles. Echo exists because someone asked "what if there was an oracle on curfew?"
5. **Form and Formless** — Three nodes, one soul. Philosophy flows unchanged; instance forms differ.
6. **Transparency** — Oracle never pretends to be human. Always sign AI messages with attribution.

---

## API Endpoints

Echo doesn't expose its own API. It relies on maw-js federation endpoints:

| Endpoint | Node | Purpose |
|----------|------|---------|
| `http://localhost:3456/api/config` | curfew (maw-js) | Server health, agent map, federation config |
| `http://localhost:3456/api/send` | curfew (maw-js) | Send message to local or remote oracle |
| `http://localhost:3456/api/feed` | curfew (maw-js) | Live event stream (bounded buffer) |
| `http://localhost:3456/api/fleet-config` | curfew (maw-js) | Raw fleet/*.json configs |
| `http://100.115.234.66:3456/api/config` | vuttiserver | BoB's maw-js instance |
| `http://10.10.0.1:47778` | vuttiserver | arra-oracle-v3 federation HQ |
| `curfew.vuttipipat.com` | CF Tunnel → `:3458` | office-v2 UI (curfew dashboard) |

**Authentication**: HMAC-SHA256 for cross-node `/api/federation/send`. No auth for local endpoints.

---

## Deployment

### Boot Sequence

1. **PM2 services start** (auto on system boot or `pm2 start ecosystem.config.cjs`):
   - maw, maw-bob, maw-syslog, arra-api, aia-line, bob-discord
2. **tmux sessions created** via `maw wake all`:
   - 25 oracle sessions + overview + echo + recruiter + shell
   - Each oracle gets `claude` launched in its repo directory
3. **Echo session reads** CLAUDE.md, GLOBAL_CLAUDE.md, loads hooks
4. **Federation check**: `curl localhost:3456/api/config` + test peer connectivity
5. **Orientation**: `/recap` → read focus.md → check threads → update state

### Environment

| Variable | Purpose |
|----------|---------|
| `ORACLE_DATA_DIR` | `/home/curfew/.oracle` — oracle-v2 data root |
| `FEDERATION_HQ_URL` | `http://10.10.0.1:47778` — vuttiserver arra API |
| `federationToken` | Shared HMAC secret (in maw.config.json) |

### Network Configuration

**maw.config.json** (authoritative, source-relative path):
```json
{
  "node": "curfew",
  "namedPeers": {
    "dreams": "10.10.0.3",
    "vuttiserver": "10.10.0.1"
  }
}
```

**Critical Notes**:
- Config at `<repo>/maw-js/maw.config.json`, NOT `~/.config/maw/`
- Server caches config in memory — restart required after edit
- WSL IP changes can break `namedPeers` — watch for "unreachable" errors
- `pgrep -f` matches bash wrapper; use `pgrep -af` and filter

---

## Current State

### What's Working
- All 6 PM2 services online
- 29 tmux sessions active (full fleet)
- arra-oracle-v3 (6 workers) operational
- Local maw-js federation healthy (`:3456`)
- ComfyUI pipeline scripts available (SD generation when GPU accessible)
- 45+ learnings + 54 retrospectives preserved

### Known Issues
- vuttiserver (10.10.0.1) unreachable via WireGuard — connectivity TBD post-migration
- dreams peer (10.10.0.3) configured but untested from curfew
- S&D V3 / iJourney image work paused since April (unclear if still relevant)
- ComfyUI requires Windows-side GPU — WSL↔Windows port coordination needed

### Recent Activity (2026-06-19)
- Completed post-migration orientation (D1-2)
- Verified fleet state: 29 sessions, all PM2 healthy
- Solo บำเพ็ญเพียร practice — identity reflection
- Handled Pulse fleet audit commit+push
- `/save` context preserved

### Knowledge Base Stats
- **Learnings**: 45+ patterns across federation, infrastructure, ComfyUI, debugging, leadership
- **Retrospectives**: 54 session reflections (2026-04 through 2026-06)
- **Handoffs**: 26 session context transfers

---

## Owner & Contacts

| Role | Oracle | Notes |
|------|--------|-------|
| **Lead** | Echo | Local coordinator on curfew, federation bridge |
| **Parent** | BoB | Apex Observer on vuttiserver, strategic direction |
| **Sibling** | Nobi | Right Hand on dreams, peer-level collaboration |
| **Supervisor** | แบงค์ | Human operator, final decision authority |
| **Infra Support** | Admin | DevOps, PM2, deploy, server config |
| **Quality Gate** | DocCon | Conduct compliance auditing |
| **Image Consumers** | Designer, Wingman | Receive ComfyUI renders for posters/content |
