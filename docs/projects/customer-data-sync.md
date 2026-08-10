# Customer Data Sync

## Overview

- **What it does**: Data ingestion, transformation, and knowledge base management for BoB's Office. Transforms raw AIA insurance data (PDFs, portal scrapes, web content) into structured, searchable knowledge via Supabase + BGE-M3 vector embeddings. Manages customer data sync between ePOS portal and iAgency CRM, promo lifecycle tracking, and premium lookup services.
- **Who uses it**: iAgencyAIA-Oracle (P0 priority — LINE bot customer queries), Wingman-Oracle (Discord news), Researcher-Oracle (market data), all oracles needing verified insurance data.
- **Where it runs**: Python scripts executed in Data-Oracle's tmux session on curfew server. Data stored in two Supabase projects. Embedding service via local BGE-M3 HTTP wrapper.

## Architecture

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Data Store** | Supabase (PostgreSQL + pgvector) | Primary storage + vector search |
| **Embedding** | BGE-M3 (BAAI/bge-m3) | Multilingual Thai/English, 1024-dim dense + sparse lexical |
| **Extraction** | PyMuPDF | PDF parsing (100% accuracy for Thai table layouts) |
| **Scraping** | Playwright (pw-cli.sh) | Portal scraping (ePOS, AIA portal) |
| **Scripts** | Python 3 (uv runtime) | ETL pipelines, embedding, data sync |
| **Search** | pgvector + FTS5 | Vector similarity + full-text search |
| **Data Format** | JSON / JSONL | Chunks, promotions, training data |

### Supabase Projects

| Project | Ref ID | Purpose |
|---------|--------|---------|
| **AIA Knowledge Base** | `heciyiepgxqtbphepalf` | KB chunks, embeddings, aia_knowledge, bot data, customer records |
| **FA Tools** | `hztjrqlxrdsmxbkxojqg` | insurance_products (14,596 rows), premium tables, proposals |

### Key Services

```
┌─────────────────────────────────────┐
│  Data-Oracle (Claude Code session)  │
├─────────────────────────────────────┤
│  Python ETL Scripts (40+)           │
│  └─ ingest-*.py  (data loading)     │
│  └─ embed-*.py   (vectorization)    │
│  └─ customer-data-sync.py           │
│  └─ import-epos-customers.py        │
├─────────────────────────────────────┤
│  BGE-M3 Embedding Service           │
│  └─ HTTP: localhost:8100/embed      │
│  └─ 1024-dim, batch ≤32            │
├─────────────────────────────────────┤
│  Supabase (2 projects)              │
│  └─ heciyiepgxqtbphepalf (KB)       │
│  └─ hztjrqlxrdsmxbkxojqg (FA Tools) │
├─────────────────────────────────────┤
│  Playwright (pw-cli.sh)             │
│  └─ Portal scraping (ePOS, AIA)     │
└─────────────────────────────────────┘
```

## Code Structure

```
Data-Oracle/
├── CLAUDE.md                     # Identity + 10 Commandments + laws (30.0K)
├── SOP.md                        # 8 SOPs: KB pipeline, embedding, promo, ETL, verification (20.4K)
├── README.md                     # Overview + philosophy (1.7K)
├── okr.md                        # Q1 2026 OKRs + KPIs (2.9K)
│
├── scripts/                      # 40+ Python ETL scripts
│   ├── embed-chunks.py           # Main embedder — batch from DB (11.2K)
│   ├── embed-missing.py          # Find + embed NULL embedding chunks (3.5K)
│   ├── embed-missing-batch.py    # Large gap-fill embedder (3.7K)
│   ├── embed-health-check.py     # BGE-M3 service health validation (5.0K)
│   ├── auto-embed-watcher.py     # Continuous embedding mode (12.0K)
│   ├── embed-aia-knowledge.py    # AIA-specific embedder
│   ├── embed-from-storage.py     # Storage-based pipeline
│   │
│   ├── ingest-health-happy-benefits.py    # Health Happy product data (29.0K)
│   ├── ingest-vitality.py                 # Vitality discount data (27.4K)
│   ├── ingest-iagencyaia-content.py       # Website content (26.4K)
│   ├── ingest-kb-gap-fill-v2.py           # KB coverage gaps (18.2K)
│   ├── ingest-bmi-underwriting.py         # BMI underwriting rules (12.9K)
│   ├── ingest-iagencyaia-kb.py            # iAgencyAIA KB (5.0K)
│   │
│   ├── customer-data-sync.py     # ePOS → iAgency DB sync (9.9K)
│   ├── import-epos-customers.py  # ePOS customer+policy bulk import (15.7K)
│   ├── ingest-investment-funds.py # UL fund data ingestion (6.5K)
│   ├── build-iagencyaia-chunks.py # Website → KB chunks (46.5K)
│   │
│   ├── dedup-kb-chunks.py        # Deduplicate KB entries
│   ├── normalize-oversized-chunks.py  # Split large chunks
│   ├── kb-cleanup-audit-fixes.py # KB maintenance
│   │
│   ├── export-training-v3-round7.py  # Fine-tuning data export (31.5K)
│   ├── extract-training-data.py      # Training data extraction (14.0K)
│   └── google-stack-setup.py         # Automated GTM+GA4+GSC+IndexNow setup (259 lines)
│
├── output/                       # Generated reports
│   ├── wb-article-register-*.html    # Article Register HTML reports (v3.1 current)
│   └── wb-daily-intel-*.html         # Daily Intel HTML dashboards (20 reports, Jul 21 — Aug 10)
│
├── data/                         # Data files
│   ├── kb/                       # KB chunk files (JSON)
│   ├── training/                 # Training data (JSONL, 1M-3.9M lines)
│   ├── premium-tables/           # Premium lookup files
│   ├── aia-promotions-2026.json  # Active promo database (~14 active)
│   └── migrations/               # SQL migration files
│
├── wealth-bank/scripts/          # WealthBanks analytics pipelines
│   ├── pull-ga4.py               # GA4 daily page views pull (104 lines)
│   ├── pull-gsc.py               # GSC daily impressions pull (103 lines)
│   ├── pull-psi.py               # PSI score pull (153 lines)
│   └── generate-article-register.py  # Article Register generator (353 lines)
│
├── wealth-bank/data/analytics/   # Daily analytics JSON pulls
│   ├── ga4-*.json                # 13 GA4 daily files
│   ├── gsc-*.json                # 27 GSC daily files
│   ├── psi-*.json                # 25 PSI daily files
│   ├── article-register.json     # Article register data
│   └── .index-state.json         # Index state tracking
│
├── wealth-bank/src/data/generated/funds/  # Fund NAV JSONs
│   └── *.json                    # 24 fund NAV files (22 AIA funds)
│
├── migrations/                   # Supabase SQL migrations
│   ├── kb_bot_search.sql         # KB search RPC with source boosting
│   └── 002_unique_policy_number.sql  # Policy uniqueness (pending auth)
│
├── docs/                         # Documentation
│   ├── schema-reference.md       # Table schemas (verified 2026-06-18)
│   ├── data-contract-premium-lookup.md  # iAgencyAIA ↔ Data contract
│   ├── product-data-extraction-playbook.md  # Step-by-step extraction guide
│   └── fasai-premium-self-serve-guide.md    # FA team self-serve guide
│
├── ψ/                            # Oracle brain structure
│   ├── inbox/focus.md            # Current session state
│   ├── inbox/handoff/            # Session handoffs
│   ├── memory/learnings/         # Lessons learned (20+ files)
│   ├── memory/retrospectives/    # Session retros
│   └── active/                   # Current work
│
└── .mcp.json                     # MCP config (oracle-v2, playwright, supabase)
```

## Business Logic

### The 10 Data Commandments

1. **Schema first** — define target table before ingesting
2. **Idempotent always** — rerun pipeline = same result, no duplicates
3. **DELETE before INSERT (MANDATORY)** — 5-step procedure, never skip
4. **Validate at boundary** — check data at ingestion point
5. **Lineage is sacred** — every record tracks: where, when, who
6. **Batch + Stream** — batch for bulk, stream for real-time
7. **Normalize then denormalize** — store normalized, serve denormalized
8. **Fail loud, not silent** — pipeline failures send alerts
9. **Version everything** — schema, pipeline, embedding model versions
10. **Document the why** — transformation rationale in code + docs

### Pipeline 1: KB Ingestion

```
Source (PDF/Web/Portal)
  ↓
Schema Check — define target table columns
  ↓
Extract — PyMuPDF for PDFs (position-based Thai tables), Playwright for portal
  ↓
Transform — chunk by product_uid × gender (~500 tokens), section headers (~512 tokens)
  ↓
DELETE old rows (MANDATORY 5-step procedure):
  1. COUNT existing rows for source
  2. BACKUP if >100 rows
  3. DELETE WHERE source = 'tag'
  4. VERIFY count = 0
  5. INSERT new rows
  ↓
Load — Upsert to kb_chunks table (Supabase)
  ↓
Embed — BGE-M3 batch ≤32, validate for NaN, upsert 1024-dim vectors
  ↓
Verify — spot-check 5-10 records, test semantic search
  ↓
Document — log counts, notify downstream oracles
```

**Critical incident**: 42K duplicates from skipped DELETE on 2026-05-12.

### Pipeline 2: BGE-M3 Embedding

| Parameter | Value |
|-----------|-------|
| Model | BAAI/bge-m3 |
| Dimensions | 1024 (dense) + sparse lexical |
| Batch size | ≤32 (larger causes NaN for Thai) |
| Float type | float32 (float64 causes NaN in deep transformers) |
| Service | HTTP at localhost:8100/embed |
| Runtime | `uv run` (not pip) |

**Scripts**: `embed-chunks.py` (main), `embed-missing.py` (gap-fill), `embed-missing-batch.py` (bulk), `embed-health-check.py` (validation), `auto-embed-watcher.py` (continuous)

### Pipeline 3: Customer Data Sync (ePOS → iAgency)

**Script**: `scripts/customer-data-sync.py` (239 lines)

```
ePOS Portal (source of truth)
  ↓
Download customer + policy JSON export
  ↓
Match by name + birthdate (±1 day tolerance for timezone bugs)
  ↓
UPDATE-only existing iagency_customers (no new creation)
  ↓
Sync fields: first_name, last_name, title, birthdate, address
  ↓
Policy sync: plan_name, sum_assured, annual_premium, payment_frequency, policy_date, status
  ↓
Generate match report → manual review for uncertain matches
```

**Rules**:
- ePOS = source of truth (overwrites iAgency typos)
- UPDATE-only — never create new customers without manual approval
- Name match with ±1 day birthdate tolerance
- Uncertain/no match → skip and log for manual review
- Dry-run by default, requires explicit `--execute` flag
- Recent run: 1,382 customers + 2,044 policies (2026-06-18)

**Script**: `scripts/import-epos-customers.py` (234 lines) — bulk import with idempotent `policy_number` key

**Filters** (added 2026-06-20, bug #126):
- `is_policy_importable()` filters out: rejected, lapsed, surrendered, freelook-cancelled, zero-premium/zero-SA
- Skips customers where ALL policies are non-active
- Result: 1,382 raw → 937 importable customers, 2,044 → 1,243 active policies
- CG* (group insurance) records: 50 exist in DB from iAgency app, not from ePOS import

### Pipeline 5: Investment Fund Ingestion

**Script**: `scripts/ingest-investment-funds.py` (180 lines)

```
AIA ePOS Investment Tab (Playwright scrape by AIA-Oracle)
  ↓
JSON file: AIA-Oracle/.tmp/investment-ALL.json
  ↓
Parse: Thai Buddhist Era dates (year - 543), comma numbers, NBSP percentages
  ↓
Populate customer_policies (FK parent, UL policies only)
  ↓
Insert policy_investments (fund allocations, snapshot model)
  ↓
Verify: 0 NULLs, 0 orphans, 0 dupes
```

**Schema**: `policy_investments` table (16 columns) — policy_no, fund_name, fund_code, risk_level, units, nav_per_unit, nav_date, avg_cost_per_unit, cost_value, current_value, gain_loss, gain_loss_pct, allocation_pct, scraped_at

**FK**: `policy_investments.policy_no → customer_policies.policy_no`

**Current state** (2026-06-20): 243 UL policies, 603 fund rows, NAV dates 2026-06-16/17

**Snapshot model**: Each scrape creates new rows with `scraped_at` timestamp. Upsert key planned: `policy_no + fund_code + nav_date` (pending UNIQUE index migration).

### Pipeline 6: Promo Lifecycle

**Storage**: `data/aia-promotions-2026.json` (~14 active promos, down from 33 after Jun 30 expiry wave + status normalization: `archived` → `expired`)

| Category | Type | Visibility |
|----------|------|-----------|
| `marketing_promo` | Temporary, has expiry | Tagged `customer_facing` or `agent_only` |
| `product_discount` | Mostly permanent | Tagged per product |

**Lifecycle**:
1. New promo → Researcher deep learn → Data ingest with tags
2. Active → iAgencyAIA syncs `customer_facing` only, Wingman syncs all
3. 7 days before expiry → flag warning to consumers
4. Expired → update status + notify immediately
5. Superseded → old promo archived, new promo linked

**CRITICAL**: Never show internal codes (MKT26, ECM02, PT07) to customers. iAgencyAIA gets `customer_facing_summary` only.

### Pipeline 7: Daily Analytics Pulls (GA4 + GSC + PSI)

**Scripts** (in `wealth-bank/scripts/`):
| Script | Lines | Purpose |
|--------|-------|---------|
| `pull-ga4.py` | 104 | Google Analytics 4 page views |
| `pull-gsc.py` | 103 | Google Search Console impressions/clicks/position |
| `pull-psi.py` | 153 | PageSpeed Insights scores |

**Data**: `wealth-bank/data/analytics/` — 13 GA4, 27 GSC, 25 PSI daily JSON files

**Features**:
- Retry with exponential backoff (3 attempts, 5/15/30s delay)
- Property ID hardcoded with assertion (prevents cross-contamination)
- PSI skip-when-fresh (<3 days old)

**Known issue**: PSI API 429 rate limit on day 5+ — pending Admin key rotation

**Data integrity**: 12 contaminated GA4 files quarantined to `quarantine-property-mismatch/`

**Operational since**: Jul 21, 2026 (GA4+GSC); Jul 26, 2026 (PSI)

### Pipeline 8: Article Register (#70)

**Script**: `wealth-bank/scripts/generate-article-register.py` (353 lines)
**Output**: `Data-Oracle/output/wb-article-register-*.html` (v3.1 current)

**Capability**: Per-article Google Search Console analytics for 57 WealthBanks blog articles.

**Evolution**:
| Version | What Changed |
|---------|-------------|
| v1 | Base stock view — article list with basic metrics |
| v2 | Added `index_status` + URL inspection from GSC API |
| v3 | Added `query_type` column — branded vs generic query split |
| v3.1 | Authority baseline DA=1, SERP floor DA per gap, phase 2 coverage gaps |

**Output**: HTML reports generated for BoB review.

**State**: Awaiting BoB → แบงค์ approval to wire into daily report Section F.

### Pipeline 9: Daily Intel Report

**Output**: `Data-Oracle/output/wb-daily-intel-*.html` (20 reports, Jul 21 — Aug 10)

**Aggregates**:
- GA4 pageviews (from Pipeline 7)
- GSC impressions/clicks/position (from Pipeline 7)
- PSI scores (from Pipeline 7)
- T177 fund NAV freshness (from Pipeline 10)
- Promo expiry status (from Pipeline 6)
- Promo campaign tracking (e.g. 8.8 campaign)

**Format**: HTML dashboard for แบงค์ review.

### Pipeline 10: Fund NAV Operations (T177)

**Data**: `wealth-bank/src/data/generated/funds/` — 24 fund JSON files (22 AIA funds)
**Source**: aiaim.co.th `fundList.json` endpoint

**Operations**:
- Periodic NAV refresh from AIA Investment Manager
- JSON file regeneration for 24 funds
- Freshness check (T030) integrated into Daily Intel report

**Known issue**: 2 non-AIA funds (`ES-GF-A`, `KF-CINCOME-A`) need different NAV source — not yet automated.

### Premium Lookup Rules

| Product Type | Column to Use | Formula |
|-------------|--------------|---------|
| Life / Endowment | `premium_per_1000` | `premium_per_1000 × SA / 1000` |
| Health / CI / Rider | `rider_premium` | Direct value (age-banded) |

**CRITICAL**: `premium_per_1000` = NULL for health/CI products. Using wrong column = #1 lookup mistake.

**Source table**: `insurance_products` in FA Tools project (hztjrqlxrdsmxbkxojqg), 14,728 rows (product × age × gender), 26 product families.

## Database Schema

### Table: `kb_chunks` (heciyiepgxqtbphepalf)

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key (auto) |
| `document_name` | text | Source doc identifier |
| `source` | text | Pipeline tag (e.g. "fa-products-2026-06") |
| `category` | text | Content category (e.g. "product/health") |
| `section` | text | Section within document |
| `product_name` | text | Display name |
| `product_short_name` | text | Product UID (e.g. "HH2010M") |
| `chunk_index` | int4 | Position within document (0-based) |
| `chunk_text` | text | Actual content text |
| `chunk_tokens` | int4 | Estimated token count |
| `embedding` | vector(1024) | BGE-M3 dense embedding |
| `sparse_embedding` | jsonb | BGE-M3 lexical/sparse weights |
| `metadata` | jsonb | Pipeline-specific metadata |
| `created_at` | timestamptz | Row creation timestamp |

**Dedup key**: `(source, chunk_text)` — keeps lowest `id` per pair.
**Size**: 10,000+ chunks.

### Table: `insurance_products` (hztjrqlxrdsmxbkxojqg)

| Column | Type | Description |
|--------|------|-------------|
| `product_uid` | text | Unique code (e.g. "HH2010M") |
| `plan_name` | text | Plan name |
| `family` | text | Product family grouping |
| `contract_type` | text | "Main", "Main_UnitLinked", "Rider", "Rider_UDR" |
| `gender` | text | "ชาย" / "หญิง" |
| `age` | int4 | Specific age for premium row |
| `premium_per_1000` | numeric | Premium rate per 1,000 SA (life only, NULL for health/CI) |
| `rider_premium` | numeric | Rider premium amount (health/CI products) |
| `min_age`, `max_age` | int4 | Age range |
| `min_sa`, `max_sa` | numeric | Sum assured range |

**Size**: 14,728 rows. Each row = product × age × gender. 26 product families.

### Table: `aia_knowledge` (heciyiepgxqtbphepalf)

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `title` | text | Article title |
| `content` | text | Full text |
| `category` | text | Article category |
| `source_url` | text | Original URL |
| `embedding` | vector(1024) | BGE-M3 dense embedding |

### Table: `customer_policies` (hztjrqlxrdsmxbkxojqg)

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `policy_no` | text | Policy number (FK parent for policy_investments) |
| `customer_name` | text | Thai full name with title |
| `product_code` | text | ePOS plan code (e.g. NILPP5) |
| `product_type` | text | Product category (all "Unit Linked") |
| `sum_assured` | numeric | Sum assured |
| `annual_premium` | numeric | Annual premium |
| `payment_mode` | text | Payment frequency (Thai: รายปี, รายเดือน) |
| `status` | text | Policy status |
| `agent_code` | text | AIA agent code |

**Size**: 243 rows (UL policies only). FK parent for `policy_investments`.

### Table: `policy_investments` (hztjrqlxrdsmxbkxojqg)

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `policy_no` | text | FK → customer_policies.policy_no |
| `fund_name` | text | Thai fund name |
| `fund_code` | text | Fund identifier (truncated name, no short code from ePOS) |
| `risk_level` | text | Risk level ('4', '5', '6') |
| `units` | numeric | Number of units held |
| `nav_per_unit` | numeric | NAV per unit |
| `nav_date` | date | NAV valuation date |
| `avg_cost_per_unit` | numeric | Average cost basis |
| `cost_value` | numeric | Total cost |
| `current_value` | numeric | Current redemption value |
| `gain_loss` | numeric | Unrealized PnL (baht) |
| `gain_loss_pct` | numeric | Unrealized PnL (%) |
| `allocation_pct` | numeric | Fund allocation % |
| `scraped_at` | timestamptz | Scrape timestamp |

**Size**: 603 rows. Snapshot model — new rows per scrape with `scraped_at`.

### RPC: `kb_bot_search()`

Source-boosted search wrapper for iAgencyAIA bot:
- Source priority boosting (iAgencyAIA content 1.35× > PDF brochures 0.85×)
- Content type weighting (FAQ > blog > product page > nav page)
- Discontinued product penalty (-30%)
- Deduplication (max 2 chunks per document)

**Migration**: `migrations/kb_bot_search.sql`

## API Endpoints

Data-Oracle does not expose HTTP APIs directly. All interactions via:

1. **Supabase REST API** — direct table queries from scripts
2. **`/talk-to data "request"`** — inter-oracle data requests via MCP
3. **`maw hey data "request"`** — fallback notification

### Cross-Oracle Request Priority

| Priority | Requester | SLA |
|----------|-----------|-----|
| P0 | iAgencyAIA-Oracle (LINE bot) | Respond ASAP via `maw hey iagencyaia` |
| P0 | แบงค์ direct | Immediate |
| P1 | BoB task assignment | Within session |
| P2 | Other oracles | Best effort |

**CRITICAL oracle name mapping**: `iagencyaia` = LINE bot (tmux 20), NOT `aia` = ePOS portal (tmux 08). Wrong target = customers wait 15+ min.

## Deployment

### Environment Variables

```env
# KB project (most scripts default)
SUPABASE_URL=https://heciyiepgxqtbphepalf.supabase.co
SUPABASE_SERVICE_KEY=[from vault]

# Embedding service
EMBED_URL=http://localhost:8100/embed

# FA Tools project (premium lookups)
FATOOLS_SUPABASE_URL=https://hztjrqlxrdsmxbkxojqg.supabase.co
```

### Execution

All scripts run manually in Data-Oracle's tmux session:

```bash
# Embedding
uv run scripts/embed-chunks.py
uv run scripts/embed-missing.py --dry-run

# Ingestion
uv run scripts/ingest-health-happy-benefits.py
uv run scripts/ingest-vitality.py

# Customer sync
uv run scripts/customer-data-sync.py --dry-run
uv run scripts/import-epos-customers.py --execute

# KB maintenance
uv run scripts/dedup-kb-chunks.py
uv run scripts/normalize-oversized-chunks.py
```

### Scheduled Tasks

Via `maw loop add` (persistent, dashboard-visible):
- Daily promo expiry check (9 AM)
- Embedding health check (periodic)
- Pipeline status monitoring

### KPIs

| Metric | Target |
|--------|--------|
| Pipeline Success Rate | ≥ 95% |
| Data Freshness | ≤ 24h source-to-KB |
| Embedding Coverage | 100% |
| Data Quality Score | ≥ 95% |
| Ingestion Throughput | ≥ 50 docs/session |

### Alert Triggers

- \>10 unembedded chunks in KB
- Pipeline failure (any script)
- Expired promos without status update
- Stale data >7 days without refresh
- Duplicate rows detected

## Current State

### What's Working
- KB pipeline: 10,000+ chunks ingested, 100% embedded, searchable
- Premium lookup: 14,728 product rows (26 families) serving FA Tools + iAgencyAIA bot
- Customer data sync: 937 active customers (filtered from 1,382 raw) ready for import
- Investment fund data: 243 UL policies, 603 fund allocations in Supabase (QA verified)
- Promo tracking: ~14 active promos with lifecycle management (down from 33 after Jun 30 expiry wave)
- BGE-M3 embedding: batch pipeline stable with NaN validation
- Cross-oracle data serving: P0 responses to iAgencyAIA operational
- Daily analytics pulls: GA4+GSC operational since Jul 21, PSI since Jul 26 (Pipeline 7)
- Article Register v3.1: 57 WealthBanks articles tracked with GSC analytics, branded/generic query split, authority baseline DA=1 (#70, Pipeline 8)
- Daily Intel reports: 20 HTML dashboards generated Jul 21 — Aug 10, aggregating GA4+GSC+PSI+NAV+promo status (Pipeline 9)
- Fund NAV T177: 22 AIA fund NAVs refreshed periodically + 24 fund JSON files regenerated (Pipeline 10)
- Rider display (#226): rider section under each policy in Data-Oracle dashboard, policies parser handles Life/PA type field
- Customer report generator (#213): family mode, customer mode, JSON cache, validate-before-replace gate, published to Supabase `report_index` (20 records)
- Storage (#221): completed

### Known Issues
- **UNIQUE constraint pending**: `iagency_policies.policy_number` migration ready but Supabase MCP OAuth not authorized
- **269 oversized chunks**: Normalization Phase 2 pending (>2000 tokens)
- **66 massive PDF form chunks**: Strategic decision needed (split vs keep)
- **Embedding service**: Ollama/BGE-M3 local availability intermittent after HQ migration
- **PSI API 429 rate limit**: PageSpeed Insights returns 429 on day 5+ of consecutive pulls — pending Admin key rotation
- **Non-AIA fund NAV source**: 2 funds (`ES-GF-A`, `KF-CINCOME-A`) need different NAV source than aiaim.co.th — not yet automated
- **Article Register approval**: v3.1 awaiting BoB → แบงค์ approval to wire into daily report Section F

### Recent Work (2026-06-20 to 2026-08-11, W32 Audit)
- **Daily Analytics Pulls** (NEW Pipeline 7): 3 scripts (`pull-ga4.py`, `pull-gsc.py`, `pull-psi.py`) with retry/backoff, property hardcode, PSI skip-when-fresh. 12 contaminated GA4 files quarantined. Operational since Jul 21
- **Article Register v1-v3.1** (#70, NEW Pipeline 8): Per-article GSC analytics for 57 WealthBanks articles — v1 base stock → v2 index_status + URL inspection → v3 branded/generic query_type → v3.1 authority baseline DA=1, SERP floor DA per gap, phase 2 coverage gaps. HTML reports for BoB review. Awaiting approval for daily report Section F
- **Daily Intel Report** (NEW Pipeline 9): 20 HTML dashboards (Jul 21 — Aug 10) aggregating GA4+GSC+PSI+NAV freshness+promo expiry. Campaign tracking (8.8 campaign)
- **Fund NAV T177** (NEW Pipeline 10): 22 AIA fund NAVs refreshed periodically from aiaim.co.th, 24 fund JSON files regenerated. Freshness check (T030) integrated into Daily Intel
- **#226 Rider Section**: Rider table display (FA Tools navy header style) + unit annotations. Policies parser updated for Life/PA type field in new format. Safety rule: PA vs RCC never sum, use separate category keys
- **#213 Customer Report Generator**: Family mode, customer mode, JSON cache, validate-before-replace gate. Fixes: NaN bug for TRAD-only (hide UL sections), sub-1M M() format shows full number instead of "0.X ล้าน", PA disclaimer, FA Tools line removed from chart labels. Published to Supabase `report_index` (20 records)
- **#221 Storage**: Storage task completed
- **Google Stack Setup**: Automated GTM+GA4+GSC+IndexNow setup script (`scripts/google-stack-setup.py`, 259 lines)
- **Promo Lifecycle**: 9 promos expired Jun 30 (33→~14 active). Status normalization: `archived` → `expired`

### Prior Work (2026-06-18 to 2026-06-21)
- Customer Data Sync ETL: bulk import script + plan code decoder (pay_term/coverage_term)
- Investment fund ingestion: 603 fund rows from ePOS, Thai date/number parsing
- QA fixes: duplicate cleanup (7 records), updated_at on PATCH, CG/inactive filter (#126)
- Premium lookup: rider_premium vs premium_per_1000 documented, self-serve guide for ฟ้าใส
- Data contract: formal request/response spec for iAgencyAIA premium queries
- KB: 9 recruitment journey + bot persona chunks added (source=recruitment-bot-personas)
- Bug fix: display mapping (plan_code decode → pay_term/coverage_term), coordinated with BotDev
- SOP updates: MAW HEY ALWAYS rule, oracle name mapping (aia vs iagencyaia)

### Critical Incidents
- **2026-05-12**: 42K duplicate rows from skipped DELETE-before-INSERT → mandatory 5-step procedure enacted
- **2026-05-08**: Wrong promo tags sent to customer bot → promo data separation rules (customer_facing vs agent_only)
- **2026-06-20**: Sent `maw hey aia` instead of `maw hey iagencyaia` 3 times → customers waited 15+ min → oracle name mapping documented

## Owner & Contacts

| Role | Oracle | Notes |
|------|--------|-------|
| **Lead** | Data-Oracle | Chief Data Engineer, "The Alchemist" |
| **Supervisor** | BoB | Task assignment, monitoring |
| **Primary Consumer** | iAgencyAIA-Oracle (ฟ้าใส) | P0 priority — LINE bot customer queries |
| **Secondary Consumer** | Wingman-Oracle | Discord news content, promo data |
| **Verification** | QA-Oracle | Data quality audits |
| **Source Provider** | Researcher-Oracle | Market data, product research |
| **Infrastructure** | Admin-Oracle | BGE-M3 service, Supabase access |
