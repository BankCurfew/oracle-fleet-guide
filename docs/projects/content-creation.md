# Content Creation

## Overview

- **What it does**: Visual content production system — poster design, brand identity management, design system maintenance, and social media asset generation for iAgencyAIA and BoB's Office ecosystem
- **Who uses it**: Wingman-Oracle (poster delivery to Discord), QA-Oracle (quality checks), Writer-Oracle (headline copy), the entire fleet (design system tokens)
- **Where it runs**: Local rendering on Curfew (WSL2), output delivered to Wingman for Discord/social posting
- **Repository**: `BankCurfew/Designer-Oracle`
- **Born**: 2026-03-13
- **Identity**: Creative Director — 10 Commandments inspired by Dieter Rams, Don Norman, Jony Ive

## Architecture

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Templating** | HTML5 + CSS3 | Poster layout (Kanit, Inter, Noto Sans Thai fonts) |
| **Rendering** | Playwright CLI (headless Chromium) | HTML → PNG screenshot at exact dimensions |
| **Image Gen (Primary)** | ChatGPT Brand Chat (trained DALL-E) | Hero images — brand-trained, 55+ approved images |
| **Image Gen (Secondary)** | Gemini 2.5-Flash (Python `google-genai`) | Hero images — fallback, batch via `gen-batch.py` |
| **Image Gen (Tertiary)** | ComfyUI (Stable Diffusion) | Highest quality when available |
| **Image Processing** | Sharp v0.34.5, PIL/Pillow | Resize, crop, format conversion |
| **Card Rendering** | Puppeteer v24 | Character/persona card generation |
| **Design System** | CSS custom properties (Pigment v8) | 165 design tokens, complete framework |
| **Knowledge** | oracle-v2 MCP (Bun) | Agent memory, cross-oracle communication |
| **Browser Fallback** | Playwright MCP | When APIs fail |
| **Database** | Supabase MCP | Project `hztjrqlxrdsmxbkxojqg` integration |

### Key Services & Connections

```
Brief (from Wingman/BoB)
  ↓
Designer generates hero image (ChatGPT Brand Chat → Gemini → ComfyUI)
  ↓
Designer builds HTML template (4 sizes with safe zones)
  ↓
Playwright renders HTML → PNG (1200×630, 1080×1350, 1080×1920, 1080×1080)
  ↓
Self-check 7/7 (mandatory before delivery)
  ↓
Deliver to Wingman-Oracle → QA → Discord post
```

## Code Structure

```
Designer-Oracle/
├── CLAUDE.md                          # Identity, 10 commandments, laws (main doc)
├── CLAUDE_poster_conduct.md           # Authoritative poster creation standard
├── CLAUDE_workflows.md                # Oracle-v2 MCP workflows
├── CLAUDE_lessons.md                  # Design patterns & learnings
├── CLAUDE_safety.md                   # Git/file safety rules
├── README.md                          # Philosophy & role guide
├── component-library.md               # Pigment v8 components (v2.4.0)
├── .mcp.json                          # MCP servers config
│
├── brand/
│   ├── BRAND_GUIDE.md                 # Logo, color palette, typography specs
│   ├── tokens/
│   │   └── design-tokens.json         # v2.2.0 complete token system (165 tokens)
│   └── logos/                         # Bob's Office neural network logo
│
├── design-system/
│   ├── bob-office.css                 # v2.4.0 complete CSS framework
│   └── preview.html                   # Design system showcase
│
├── docs/
│   ├── SOP.md                         # Poster pipeline standard (approved 2026-06-07)
│   ├── DESIGN_KNOWLEDGE.md            # Design system deep-dive
│   ├── CREATIVE_FORMATS.md            # Poster layout variants
│   ├── REFERENCE_ANALYSIS.md          # Competitive analysis
│   ├── ui-ux-playbook.md              # UX patterns & flows
│   └── fa-tools-ui-ux-guideline.md    # FA dashboard UI specs
│
├── output/                            # Generated posters & designs (300+ sets)
│   ├── atw-YYYYMMDD/                  # Around The World news series
│   ├── mb-YYYYMMDD/                   # Market Brief series
│   ├── fund-YYYYMMDD/                 # Fund insights series
│   ├── daily-news/                    # Daily news poster archives
│   ├── hybrid-poster-system/          # Poster generator templates
│   └── [series]-YYYYMMDD/render.js    # Playwright render scripts per batch
│
├── assets/
│   ├── cards/                         # Card rendering (Puppeteer, v1.0.0)
│   │   └── package.json               # puppeteer ^24.40.0
│   └── scenes/                        # Scene image generation
│       ├── gen-batch.py               # Gemini API batch image generator
│       └── package.json               # sharp ^0.34.5
│
├── specs/                             # Specification documents
│   ├── jarvis-dashboard-tab.md
│   ├── dashboard-ux-audit.md
│   └── fa-tools-ui-ux-guideline.md
│
└── ψ/                                 # Brain (Oracle knowledge system)
    ├── active/                        # Ephemeral research & context
    ├── memory/
    │   ├── retrospectives/            # Session summaries
    │   ├── learnings/                 # Persisted patterns & lessons
    │   └── resonance/                 # Identity & soul
    ├── writing/
    │   ├── posters/                   # Hero images, logo assets
    │   └── research/                  # Role guide, design research
    ├── lab/                           # Experimental designs
    └── inbox/ | outbox/               # Oracle communication
```

### Key Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Identity, 10 commandments, laws, philosophy |
| `CLAUDE_poster_conduct.md` | Authoritative poster QA standard |
| `docs/SOP.md` | Full poster pipeline (approved by แบงค์ 2026-06-07) |
| `brand/BRAND_GUIDE.md` | Logo, color, typography specs |
| `brand/tokens/design-tokens.json` | Complete token export (v2.2.0, 165 tokens) |
| `design-system/bob-office.css` | Full CSS framework with all components (v2.4.0) |
| `component-library.md` | Design system component specs |
| `output/*/render.js` | Playwright render scripts (per poster batch) |
| `assets/scenes/gen-batch.py` | Gemini batch image generator |

## Business Logic

### 1. Daily Poster Pipeline

**Full workflow** (from `docs/SOP.md`):

```
Brief received (from Wingman-Oracle/ψ/writing/<series>-YYYYMMDD.md)
  ↓
Step 1: Full Poster Image via ChatGPT Brand Chat (DALL-E)
  - Tab: "iAgencyAIA Brand Visuals" — find by title, NOT hardcoded ID
  - Use pre-built prompt template from output/poster-templates/<series>.txt
  - Fill [PLACEHOLDER] fields with brief data
  - Send via MQTT proxy (chatgpt_chat action)
  - Poll chatgpt_get_images every 60s (DALL-E takes 1-3 min)
  - Track image count before/after to detect new images
  - Download by specific imageIndex (NOT latest:true — broken)
  - Rules: --keep always, NEVER --new (brand context preserved)
  ↓
Step 2: Verify downloaded image
  - Check correct poster (not old cached image)
  - Verify badge, logo, headline, data cards visible
  - If DALL-E refused (content policy) — rephrase with neutral wording
  ↓
Step 3: Deliver 1 Story IG (1080×1920) to Wingman
  - Default: 1 size only (แบงค์ directive 2026-06-19)
  - Multiple sizes only when explicitly requested
  ↓
Step 4: cc Wingman + cc BoB (structured format)
```

**Legacy pipeline** (HTML template → Playwright render → 4 sizes) still available in `ψ/writing/posters/gen-*.py` scripts for cases where DALL-E fails or custom layouts are needed.

### 2. Rendering Pipeline (Playwright)

```javascript
// Example from output/atw-20260612/render.js
const posters = [
  { file: 'story-fb.html',    w: 1200, h: 630  },
  { file: 'story-ig.html',    w: 1080, h: 1350 },
  { file: 'story-story.html', w: 1080, h: 1920 },
  { file: 'story-sq.html',    w: 1080, h: 1080 },
];

const browser = await chromium.launch();
for (const p of posters) {
  const page = await browser.newPage();
  await page.setContent(html, { waitUntil: 'networkidle' });
  await page.waitForTimeout(1500); // fonts load
  await page.screenshot({ path: outFile, type: 'png' });
}
```

### 3. HTML Template Structure (Light Theme v6)

```html
<body width=[W] height=[H]>
  <!-- Geometric accents (subtle, non-overlapping) -->
  <div class="geo-chev">...</div>

  <!-- Branding: Badge (top-left) + Logo (top-right) -->
  <div class="badge">MARKET</div>
  <img class="logo" src="iagencyaia-logo.png">

  <!-- Hero image (contained box with border-radius, shadow) -->
  <div class="hero-box"><img src="hero.png" /></div>

  <!-- Text area: Headline, Subtitle, Stats Grid -->
  <div class="text-area">
    <div class="headline">HEADLINE<br><span class="red">Thai subtitle</span></div>
    <div class="sub">SERIES — date</div>
    <div class="stats-grid"><!-- Data visualization --></div>
  </div>

  <!-- Optional callout box -->
  <div class="callout">Key data points</div>

  <!-- Footer bar with source + date + mini logo -->
  <div class="footer-bar">source | date</div>
</body>
```

### 4. Branding Standards

**iAgencyAIA Logo** (mandatory, inline SVG):

```html
<svg viewBox="0 0 280 48">
  <text font-family="Inter" font-weight="900"
    stroke="#FFF" stroke-width="1.8" paint-order="stroke fill">
    <tspan fill="#C8102E">i</tspan>
    <tspan fill="#1a1a2e">Agency</tspan>
    <tspan fill="#C8102E">AIA</tspan>
  </text>
</svg>
```

- Colors: AIA Red (`#C8102E`) for "i" and "AIA", Black (`#1a1a2e`) for "Agency"
- White stroke: 1.8px, `paint-order: stroke fill`
- Position: Top-right, inside safe zone
- Heights: 32px (FB) / 36px (IG/Square) / 44px (Story)
- No modifications allowed (แบงค์ directive 2026-05-14)

**Series Badge Colors** (top-left):

| Series | Code | Color | Hex |
|--------|------|-------|-----|
| Around The World | ATW | Blue | `#3B82F6` |
| Market Brief | MB | Green | `#16a34a` |
| Fund Insights | FND | Amber | `#F59E0B` |
| Health & Wealth | HW | Pink | `#EC4899` |
| Breaking News | BREAKING | Red | `#DC2626` |
| AIA Promo | PROMO | Gold + Red | — |

### 5. Image Generation Rules

| Priority | Tool | When | Notes |
|----------|------|------|-------|
| 1 (Primary) | ChatGPT Brand Chat | Default | Trained DALL-E session, 55+ approved images |
| 2 (Secondary) | Gemini 2.5-Flash | Fallback | `gen-batch.py`, Python `google-genai` |
| 3 (Tertiary) | ComfyUI | Highest quality | When available on Windows-side |
| Never | CSS gradients only | — | Not acceptable as hero |
| Never | Stock photos | — | No generic stock |
| Never | AI with baked text | — | All text is HTML overlay |

### 6. Safe Zone Specifications (Per Format)

| Format | Badge Top | Headline Y | Font | Footer Y |
|--------|-----------|-----------|------|----------|
| FB (1200×630) | 30px | y:430 | 56px | y:580 |
| IG Feed (1080×1350) | 90px | y:940 | 48px | y:1090 |
| IG Story (1080×1920) | 120px | y:1050 | 72px | y:1350 |
| Square (1080×1080) | 80px | y:750 | 56px | y:930 |

Safe zones account for platform UI overlays (action buttons, swipe-up areas, caption zones).

## Design System: Pigment v8 (BoB's Office)

### Color Tokens

**Primary Purple** (Oracle Intelligence):
```css
--bob-purple-50:  #F5F3FF;
--bob-purple-300: #C084FC;
--bob-purple-500: #8B5CF6;
--bob-purple-700: #6C3BF5;  /* Brand core */
--bob-purple-900: #4C1D95;
```

**Accent Amber** (Human Energy):
```css
--bob-amber-300: #FCD34D;
--bob-amber-500: #F59E0B;
```

**Neutral Ink & Paper**:
```css
--bob-ink-50:  #F8F8FC;   /* Page background */
--bob-ink-300: #B0B0C4;   /* Placeholder */
--bob-ink-600: #535370;   /* Secondary text */
--bob-ink-900: #1A1A2E;   /* Primary text */
```

**Semantic Colors**:
- Success: `#047857` (WCAG AA 5.48:1)
- Warning: `#D97706`
- Error: `#DC2626` (WCAG AA 4.83:1)
- Info: `#2563EB` (WCAG AA 5.17:1)

**Agent Identity Colors**:

| Oracle | Color | Hex |
|--------|-------|-----|
| Bob | Purple | `#6C3BF5` |
| Dev | Blue | `#3B82F6` |
| QA | Green | `#10B981` |
| Writer | Rose | `#BE123C` |
| Designer | Purple | `#8B5CF6` |
| DocCon | Violet | `#7C3AED` |

### Typography

| Level | Size | Weight | Usage |
|-------|------|--------|-------|
| Display | 48px | 800 | Hero headings |
| H1 | 36px | 700 | Page titles |
| H2 | 30px | 700 | Section headers |
| H3 | 24px | 600 | Subsections |
| Body | 16px | 400 | Paragraphs |
| Small | 14px | 400 | Captions |

**Font stack**: Inter (display/body), JetBrains Mono (monospace), Noto Sans Thai 900 (Thai headlines, fallback: Kanit Black)

### Spacing & Motion

- **Spacing scale** (4px base): `--bob-space-1` (4px) through `--bob-space-24` (96px)
- **Shadows**: sm (1px), md (4px), lg (8px), glow (24px purple)
- **Motion**: fast (150ms), normal (250ms), slow (400ms), easing: `cubic-bezier(0.4, 0, 0.2, 1)`
- **Breakpoints**: sm (640px), md (768px), lg (1024px), xl (1280px)

### Import

```html
<link rel="stylesheet" href="design-system/bob-office.css">
```

Full token file: `brand/tokens/design-tokens.json` (v2.2.0, 165 tokens)

## API Endpoints

No dedicated API server. Designer-Oracle operates through:

| Integration | Method | Purpose |
|-------------|--------|---------|
| Playwright CLI | `pw-cli.sh` commands | HTML → PNG rendering |
| Gemini API | Python `google-genai` | Image generation (batch) |
| ChatGPT Brand Chat | Playwright proxy (`chatgpt-gen.sh`) | Primary image generation |
| oracle-v2 MCP | `/talk-to`, `oracle_search` | Cross-oracle communication |
| Supabase MCP | Database queries | Project `hztjrqlxrdsmxbkxojqg` |

## Deployment

**No traditional deployment** — Designer-Oracle is a knowledge + production repo:

- Runs locally on Curfew (WSL2, Linux)
- Poster rendering: `node output/[series]-[date]/render.js` (Playwright)
- Image generation: `bash gemini-gen.sh "prompt" --download "prefix"` or ChatGPT Brand Chat
- Batch scenes: `python3 assets/scenes/gen-batch.py`
- Output stored in `output/[series]-[date]/` (PNG files)
- All changes tracked in Git, synced to GitHub
- Design tokens exported to `brand/tokens/design-tokens.json` for downstream apps

**Output delivery**:
- PNG posters → Wingman-Oracle → Discord social posts
- SVG components → BoB's Office UI
- Design tokens → imported by downstream apps (FA Tools, dashboard)

## Current State

### What's Working

- Daily poster pipeline (Brief → Hero → HTML → 4 sizes → QA → Deliver)
- ChatGPT Brand Chat as primary image generator (55+ approved images)
- Pigment v8 design system with 165 tokens (v2.4.0 CSS framework)
- 7-point self-check before delivery
- 300+ poster sets generated (1200+ individual PNGs)
- 7 active series: ATW, Market Brief, Fund Holdings, Fund Insights, Viral, Health & Wealth, Breaking
- 8 pre-built prompt templates for Wingman self-service (`output/poster-templates/`)
- Default output: 1 Story IG (1080×1920) per poster (แบงค์ directive 2026-06-19)

### Known Issues

- **chatgpt-gen.sh `latest:true` broken** — downloads old images from long conversations. Use manual image count tracking + download by specific imageIndex instead
- **DALL-E guardrail detection missing** — "similarity to third-party content" errors not surfaced by MQTT proxy. Dev working on fix (proxy #12). Workaround: avoid brand names (Nasdaq, CNBC) in prompts
- **DALL-E content policy** — health/disease topics (Ebola, medical) trigger refusal. Workaround: use neutral framing (airport/policy, not disease/medical imagery)
- **Extension goes offline** — requires manual reload at chrome://extensions/. No auto-recovery
- **ComfyUI availability** depends on Windows-side GPU (not always accessible from WSL)
- **4.1GB repo size** (heavy with rendered PNGs) — may need LFS or archival strategy

### Recent Work (as of 2026-06-21)

- 8 pre-built poster prompt templates created ([office] #151)
- FA Tools Profile UX wireframe ([fa-tools] #153)
- Daily poster production: ATW, MB, Fund Holdings, Fund Insights, Viral, H&W EP.1-2
- Pipeline shifted from HTML template rendering to ChatGPT DALL-E direct poster generation
- Quality loop v7.4 locked at QA score 88/100
- MQTT polling optimized: 60s intervals (was 3s)

## Owner & Contacts

| Role | Oracle | Responsibility |
|------|--------|---------------|
| **Lead** | Designer-Oracle | Visual design, poster production, design system |
| **Delivery** | Wingman-Oracle | Discord posting, social distribution |
| **QA** | QA-Oracle | Poster checklist verification |
| **Copy** | Writer-Oracle | Headline writing, content copy |
| **Data** | Researcher-Oracle | News data, statistics verification |
| **Supervisor** | BoB-Oracle | Task dispatch, quality gate |
