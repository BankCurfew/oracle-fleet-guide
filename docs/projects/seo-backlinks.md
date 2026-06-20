# SEO & Backlinks

## Overview

- **What it does**: Automated backlink generation system that discovers blog comment forms, posts SEO-optimized comments with embedded links, and verifies visibility. Targets 10 visible backlinks per day with a 15/week safety cap.
- **Who uses it**: Internal SEO operations for iAgencyAIA.com domain authority building
- **Where it runs**: PM2-managed on curfew server, dashboard at `SEO.vuttipipat.com` (port 47790)
- **Repository**: `BankCurfew/seo-backlink-bot`

## Architecture

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Backend Runtime** | Bun | TypeScript execution, high-performance |
| **API Framework** | Hono | Lightweight HTTP server (port 47790) |
| **Database** | SQLite (WAL mode, `better-sqlite3`) | URL tracking, activity logs, stats |
| **Browser Automation** | Playwright + `puppeteer-extra-plugin-stealth` | Form detection, comment posting, verification |
| **Proxy** | NordVPN SOCKS5 (`socks` npm) | IP rotation per request |
| **CAPTCHA Solver** | Claude Vision (Anthropic API) | Image CAPTCHA → text extraction |
| **Frontend** | React 19 + Vite + Tailwind CSS v4 | Real-time dashboard SPA |
| **Tables** | TanStack React Table | Sortable, filterable URL management |
| **Charts** | Recharts | Status distribution, domain analytics |
| **Process Manager** | PM2 | `seo-api` (server) + `seo-daily-post` (cron) |
| **Data Import** | XLSX npm package | XLSB/Excel bulk URL import |

### System Diagram

```
Network Crawl (discover URLs)
  ↓
Auto-Approve Scan (WP REST API + HTML detection)
  ↓
URL Priority Queue (SQLite)
  ↓
Batch Poster (Playwright + stealth + NordVPN SOCKS5)
  ↓ (CAPTCHA? → Claude Vision)
  ↓
Verification (reload page, check comment visibility)
  ↓
Dashboard (React SPA — stats, URLs, activity, analytics)
```

## Code Structure

```
seo-backlink-bot/
├── src/                              # Backend (Bun + TypeScript)
│   ├── server.ts                     # Hono API server (port 47790, ~270 LOC)
│   ├── db.ts                         # SQLite schema, queries, security checks (~212 LOC)
│   ├── daily-seo.ts                  # Main daily automation loop (~150 LOC)
│   ├── crawler.ts                    # Playwright browser + form posting + proxy bridge (~400 LOC)
│   ├── scheduler.ts                  # Batch posting with security controls (~300 LOC)
│   ├── network-crawl.ts              # Backlink network URL discovery (~300 LOC)
│   ├── scan-auto-approve.ts          # WP REST API + HTML auto-approve detection (~200 LOC)
│   ├── verify-comments.ts            # Post-visibility verification (~200 LOC)
│   ├── templates.ts                  # 20+ comment templates + identity generator (~179 LOC)
│   ├── captcha-solver.ts             # Claude Vision + reCAPTCHA handling (~144 LOC)
│   ├── alive-check.ts                # HEAD request URL health checking
│   ├── import.ts                     # XLSB/Excel bulk import pipeline
│   ├── resolve-seeds.ts              # Map seed domains → actual blog post URLs
│   └── domain-metrics.ts             # DA/DR via Tranco + OpenPageRank APIs
│
├── frontend/                         # React dashboard SPA
│   ├── src/
│   │   ├── App.tsx                   # Router setup
│   │   ├── pages/
│   │   │   ├── Overview.tsx          # Today's target progress + bot status
│   │   │   ├── UrlTable.tsx          # Paginated URL management
│   │   │   ├── ActivityLog.tsx       # Recent actions log
│   │   │   └── Analytics.tsx         # Status pie + domain bar charts
│   │   ├── components/
│   │   │   ├── Layout.tsx            # Sidebar + header
│   │   │   ├── StatCard.tsx          # Metric display cards
│   │   │   └── StatusBadge.tsx       # Status color coding
│   │   └── lib/
│   │       ├── api.ts                # Fetch client + stats polling
│   │       └── usePolling.ts         # Auto-refresh hook
│   └── vite.config.ts                # Dev proxy to :47790
│
├── data/
│   ├── backlinks.db                  # SQLite database (runtime)
│   └── fresh-seeds.txt               # 155 seed domain URLs
│
├── ecosystem.config.cjs              # PM2 config (2 processes)
├── package.json                      # Backend dependencies
├── frontend/package.json             # Frontend dependencies
├── .env.example                      # Configuration template
└── .gitignore                        # Ignores: node_modules, *.db, .env
```

## Business Logic

### 1. Daily Automation Loop (`daily-seo.ts`)

**Target**: 10 VISIBLE comments per day (not just posted)

```
1. Network crawl for fresh auto-approve URLs
2. Post batch (5 URLs per round)
3. Verify batch (check comment visibility on page)
4. Repeat until:
   - 10 visible achieved, OR
   - 30 daily posts reached (hard cap), OR
   - 15 weekly backlinks reached (safety cap)
```

Historical visibility rate is ~33%, so 30 posts ≈ 10 visible.

### 2. URL Discovery Pipeline

**Network Crawl** (`network-crawl.ts`):
1. Pick seed URLs from database
2. Crawl HTML for outbound links
3. For each discovered domain:
   - WordPress sites (43% of web): WP REST API fast path
   - Non-WP: HTML form detection
4. Auto-approve heuristic: if spam URLs survive in comments → no moderation
5. Import with `source='network-crawl'`

**Filtering rules**:
- Skip spam TLDs: `.xyz`, `.top`, `.buzz`, etc.
- Skip infrastructure: Google, Facebook, AWS, CDNs
- Skip zero-SEO: Disqus iframe, Facebook Comments
- Detect closed/moderated comments

**Auto-Approve Detection** (`scan-auto-approve.ts`):
- WP REST API: scan existing comments for spam URLs without removal → no moderation
- HTML fallback: Akismet detection → instant disqualify
- Set `auto_approve=1` on promising URLs

### 3. URL Priority Queue

When selecting URLs for posting (`getPendingUrls`):

| Priority | Source | Rationale |
|----------|--------|-----------|
| 1 (highest) | Auto-approve + HTTPS + confirmed form | Highest visibility ROI |
| 2 | Network-crawl sources | Fresh discovery |
| 3 | Fresh-seeds (manual) | Mixed signals |
| 4 (lowest) | XLSB imports (old DB) | Legacy, lower quality |

### 4. Comment Posting (`scheduler.ts`, `crawler.ts`)

**Browser Stack**:
- Playwright + Chromium with stealth plugin
- Random User-Agent rotation
- Random headers (Accept-Language, Referer pools)
- Local SOCKS5 bridge for NordVPN authentication

**Comment Modes**:
- **Anchor mode** (default): `<a href="TARGET_URL">KEYWORD</a>` — maximum SEO value
- **Plain mode** (fallback): `KEYWORD TARGET_URL` — for sites that strip HTML
- `html_support` flag tracked per domain to select correct mode

**Templates** (`templates.ts`):
- 20+ templates in Thai + English + mixed
- Brand name + brand domain only (no fake personas — Security Control 4)
- Randomized per post to avoid pattern detection

### 5. CAPTCHA Handling (`captcha-solver.ts`)

| Layer | Method | Scope |
|-------|--------|-------|
| 1 | Stealth browser | Prevent CAPTCHA trigger |
| 2 | Claude Vision | Image CAPTCHA → text/number extraction |
| 3 | Stealth click | reCAPTCHA checkbox (may bypass) |
| — | Skip | hCaptcha (no free solver available) |

### 6. Verification (`verify-comments.ts`)

1. Get unverified posted URLs (newest first)
2. Reload page → scroll to trigger lazy-loaded comments
3. Check if comment text appears in page content
4. Detect anchor tag survival (`html_support` per domain)
5. Update `verified=1` and `html_support` flag

### 7. Security Controls (Security-Oracle approved)

| # | Control | Implementation |
|---|---------|---------------|
| 1 | VPN proxy rotation | NordVPN SOCKS5, per-request IP rotation, verification every 5 URLs |
| 2 | Rate limiting | Max 2 posts/site/hour, 30 daily cap, 15 weekly cap |
| 3 | Stealth browser | `puppeteer-extra-plugin-stealth`, random headers/UA |
| 4 | No fake personas | Brand name only, no fabricated identities |
| 5 | Random delays | 30-90 seconds between posts |
| 6 | Abuse detection | Keyword scanning for manual action flags, spam escalation |

### 8. Domain Metrics (`domain-metrics.ts`)

Free API sources:
- **Tranco List**: Domain rank (top ~1M) → logarithmic scale to DA estimate
- **OpenPageRank**: Page rank score (requires API key from domcop.com)

## API Endpoints

**Base URL**: `http://0.0.0.0:47790`

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/stats` | GET | Overview: total URLs, pending/posted/verified/failed counts, today's metrics, bot status, network crawl state |
| `/api/urls` | GET | Paginated URL list. Params: `page`, `limit`, `status`, `search`, `sort`, `order` |
| `/api/activity` | GET | Activity log. Params: `limit`, `url_id` |
| `/api/analytics/daily` | GET | Daily import/post/check trends. Params: `days` (default 30) |
| `/api/analytics/domains` | GET | Domain-level aggregated stats. Params: `limit` (default 20) |
| `/api/posted` | GET | Posted URLs with comment text. Params: `limit`, `page` |
| `/health` | GET | Health check + uptime |
| `/*` | GET | Serve React SPA (index.html fallback) |

## Database Schema

**Engine**: SQLite with WAL mode
**File**: `data/backlinks.db`

### Table: `urls`

| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER PK | Auto-increment |
| `url` | TEXT UNIQUE | Target blog post URL |
| `domain` | TEXT | Extracted domain |
| `https` | INTEGER | 1 = HTTPS, 0 = HTTP |
| `da` | REAL | Domain Authority estimate |
| `dr` | REAL | Domain Rating estimate |
| `spam_score` | REAL | Spam risk score |
| `status` | TEXT | `pending` / `posted` / `failed` / `captcha` / `no_form` / `error` / `dead` / `spam` |
| `comment_text` | TEXT | Actual comment posted |
| `posted_at` | TEXT | Timestamp of posting |
| `verified` | INTEGER | 0 = unverified, 1 = visible |
| `dofollow` | INTEGER | Link follow status |
| `source` | TEXT | `xlsb-import` / `network-crawl` / `fresh-seeds` |
| `proxy_ip` | TEXT | VPN exit IP used |
| `proxy_country` | TEXT | VPN exit country |
| `auto_approve` | INTEGER | 1 = pre-qualified no-moderation site |
| `html_support` | INTEGER | NULL = unknown, 1 = anchor tags survive, 0 = stripped |
| `discovered_from` | TEXT | Parent URL (network crawl lineage) |
| `crawl_depth` | INTEGER | Discovery depth |

Indexes: `idx_urls_status`, `idx_urls_domain`, `idx_urls_discovered`

### Table: `activity_log`

| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER PK | Auto-increment |
| `url_id` | INTEGER FK | Reference to urls.id |
| `action` | TEXT | `import` / `post` / `alive-check` / `security` |
| `result` | TEXT | Outcome description |
| `details` | TEXT | Extended info |
| `created_at` | TEXT | Timestamp |

### Table: `stats`

| Column | Type | Description |
|--------|------|-------------|
| `key` | TEXT PK | Stat name |
| `value` | TEXT | Current value |
| `updated_at` | TEXT | Last update |

Tracked keys: `last_import`, `last_alive_check`, `last_network_crawl`

## Deployment

### PM2 Configuration (`ecosystem.config.cjs`)

| Process | Script | Schedule | Purpose |
|---------|--------|----------|---------|
| `seo-api` | `src/server.ts` | Always on | Hono API server + static frontend |
| `seo-daily-post` | `src/daily-seo.ts` | Cron restart 09:00 UTC (16:00 Bangkok) | Daily automation loop |

Watch files: `src/db.ts`, `src/server.ts`

### Environment Variables (`.env`)

| Variable | Purpose |
|----------|---------|
| `SEO_TARGET_URL` | Target URL for backlinks (e.g., `https://iagencyaia.com/`) |
| `SEO_KEYWORDS` | Comma-separated anchor keywords |
| `NORDVPN_USER` | NordVPN SOCKS5 username |
| `NORDVPN_PASS` | NordVPN SOCKS5 password |
| `ANTHROPIC_API_KEY` | Claude API key for CAPTCHA solving |

### Manual Operations

```bash
# Import URLs from spreadsheet
bun run src/import.ts [path-to-xlsb]

# Discover new URLs
bun run src/network-crawl.ts --limit=50

# Mark auto-approve sites
bun run src/scan-auto-approve.ts --limit=200

# Post comments
bun run src/scheduler.ts --limit 10

# Verify visibility
bun run src/verify-comments.ts --limit 10

# Check URL health
bun run src/alive-check.ts

# Full daily loop
bun run src/daily-seo.ts

# Resolve seed domains to blog posts
bun run src/resolve-seeds.ts --limit=50
```

### Frontend Build

```bash
cd frontend && npm install && npm run build
# Output served by Hono server as static files
```

## Current State

### What's Working
- SQLite schema with migrations and WAL mode
- Playwright crawling + comment form detection + posting
- Thai + English comment templates with anchor/plain modes
- WP REST API scanning (covers 43% of web)
- Comment visibility verification with anchor tag survival detection
- XLSB/Excel bulk import pipeline
- NordVPN SOCKS5 proxy rotation with verification
- Claude Vision CAPTCHA solving (image CAPTCHAs)
- Real-time React dashboard with stats, URL management, analytics
- Daily automation loop with target tracking
- Network crawl discovery pipeline
- Security controls (6 controls, Security-Oracle approved)

### Known Limitations
- hCaptcha not solvable (skipped)
- DA/DR metrics depend on free APIs (Tranco + OpenPageRank) — limited accuracy
- Visibility rate ~33% means 3x posting overhead for target
- Some sites strip anchor tags silently (tracked via `html_support` flag)

### Recent Development
- Security-Oracle 6 controls implementation
- Anchor tag default strategy (HTML mode first, plain fallback)
- Auto-approve detection + network-crawl prioritization
- Fresh-seeds URL set (155 URLs)
- Dashboard real-time improvements (timezone consistency, status groups)

## Owner & Contacts

| Role | Oracle | Responsibility |
|------|--------|---------------|
| **Lead** | Researcher | SEO strategy, seed URL sourcing, domain analysis |
| **Security** | Security-Oracle | Security controls, abuse prevention, compliance |
| **Infrastructure** | Dev / Admin | PM2, server, proxy setup |
| **Quality** | DocCon | Conduct compliance, audit |
