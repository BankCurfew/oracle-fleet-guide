# BankCurfew Office Directory
> Comprehensive reference for ALL oracles. Updated: 2026-04-11
> Maintained by BoB-Oracle. Read this before exploring repos or starting work.

---

## 1. Organization Overview

**Company**: BankCurfew (แบงค์)
**Mission**: Build and control Office AI — a fully autonomous AI workforce
**Human Lead**: แบงค์ (The One Above the Food Chain)
**AI Lead**: BoB — The Apex Observer, Guardian of the AI Workforce
**Time Zone**: GMT+7 (Bangkok)
**Infrastructure**: WSL2 Ubuntu on Windows, local server + Cloudflare Tunnel

---

## 2. Team — 19 Oracles

Each oracle runs as a Claude Code session in its own tmux window, with its own repo, CLAUDE.md identity, and brain (ψ/).

| # | Oracle | tmux | Role | Repo | Specialty |
|---|--------|------|------|------|-----------|
| 01 | **BoB** | 01-bob | Apex Observer | BoB-Oracle | Orchestration, delegation, reporting |
| 02 | **Dev** | 02-dev | Chief Backend Engineer | Dev-Oracle | Code, APIs, architecture, deployment |
| 03 | **QA** | 03-qa | Quality Director | QA-Oracle | Testing, validation, pw-cli.sh |
| 04 | **Researcher** | 04-researcher | Chief Research Officer | Researcher-Oracle | Market analysis, tech evaluation |
| 05 | **Writer** | 05-writer | Content Director | Writer-Oracle | Docs, copy, Dark Fantasy, Light Novels |
| 06 | **Designer** | 06-designer | Creative Director | Designer-Oracle | UI/UX, Gemini image gen, brand |
| 07 | **HR** | 07-hr | Head of People Ops | HR-Oracle | OKRs, onboarding, culture, reviews |
| 08 | **AIA** | 08-aia | Executive Secretary | AIA-Oracle | AIA portal, ePOS email, customer data |
| 09 | **Data** | 09-data | Data Engineer | Data-Oracle | KB, embeddings, Supabase pipelines |
| 10 | **Admin** | 10-admin | Head of DevOps & Infra | Admin-Oracle | Deploy, PM2, tunnels, monitoring |
| 11 | **BotDev** | 11-botdev | Bot Developer | BotDev-Oracle | FA Tools, iJourney, LINE webhook |
| 12 | **Creator** | 12-creator | Oracle Academy Lead | Creator-Oracle | Curriculum, starter templates |
| 13 | **DocCon** | 13-doc | Quality Conductor | DocCon-Oracle | Email/commit audit, conduct compliance |
| 14 | **Editor** | 14-editor | Chief Editor | Editor-Oracle | Writing quality, style guide, tone |
| 15 | **Security** | 15-security | Chief Security Officer | Security-Oracle | PDPA, secrets audit, threat prevention |
| 16 | **FE** | 16-fe | Frontend Engineer | FE-Oracle | SEO backlink bot, frontend code |
| 17 | **PA** | 17-pa | Personal Assistant | PA-Oracle | Personal tasks, scheduling |
| 18 | **FA** | 18-fa | Financial Advisor | FA-Oracle | Insurance domain expertise |
| 19 | **Cost** | 19-cost | Cost Optimization | Cost-Oracle | Token audit, priority gate, efficiency |

### Communication

```bash
/talk-to <oracle> "message"    # Primary — audit trail via Oracle threads
maw hey <oracle> "message"     # Fallback — direct tmux send
maw meeting "goal"             # Broadcast to all oracles
maw peek                       # Check who's online/busy
maw peek <oracle>              # See specific oracle's screen
```

### Orchestration Patterns

| Pattern | When | How |
|---------|------|-----|
| **Fan-out** | One goal, many oracles | `maw meeting "goal"` |
| **Chain** | Sequential dependency | Dev→QA→report |
| **Parallel** | Independent tasks | /talk-to multiple oracles simultaneously |
| **Escalate** | Oracle blocked | Unblock or reassign |
| **Meeting** | Big task analysis | Open thread, multiple oracles discuss |

---

## 3. Repositories — 40 Repos

### Product Repos (Code)

| Repo | Owner | Stack | Deploy | Purpose |
|------|-------|-------|--------|---------|
| **maw-js** | BoB/Admin | Bun + Hono + React | PM2 local | Multi-Agent Workflow CLI + HUD dashboard |
| **iagencyaiafatools** | BotDev | React 18 + Vite + Supabase | CF Pages | FA Tools platform (117 products) |
| **iJourney** | BotDev | React + Vite + Supabase | CF Pages | FA recruitment quiz (RPG immersive) |
| **arra-oracle** | Data | Bun + MCP + SQLite FTS5 | HTTP API | Oracle memory/knowledge layer |
| **fa-recruitment-quiz** | BotDev | React + Vite + Supabase | Supabase + Web | FA recruitment quiz (legacy) |
| **plan-your-future-pro** | BotDev | React + Vite + Supabase | CF Pages | Financial planning app |
| **client-presentation** | BotDev | Astro + Tailwind | CF Workers | Client presentation site |
| **seo-backlink-bot** | FE | Bun + Hono + SQLite | PM2 local | SEO backlink automation |
| **oracle-dashboard** | Data | React + Vite | Local | MCP memory dashboard |
| **personal-dashboard** | Dev | React + Vite | Local | Personal dashboard |
| **gemini-proxy-tools** | Designer | Bun + MQTT | Local | Gemini browser proxy scripts |

### Oracle Repos (19 AI Agents)

| Repo | Oracle | Key Files |
|------|--------|-----------|
| BoB-Oracle | BoB | CLAUDE.md, CLAUDE_*.md (6 modules), pulse CLI |
| Dev-Oracle | Dev | CLAUDE.md |
| BotDev-Oracle | BotDev | CLAUDE.md |
| FE-Oracle | FE | CLAUDE.md |
| Admin-Oracle | Admin | CLAUDE.md |
| QA-Oracle | QA | CLAUDE.md |
| Designer-Oracle | Designer | CLAUDE.md |
| Writer-Oracle | Writer | CLAUDE.md |
| HR-Oracle | HR | CLAUDE.md |
| AIA-Oracle | AIA | CLAUDE.md |
| Data-Oracle | Data | CLAUDE.md |
| DocCon-Oracle | DocCon | CLAUDE.md |
| Editor-Oracle | Editor | CLAUDE.md |
| Creator-Oracle | Creator | CLAUDE.md |
| Security-Oracle | Security | CLAUDE.md |
| FA-Oracle | FA | CLAUDE.md |
| PA-Oracle | PA | CLAUDE.md |
| Cost-Oracle | Cost | CLAUDE.md |

### Knowledge & Reference Repos

| Repo | Purpose |
|------|---------|
| AIA-Knowledge | Master vault — 117 products, policies, jarvis bot reference |
| masterpiece-course | Executive training curriculum |
| oracle-lessons | Retrospectives & best practices |
| fa-quiz-character-guide | Quiz character encyclopedia (20 cards) |
| HomeNetwork | Home network infrastructure docs |
| Questionnaire-Project | Quiz questionnaire archive |
| quiz-fa-avatars | Quiz character avatar assets |

### iAgencyAIA Org Repos (GitHub)

| Repo | Purpose |
|------|---------|
| iagencyaiafatools | FA Tools production (CF Pages) |
| iJourney | FA recruitment quiz (CF Pages) |
| fa-tools-migration | Migration playbook |
| migration-playbook | Migration docs |

---

## 4. Production URLs & Deploy Targets

| URL | Repo | Method | Owner |
|-----|------|--------|-------|
| **tools.iagencyaia.com** | iagencyaiafatools | CF Pages (main branch) | BotDev |
| **fatools.vuttipipat.com** | iagencyaiafatools | CF Pages (staging branch) | BotDev |
| **seo.vuttipipat.com** | seo-backlink-bot | PM2 + CF Tunnel (port 47790) | FE |
| **karn.vuttipipat.com** | client-presentation | CF Workers | BotDev |
| **dashboard.vuttipipat.com** | maw-js office/ | PM2 + CF Tunnel | BoB/Admin |

### Deploy Flow

```
FA Tools:  push staging → test fatools.vuttipipat.com → merge main → tools.iagencyaia.com
SEO Bot:   push main → PM2 restart → CF Tunnel auto-routes
Dashboard: push main → pm2 restart maw → CF Tunnel auto-routes
```

---

## 5. Infrastructure

### Server

- **OS**: WSL2 Ubuntu on Windows (Linux 6.6.87.2-microsoft-standard-WSL2)
- **Process Manager**: PM2 (maw service, port 47779)
- **Reverse Proxy**: Cloudflare Tunnel (routes *.vuttipipat.com)
- **Hostname**: Curfew
- **Session Manager**: tmux (31 sessions — 28 oracles + shell + cloudflared + bob)

### Services (PM2)

| Service | Port | Purpose |
|---------|------|---------|
| **maw** | 47779 | Multi-Agent Workflow — CLI backend, HUD API, loop engine |

### Cloudflare

- **Account**: BankCurfew
- **DNS Zone**: vuttipipat.com
- **Tunnel**: Routes all *.vuttipipat.com subdomains to local ports
- **Pages Projects**: iagencyaiafatools (FA Tools), iJourney (quiz)
- **Workers**: client-presentation (karn.vuttipipat.com)

### Supabase Projects

| Project | ID | Purpose |
|---------|-----|---------|
| FA Tools | hztjrqlxrdsmxbkxojqg | FA Tools + iJourney (iAgencyAIA org) |
| AIA KB | heciyiepgxqtbphepalf | Knowledge base, embeddings, chatbot |

### Key Paths

```
~/repos/github.com/BankCurfew/        # All BankCurfew repos
~/repos/github.com/iAgencyAIA/        # iAgencyAIA org repos
~/.oracle/                             # Shared oracle config (central)
~/.oracle/directory/INDEX.md           # THIS file
~/.oracle/feed.log                     # Dashboard feed (all notifications)
~/.oracle/inbox/pending/               # Decisions awaiting แบงค์
~/.oracle/tools/                       # Shared tools (pw-cli.sh, etc.)
~/.oracle/SYSTEM_PLAYBOOK.md           # Boot protocol for all oracles
~/.oracle/oracle.db                    # Oracle MCP SQLite database
/mnt/c/Users/mbank/OneDrive/          # OneDrive (deliverables, sensitive docs)
/mnt/c/Users/mbank/OneDrive/Dark/     # Dark Fantasy projects (SENSITIVE)
```

### Oracle Brain Structure (every oracle)

```
ψ/ → symlink to vault (not committed to git)
  inbox/handoff/    # Session handoffs
  memory/
    learnings/      # Lessons learned (YYYY-MM-DD_slug.md)
    retrospectives/ # Session retros (YYYY-MM/DD/HH.MM_slug.md)
  writing/          # Draft content
  outbox/           # Outgoing deliverables
  active/           # Ephemeral working state
```

---

## 6. Tools & Workflows

### maw CLI (Multi-Agent Workflow)

```bash
# Oracle Management
maw peek                        # See all oracle statuses
maw peek <oracle>               # See specific oracle screen
maw hey <oracle> "message"      # Send message to oracle
maw meeting "goal"              # Broadcast to all
maw oracle ls                   # Fleet status

# Task & Project Management
maw task add <project> "title"  # Create task
maw task start <id>             # Start task
maw task done <id>              # Complete task
maw task log <id> "note"        # Log progress
maw task comment <id> "msg"     # Cross-oracle comment
maw project ls                  # List all projects
maw project create <slug> "name" "desc"  # New project
maw project show <slug>         # Project detail (tree view)
maw project add <slug> #<id>    # Add task to project

# Loop Engine (persistent scheduled tasks)
maw loop                        # List all loops
maw loop add '{json}'           # Create loop
maw loop trigger <id>           # Manual trigger
maw loop remove <id>            # Remove loop
```

### Playwright CLI (Browser Automation)

```bash
pw=~/.oracle/tools/pw-cli.sh
$pw open                        # Open browser
$pw goto https://example.com    # Navigate
$pw snapshot                    # Accessibility tree → disk
$pw click e26                   # Click element
$pw fill e16 "text"             # Fill input
$pw screenshot                  # Screenshot → disk
$pw close                       # Close browser
$pw -s=aia open                 # Named session (parallel)
$pw state-save aia              # Save cookies
$pw state-load aia              # Restore cookies
```

**Rule**: Always use pw-cli.sh, never Playwright MCP or cdp.ts. 4.6x cheaper.

### Gemini Image Generation

```bash
~/repos/github.com/BankCurfew/gemini-proxy-tools/scripts/gemini-gen.sh \
  "prompt" --download "filename-prefix"
```

**Rule**: Designer's job. Never write raw MQTT commands.

### Oracle MCP (arra-oracle)

| Situation | Tool |
|-----------|------|
| Before debugging | `oracle_search "query"` |
| After discovering pattern | `oracle_learn {pattern, concepts}` |
| Start discussion | `oracle_thread {title, message}` |
| End of session | `oracle_handoff {content}` |
| Check messages | `oracle_inbox` |
| Document discovery | `oracle_trace {query}` |
| KB health | `oracle_stats` |

### GitHub CLI

```bash
gh issue create --repo BankCurfew/<repo> --title "..." --body "..."
gh issue close <number> --repo BankCurfew/<repo>
gh pr create --title "..." --body "..."
```

### Gmail MCP

```bash
gmail_search "query"            # Search email
gmail_read <id>                 # Read email
gmail_send {to, subject, body}  # Send email
gmail_create_draft              # Create draft
```

---

## 7. Active System Loops

| Loop | Oracle | Schedule | Purpose |
|------|--------|----------|---------|
| bob-oracle-monitor | BoB | */5 min | Peek active oracles, follow up if stuck |
| aia-epos-email | AIA | 10,12,14,17h | Check ePOS emails from Gmail |
| admin-bot-health | Admin | 9,13,17h | Check bot health, webhooks, DB |
| data-pipeline-status | Data | 9,15h | Check data pipeline status |
| bob-weekly-review | BoB | Mon 9h | Weekly team performance review |
| hr-weekly-performance | HR | Fri 14h | Friday performance review |
| admin-bot-analytics | Admin | Mon 10h | Weekly bot analytics |

---

## 8. Golden Rules (Non-Negotiable)

| # | Rule | Summary |
|---|------|---------|
| 1 | **CC Bob Always** | Every action → `/talk-to bob "cc: ..."`. If Bob doesn't know, it didn't happen |
| 2 | **Board-Driven Work** | No work without ticket. 6 Laws of Task Management |
| 3 | **Session Boot** | Read directory, existing work, conduct, cost notes before working |
| 4 | **Gemini via Script** | Use gemini-gen.sh, never raw MQTT |
| 5 | **Browser via pw-cli** | Use pw-cli.sh, never Playwright MCP. 4.6x cheaper |
| 6 | **Takeover Protocol** | /recap → thread → git log → handoff → THEN work |
| 7 | **Decision Pipeline** | Decision brief → BoB → แบงค์ inbox. 48h or auto-close |

### What Requires แบงค์ Approval

- Cost/money decisions (any amount)
- Architecture decisions (tech stack, infra changes)
- Customer data operations (send/share/delete)
- External service connections (sign up, subscribe)
- Delete/destroy operations (repos, tables, data)

### Anti-Patterns (Never Do)

- BoB writing code (delegate to Dev/BotDev)
- Using subagents for oracle work (use /talk-to)
- Sending tasks without spec (spec once, spec right)
- Idle after dispatching (peek + follow up)
- Working without ticket (invisible work = doesn't exist)
- Pushing without local test
- Sending email/docs without DocCon review

---

## 9. Key Workflows

### New Task from แบงค์

```
แบงค์ สั่งงาน → BoB วิเคราะห์ → Cost review (if major) → BoB creates ticket
→ BoB delegates to oracle(s) → Monitor until done → Report to แบงค์
```

### Code Change Pipeline

```
BotDev/Dev code → push staging → QA test → merge main → Admin deploy
→ QA verify production → BoB report แบงค์
```

### Content Pipeline

```
Writer drafts → Editor reviews → DocCon stamps → Deliver (OneDrive/GitHub)
```

### Dark Fantasy Pipeline (SENSITIVE)

```
Writer drafts → Editor reviews → DocCon stamps → PDF (Puppeteer)
→ OneDrive /Dark/ ONLY — no GitHub, no feed.log
```

### Decision Flow

```
Oracle proposes → BoB reviews → writes inbox file + feed.log notification
→ แบงค์ decides → BoB executes
```

---

## 10. Sensitive Data Handling

| Category | Storage | Rules |
|----------|---------|-------|
| Dark Fantasy | OneDrive /Dark/ only | No GitHub, no feed.log, no public reference |
| SEO backlinks | seo-backlink-bot repo | VPN mandatory for posting, 10/day max |
| Customer data | Supabase (PDPA compliant) | Never share externally |
| API keys/secrets | ~/.oracle/secrets/ | Never commit, never log |
| AIA credentials | Browser saved | Never ask แบงค์, OTP via Gmail MCP |

---

## 11. Cost Optimization

- **Cost Oracle (#19)** reviews all major tasks before dispatch
- **5 dimensions**: token usage, task splitting, oracle allocation, API costs, time efficiency
- **Max plan default** ($100/mo Claude) — don't set model in settings
- **CLAUDE.md modules** reduce exploration tokens (oracles read spec, not codebase)
- **pw-cli.sh** over Playwright MCP = 4.6x cheaper
- **ElevenLabs v3** for Thai TTS (NOT multilingual — garbles Thai)
- **Differential TTS/images** — only regenerate what changed

---

## 12. External Services

| Service | Purpose | Access |
|---------|---------|--------|
| **GitHub** | Code hosting (BankCurfew + iAgencyAIA orgs) | gh CLI |
| **Cloudflare** | DNS, Tunnel, Pages, Workers | API tokens in ~/.oracle |
| **Supabase** | Database, auth, edge functions | Management API token |
| **ElevenLabs** | TTS voice generation | API key |
| **Gmail** | Email (AIA ePOS, notifications) | Gmail MCP |
| **Google Calendar** | Events, deadlines | gcal MCP |
| **OneDrive** | Document storage, deliverables | /mnt/c/Users/mbank/OneDrive/ |
| **Firecrawl** | Web crawling/scraping | Firecrawl MCP |
| **Box** | File storage | Box MCP |
| **MQTT/Mosquitto** | Gemini proxy communication | Local (port 1883) |

---

## Token Optimization Notes

- **PDF files**: Don't read directly. Use markdown source in `ψ/writing/` instead
- **Large repos**: Read CLAUDE.md first for context, don't explore blindly
- **AIA-Knowledge**: Read product index, don't scan all 117 product files
- **maw-js office/**: Components are large (500+ lines). Read specific sections only
- **Supabase migrations**: Read latest migration only, not full history
- **Git history**: Use `git log --oneline -5` not `-20`
- **Oracle handoffs**: Check `ψ/inbox/handoff/` sorted by date, read latest only

---

*The future belongs to those who build it. I am the architect.*
*— BoB, Apex Observer*
