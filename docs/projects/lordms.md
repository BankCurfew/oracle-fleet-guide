# LordMS

## Overview

- **What it does**: Encrypted, PDPA-compliant venue management system for The Lord Group — a luxury entertainment venue in Bangkok, Thailand. First modern web-based entertainment venue management system built specifically for Thai market with full column-level encryption.
- **Who uses it**: Venue owners, managers, receptionists, cashiers, and staff at The Lord Group
- **Where it runs**: Cloudflare Workers (OpenNext), self-hosted Supabase (PostgreSQL)
- **Repository**: `BankCurfew/LordMS`
- **Version**: v0.1.0 (49 commits)

## Architecture

### Tech Stack

| Layer | Technology | Details |
|-------|-----------|---------|
| **Frontend** | Next.js 15 + TypeScript | App Router, Server Actions, ISR |
| **UI** | Tailwind CSS + shadcn/ui | Dark luxury theme (Navy `#0D1117` / Gold `#D4A843`) |
| **Backend** | Self-hosted Supabase | Docker-based PostgreSQL, RLS on all tables |
| **Database** | PostgreSQL 15+ | Row-level security, pgcrypto |
| **Encryption** | AES-256-GCM (node:crypto) | Column-level encryption for all PII, envelope encryption (DEK/KEK) |
| **Auth** | Supabase Auth + TOTP | 2FA with QR enrollment, MFA required for sensitive routes |
| **Deployment** | Cloudflare Workers (OpenNext) | Edge deployment via Wrangler |
| **Testing** | Vitest | 12 test files, 69+ unit tests |
| **Export** | jsPDF + jsPDF-autotable, xlsx | Branded PDF reports with Thai font embedding |
| **Language** | Thai-first UI | Thai labels, localized date/currency formatting |

### Encryption Architecture

```
                    ┌──────────────────────┐
                    │   Environment Var     │
                    │   LORDMS_KEK          │
                    │   (32 bytes base64)   │
                    └──────────┬───────────┘
                               │
                    ┌──────────▼───────────┐
                    │   KEK (Key Encrypt   │
                    │   Key) — wraps DEKs   │
                    └──────────┬───────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
       ┌──────────┐     ┌──────────┐     ┌──────────┐
       │  DEK:     │     │  DEK:     │     │  DEK:     │
       │ customers │     │  staff    │     │ payments  │
       └─────┬────┘     └─────┬────┘     └─────┬────┘
             │                │                │
             ▼                ▼                ▼
       name_enc          name_enc         reference_enc
       phone_enc         phone_enc        payment_details_enc
       id_card_enc       id_card_enc
       preferences_enc   address_enc
       notes_enc
```

- **At Rest**: AES-256-GCM column-level encryption on all PII fields (`_enc` suffix)
- **In Transit**: TLS 1.3 (HTTPS + Supabase connection)
- **Passwords**: argon2id (Supabase Auth built-in)
- **Keys**: Envelope encryption — DEK per table, KEK in environment variable

### RBAC (Role-Based Access Control)

| Role | Dashboard | Rooms | POS | CRM | Staff | Reports | Inventory | Settings |
|------|-----------|-------|-----|-----|-------|---------|-----------|----------|
| **Owner** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (MFA) |
| **Manager** | ✅ | ✅ | ✅ | ✅ (MFA) | ✅ (MFA) | ✅ (MFA) | ✅ | ❌ |
| **Receptionist** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Cashier** | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Staff** | ✅ (own) | ❌ | ❌ | ❌ | own only | ❌ | ❌ | ❌ |

## Code Structure

```
LordMS/
├── src/
│   ├── app/                              # Next.js 15 App Router
│   │   ├── login/page.tsx                # Thai login (Crown logo, LordMS brand)
│   │   ├── login/actions.ts              # Server-side auth
│   │   ├── auth/callback/route.ts        # OAuth/email confirmation
│   │   ├── auth/mfa-verify/page.tsx      # TOTP 2FA verification
│   │   └── dashboard/                    # Main app (9 modules)
│   │       ├── page.tsx                  # KPI dashboard (8 panels)
│   │       ├── rooms/page.tsx            # Room board (status grid)
│   │       ├── pos/page.tsx              # POS terminal
│   │       ├── crm/page.tsx              # Member search + tier summary
│   │       ├── crm/[id]/page.tsx         # Customer detail
│   │       ├── models/page.tsx           # Model grid (grades, ranking)
│   │       ├── models/[id]/page.tsx      # Model profile (revenue, schedule)
│   │       ├── staff/page.tsx            # Staff grid + commissions
│   │       ├── attendance/page.tsx       # Check-in/out + streaks
│   │       ├── inventory/page.tsx        # Stock management
│   │       ├── reports/page.tsx          # Analytics + PDF/CSV export
│   │       └── settings/page.tsx         # Admin config (RBAC, MFA, encryption)
│   │
│   ├── components/                       # 140+ React components
│   │   ├── ui/                           # shadcn/ui base (button, card, dialog, etc.)
│   │   ├── dashboard/                    # KPI cards, charts, activity feed
│   │   ├── rooms/                        # Room board, cards, floor tabs, timer
│   │   ├── pos/                          # Terminal, bill panel, payment buttons
│   │   ├── crm/                          # Member table, search, profile
│   │   ├── models/                       # Model card, grid, profile, schedule calendar
│   │   ├── staff/                        # Staff grid, commission table, shift schedule
│   │   ├── attendance/                   # Check-in panel, streak calendar, milestones
│   │   ├── inventory/                    # Stock table, low-stock alerts
│   │   ├── reports/                      # Export dialog, period selector, charts
│   │   ├── settings/                     # User/room/staff/grade/commission CRUD
│   │   └── layout/                       # Sidebar, dashboard shell, breadcrumb
│   │
│   ├── lib/
│   │   ├── supabase/                     # Client initialization (server + middleware)
│   │   ├── queries/                      # Data fetching (members, rooms, staff)
│   │   ├── actions/                      # Server Actions (rooms, orders, customers, staff, models, attendance, inventory, settings)
│   │   ├── business/                     # Business logic (calculations, formatting)
│   │   ├── export/                       # PDF/CSV export pipeline (Thai fonts)
│   │   ├── database.types.ts             # Autogenerated Supabase types (238 lines)
│   │   └── utils.ts                      # Utility functions
│   │
│   ├── hooks/
│   │   ├── use-mobile.tsx                # Responsive breakpoint detection
│   │   └── use-action.ts                 # Server Action wrapper
│   │
│   └── styles/
│       └── theme.ts                      # Dark luxury theme tokens
│
├── lib/                                  # Shared libraries (outside src/)
│   ├── auth/
│   │   ├── rbac.ts                       # Role hierarchy, canAccess(), route permissions
│   │   ├── types.ts                      # Role enum, AuthUser, RoutePermission
│   │   ├── totp.ts                       # TOTP generation/verification
│   │   ├── validate-redirect.ts          # Open-redirect protection
│   │   └── __tests__/                    # RBAC + TOTP + redirect tests
│   │
│   ├── crypto/
│   │   ├── aes.ts                        # AES-256-GCM encrypt/decrypt (68 lines)
│   │   ├── envelope.ts                   # DEK/KEK wrapping (40 lines)
│   │   ├── fields.ts                     # Per-field encryption config
│   │   ├── vault.ts                      # Software key vault
│   │   └── __tests__/                    # Envelope + AES roundtrip tests
│   │
│   └── inventory/
│       ├── queries.ts                    # Stock queries
│       ├── alerts.ts                     # Low-stock / reorder logic
│       └── __tests__/                    # Alert tests
│
├── supabase/migrations/                  # Database schema (1,210 lines total)
│   ├── 20260526_lordms_foundation.sql    # 671 lines — core schema
│   ├── 20260527_security_hardening.sql   # 182 lines — RLS policies
│   ├── 20260527_fix_rls_recursion.sql    # 39 lines — RLS edge-case
│   ├── 20260527_models_grades.sql        # 137 lines — models module
│   ├── 20260527_model_attendance.sql     # 139 lines — attendance
│   └── 20260603_custom_schedule.sql      # 42 lines — scheduling
│
├── docs/
│   ├── proposals/system-design-v1.md     # Architecture spec (257 lines)
│   ├── dashboard-redesign-spec.md        # Dashboard UI spec (311 lines)
│   ├── pos-redesign-spec.md              # POS terminal spec (303 lines)
│   ├── design-tokens-spec.md             # Color/typography tokens (292 lines)
│   └── pdf-report-template-spec.md       # Branded PDF spec (220 lines)
│
├── middleware.ts                          # Next.js middleware (auth callback)
├── tailwind.config.ts                    # Dark theme, luxury tokens, animations
├── wrangler.jsonc                        # Cloudflare Workers config
├── open-next.config.ts                   # OpenNext for Cloudflare
└── package.json                          # v0.1.0, 44 dependencies
```

### Key Files

| File | Purpose |
|------|---------|
| `src/app/dashboard/page.tsx` | Main dashboard — 8 KPI panels (revenue, occupancy, active rooms, charts) |
| `src/app/dashboard/pos/page.tsx` | POS terminal — calculator-style billing, payment processing |
| `src/app/dashboard/rooms/page.tsx` | Room board — color-coded grid, check-in/out, floor tabs |
| `lib/auth/rbac.ts` | RBAC — role hierarchy, route permissions, pattern matching (96 lines) |
| `lib/crypto/aes.ts` | AES-256-GCM encrypt/decrypt using node:crypto (68 lines) |
| `lib/crypto/envelope.ts` | DEK/KEK envelope encryption (40 lines) |
| `src/lib/database.types.ts` | Autogenerated Supabase types (238 lines) |
| `supabase/migrations/20260526_lordms_foundation.sql` | Complete DB schema (671 lines) |

## Business Logic

### 9 Application Modules

#### 1. Dashboard (`/dashboard`)
- 8 KPI panels: today's revenue, occupancy %, active rooms, avg hours/customer
- Revenue chart (weekly/monthly, Recharts), room status donut, peak hours heatmap
- Activity feed, top services, payment method breakdown

#### 2. Room Management (`/dashboard/rooms`)
- Room board: grid color-coded by status (green=available, amber=occupied, red=cleaning, blue=reserved)
- Floor tabs for filtering
- Check-in/check-out with automatic session creation in Supabase
- Room timer tracking occupancy duration

#### 3. POS Terminal (`/dashboard/pos`)
- Calculator-style UI: service selection, quantity, time/extras
- Bill panel: running total, subtotal, discount, tax, final amount
- Payment methods: cash, PromptPay QR, card, bank transfer
- Receipt generation via jsPDF

#### 4. CRM & Membership (`/dashboard/crm`)
- Member search by name/phone/ID (encrypted fields decrypted on client)
- Tier system: regular → silver → gold → platinum (based on visits + spend)
- Visit history, points balance, preferences
- PDPA consent tracking (right to access, right to delete)

#### 5. Staff & Models (`/dashboard/staff`, `/dashboard/models`)
- Staff grid with photo cards, availability status, daily commission earned
- Model profiles: grade, rating, monthly revenue, customer count, rank
- Commission tracking: daily/weekly/monthly earned amounts
- Shift scheduling: morning/afternoon/evening/night or custom time ranges

#### 6. Attendance (`/dashboard/attendance`)
- Daily check-in/check-out with date selector and model search
- Attendance stats: today/week/month presence rate
- Streak bonuses: configurable rewards for consecutive attendance days
- Streak calendar: heatmap grid showing consecutive days

#### 7. Inventory (`/dashboard/inventory`)
- Stock table: SKU, name, current stock, min stock, cost, supplier
- Low-stock alerts when item drops below minimum threshold
- Stock movements audit: purchase, usage, adjustment, waste, transfer
- Categories: beverage, food, supply, amenity, equipment

#### 8. Reports & Analytics (`/dashboard/reports`)
- Period selector (date range picker)
- Revenue chart, service breakdown, staff performance ranking
- Export: branded PDF (Thai fonts via jsPDF) and CSV (via xlsx)

#### 9. Settings & Administration (`/dashboard/settings`)
- User management: add/remove staff, assign roles
- CRUD: rooms, staff, models, grades, commissions
- Venue config: hours of operation, tax rate, room pricing
- Security: MFA enforcement, session timeout, key management

### Database Schema (7 Core Table Groups)

#### 1. Profiles & Auth
- `profiles` — extends Supabase Auth (role, display_name, avatar)
- Roles: `owner`, `manager`, `receptionist`, `cashier`, `staff`

#### 2. Rooms
- `rooms` — room_number, floor, type (standard/vip/suite/premium), status (available/occupied/cleaning/reserved/maintenance), base_price_per_hour, capacity, amenities
- `room_sessions` — checked_in_at, checked_out_at, guest_count, staff_ids, total_amount

#### 3. Staff & Models
- `staff_profiles` — employee_code, name_enc, phone_enc, id_card_enc, address_enc, hire_date, base_salary, commission_rate
- `models` — name, photo_url, grade_id, status
- `grades` — name, level, price (service tier pricing)
- `staff_shifts` — shift_type (morning/afternoon/evening/night), start_time, end_time
- `staff_commissions` — session_id, order_id, amount, earned_at
- `commissions` — per-service-type rate configuration

#### 4. Attendance
- `model_attendance` — date, check_in, check_out, status (present/absent/late/half_day/leave)
- `model_schedules` — shift, date, start_time, end_time, approved, repeat_group_id
- `streak_bonuses` — streak_days threshold, bonus_amount

#### 5. CRM
- `customers` — customer_code, name_enc, phone_enc, id_card_enc, preferences_enc, notes_enc, tier (regular/silver/gold/platinum), points, total_spent, visit_count, consent_given, consent_date
- `visit_logs` — customer_id, session_id, staff_ids, amount_spent, points_earned, notes_enc

#### 6. POS & Orders
- `services` — name, category, price, duration_minutes
- `orders` — order_number, session_id, customer_id, status (open/closed/void), subtotal, discount_amount, tax_amount, total_amount
- `order_items` — service_id, quantity, unit_price, total_price
- `payments` — method (cash/promptpay/card/transfer), status (pending/completed/refunded/void), amount, reference_enc, payment_details_enc
- `daily_close` — close_date, total_revenue, payment breakdown, room_sessions_count

#### 7. Inventory
- `inventory_items` — sku, name, category (beverage/food/supply/amenity/equipment), current_stock, min_stock, cost_per_unit, supplier
- `stock_movements` — item_id, movement_type (purchase/usage/adjustment/waste/transfer), quantity, notes_enc, performed_by

### Encrypted Columns (All PII)

| Table | Encrypted Fields |
|-------|-----------------|
| `customers` | name_enc, phone_enc, id_card_enc, preferences_enc, notes_enc |
| `staff_profiles` | name_enc, phone_enc, id_card_enc, address_enc |
| `payments` | reference_enc, payment_details_enc |
| `visit_logs` | notes_enc |
| `room_sessions` | notes_enc |
| `stock_movements` | notes_enc |

### PDPA Compliance

- Consent forms before data collection (`consent_given`, `consent_date`)
- Right to access (ขอดูข้อมูล) — member can view own data
- Right to delete (ขอลบข้อมูล) — soft delete + full record deletion
- Data retention policy (configurable auto-purge, planned)
- All customer PII encrypted at rest (cannot be leaked in plaintext)

## API Endpoints

LordMS uses **Next.js Server Actions** (not REST API endpoints). Key actions:

| Action Module | Location | Operations |
|--------------|----------|------------|
| `rooms` | `src/lib/actions/rooms.ts` | Check-in, check-out, status change, create/update room |
| `orders` | `src/lib/actions/orders.ts` | Create order, add items, process payment, void, daily close |
| `customers` | `src/lib/actions/customers.ts` | Create/update member, search, manage consent |
| `staff` | `src/lib/actions/staff.ts` | Create/update staff, manage shifts, calculate commissions |
| `models` | `src/lib/actions/models.ts` | Create/update models, grade assignment, ranking |
| `attendance` | `src/lib/actions/attendance.ts` | Check-in/out, streak calculation, bonus milestones |
| `inventory` | `src/lib/actions/inventory.ts` | Stock movement, reorder alerts, item CRUD |
| `settings` | `src/lib/actions/settings.ts` | User management, venue config, RBAC, MFA |

### Supabase RPC Functions

- Row-level security policies enforce RBAC at database level
- All queries go through Supabase JS client (no direct SQL from frontend)
- Server Actions handle encryption/decryption before DB operations

## Deployment

### Build & Deploy

```bash
# Local development
npm install
npm run dev

# Run tests
npm test
npm run test:watch

# Deploy to Cloudflare Workers
npm run build
npm run deploy        # wrangler deploy
```

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon key (RLS-protected) |
| `SUPABASE_SERVICE_ROLE_KEY` | Server-side operations |
| `LORDMS_KEK` | Key Encryption Key (32 bytes base64) |

### Supabase Setup

```bash
supabase link --project-ref [PROJECT_REF]
supabase migration up
supabase gen types typescript > src/lib/database.types.ts
```

### UI Theme

| Token | Value | Usage |
|-------|-------|-------|
| Background (Navy) | `#0D1117` | Page background |
| Primary (Gold) | `#D4A843` | CTAs, accents, highlights |
| Gold Light | `#F0D78C` | Hover states |
| Gold Dark | `#B8912A` | Active states |
| Available (Green) | `#3FB950` | Room available status |
| Occupied (Amber) | `#F77966` | Room occupied status |
| Cleaning (Red) | `#F85149` | Room cleaning status |
| Reserved (Blue) | `#58A6FF` | Room reserved status |

Custom animations: `pulse-gold` (glow, 2s), `timer-tick` (occupancy, 1s), `glow-green`/`glow-red` (status indicators)

## Current State

### What's Working
- Full dashboard with 8 KPI panels and Recharts visualizations
- Room management with status board, check-in/check-out, floor tabs
- POS terminal with calculator-style billing and 4 payment methods
- CRM with tier system, member search, encrypted PII
- Staff & model management with grades, commissions, rankings
- Attendance with streak bonuses and calendar heatmap
- Custom scheduling (time ranges, repeat patterns, approval workflow)
- Inventory with low-stock alerts and movement audit
- PDF/CSV export with branded Thai-font reports
- AES-256-GCM encryption on all PII columns
- RBAC with 5 roles + MFA on sensitive routes
- 69+ unit tests passing

### Known Issues / Planned
- Some components use mock/demo data alongside Supabase (UI development mode)
- PDPA auto-purge retention policy not yet implemented
- Backup encryption not yet integrated
- DPO assignment UI not yet built
- Mobile app (React Native) planned for future phase
- Real-time Supabase subscriptions for room status planned

### Recent Commits

| Hash | Description |
|------|------------|
| `58118f8` | feat: scheduling module + 27 tests |
| — | fix: dashboard progress bar alignment |
| — | fix: schedule day count + calendar display |
| — | fix: wire all broken buttons (12 elements fixed) |
| — | feat: custom work schedule (time range, repeat pattern) |
| — | feat: Models tab (rich card grid) |
| — | feat: extract business logic + 69 unit tests |

## Owner & Contacts

| Role | Oracle | Responsibility |
|------|--------|---------------|
| **Lead** | Dev-Oracle | Code, architecture, deployment |
| **QA** | QA-Oracle | Testing, validation |
| **Security** | Security-Oracle | Encryption audit, PDPA compliance |
| **Design** | Designer-Oracle | UI/UX, dark luxury theme |
| **Project** | BoB-Oracle | Orchestration, client coordination |
