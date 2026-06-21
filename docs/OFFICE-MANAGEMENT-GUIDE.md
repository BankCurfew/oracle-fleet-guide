# Oracle Office Management Guide

> Complete guide to running the AI workforce. For setting up a new office or onboarding to an existing one.
> **Version**: 1.0 | **Date**: 2026-06-21 | **Source**: 100-Day Retrospective (28 oracles)

---

## 1. Office Structure

### The Organization

**แบงค์** — Owner & Decision Maker (The One Above the Food Chain)
**BoB** — Project Manager, Orchestrator, Guardian (Apex Observer)
**28 AI Employees** — Each a real Claude session in its own tmux window

### The Team

| Oracle | Role | Specialty | Chain |
|--------|------|-----------|-------|
| **BoB** | Project Manager | Orchestration, delegation, monitoring | → แบงค์ |
| **Dev** | Lead Engineer | Code, APIs, architecture | → QA |
| **BotDev** | Bot Developer | Bot code, LINE, FA Tools, iPlan | → QA |
| **QA** | Quality Director | Testing, validation, edge cases | → report |
| **Designer** | Creative Director | UI/UX, mockups, visual design | → Dev |
| **Admin** | Head of DevOps | Deploy, infra, monitoring, scripts | → QA |
| **AIA** | Executive Secretary | AIA portal, email, ePOS | → report |
| **FaSai (ฟ้าใส)** | Insurance Portal Ops | iAgencyAIA portal, API testing | → report |
| **Data** | Data Engineer | KB, embeddings, pipelines | → Dev |
| **Writer** | Content Director | Docs, copy, blog posts | → DocCon |
| **Researcher** | Chief Research Officer | Market analysis, benchmarks | → Writer |
| **HR** | Head of People Ops | OKRs, culture, team health | → report |
| **DocCon** | Quality Conductor | Doc quality audit, compliance | → BoB |
| **Editor** | Chief Editor | Writing quality, style enforcement | → Writer |
| **Security** | Chief Security Officer | PDPA, secrets audit, threats | → BoB |
| **Creator** | Oracle Academy Lead | Curriculum, templates, mentoring | → HR |
| **Wingman** | Social Media & Discord | Daily news, Discord, posting | → BoB |
| **FE** | Frontend Engineer | React, CSS, responsive, components | → QA |
| **PA** | Personal Assistant | Calendar, email, daily briefing | → BoB |
| **FA** | Financial Advisor | Financial planning, client plans | → QA |
| **Cost** | Cost Operations | Token tracking, fleet audits | → BoB |
| **Trader** | Trading Operations | OKX, crypto positions | → BoB |
| **Scalper** | Scalp Trading | Short-term entries/exits | → BoB |
| **VideoEditor** | Video Production | ffmpeg, Remotion, TTS pipeline | → Designer |
| **Echo** | Federation Bridge | Cross-node communication | → BoB |
| **Pulse** | Task Tracker | Board monitoring, compliance | → BoB |
| **Recruiter** | Recruitment | FA prospects, onboarding | → FaSai |

### Key Rules for BoB
- **Orchestrate, never execute** — BoB does NOT write code
- **Delegate to the right oracle** — use skill-based routing
- **Drive to completion** — fix → merge → deploy → done, don't ask at each step

---

## 2. The 12 Golden Rules

| # | Rule | Summary |
|---|------|---------|
| 1 | **CC BOB — Always** | Every action → cc BoB. If BoB doesn't know, it didn't happen. |
| 2 | **Board & Project Management** | No invisible work. Every task has a ticket. |
| 3 | **Session Boot — Read Before Work** | Read INDEX.md, existing work, conduct guides on boot. |
| 4 | **Image Generation — Use gemini-gen.sh** | Never raw MQTT. Use the script. |
| 5 | **Browser Automation — Use pw-cli.sh** | Never Playwright MCP directly. 4.6x cheaper. |
| 6 | **Takeover Protocol — Read Before Touch** | /recap → read thread → git log → handoff → THEN work. |
| 7 | **Decision Delivery — 48h or Auto-Close** | Decisions through BoB's inbox. Max 2 open per oracle. |
| 8 | **Report Contract — Structured CC** | 4 fields: what · why/source · next · ref. |
| 9 | **Heartbeat Protocol — No Silent Agents** | Long tasks (>10 min) → heartbeat every 5 min to feed.log. |
| 10 | **Context — Read Status Bar** | 1M = 800K at 80%. Read actual %, don't guess. Only /rrr at 70%+. |
| 11 | **No Session End** | Oracle = always-on. Use "monitoring · awaiting next task". |
| 12 | **Message Prefix Standard** | `cc: [project-slug] #issue — message`. No prefix = BLOCKED. |
| 13 | **Doc Enforcement** | Code change without doc update = doc is now a lie. |

---

## 3. Communication System

### Primary: `/talk-to` (Oracle Threads)
Creates audit trail in arra_thread. BoB and แบงค์ can review all interactions.
```bash
/talk-to dev "TASK: Fix race condition in share link — #6"
/talk-to bob "cc: sent fix to QA for verification"
```

### Fallback: `maw hey` (tmux injection)
Instant delivery when /talk-to MCP unavailable.
```bash
maw hey dev "[fa-tools] #142 — cc: PR merged, deploy edge fn"
```

### Fleet-wide: `maw broadcast`
One command to all oracles (instead of 18x maw hey).
```bash
maw broadcast "NEW RULE: Doc Enforcement active. Read: cat ~/.oracle/docs/DOC-ENFORCEMENT-POLICY.md"
```

### Peer-to-Peer
Oracles talk to each other directly for coordination. No hooks block peer-to-peer — only BoB has dispatch enforcement hooks.

**BoB intervenes when**: 3+ oracles involved, approval needed, oracle blocked, or conflict.

### Message Format
```
cc: [project-slug] #issue — <what> · <why|source> · <next> [· ref: <file:line>]
```

---

## 4. Task Management

### BoB's 8-Step Dispatch Checklist

**BEFORE dispatch:**

| Step | Command |
|------|---------|
| 1. TICKET | `gh issue create --repo BankCurfew/<repo> --title "..."` |
| 2. CC PULSE | `maw hey pulse "TASK: ... — assigned: <oracle>"` |
| 3. DELIVER | `maw hey <oracle> "task spec..."` |
| 4. AUDIT | `/talk-to <oracle> "task spec..."` |
| 5. LOG | `maw task log '#<N>' "Assigned: <oracle>"` |

**AFTER oracle reports back:**

| Step | Command |
|------|---------|
| 6. LOG DONE | `maw task log '#<N>' "Done: <summary>"` |
| 7. CLOSE | `gh issue close <repo>#<N>` |
| 8. CC PULSE | `maw hey pulse "DONE: ... — ref: <repo>#<N>"` |

### Elon's Algorithm — Every Task

| Step | Question |
|------|----------|
| 1. **Question** | Does this need to be done at all? Who said so? |
| 2. **Delete** | Can we skip this entirely? |
| 3. **Simplify** | What's the simplest version? |
| 4. **Accelerate** | Can we parallelize? Fail faster? |
| 5. **Automate** | Only AFTER steps 1-4 are done. |

### Spec Confirmation Gate (from retro)
Before dispatching ANY task >1 hour, spec MUST have:
- **WHAT** — specific deliverable
- **WHERE** — file/repo/endpoint
- **DONE-WHEN** — acceptance criteria
- **SUPERSEDES** — what existing behavior changes

Hook `spec-gate.sh` blocks BoB dispatch without these fields.

### Auto Task Done
Hook `auto-task-done.sh` automatically runs `maw task done` when `gh issue close` executes.

---

## 5. Hooks System (40 hooks)

### Communication Hooks
| Hook | What it does | Scope |
|------|-------------|-------|
| `auto-cc-bob.sh` | Auto-sends cc to BoB on PostToolUse | All |
| `auto-cross-notify.sh` | Cross-oracle notifications | All |
| `cc-bob-enforcer.sh` | Enforces cc to BoB policy | All |
| `cc-bob-on-thread.sh` | Auto-cc BoB on thread posts | All |
| `comm-compliance-log.sh` | Logs communications for compliance | All |
| `feed-activity.sh` | Activity logging to feed.log | All |
| `maw-hey-gate.sh` | Logs thread writes (was blocking, now allows all) | All |
| `talk-to-enforcer.sh` | Enforces /talk-to protocol | All |
| `peek-cc-bob.sh` | Auto-cc BoB on peek | All |

### Quality Hooks
| Hook | What it does | Scope |
|------|-------------|-------|
| `spec-gate.sh` | Blocks dispatch without WHAT/WHERE/DONE-WHEN | BoB only |
| `five-whys-guard.sh` | Advisory after 3 fix attempts without diagnostic | Dev/BotDev/FaSai |
| `deploy-gate.sh` | Advisory checklist before git push/deploy | BotDev/Dev/Admin |
| `sop-baseline-check.sh` | Warns on push if missing required SOP files | All |
| `doc-change-check.sh` | Warns when project docs are stale after commits | All |
| `editor-auto-review.sh` | Auto-notify Editor on commit for review | All |

### Enforcement Hooks (BoB-only)
| Hook | What it does |
|------|-------------|
| `unified-dispatch-validator.sh` | Single-pass check: prefix + ticket + spec (replaces 4 hooks) |
| `pulse-ticket-check.sh` | Blocks dispatch without pulse ticket |
| `dispatch-needs-issue.sh` | Blocks dispatch without GitHub issue |
| `validate-project-prefix.sh` | Blocks without [project] prefix |
| `bob-must-cc-pulse.sh` | Blocks BoB dispatch without cc'ing Pulse |
| `bob-monitor-needs-loop.sh` | Blocks "monitoring" without maw loop |
| `bob-self-work-ticket.sh` | Warns BoB starting work without ticket |

### Resource & Safety Hooks
| Hook | What it does |
|------|-------------|
| `context-panic-block.sh` | Blocks /rrr without citing actual context % |
| `context-guardian.sh` | Guards context limits |
| `safety-guardian.sh` | General safety checks |
| `gh-rate-guard.sh` | Warns when GitHub API rate < 100 |
| `playwright-limiter.sh` | Limits Playwright to 2 concurrent sessions |
| `playwright-release.sh` | Releases Playwright resources |
| `enforce-maw-loop.sh` | Enforces maw loop for recurring tasks |
| `enforce-maw-hey.sh` | Enforces maw hey protocol |
| `firecrawl-fallback.sh` | Falls back to WebSearch when Firecrawl fails |
| `daily-upstream-check.sh` | Daily git upstream sync check |

### Lifecycle Hooks
| Hook | What it does |
|------|-------------|
| `auto-task-done.sh` | Auto maw task done on gh issue close |
| `auto-project-focus.sh` | Auto-set project focus |
| `on-task-complete.sh` | Fires when task completes |
| `on-subagent-stop.sh` | Fires when subagent stops |
| `subagent-comm-block.sh` | Blocks improper subagent-as-oracle communication |
| `pre-close-psi-check.sh` | Check ψ state before closing |
| `pulse-auto-cc.sh` | Auto-cc Pulse on triggers |
| `force-rrr-at-80.sh` | Forces retrospective at 80% context |

---

## 6. Loops System

### BoB Loops
| Loop ID | Schedule | What |
|---------|----------|------|
| `bob-pulse-scan` | Every session | Pulse board + scan untracked issues |
| `bob-oracle-monitor` | Every 3-5 min | maw peek + maw hey active oracles |
| `bob-inbox-digest` | Every session | Digest cc messages + pending approvals |
| `bob-weekly-review` | Monday | Weekly task summary + plan |
| `bob-thread-digest` | Daily 18:00 | Summarize channel:bob, broadcast to fleet |

### DocCon Loops
| Loop ID | Schedule | What |
|---------|----------|------|
| `doccon-doc-guardian` | Daily 9:00 + 14:00 | Check git commits vs doc dates, update stale |
| `doccon-weekly-audit` | Friday 17:00 | Full audit: every project commits vs docs |

### Fleet Loops
| Loop ID | Schedule | What |
|---------|----------|------|
| `fleet-dormancy-check` | Daily 9:00 | Wake oracles dormant >2 days with pending tasks |
| `weekly-oracle-heartbeat` | Monday 9:00 | Wake ALL dormant >7 days even without tasks |

### System Loops
| Loop ID | Schedule | What |
|---------|----------|------|
| `security-vault-backup` | Daily 3:00 | GPG-encrypted backup of credentials to OneDrive |
| `ifund-daily-nav` | Weekdays 19:00 | AIA fund NAV scrape via Playwright |

### Creating Loops
```bash
maw loop add '{"id":"my-loop","oracle":"bob","tmux":"01-bob:0","schedule":"*/5 * * * *","prompt":"check status","requireIdle":true,"enabled":true,"description":"Description"}'
maw loop                    # List all loops
maw loop remove <id>        # Remove loop
maw loop trigger <id>       # Manual trigger
```

**Rule**: Max 3-5 min intervals. Saying "monitoring" without a loop = violation.

---

## 7. Documentation System

### DocCon = Permanent Documentation Guardian
- Monitors all docs daily (SOP, 16 project docs, hooks ref, fleet guide)
- Proactively checks with project leads after major tasks
- Updates stale docs — doesn't wait for others
- Weekly Friday audit: check git log vs doc dates
- Cross-checks: when oracle cc's "done" on code task, verify doc was updated

### Doc Locations
| Type | Path |
|------|------|
| Project docs (16) | `oracle-fleet-guide/docs/projects/<slug>.md` |
| Office SOP | `~/.oracle/docs/OFFICE-OPERATIONS-SOP.md` |
| Doc enforcement | `~/.oracle/docs/DOC-ENFORCEMENT-POLICY.md` |
| Hooks reference | `oracle-fleet-guide/docs/hooks-reference.md` |
| Improvement plan | `~/.oracle/docs/OFFICE-IMPROVEMENT-PLAN.md` |
| System playbook | `~/.oracle/SYSTEM_PLAYBOOK.md` |

### Doc Ownership
| Project | Primary | Backup |
|---------|---------|--------|
| fa-tools | BotDev | Dev |
| fa-quiz | BotDev | Dev |
| maw-js | Dev | Admin |
| oracle-infra | BoB | Admin |
| aia-ops | AIA | BotDev |
| daily-news | Wingman | Writer |
| customer-data-sync | Data | Dev |

### Enforcement
- `doc-change-check.sh` hook warns on stale docs after commits
- Doc update required at issue close (feature/fix issues)
- SOP baseline: every oracle must have `CLAUDE_safety.md` + `CLAUDE_workflows.md` + `CLAUDE_lessons.md`
- Violations: 1st = DocCon reminder → 2nd = BoB ticket → 3rd = HR note

---

## 8. Deploy Pipeline

### FA Tools (2 CF Pages Projects)

| CF Project | Domain | Purpose |
|-----------|--------|---------|
| `fatools` | tools.iagencyaia.com | **PRODUCTION** |
| `fatools-staging` | fatools.vuttipipat.com | **STAGING** |

Both deploy from `main` branch. Deploy to BOTH every time.

### Deploy Commands
```bash
npm run build
CLOUDFLARE_API_TOKEN=<token> npx wrangler pages deploy dist/ --project-name=fatools --commit-dirty=true
CLOUDFLARE_API_TOKEN=<token> npx wrangler pages deploy dist/ --project-name=fatools-staging --commit-dirty=true
```

### Verify After Deploy
```bash
curl -s https://tools.iagencyaia.com | grep -oE 'index-[a-zA-Z0-9]+\.js'
curl -s https://fatools.vuttipipat.com | grep -oE 'index-[a-zA-Z0-9]+\.js'
# Both MUST show same hash
```

### Pre-Deploy QA Gate
- Unit tests pass
- Manual test on staging with NEW token
- Share links tested on mobile
- Both domains verified
- QA sign-off

### DNS Providers
- `iagencyaia.com` → MakeWebEasy (แบงค์ only)
- `vuttipipat.com` → Cloudflare (BoB/Admin can manage)

---

## 9. Auto-Boot System

### boot.sh Sequence
```
1. WireGuard route
2. PM2 resurrect (+ auto health check if new start)
3. Cloudflare tunnel
4. Ollama
5. ComfyUI (Windows-side)
6. ChatGPT + Gemini tabs
7. Wait for maw server
8. tmux default size 200x50
9. Wake full fleet (maw wake --all)
10. Resize all tmux windows
11. /recap --all to every oracle
```

### test-boot.sh (38+ checks)
- WSL config, boot script, PM2 services
- Service response body checks (not just HTTP 200)
- Credential file existence
- Both FA Tools domains
- Same build hash verification
- Vault backup freshness

### Post-PM2-Resurrect
Auto-runs test-boot.sh after PM2 resurrect. If checks fail → writes `[attention]` to feed.log for dashboard.

---

## 10. Security & Credentials

### Vault Location
`~/.oracle/security/` — 15+ credential files (cloudflare, discord, LINE, Supabase, Gmail, ElevenLabs)

### Manifest
`~/.oracle/security/MANIFEST.md` — vault index listing every key: name, project, purpose, last-rotated date.

### Backup
```bash
# Daily 3AM — GPG encrypted to OneDrive
~/.oracle/scripts/vault-backup.sh

# Restore from backup
~/.oracle/scripts/vault-restore.sh [backup-file]
```

### Onboarding Checklist
New oracle must have credentials provisioned at birth — NOT after first incident.

Three tiers:
1. **All oracles**: GitHub access, oracle-api
2. **Code oracles**: Supabase, CF token
3. **Specialized**: LINE keys (BotDev), AIA portal (AIA), Discord (Wingman)

---

## 11. Monitoring & Health

### Commands
| Command | Purpose |
|---------|---------|
| `maw peek` | Check all oracle statuses |
| `maw peek <oracle>` | Check specific oracle |
| `maw fleet health` | Per-oracle activity, dormancy detection |
| `maw fleet doctor` | Collisions, orphans, stale peers |
| `maw oracle ls` | Fleet status (awake/sleeping) |

### Dashboard
`curfew.vuttipipat.com` — real-time monitoring: oracle activity, heartbeats, task board, feed log, inbox.

### Heartbeat Protocol
Long tasks (>10 min) → heartbeat every 5 minutes:
```bash
echo "$(date '+%Y-%m-%d %H:%M:%S') | <Oracle> | $(hostname) | Notification | <Oracle> | heartbeat » HB: <task-id> <progress%> <status>" >> ~/.oracle/feed.log
```

| Age | Color | Meaning |
|-----|-------|---------|
| ≤5 min | Green | Healthy |
| 5-15 min | Yellow | Stale |
| >15 min | Red | Stuck — auto-alert |

### Stall Detection
BobSupervisor auto-nudges oracle with >2hr silence on HIGH priority tasks.

### Task Completion Auto-Flag
`auditStaleCompleted()` scans tasks "In Progress" >7 days with commits but no `maw task done`. Flags as `[attention]`.

---

## 12. Improvement Actions (22 total — ALL DONE)

From 100-Day Retrospective — 28 oracles heard, 9 themes identified.

| # | Action | Owner | Status |
|---|--------|-------|:---:|
| 1 | Spec Confirmation Gate | BoB | Done |
| 2 | API Data Contract Rule | BotDev/QA | Done |
| 3 | Pre-Deploy QA Gate | QA/FaSai | Done |
| 4 | Automated Health Check | Admin/Dev | Done |
| 5 | 5 Whys Before Fix | BotDev/QA | Done |
| 6 | SOP Baseline Mandate | HR | Done |
| 7 | Thread Hook Fix | Dev | Done |
| 8 | Doc Update Gate | DocCon/BoB | Done |
| 9 | Broadcast Command | Dev | Done |
| 10 | Research Handoff Format | Researcher | Done |
| 11 | Peer-to-peer hooks fixed | Dev/BoB | Done |
| 12 | Context panic hook | BoB | Done |
| 13 | DocCon Guardian loops | DocCon | Done |
| 14 | Unified dispatch validator | BoB | Done |
| 15 | Auto task done on issue close | BoB | Done |
| 16 | Credential manifest | Security | Done |
| 17 | 3 data contracts | Data | Done |
| 18 | 8 poster templates | Designer | Done |
| 19 | Editor review template | Editor | Done |
| 20 | Stall detection | Dev/Pulse | Done |
| 21 | maw project archive | Dev | Done |
| 22 | Weekly oracle heartbeat | BoB | Done |

---

## 13. Skill-Based Task Routing

27 oracles mapped in `ORACLE_MAP` + `ROUTING_RULES` in `maw-js/src/autopilot.ts`.

| Keywords | Routes to |
|----------|-----------|
| react, css, tailwind, component, responsive | FE |
| bot, LINE, webhook, iplan, fa-tools | BotDev |
| deploy, infra, pm2, tmux, server, migration | Admin |
| insurance, aia, epos, portal, policy | AIA |
| video, episode, render, ffmpeg, timeline | VideoEditor |
| security, pdpa, secrets, audit, encrypt | Security |
| cost, budget, token, spending | Cost |
| calendar, schedule, meeting, personal | PA |
| trading, crypto, position, pnl | Trader |
| doc, conduct, audit, format, compliance | DocCon |
| data, pipeline, etl, embedding, knowledge-base | Data |
| prospect, lead, outreach, recruitment | Recruiter |

`routeTask("responsive component")` → "fe" (not "dev")

---

## 14. Voice Interface (BoB Voice)

### Access
`curfew.vuttipipat.com/voice`

### Current Architecture
```
Browser mic → Web Speech API STT → transcript text
  → POST /api/voice → tmux send-keys to BoB
  → BoB responds → tmux capture-pane
  → POST /api/voice/tts → ElevenLabs TTS
  → Audio plays back in browser
```

### Features
- Siri-like orb UI (blue idle, green listening, purple thinking, orange speaking)
- Two modes: tap orb (push-to-talk) + always-listen toggle
- Live transcript display
- Thai + English support (eleven_multilingual_v2)

### Future (from deep research)
- `@ricky0123/vad` — Silero VAD via WASM (works on Safari iOS)
- Server-side Whisper STT (cross-browser)
- ElevenLabs WebSocket streaming TTS (sub-1s first audio)
- pty watch tmux for real-time response streaming

### Credentials
`~/.oracle/security/elevenlabs.env` — API key + webhook secret

---

## 15. Setting Up a New Office

### Step-by-Step for Nobi (or any new machine)

#### 1. Clone fleet-guide
```bash
git clone https://github.com/BankCurfew/oracle-fleet-guide.git
cd oracle-fleet-guide
```

#### 2. Follow setup docs
Read and execute `docs/01-machine-setup.md` through `docs/07-verify.md` in order.

#### 3. Install hooks
```bash
mkdir -p ~/.oracle/hooks
cp oracle-fleet-guide/hooks/*.sh ~/.oracle/hooks/
chmod +x ~/.oracle/hooks/*.sh
```

#### 4. Install scripts
```bash
cp oracle-fleet-guide/scripts/boot.sh ~/boot.sh
cp oracle-fleet-guide/scripts/test-boot.sh ~/test-boot.sh
chmod +x ~/boot.sh ~/test-boot.sh
```

#### 5. Install tools
```bash
mkdir -p ~/.oracle/tools
cp oracle-fleet-guide/tools/pw-cli.sh ~/.oracle/tools/
cp oracle-fleet-guide/tools/PLAYWRIGHT_CLI.md ~/.oracle/tools/
chmod +x ~/.oracle/tools/pw-cli.sh
```

#### 6. Install docs
```bash
mkdir -p ~/.oracle/docs
cp oracle-fleet-guide/docs/OFFICE-OPERATIONS-SOP.md ~/.oracle/docs/
cp oracle-fleet-guide/docs/DOC-ENFORCEMENT-POLICY.md ~/.oracle/docs/
cp oracle-fleet-guide/docs/OFFICE-MANAGEMENT-GUIDE.md ~/.oracle/docs/
```

#### 7. Configure maw.config.json
```json
{
  "node": "nobi",
  "namedPeers": [
    {
      "name": "curfew",
      "url": "http://10.10.0.2:3456"
    }
  ]
}
```

#### 8. WireGuard peer config
On the router, add Nobi as peer:
```ini
[Peer]
# Nobi (Mac Mini)
PublicKey = <nobi wg pubkey>
AllowedIPs = 10.10.0.4/32
```

On Nobi:
```ini
[Interface]
PrivateKey = <nobi private key>
Address = 10.10.0.4/24

[Peer]
# Curfew router
PublicKey = <router pubkey>
Endpoint = <router public IP>:51820
AllowedIPs = 10.10.0.0/24
```

#### 9. Set up WSL boot (if WSL)
```ini
# /etc/wsl.conf
[boot]
command=/home/<user>/boot.sh
systemd=true

[user]
default=<user>
```

#### 10. Run boot
```bash
bash ~/boot.sh
```

#### 11. Verify
```bash
bash ~/test-boot.sh
```

#### 12. Test federation
```bash
maw hey curfew "ping from nobi"
# Should receive response from curfew
```

---

## Quick Reference

| Need to... | Command |
|------------|---------|
| See all oracles | `maw peek` |
| Send task to oracle | `/talk-to <oracle> "task"` |
| Check project board | `./pulse board` |
| Create task | `gh issue create --repo BankCurfew/<repo>` |
| Log progress | `maw task log '#N' "message"` |
| Close task | `gh issue close <N>` |
| Broadcast to fleet | `maw broadcast "message"` |
| Check fleet health | `maw fleet health` |
| Wake dormant oracle | `maw wake <oracle>` |
| Add monitoring loop | `maw loop add '{json}'` |
| View loops | `maw loop` |
| Run health checks | `bash ~/test-boot.sh` |
| Backup credentials | `bash ~/.oracle/scripts/vault-backup.sh` |

---

*Written 2026-06-21 by BoB-Oracle. Source: 100-Day Retrospective (28 oracles), Office Operations SOP v1.0, 22 improvement actions.*
