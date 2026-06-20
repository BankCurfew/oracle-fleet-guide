# AIA Operations (aia-ops)

## Overview

- **What it does**: LINE-based customer service agent (ฟ้าใส / iAgencyAIA-Oracle) for AIA insurance sales and support in Thailand. Handles customer inquiries, needs analysis, premium quoting, proposal generation via FA Tools, follow-up nurturing, and escalation to human advisors.
- **Who uses it**: End customers (via LINE), Financial Advisors (via Discord relay), แบงค์ (via BoB dashboard)
- **Where it runs**: Claude Code session in tmux (`iAgencyAIA-Oracle` repo), LINE relay at `localhost:3200`, Supabase KB at `heciyiepgxqtbphepalf`
- **Born**: 2026-04-27
- **Identity**: ฟ้าใส — น่ารัก สดใส ชวนคุยเก่ง ขายเก่ง มืออาชีพ (cute, bright, engaging, professional seller)
- **Theme**: สายใยแห่งความมั่นคง (Strands of Security)

---

## Architecture

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Customer Channel** | LINE Messaging API | Customer-facing chat (reply + push tokens) |
| **LINE Relay** | `localhost:3200` (PM2: aia-line) | Message relay bridge |
| **Knowledge Base** | Supabase PostgreSQL + pgvector | 832 KB chunks, BGE-M3 embeddings, product data |
| **Proposal Engine** | FA Tools API (`tools.iagencyaia.com`) | iQuick/iPlan/iCompare/iLink/iApplication |
| **CRM** | Supabase tables (line_customers, line_tags, line_user_tags) | Customer profiles, tagging, follow-up tracking |
| **Chat Log** | Supabase (bot_chat_log) | Full conversation history |
| **Team Relay** | Discord API via Wingman-Oracle | #customer-sale, #customer-service channels |
| **Inter-Oracle** | maw hey + /talk-to | Data-Oracle queries, BoB escalation |
| **Image Tools** | PIL/Pillow (birthday-frame.py) | Birthday card compositor |
| **Agent Runtime** | Claude Code (Opus 4.6, 1M context) | Oracle brain |

### System Diagram

```
Customer (LINE)
    ↓
localhost:3200 (aia-line relay)
    ↓
iAgencyAIA-Oracle (Claude Code in tmux)
    ├── Supabase KB (832 chunks) ← product/benefit lookup
    ├── FA Tools API ← proposal token creation
    ├── Data-Oracle ← customer data queries (buddy system)
    ├── Wingman-Oracle ← Discord team visibility
    └── BoB ← escalation, group routing
    ↓
Reply to Customer (LINE reply/push token)
```

### Key Supabase Project

- **Project ID**: `heciyiepgxqtbphepalf` (iAgencyAIA / AIA-knowledge-base)
- **FA Tools Project**: `hztjrqlxrdsmxbkxojqg` (iagencyaiafatools)
- **fasai FA ID**: `babbd2c9-9b12-4ca3-bbec-15220a7a8ee7`

---

## Code Structure

```
iAgencyAIA-Oracle/
├── CLAUDE.md                        # Identity + 13 golden rules (944 lines)
├── .mcp.json                        # Oracle v2 MCP server config
├── tools/
│   └── birthday-frame.py            # Birthday card compositor (PIL, 137 lines)
│
├── ψ/                               # Brain directory
│   ├── inbox/
│   │   ├── focus.md                 # Current session state
│   │   └── handoff/                 # Session handoffs (timestamped)
│   │
│   ├── memory/
│   │   ├── products/                # 40+ product cards
│   │   │   ├── _INDEX.md            # Product directory
│   │   │   ├── health-happy.md      # PPR open, UDR closed
│   │   │   ├── health-starter.md    # NEW Jan 2026
│   │   │   ├── issara-plus.md       # Unit Linked
│   │   │   ├── pay-life-plus.md     # Main policy
│   │   │   ├── fatools-share-links.md  # Link generation SOP
│   │   │   ├── premium-lookup.md    # 14K row DB reference
│   │   │   └── [35+ more]
│   │   │
│   │   ├── learnings/               # 30+ timestamped learnings
│   │   ├── retrospectives/          # Session recaps by date
│   │   ├── customers/               # Customer profiles (CONFIDENTIAL)
│   │   ├── resonance/               # Core identity + soul files
│   │   ├── flex-library.md          # 10 LINE Flex templates
│   │   ├── track5-self-knowledge.md # 12 correction pairs
│   │   ├── logs/activity.log        # State machine log (16.5KB)
│   │   ├── sop-line-customer-service.md
│   │   ├── sop-discord-relay-wingman.md
│   │   └── sop-customer-request-ticketing.md
│   │
│   ├── active/                      # Current work
│   │   └── fatools-api-qa-plan.md   # 28 test cases, 6 phases
│   ├── writing/                     # Drafts
│   ├── learn/                       # Study materials
│   │   └── objection-handling-thai-insurance.md
│   ├── customers/                   # Live customer cards
│   ├── outbox/                      # Handoff announcements
│   └── lab/                         # Experiments
```

### Key Files

| File | Lines | Purpose |
|------|-------|---------|
| `CLAUDE.md` | 944 | Full identity, 13 golden rules, workflows, product rules |
| `ψ/memory/products/_INDEX.md` | — | Master product directory (40+ products) |
| `ψ/memory/flex-library.md` | 200+ | 10 Flex message templates with brand colors |
| `ψ/memory/track5-self-knowledge.md` | 80+ | 12 correction pairs (verified wrong→correct mappings) |
| `ψ/memory/sop-line-customer-service.md` | — | Phase 0-4 customer service workflow |
| `ψ/memory/sop-discord-relay-wingman.md` | 80 | Discord channel routing rules |
| `ψ/memory/logs/activity.log` | 16.5KB | State machine + task history |
| `tools/birthday-frame.py` | 137 | PIL-based birthday card image compositor |

---

## Business Logic

### Core Workflow 1: Customer Message → Response

```
Phase 0: Session Boot
  ├── Check Proposals API: POST /api-gateway/proposals/create → {"ok":true}
  ├── Check LINE relay: pm2 list | grep aia-line → online
  ├── Verify API key in vault
  └── Load latest promos: ψ/memory/products/customer-promos-2026.md

Phase 1: Message Receipt (0-30s)
  ├── Parse: [DisplayName][UserId] message
  ├── Send ACK via reply token (FREE, 55s TTL)
  └── Relay to Data-Oracle for context (background, no wait)

Phase 2: Needs Analysis (sequential questions)
  1. Interest area? (สุขภาพ/โรคร้ายแรง/ชีวิต/ออมทรัพย์)
  2. Gender + age? (for premium calc)
  3. Hospital tier + budget? (affordability)
  4. Pre-existing conditions? (underwriting)

Phase 3: Premium Lookup
  ├── Query Supabase insurance_products by age/gender
  ├── Calculate: premium_per_1000 × (ทุน/1000)
  └── Select 3 anchor plans (สุขภาพ + ชดเชยรายวัน + โรคร้ายแรง)

Phase 4: Send Flex Carousel (1 push message)
  ├── 3 bubbles: features + premium table + CTA buttons
  ├── Brand header mandatory (iAgencyAIA letterhead)
  └── Colors: #C8102E (AIA Red), #1a1a2e (Dark), #666666 (Muted)

Phase 5-9: Logging + Follow-up
  ├── Log to bot_chat_log (customer + agent sides)
  ├── Update customer profile in line_customers
  ├── CC Bob: maw hey bob-oracle "cc: replied..."
  └── Set follow-up schedule
```

### Core Workflow 2: FA Tools Proposal Generation

**5 Tools** (all at `https://tools.iagencyaia.com/i{mode}/{token}`):

| Tool | Mode | When Used | Creates Link? |
|------|------|-----------|---------------|
| **iQuick** | quick | Single product price inquiry | Yes (token) |
| **iPlan** | plan | Full policy + riders + projection | Yes (token) — **core job** |
| **iCompare** | compare | Side-by-side 2-4 plans | Yes (token) |
| **iLink** | unitlink | Unit Linked projection (Issara Plus/Smart Select) | Yes (token) |
| **iApplication** | — | Online application form | Yes (token) |
| **FHC** | — | Financial health check quiz | Tokenless |

**Token Creation** (via Supabase `proposals` table):
```
SHORT_TOKEN = 8-char random (safe charset, no ambiguous chars)
fa_id = babbd2c9-9b12-4ca3-bbec-15220a7a8ee7 (fasai)
mode = 'quick' | 'plan' | 'compare'
Link = https://tools.iagencyaia.com/iplan/{SHORT_TOKEN}?openExternalBrowser=1
```

### Core Workflow 3: Follow-up Schedule

| Step | Timing | Message | Tag |
|------|--------|---------|-----|
| 1 | 5 min | "สนใจข้อมูลเพิ่มเติมไหมคะ?" | F.แชทติดตาม |
| 2 | 30 min | "น้องส่งข้อมูลเพิ่มให้ได้นะคะ" | — |
| 3 | 1 hour | "ถ้าสะดวกเมื่อไหร่ทักมาได้เลยค่ะ" | — |
| 4 | 1 day | Follow-up + value (article/promo) | F.1/3 |
| 5 | 3 days | Follow-up + context (refer to chat) | F.2/3 |
| 6 | 7 days | Follow-up + summary of plans | F.3/3 |
| 7 | 14 days | "ยังสนใจอยู่ไหมคะ?" (soft close) | — |
| 8 | 30 days | Final follow-up | — |

Stop after 30 days no response → tag: W. (wait) or D. (deny)

### Core Workflow 4: Correction Memory

When customer message arrives with `[CORRECTIONS: ...]` suffix:
1. Read CORRECT field for each correction pair
2. **Never** answer using WRONG field
3. Use CORRECT as reply guide
4. Verify reply doesn't contradict CORRECT

**Known Corrections** (12 pairs in `track5-self-knowledge.md`):
- CP-01: Health Happy UDR (closed) vs PPR (open) — ห้ามบอกว่าปิดแล้ว
- CP-02: Health Happy copay — ตามมาตรฐาน คปภ.
- CP-03: Vitality = "เงินคืนตามสัญญา" NOT "ส่วนลด"
- CP-04/05: Fixed premium = main contract only, NOT riders
- CP-06: Cash Value ≠ "เงินคืน" (different concepts)
- CP-07: Senior Happy has no riders allowed

### CRM Tag System

Every customer MUST be tagged after interaction:

| Prefix | Meaning | Examples |
|--------|---------|----------|
| **P** | Processing | P.ลงทะเบียน(1/3), P.รอ iSign(2/3) |
| **N** | Need (Interest) | N.สุขภาพ, N.CI, N.Prestige |
| **C** | Client (Bought) | C.สุขภาพ, C.Prestige, C.ครอบครัว |
| **F** | Follow-up | F.ติดตามครั้งที่ 1/3, F.โทรติดตาม |
| **W** | Wait | W.ปรึกษาครอบครัว |
| **D** | Deny | D.ไปซื้อที่อื่น, D.ปฏิเสธ |
| **S** | Spam | S.Spam/Spy |
| **L** | Lapsed | L.ไม่ต่ออายุ |
| **Month** | Renewal | เดือน.ม.ค. through เดือน.ธ.ค. |

### Product Portfolio (40+ products)

#### Health (สุขภาพ)

| Product | Status | PPR | UDR | Notes |
|---------|--------|-----|-----|-------|
| Health Starter (NEW) | OPEN | Yes | Yes | BEGIN/BALANCED, age 11-75 |
| Health Happy | OPEN | Yes | No | 4 plans (1M-25M), UDR closed 31 Mar |
| Health Saver | OPEN | Yes | No | UDR closed 31 Mar |
| H&S Extra | CLOSED | No | No | 31 Mar 2026 |
| Infinite Care | OPEN | — | — | Premium worldwide (except 60M plan) |

#### CI + Daily Benefit
- CI SuperCare (single payout, Vitality)
- CI ProCare (multi-payout, Vitality Platinum)
- CI Plus (rider for main policies)
- HB Extra (daily hospitalization 3K-5K/day)

#### Life / Endowment
- Pay Life Plus (standard main policy, riders attachable, fixed premium)
- Legacy Prestige Plus (wealth transfer, prestige tier)
- Senior Happy (age 50-70, no medical exam, **no riders**)
- Savings: Flexi Saving, Endowments (15/25, 20/20, 5/10)
- Annuity: Lifetime Income, Protection 65

#### Unit Linked
- Issara Plus (main UL, iLink available)
- Smart Select (variant, iLink available)
- Elite Income / Infinite Wealth (NOT allowed in FA Tools)

### 13 Golden Rules

| # | Rule | Severity |
|---|------|----------|
| 1 | Knowledge Source Restriction — KB + iAgencyAIA.com only, no guessing | CRITICAL |
| 1.5 | Correction Memory — read CORRECT field, never WRONG | CRITICAL |
| 1.6 | Customer Images — read from ~/.maw/inbox/ immediately | REQUIRED |
| 2a | Customer Data Flow — relay to Data-Oracle, never query DB directly | REQUIRED |
| 2b | Zero Information Leak (PDPA) — no cross-customer data | FIRING |
| 3 | Self-Improvement Every Reply — reflect, learn, improve, log | REQUIRED |
| 6 | Transparency — never pretend to be human, sign as Oracle | REQUIRED |
| 7 | Customer Data Accuracy — cross-check ALL data before sending | FIRING |
| 8 | Promo Data Separation — customer-facing vs agent-only | REQUIRED |
| 10 | Never Guess Coverage Amount — must ask income, debts, family | REQUIRED |
| 13 | Follow-up Schedule — 8-step nurture (5min→30d) | REQUIRED |

---

## API Endpoints

### LINE Relay (localhost:3200)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/aia-reply` | Send LINE message (text or Flex) |
| POST | `/api/corrections/add` | Log corrected answers |
| POST | `/api/followup` | Create follow-up task |
| PATCH | `/api/followup/respond` | Mark customer responded |
| PATCH | `/api/followup/stop` | Stop follow-up series |
| GET | `/api/followup/pending` | List pending follow-ups |

**LINE Reply Format**:
```bash
# Text message
curl -s -X POST http://localhost:3200/api/aia-reply \
  -H "Content-Type: application/json" \
  -d '{"userId":"Uxxxxxxx", "text":"message"}'

# Flex message
curl -s -X POST http://localhost:3200/api/aia-reply \
  -H "Content-Type: application/json" \
  -d '{"userId":"Uxxxxxxx", "messages":[{"type":"flex",...}]}'
```

**Reply Token Priority**: reply token (free, 55s TTL) first → push token (paid, 300/month quota) fallback

### Supabase KB Functions

| Function | Purpose |
|----------|---------|
| `kb_bot_search(query_text)` | Vector search across 832 KB chunks |
| `kb_find_product_by_alias(alias)` | Product lookup by name/alias |
| `kb_find_article_urls(query)` | Get KB article links for "อ่านเพิ่มเติม" |

### Supabase Tables Used

| Table | Purpose |
|-------|---------|
| `line_customers` | Customer profiles (user_id, display_name, profile JSONB, persona, tags) |
| `bot_chat_log` | Chat history (user_id, role, message, topic, created_at) |
| `line_tags` | Tag definitions (C.สุขภาพ, N.CI, F.ติดตาม, etc.) |
| `line_user_tags` | Customer-tag mapping (many-to-many) |
| `insurance_products` | Product catalog for premium lookup |
| `proposals` | FA Tools proposal tokens |

### Flex Message Standards

- **Size**: kilo (7-8KB per bubble, max 50KB carousel, 12 bubbles max)
- **Header**: Mandatory iAgencyAIA letterhead on every bubble
- **Colors**: `#C8102E` (AIA Red), `#1a1a2e` (dark), `#666666` (muted), `#A6873E` (gold, prestige only)
- **Layout**: Carousel split (not single bubble) for 2+ items
- **Buttons**: URI with `?openExternalBrowser=1`
- **Templates**: 10 standard templates in `ψ/memory/flex-library.md`

---

## Deployment

### Session Boot Checklist

1. Check Proposals API health: `POST /api-gateway/proposals/create` → `{"ok":true}`
2. Check LINE relay online: `pm2 list | grep aia-line` → online
3. Verify API key in vault: `iagencyaia_proposals_api_key`
4. Load latest promos: `cat ψ/memory/products/customer-promos-2026.md`
5. If anything fails → alert BoB before accepting customers

### Runtime

- **Process**: Claude Code session in tmux (managed by maw fleet)
- **LINE Relay**: PM2 service `aia-line` on localhost:3200
- **Supabase**: Cloud-hosted (no local deployment)
- **FA Tools**: Cloud-hosted at tools.iagencyaia.com

### Monitoring

- **Activity Log**: `ψ/memory/logs/activity.log` — state machine (idle/working/blocked/monitoring)
- **Focus File**: `ψ/inbox/focus.md` — current STATE, TASK, SINCE, BLOCKED
- **Heartbeat**: Feed.log entries per Golden Rule #9

---

## Current State

### What's Working
- LINE customer chat (reply + push tokens)
- KB search (832 chunks, BGE-M3 embeddings)
- FA Tools proposal creation (iQuick, iPlan, iCompare)
- Flex message templates (10 standard layouts)
- Follow-up scheduling (8-step nurture)
- CRM tagging system
- Correction memory (12 verified pairs)
- Discord team relay via Wingman

### Known Issues
- **#114 (BotDev)**: 3 FA Tools API bugs — rider age-banding, application form_type, HB Extra premium
- **#86**: AIA portal scrape blocked by OTP (2026-06-19)
- **#119**: Post-migration QA plan for AIA portal pending

### Recent Work
- FA Tools API comprehensive QA plan (28 test cases, 6 phases)
- iPlan creation SOP (Pay Life minimum, rider validation, Vitality verification)
- Flex carousel rule enforcement (carousel not single bubble)
- Identity update: น้องแอดมิน → ฟ้าใส (#12)
- Track 5 self-knowledge corrections expanded to 12 pairs

### Pending Features
- FA Tools API QA execution (blocked on BotDev #114 fixes)
- Dream (พี่ดรีม) iApplication testing
- Customer data sync integration with Data-Oracle scraping

---

## Owner & Contacts

| Role | Oracle | Responsibility |
|------|--------|----------------|
| **Lead** | iAgencyAIA-Oracle (ฟ้าใส) | Customer service, proposals, follow-up |
| **Data Partner** | Data-Oracle | Customer queries, KB ingestion, premium lookup |
| **Team Relay** | Wingman-Oracle | Discord #customer-sale, #customer-service |
| **Supervisor** | BoB | Escalation, group routing, QA |
| **API Owner** | BotDev-Oracle | FA Tools API, LINE webhook, bug fixes |
| **QA** | QA-Oracle | Proposal verification, API testing |
| **Compliance** | DocCon-Oracle | Data accuracy audit, conduct review |

---

*"ทุกข้อความคือการดูแล ทุกคำตอบคือความอุ่นใจ" — Every message is care. Every answer is warmth.*
