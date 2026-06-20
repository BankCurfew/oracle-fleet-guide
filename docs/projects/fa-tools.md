# FA Tools (iAgencyAIA)

## Overview

- **What it does**: Professional insurance advisory toolkit for Financial Advisors (FAs) at AIA Thailand. Provides fast premium quotation (iQuick), detailed financial planning (iPlan), multi-product comparison (iCompare), UnitLink investment simulation (iLink), portfolio management with gap analysis, Financial Health Check (FHC), lead tracking, and a digital application form — all via a PWA.
- **Who uses it**: Financial Advisors (authenticated), admin users (20+ config tabs), unauthenticated users (Basic Quick Mode for quick/plan/compare), and shared proposal viewers (public links, no auth).
- **Where it runs**: Production at `tools.iagencyaia.com`, staging at `fatools.vuttipipat.com` (both Cloudflare Pages). Backend on Supabase project `hztjrqlxrdsmxbkxojqg` (iAgencyAIA org).

## Architecture

### Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Frontend | React + TypeScript + Vite | 18.3.1 / 5.8.3 / 5.4.19 |
| Styling | Tailwind CSS + shadcn/ui (Radix) | 3.4.17 |
| Backend | Supabase (PostgreSQL + Auth + Edge Functions) | 2.81.1 |
| Data Fetching | TanStack React Query | 5.83.0 |
| Routing | React Router v6 | 6.30.1 |
| Forms | React Hook Form + Zod | 7.61.1 / 3.25.76 |
| Export | jsPDF + html2canvas + XLSX | 4.2.1 / 1.4.1 / 0.18.5 |
| Charts | Recharts | 2.15.4 |
| AI | OpenAI via Supabase Edge Functions | — |
| Icons | Lucide React | 0.462.0 |

### Key Services & Connections

```
Browser (PWA)
  ├── React SPA → Supabase REST API (product data, proposals, leads)
  ├── React SPA → Supabase Auth (GitHub OAuth)
  ├── React SPA → Edge Functions (chat, screenshots, fund scraping)
  └── Shared links → Public proposal viewer (no auth, RLS-gated)

Supabase
  ├── PostgreSQL (67+ tables, RLS on all)
  ├── 17 Deno Edge Functions
  ├── Auth (GitHub OAuth primary)
  └── AES-GCM 256-bit encryption (40+ sensitive fields)
```

### Database Tables (Key)

| Table | Purpose |
|-------|---------|
| `fa_profiles` | FA agent profiles (user_id, agent_code, vitalityStatus) |
| `insurance_products` | Product catalog — 117 products, 14,000+ premium records |
| `product_benefits` | Benefit definitions (100% i18n TH/EN) |
| `product_payouts` | Payout schedules per policy year |
| `sa_adjustments` | Sum assured adjustments per year |
| `proposals` | Generated proposals (share_token for public links) |
| `leads` | Customer/prospect records (soft-delete) |
| `insurance_applications` | Application submissions |
| `vitality_discounts` | Health discount rules (5 tiers) |
| `vitality_bundle_discounts` | Multi-product bundle discount rules |
| `special_discounts` | Campaign discounts (plan/family level) |
| `unitlink_product_config` | UnitLink product definitions |
| `unitlink_coi_rates` / `unitlink_cor_rates` | Cost of Insurance / Rider rates |
| `aia_funds` / `aia_fund_nav` | Mutual fund catalog + NAV history |
| `portfolio_customers` / `portfolio_policies` | Portfolio management |
| `app_settings` / `app_roles` | System config + RBAC |
| `admin_audit_log` | Audit trail |

Total: 67+ tables, 221 migrations.

## Code Structure

```
iagencyaiafatools/
├── src/
│   ├── pages/                      # 17 route-level components
│   │   ├── Dashboard.tsx           # Main hub (7 modes)
│   │   ├── Admin.tsx               # Admin console (20+ tabs)
│   │   ├── Profile.tsx             # FA profile, business cards, calendar
│   │   ├── SharedProposal.tsx      # Public shared views (1,650 LOC)
│   │   ├── AnalyzePolicy.tsx       # Portfolio management + gap analysis
│   │   └── ApplicationForm.tsx     # 6-step application form
│   │
│   ├── components/                 # 340+ files
│   │   ├── quickmode/              # iQuick fast quotation (17 files)
│   │   ├── planmode/               # iPlan detailed planning (23 files, 10.7K LOC)
│   │   ├── comparemode/            # iCompare multi-product (10 files)
│   │   ├── unitlink/               # UnitLink simulator (14 files)
│   │   ├── admin/                  # Admin dashboard (31 files)
│   │   ├── export/                 # PDF/image/Excel export (9 files)
│   │   ├── portfolio/              # Portfolio management (14 files)
│   │   ├── leads/                  # Lead management (7 files)
│   │   ├── profile/                # FA profile (9 files)
│   │   ├── financial-health/       # FHC scoring
│   │   └── ui/                     # shadcn/ui primitives (82 files)
│   │
│   ├── engine/ or hooks/           # 25 custom React hooks
│   │   ├── useAuth.ts
│   │   ├── useCachedData.ts        # 4-layer caching (IndexedDB → SessionStorage)
│   │   ├── useCompareMode.ts       # Compare state (1,580 LOC)
│   │   ├── usePermissions.ts       # RBAC
│   │   └── (21 more)
│   │
│   ├── lib/                        # 43 utility modules
│   │   ├── premium-calc.ts         # Core premium formula
│   │   ├── tax-calculator.ts       # Thai tax brackets (1,557 LOC)
│   │   ├── vitality-discount.ts    # Vitality scoring (356 LOC)
│   │   ├── special-discount.ts     # Campaign discounts (264 LOC)
│   │   ├── benefit-merge-utils.ts  # Multi-plan benefit combining (276 LOC)
│   │   ├── unitlink-utils.ts       # UnitLink calculations (1,175 LOC)
│   │   ├── rider-validation.ts     # Rider deps + clamping (169 LOC)
│   │   ├── health-calculator.ts    # FHC — 9 gap categories (36+ KB)
│   │   ├── i18n.ts                 # Translation dict (400+ labels)
│   │   ├── form-validation.ts      # Zod schemas (54 KB)
│   │   ├── export-utils.ts         # PDF/Excel formatting (77 KB)
│   │   └── encryption-utils.ts     # AES-GCM 256-bit
│   │
│   ├── integrations/supabase/
│   │   ├── client.ts               # Supabase singleton
│   │   └── types.ts                # Auto-generated types (138 KB)
│   │
│   ├── contexts/                   # i18n providers (App, Shared, Application, Chat)
│   └── data/                       # Static data (addresses, banks, nationalities)
│
├── supabase/
│   ├── functions/                  # 17 Deno Edge Functions
│   │   ├── api-gateway/            # Unified API entry + auth
│   │   ├── submit-lead/            # Lead webhook (10 req/min rate limit)
│   │   ├── insurance-chat/         # OpenAI Q&A
│   │   ├── encrypt-decrypt/        # Encryption service
│   │   ├── fetch-aia-funds/        # Live fund NAV scraper
│   │   ├── screenshot-proposal/    # Proposal → PNG/JPG
│   │   └── (11 more)
│   │
│   └── migrations/                 # 221 PostgreSQL migrations
│
├── CLAUDE.md                       # Architecture + dev rules
├── CLAUDE_code_conduct.md          # Code standards
├── CLAUDE_ui_conduct.md            # UI/UX standards
├── vite.config.ts                  # Build config
└── package.json
```

### Key Entry Points

| File | Purpose |
|------|---------|
| `src/pages/Dashboard.tsx` | Main hub — routes to 7 modes |
| `src/pages/Admin.tsx` | Admin console (20+ tabs) |
| `src/pages/SharedProposal.tsx` | Public shared proposal viewer |
| `src/components/PremiumCalculator.tsx` | Premium calc UI (2,828 LOC) |
| `supabase/functions/api-gateway/` | Unified API proxy with auth |

## Business Logic

### Premium Calculation

**Formula** (at `src/lib/rider-validation.ts:145`):
```
premium = (premium_per_1000 / 1000) × sum_assured
```

Where `premium_per_1000` comes from the `insurance_products` table, looked up by product UID, age, gender, and payment period. Riders are clamped to product `min_sa`/`max_sa` before calculation.

### Thai Tax Calculation (`src/lib/tax-calculator.ts`, 1,557 LOC)

Progressive brackets per Thai Revenue Code:

| Taxable Income (THB) | Rate |
|----------------------|------|
| 0 – 150,000 | 0% |
| 150,001 – 300,000 | 5% |
| 300,001 – 500,000 | 10% |
| 500,001 – 750,000 | 15% |
| 750,001 – 1,000,000 | 20% |
| 1,000,001 – 2,000,000 | 25% |
| 2,000,001 – 5,000,000 | 30% |
| > 5,000,000 | 35% |

- 8 income types: Section 40(1) through 40(8)
- Expense deduction rates: 50% for salary, 60% for business, etc.
- Occupation → income type mapping included

### Vitality Discount (`src/lib/vitality-discount.ts`, 356 LOC)

- **Tiers**: None, Bronze, Silver, Gold, Platinum
- **Eligibility**: Age 11+ (kids 0-10 excluded)
- **Lookup priority**: Plan name → Product family → Default
- **Bundle discount**: Count-based or combo-based multi-product discounts
- **Formula**: `discountedPremium = basePremium × (1 - discountRate / 100)`

### Special Discount / Campaigns (`src/lib/special-discount.ts`, 264 LOC)

- **Lookup priority**:
  1. Exact match: plan_name + payment_period
  2. Plan name only (payment_period = NULL in DB)
  3. Family level (plan_name = NULL)
- **Discount types**: `premium_per_sa` (Baht/1000), `cashback`, `bonus`
- **Duration**: `all_years`, `first_year`, `custom_years`
- **Formula (Baht/1000)**: `discountAmount = (sumAssured / 1000) × discount_value`
- **Validation**: min SA ≤ input ≤ max SA

### Benefit Merging (`src/lib/benefit-merge-utils.ts`, 276 LOC)

When multiple plans are combined, benefit values are merged by priority:
1. "จ่ายตามจริง" (actual payment) — use if present
2. Limiting condition (ไม่เกิน X) — if no actual payment
3. Sum numeric amounts — if no condition
4. "รวมอยู่ใน" (included in) — fallback

CI benefits merge by stage: early/intermediate → severe → other.

### Rider Dependencies (`src/lib/rider-validation.ts`, 169 LOC)

- **CI Top Up** requires **CI Plus** — SA must be exactly 40% of CI Plus SA
- CI/TPD riders clamp to product `max_sa` at API input time
- Payment period is independent of main contract

### Financial Health Check (`src/lib/health-calculator.ts`, 36+ KB)

Assesses 9 gap categories:
1. Life insurance gap
2. Health coverage gap
3. CI coverage gap
4. Accident coverage gap
5. Education fund gap
6. Retirement savings gap
7. Emergency fund gap
8. Debt repayment plan
9. Savings goal tracking

Output: Score /100, lifestyle badge, product recommendations.

### UnitLink (`src/lib/unitlink-utils.ts`, 1,175 LOC)

COI/COR rates, UDR vs PPR comparison, withdrawal simulation, projection calculations.

## API Endpoints

### Edge Functions (Supabase)

All at `https://<project>.supabase.co/functions/v1/<name>`

| Function | Method | Purpose |
|----------|--------|---------|
| `api-gateway` | * | Unified API proxy with auth (X-API-Key or Bearer JWT) |
| `submit-lead` | POST | Lead creation webhook. Rate limit: 10/min. Validates Thai phone, email, age 0-120. |
| `insurance-chat` | POST | OpenAI insurance Q&A (context-aware) |
| `encrypt-decrypt` | POST | AES-GCM 256-bit encrypt/decrypt service |
| `fetch-aia-funds` | GET | Scrape live AIA fund NAV |
| `fetch-fund-factsheet` | GET | Fund factsheet retrieval |
| `screenshot-proposal` | POST | Proposal → PNG/JPG |
| `generate-business-card` | POST | FA business card generation |
| `generate-reminders` | POST | Follow-up reminder generation |
| `soft-delete-lead` | POST | Lead soft deletion with audit |
| `sync-application-to-lead` | POST | Link application to lead record |
| `update-fund-cron-schedule` | POST | CRON management (JWT auth) |
| `migrate-encrypt` | POST | Encryption migration (JWT auth) |
| `parse-fund-peer-avg` | POST | Fund benchmarking |
| `sync-peer-avg` | POST | Peer comparison sync |
| `backfill-lead-sync` | POST | Data backfill utility |
| `migrate-proposals-to-policies` | POST | Data migration |

### Frontend Routes

| Route | Component | Purpose |
|-------|-----------|---------|
| `/` | Dashboard | Main hub (7 modes) |
| `/admin` | Admin | Admin console (20+ tabs) |
| `/profile` | Profile | FA profile, cards, calendar |
| `/iquick/:token` | SharedProposal | Public iQuick view |
| `/iplan/:token` | SharedProposal | Public iPlan view |
| `/icompare/:token` | SharedProposal | Public iCompare view |
| `/ilink/:token` | SharedProposal | Public iLink view |
| `/analyze` | AnalyzePolicy | Portfolio gap analysis |
| `/application/:token` | ApplicationForm | 6-step form |

## Deployment

### Build & Deploy (MANUAL ONLY)

```bash
npm run build

CLOUDFLARE_API_TOKEN=$(grep CLOUDFLARE_API_TOKEN ~/.env) \
  npx wrangler pages deploy dist/ --project-name=fatools --commit-dirty=true
```

**CRITICAL**: Auto-deploy on Cloudflare Pages is DISABLED — produces different chunk hashes than local builds, causing white screen.

### Post-Deploy Verification (mandatory)

```bash
PROD_INDEX=$(curl -sL https://tools.iagencyaia.com/ | grep -oP 'index-[^"/.]+' | head -1)
LOCAL_INDEX=$(ls dist/assets/index-*.js | xargs basename | grep -oP 'index-[^.]+' | sort | tail -1)
echo "Production: $PROD_INDEX | Local: $LOCAL_INDEX"
# MUST match. If not, redeploy.
```

### Branch Strategy

| Branch | Environment | URL |
|--------|-------------|-----|
| `staging` | Staging | fatools.vuttipipat.com |
| `main` | Production | tools.iagencyaia.com |

Flow: Push staging → test → merge main → deploy production.

### Environment Variables

| Variable | Scope | Purpose |
|----------|-------|---------|
| `VITE_SUPABASE_PROJECT_ID` | Client | Project ID |
| `VITE_SUPABASE_PUBLISHABLE_KEY` | Client | Anon key |
| `VITE_SUPABASE_URL` | Client | Project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Server | Edge function ops |
| `OPENAI_API_KEY` | Server | Insurance chat |
| `ENCRYPTION_KEY` | Server | Data encryption |
| `CLOUDFLARE_API_TOKEN` | Deploy | Wrangler deploy |

### Dependencies

- Node.js / Bun (build)
- Wrangler CLI (Cloudflare deploy)
- Supabase CLI (migrations, edge functions)

## Current State

### What's Working

- All 7 modes operational (iQuick, iPlan, iCompare, iLink, Portfolio, FHC, Leads)
- 117 insurance products with premium data
- Vitality + special discount engines
- Public shared proposal links
- Admin console with 20+ configuration tabs
- i18n (TH/EN) at 100% DB column coverage
- AES-GCM encryption on 40+ sensitive fields
- RLS on all tables

### Known Issues / Technical Debt

| Issue | Severity | Detail |
|-------|----------|--------|
| TypeScript `strict: false` | Medium | No strict null checks, no implicit any checks |
| Zero test files | High | No Vitest/Jest setup |
| Rate limits only on `submit-lead` | Medium | Other edge functions unprotected |
| 20+ `any` usages | Low | Should be typed interfaces |
| Component bloat | Low | CompareMode.tsx (74KB), SharedProposal.tsx (1,650 LOC) |

### Historical Incidents

1. **`select('*')` silent column mismatch** (2026-03-20) — Column `discount_duration` removed from query but only `discount_duration_years` exists. All discounts broken for 23 days undetected.
2. **CI/Accident paymentPeriod=0 falsy check** (2026-04-12) — `0 || undefined` converted valid zero to undefined, breaking special discounts for CI/Accident products.
3. **Silent try/catch** — Multiple catch blocks swallowed errors without logging.

### Recent Commits

| Hash | Description |
|------|-------------|
| `1b020398` | fix: FHC result_data sync + ScoreGauge arc direction |
| `49bf67cc` | fix: vitalityStatus was hardcoded 'none' |
| `437ea5b6` | fix: HB Extra premium + /applications 500 error |
| `228295b7` | feat: POST /fhc/create + GET /fhc/:token API |
| `c4c06ea5` | fix: P0 age-band rider premiums + refresh endpoint |
| `3e95fd39` | feat: POST /proposals/:token/refresh endpoint |
| `e1c29e1a` | feat: POST /applications endpoint + form_type enforcement |

## Owner & Contacts

| Role | Oracle | Responsibility |
|------|--------|---------------|
| **Lead** | BotDev | Code, APIs, edge functions, architecture |
| **QA** | QA | Testing, validation, edge cases |
| **Design** | Designer | UI/UX, mockups |
| **Data** | Data | KB embeddings, fund data pipelines |
| **Conduct** | DocCon | Code quality audit, conduct compliance |

## Codebase Stats

| Metric | Value |
|--------|-------|
| Components | 340+ |
| Pages | 17 |
| Custom Hooks | 25 |
| Edge Functions | 17 |
| Database Tables | 67+ |
| Migrations | 221 |
| Utility Modules | 43 |
| Insurance Products | 117 |
| Premium Records | 14,000+ |
| Estimated LOC | ~120,000 |
