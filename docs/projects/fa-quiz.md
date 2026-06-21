# FA Recruitment Quiz (iJourney)

## Overview

- **What it does**: RPG-style interactive psychometric assessment for financial advisor candidates at iAgencyAIA. Candidates navigate 8 story-driven chapters with Thai AI-generated narration, answering 24 questions. The system evaluates fit across 8 core dimensions and assigns one of 9 career archetypes.
- **Who uses it**: FA candidates (via LINE LIFF or direct link), recruiters/admins (admin dashboard for submissions and analytics)
- **Where it runs**: https://journey.iagencyaia.com (Cloudflare Pages), Supabase backend

## Architecture

### Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Frontend | React 19 + TypeScript + Vite 8.0.1 | Latest |
| Styling | Tailwind CSS + Framer Motion 12.38 | — |
| Backend | Supabase (Postgres + Auth + REST) | — |
| Audio | Howler.js 2.2.4 + ElevenLabs v2.40 | TTS narration |
| Avatars | DiceBear (Notionists) v9.4.2 | Character SVGs |
| Charts | Recharts 3.8.1 | Radar visualization |
| Sharing | html-to-image 1.11.13 | Screenshot export |
| Messaging | LINE LIFF SDK v2.28 | LINE embed |
| Deployment | Cloudflare Pages + Wrangler | Static CDN |

### Key Services

```
Browser (React SPA)
  ↓ REST API
Supabase (Postgres + RPC functions)
  ↓ Storage
Supabase DB (quiz_sessions, quiz_calibration, quiz_predictions, quiz_events, quiz_answers)
```

### Database Tables

| Table | Purpose |
|-------|---------|
| `quiz_sessions` | Core session tracking — visitor, phone, card, tier, dimension scores, share token, device info |
| `quiz_calibration` | Psychometric data — raw/normalized scores, answer timings, faking severity |
| `quiz_predictions` | Recruiter verdict tracking — predicted vs actual tier, accepted/rejected |
| `quiz_events` | Funnel event tracking (quiz_start, question_shown, answer_given, etc.) |
| `quiz_answers` | Individual answer records |
| `quiz_admin_users` | Admin authentication |
| `client_share_links` | Share token mappings |

**Key RPC Functions**: `quiz_dashboard_stats()`, `quiz_tier_distribution()`, `quiz_card_distribution()`, `quiz_daily_trend(days)`, `complete_quiz_session(...)`, `lookup_session_by_phone(phone)`

## Code Structure

```
fa-recruitment-quiz/
├── src/
│   ├── components/
│   │   ├── QuizAppV6.tsx           # Main quiz driver (v6 state machine)
│   │   ├── SceneView.tsx           # Question/scene renderer
│   │   ├── PrologueView.tsx        # Star Wars crawl intro
│   │   ├── CardRevealV6.tsx        # Tarot card animation
│   │   ├── ResultScreenV6.tsx      # Result display + radar chart
│   │   ├── SharedResultPage.tsx    # Share link result viewer
│   │   ├── RadarChart.tsx          # Recharts radar visualization
│   │   ├── PathWikiCards.tsx        # Career archetype encyclopedia
│   │   ├── PhoneModal.tsx          # Phone collection gate
│   │   ├── InfoFormGate.tsx        # Name/date/consent form
│   │   ├── GateScreens.tsx         # Disqualification/exit pages
│   │   ├── personalization.ts      # Geolocation, device detection
│   │   ├── share-utils.ts          # Share token generation
│   │   ├── EpilogueView.tsx       # Story epilogue after result
│   │   ├── CharacterSheet.tsx     # Detailed character profile view
│   │   ├── SceneParticles.tsx     # Ambient particle effects per scene
│   │   ├── RankingView.tsx        # Leaderboard / ranking display
│   │   ├── RecruitCTA.tsx         # Recruitment call-to-action page
│   │   └── TarotCard.tsx          # Animated tarot card component
│   │
│   ├── engine/                     # Core quiz logic
│   │   ├── scoring-v6.ts           # Scoring pipeline (264 lines)
│   │   ├── types-v6.ts             # TypeScript interfaces (102 lines)
│   │   ├── questions-v6.ts         # 24 questions + choices + scoring (335 lines)
│   │   ├── cards-v6.ts             # 9 card definitions (Thai lore, career paths)
│   │   ├── tracking.ts             # Supabase session/event logging
│   │   ├── calibration.ts          # Psychometric data collection
│   │   ├── anti-faking.ts          # Speed flag, all-high pattern detection
│   │   ├── audio.ts                # Howler.js integration
│   │   ├── liff.ts                 # LINE LIFF SDK wrapper
│   │   ├── phone.ts                # Phone normalization
│   │   ├── preload.ts              # Asset preloading
│   │   ├── adapter-v6.ts           # v6 adapter utilities
│   │   ├── action-logger.ts        # User action logging to quiz_events
│   │   ├── questions-sq.ts         # Supplementary question bank
│   │   ├── scoring-v6.test.ts      # Scoring unit tests (Vitest)
│   │   └── tracking.test.ts        # Tracking unit tests (Vitest)
│   │
│   ├── admin/                      # Admin dashboard
│   │   ├── AdminApp.tsx            # Router
│   │   └── pages/
│   │       ├── AdminDashboard.tsx   # Overview, stats, tier distribution
│   │       ├── ProspectTable.tsx    # Searchable candidate table
│   │       ├── ProspectDetail.tsx   # Individual submission details
│   │       ├── AdminActionLog.tsx   # User action audit trail
│   │       ├── AdminWiki.tsx        # Card encyclopedia
│   │       ├── AdminLogin.tsx       # Auth gate
│   │       └── ThaiMap.tsx          # Regional analytics
│   │
│   ├── App.tsx                     # Router: /admin, /share/:token, quiz routes
│   └── main.tsx                    # React entry
│
├── public/
│   ├── scenes/                     # 70+ Ghibli-style backgrounds (webp)
│   ├── audio/                      # BGM, narration, ambient sounds
│   ├── avatars/                    # Character archetype SVGs
│   ├── cards/                      # Tarot card assets
│   └── fonts/                      # Custom fonts
│
├── supabase/migrations/            # 8 database migrations
├── docs/                           # Question specs, narration scripts, scoring docs
├── vite.config.ts                  # Build config + Cloudflare asset hashing
└── .env.example                    # VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY, VITE_LIFF_ID
```

### Key Files

| File | Purpose |
|------|---------|
| `src/engine/scoring-v6.ts` | Full scoring pipeline: gate → normalize → tier → card |
| `src/engine/questions-v6.ts` | All 24 questions with exact per-choice scores |
| `src/engine/types-v6.ts` | TypeScript types: DimensionV6, TierV6, CardV6, WorkModeV6 |
| `src/engine/cards-v6.ts` | 9 card content (name, traits, income, lore, next steps) |
| `src/engine/anti-faking.ts` | Speed flags, all-high pattern, low variance detection |
| `src/components/QuizAppV6.tsx` | Main quiz state machine and reducer |

## Business Logic

### Dimensions (8 Core + Track Record)

```typescript
// src/engine/types-v6.ts:7-23
type DimensionV6 = 'drive' | 'resilience' | 'relationship' | 'discipline'
                 | 'market' | 'growth' | 'optimism' | 'persuasiveness'
```

| Dimension | Thai Label | Achievable Avg |
|-----------|-----------|----------------|
| drive | เป้าหมาย/แรงขับ | 2.20 |
| resilience | ล้มแล้วลุก | 1.64 |
| relationship | ทักษะคน | 2.25 |
| discipline | วินัย/สม่ำเสมอ | 2.27 |
| market | เครือข่าย | 1.80 |
| growth | การเรียนรู้ | 2.17 |
| optimism | มุมมองเชิงบวก | 1.33 |
| persuasiveness | พลังโน้มน้าว | 1.57 |

Track Record: separate 0-3 scale from 3 questions (TR1, TR2, TR3).

### Question Structure (24 Questions, 8 Chapters)

| Chapter | Scene | Questions | Type |
|---------|-------|-----------|------|
| 1 | ประตูหมู่บ้าน (Village Gate) | SG1, SG2 | Soft Gate (ethics) |
| 2 | ทุ่งกว้าง (Wide Fields) | W1, W2 | Work Mode |
| 3 | ร่องรอยบนเขา (Mountain Traces) | TR1, TR2, TR3 | Track Record |
| 4 | ค่ายพักกลางทาง (Midway Camp) | SJT1-5, MW1, MW2 | Situational Judgment + Market Wealth |
| 5 | หมู่บ้านกลางทาง (Midway Village) | SJT5-9 | Situational Judgment |
| 6 | รอบกองไฟ (Campfire) | FC1, FC2, FC3 | Forced Choice |
| 7 | สนามแข่ง (Arena) | SJT7-9 | SJT conclusion |
| 8 | ยอดเขา (Mountain Peak) | FC4, FC5, FC6 | Forced Choice + result reveal |

### Scoring Pipeline

**Full pipeline** (`src/engine/scoring-v6.ts:232-263`):

```
1. Soft Gate Check  →  sgTotal >= 1.5 = auto-Wanderer (Not_Suitable)
2. Work Mode        →  FT (full_time + 3+ days) or PT
3. Normalize Scores →  scale each dim to 0-3 range
4. Track Record     →  average of TR1, TR2, TR3 (0-3 each)
5. Consistency      →  flag contradictory answer pairs
6. Tier             →  Leader / FA_Prime / FA_Standard / Standard_Agent / Not_Suitable
7. Demotion         →  weak dims or consistency flags → demote 1 level
8. Card Assignment  →  per-card dimension gates within tier
```

#### Step 1: Soft Gate

```typescript
// src/engine/scoring-v6.ts:40-43
function checkSoftGateV6(state): { pass: boolean } {
  return { pass: state.sgTotal < 1.5 }
}
```

- SG1 (Market stall, no owner): honesty test. Choices: 0.0-0.5
- SG2 (Bridge lost purse): responsibility test. Choices: 0.0-1.0
- Fail threshold: `sgTotal >= 1.5` → auto-disqualify as Wanderer

#### Step 2: Work Mode

```typescript
// src/engine/scoring-v6.ts:45-52
function determineWorkMode(state): WorkModeV6 {
  const { w1, w2 } = state.workModeRaw
  if (w1 === 'full_time' && (w2 === 'full' || w2 === 'moderate')) return 'FT'
  return 'PT'
}
```

#### Step 3: Normalization

```typescript
// src/engine/scoring-v6.ts:59-76
function normalizeScores(state): DimensionScoresV6 {
  for (const dim of ALL_DIMS) {
    const rawAvg = scores.reduce((a, b) => a + b, 0) / scores.length
    const scaled = (rawAvg / DIM_ACHIEVABLE_AVG[dim]) * 3.0
    const capped = Math.max(0, Math.min(scaled, 3.0))
    const confidence = Math.min(scores.length / 2, 1.0)
    result[dim] = capped * confidence + 1.0 * (1 - confidence)
  }
}
```

Formula: `(rawAvg / achievableAvg) * 3.0`, capped to [0, 3], then confidence-damped (full confidence at 2+ answers).

#### Step 4: Tier Determination

```typescript
// src/engine/scoring-v6.ts:85-116
function determineTierV6(scores, trackRecord): TierV6 {
  const avg = ALL_DIMS.reduce((sum, d) => sum + scores[d], 0) / 8
  const minDim = Math.min(...ALL_DIMS.map(d => scores[d]))

  // Leader: trackRecord>=2.5, resilience>=2.2, drive>=2.2, avg>=2.4,
  //         relationship>=1.5, discipline>=1.5
  if (trackRecord >= 2.5 && scores.resilience >= 2.2 && scores.drive >= 2.2
      && avg >= 2.4 && scores.relationship >= 1.5 && scores.discipline >= 1.5)
    return 'Leader'

  // FA Prime: avg>=2.0, minDim>=1.2
  if (avg >= 2.0 && minDim >= 1.2) return 'FA_Prime'

  // FA Standard: avg>=1.6
  if (avg >= 1.6) return 'FA_Standard'

  // Standard Agent: avg>=0.9
  if (avg >= 0.9) return 'Standard_Agent'

  return 'Not_Suitable'
}
```

#### Step 5: Demotion Rules

```typescript
// src/engine/scoring-v6.ts:121-135
function applyDemoteRules(tier, scores, consistencyFlagged): TierV6 {
  let idx = TIER_ORDER.indexOf(tier)
  if (scores.relationship < 0.5 && idx <= 1) idx++    // demote from Leader/FA_Prime
  if (scores.discipline < 0.5 && idx <= 1) idx++      // demote from Leader/FA_Prime
  if (consistencyFlagged && idx < 4) idx++             // demote 1 level
  return TIER_ORDER[Math.min(idx, 4)]
}
```

#### Step 6: Card Assignment (Per-Card Dimension Gates)

```typescript
// src/engine/scoring-v6.ts:141-204
function tryAssignCard(tier, scores): CardV6 | null {
  switch (tier) {
    case 'Leader':
      // Commander: relationship>=2.2, discipline>=2.0, persuasiveness>=2.0
      // Strategist: discipline>=2.2, growth>=2.0
      // Both pass → higher relationship = Commander, else Strategist
    case 'FA_Prime':
      // Phoenix: resilience>=2.2, optimism>=2.0
      // Sage: growth>=2.2, persuasiveness>=2.0
      // Both pass → weighted comparison
    case 'FA_Standard':
      // Warrior: drive>=1.8, resilience>=1.5
      // Merchant: relationship>=1.8, market>=1.5
    case 'Standard_Agent':
      // Scout: growth>=1.2, optimism>=1.0
      // Apprentice: discipline>=1.2
    case 'Not_Suitable':
      return 'Wanderer'
  }
}
```

If both cards in a tier fail their gates, the candidate is demoted to the next tier (up to 4 attempts).

### 9 Career Archetypes

| Tier | Card | Gate Requirements | Income Range |
|------|------|-------------------|-------------|
| Leader | Commander | relationship>=2.2, discipline>=2.0, persuasiveness>=2.0 | 100,000-500,000+ |
| Leader | Strategist | discipline>=2.2, growth>=2.0 | — |
| FA Prime | Phoenix | resilience>=2.2, optimism>=2.0 | — |
| FA Prime | Sage | growth>=2.2, persuasiveness>=2.0 | — |
| FA Standard | Warrior | drive>=1.8, resilience>=1.5 | — |
| FA Standard | Merchant | relationship>=1.8, market>=1.5 | — |
| Standard Agent | Scout | growth>=1.2, optimism>=1.0 | — |
| Standard Agent | Apprentice | discipline>=1.2 | — |
| Not Suitable | Wanderer | (default fallback) | — |

### Anti-Faking Detection

From `src/engine/anti-faking.ts`:

| Check | Threshold | Effect |
|-------|-----------|--------|
| Speed flags | <3 seconds per question | Count accumulated |
| All-high pattern | >80% of dimensions >2.5/3.0 | Boolean flag |
| Low variance | >60% answers same letter (A/B/C/D) | Boolean flag |
| Severity | totalFlags >= 1: low, >= 2: medium, >= 3: high | Stored in calibration |

### Consistency Checks

From `src/engine/scoring-v6.ts:207-229`:

- **CC1**: SJT4D (avoids scheduling) + FC4B (claims discipline) → discipline inconsistency → demote 1 tier
- **CC2**: TR3D (no crisis) + FC6B (survived worst) → resilience inconsistency → demote 1 tier

## API Endpoints

### Frontend Routes (React Router)

| Route | Component | Purpose |
|-------|-----------|---------|
| `/` | QuizAppV6 | Quiz (v6 default, `?v=v5` for legacy) |
| `/share/:token` | SharedResultPage | Public result viewer |
| `/admin` | AdminApp | Admin dashboard |
| `/admin/dashboard` | AdminDashboard | Overview stats |
| `/admin/prospects` | ProspectTable | Candidate list |
| `/admin/prospect/:id` | ProspectDetail | Individual detail |
| `/admin/logs` | AdminActionLog | Action audit trail |
| `/admin/wiki` | AdminWiki | Card encyclopedia |

### Backend (Supabase)

- REST API via `https://<project>.supabase.co/rest/v1/`
- Anon role for quiz (no auth), authenticated for admin
- RLS: anonymous INSERT on quiz tables, authenticated SELECT/UPDATE

## Deployment

### Build & Deploy

```bash
npm run build                    # Output: dist/
npx wrangler pages deploy dist --project-name fa-recruitment-quiz
```

### Environment Variables

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_LIFF_ID=your-liff-id
```

### Hosting

- **Production**: Cloudflare Pages (static CDN)
- **Build config**: Vite with timestamp suffix for cache busting (prevents CF dedup)
- **Console removal**: Production builds strip console.log/warn

## Current State

### What's Working

- Full v6 quiz flow (24 questions, 8 chapters, Thai narration)
- Scoring pipeline with all tiers and card assignment
- Admin dashboard with stats, candidate table, action logs
- Share links for results
- LINE LIFF integration
- Anti-faking detection and consistency checks
- Psychometric calibration data collection

### Known Issues

- Database tracking failed for 18 days (May 7-25) due to missing columns — fixed by migration 20260525
- Desktop date input replaced with Thai 3-dropdown picker (accessibility fix)
- Subject encoding in Gmail shows mojibake (UTF-8 display issue, not code bug)
- No CLAUDE.md in repo — needs creation for oracle onboarding
- Legacy v5 code still in repo (`questions.ts` 157K, `scoring.ts` 125K, `QuizApp.tsx` 36K) — dead weight but not breaking

### TypeScript Status

As of 2026-06-21: **0 errors** (`npx tsc --noEmit` passes clean). Earlier audit flagged 11 errors in ProspectDetail/QuizApp/tracking.test/AdminWiki but these appear resolved or were false positives from a different tsconfig.

### Recent Commits (latest 10)

- `5a3c3e1` — feat: user action logging — table, logger util, admin page (#82)
- `8505e5c` — fix: show incomplete sessions + update wiki to V6 (#79)
- `66db7c7` — fix: desktop calendar — Thai dropdown selectors replace tiny popup
- `9ca1c39` — fix: update OG URL from quiz.vuttipipat.com to journey.iagencyaia.com
- `2e689c1` — fix: soften OG description + prologue text — แบงค์ direct feedback
- `d36483b` — fix: LINE message shows 'text=' prefix + make message professional
- `6a90fff` — fix: TOTAL_QUESTIONS comment 26→24 (actual count)
- `6c249f5` — feat(#66): add MW1+MW2 market wealth questions
- `47c93d3` — fix: z-index on all result content — overlay no longer paints over forms
- `31f8373` — fix: solid background ALL steps + remove skip button (แบงค์)

## Codebase Stats

| Metric | Value |
|--------|-------|
| Components | 20+ (quiz + admin) |
| Engine files | 18 (v6 + legacy) |
| Admin pages | 7 |
| Questions | 24 (8 chapters) |
| Career archetypes | 9 |
| Scene backgrounds | 70+ (webp) |
| Supabase tables | 7 |
| Migrations | 8 |
| Unit tests | 2 files (scoring-v6, tracking) |
| Estimated LOC | ~25,000 |
| Legacy dead code | ~282K (questions.ts + scoring.ts) |

## Changelog

| Date | What Changed | By |
|------|-------------|-----|
| 2026-06-21 | Doc updated: added missing components (EpilogueView, CharacterSheet, SceneParticles, RankingView, RecruitCTA, TarotCard), engine files (action-logger, questions-sq, tests), fixed WikiPageV6→PathWikiCards, updated commits, confirmed 0 TS errors, noted legacy dead code | BotDev |
| 2026-06-18 | Initial doc created | DocCon |

## Owner & Contacts

| Role | Oracle | Notes |
|------|--------|-------|
| **Lead** | BotDev | Primary developer, quiz engine, Supabase |
| **Scoring Research** | Researcher | Dimension definitions, psychometric validation |
| **Content** | Writer | Thai narration, card lore, question text |
| **Design** | Designer | Ghibli-style scene backgrounds, card art |
| **QA** | DocCon | Conduct review, scoring accuracy audits |
