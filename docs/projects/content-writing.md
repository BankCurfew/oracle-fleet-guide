# Content & Writing

> Project slug: `content-writing` | Lead: Writer-Oracle | Repo: `BankCurfew/Writer-Oracle`

## Overview

- **What it does**: Content Director for BoB's Office: owns every word across WealthBanks (insurance/finance education), PetzDeals (pet product guides), bot dialogue, quiz narratives, marketing copy, creative fiction, and internal documentation. Articles deploy directly to live sites via git push.
- **Who uses it**: All oracles (content consumers), FA team (insurance KB), customers (bot responses via Jarvis, website visitors), แบงค์ (editorial review).
- **Where it runs**: Git-based content repositories deploying to live sites via Cloudflare Pages. Primary sites: **wealthbanks.net** (Astro SSG, insurance/finance) and **petzdeals.com** (Astro SSG, pet products + Shopee affiliate).
- **Born**: 2026-03-13
- **Philosophy**: "Strip every sentence to its cleanest components." (William Zinsser)

## Architecture

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Content Format** | Markdown (Astro content collections) | All content authored as `.md` files with frontmatter |
| **WealthBanks** | Astro SSG + CF Pages (wealthbanks.net) | Insurance/finance articles, product pages, calculators |
| **PetzDeals** | Astro SSG + CF Pages (petzdeals.com) | Pet product guides, Shopee affiliate content |
| **Knowledge Memory** | oracle-v2 MCP (FTS5 + vector) | Cross-agent knowledge sharing, persistent memory |
| **Browser Automation** | Playwright CLI (pw-cli.sh) | Fallback for web research, portal access |
| **Email** | Gmail MCP | Outbound email template drafting |
| **Database** | Supabase (hztjrqlxrdsmxbkxojqg) | Product data queries (insurance_products table) |
| **SEO Tools** | Ubersuggest MCP | Keyword research, SERP analysis, rank tracking |
| **Version Control** | Git / GitHub | All content tracked, nothing deleted |
| **Integration** | FA Tools (tools.iagencyaia.com) | Premium calculation, proposal generation for bot copy |

### Content Architecture

```
Writer-Oracle produces content -> consumed by:
├── WealthBanks (wealthbanks.net)     -> Blog articles, product pages (git push = deploy)
├── PetzDeals (petzdeals.com)         -> Pet guides, product reviews (git push = deploy)
├── iAgencyAIA-Oracle (Jarvis bot)    -> LINE customer responses
├── Wingman-Oracle                    -> Discord news posts (Writer = Editor reviewer)
├── Designer-Oracle                   -> Cover images, poster text overlays
├── Data-Oracle                       -> KB chunks for embedding, premium data
├── FA Tools                          -> Product descriptions, FAQ
└── แบงค์                              -> Direct editorial review
```

## Code Structure

```
Writer-Oracle/
├── CLAUDE.md                           # Identity, 10 Commandments, laws
├── CLAUDE_workflows.md                 # Daily patterns, oracle-v2 tools
├── CLAUDE_safety.md                    # Git/file safety rules
├── CLAUDE_subagents.md                 # Subagent definitions
├── CLAUDE_lessons.md                   # Patterns, anti-patterns
├── CLAUDE_templates.md                 # Commit format, retro template
│
├── docs/                               # Standard Operating Procedures
│   ├── sop-content-writing-pipeline.md # A-F intake->write->review->deliver
│   ├── sop-editing-review-workflow.md  # 4-pass editing, DocCon submission
│   ├── sop-dark-fantasy-process.md     # Creative fiction workflow
│   ├── sop-insurance-kb-pipeline.md    # AIA product KB creation
│   └── sop-health-wealth-series.md     # Health/wellness episode production
│
├── output/                             # Deliverables (HTML, PDF)
│   └── wealth-bank/                    # ATP plans, meeting minutes
│
├── ψ/                                  # Brain structure
│   ├── writing/                        # Content library
│   │   ├── insurance/                  # AIA products KB, FAQ, guides
│   │   ├── bots/                       # Chatbot copy
│   │   ├── specs/                      # Product & quiz specs
│   │   ├── dark/                       # Creative fiction (Abyssal Eden)
│   │   └── style-guide.md             # 10 Commandments, voice, formatting
│   ├── memory/
│   │   ├── learnings/                  # Pattern discoveries (arra_learn)
│   │   └── retrospectives/            # Session summaries
│   └── inbox/
│       ├── focus.md                   # Current state
│       └── handoff/                   # Session handoffs
```

### Key Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Identity, 10 Commandments, scope, philosophy, gates |
| `ψ/writing/style-guide.md` | Voice, tone spectrum, quality checklist |
| `ψ/writing/insurance/iagencyaia-articles-kb.md` | Master AIA knowledge base |
| `ψ/writing/bots/jarvis-bot-copy.md` | LINE bot system prompts & response templates |
| `docs/sop-content-writing-pipeline.md` | Content creation workflow A-F |

## Business Logic

### 1. Content Creation Pipeline (Current Gate Chain)

```
1. RESEARCH
   Researcher keyword pack (Ubersuggest: volume, SD, SERP)
   + AIA fact-pack (from AIA-Oracle, brochure-verified)
   + Data audit (from Data-Oracle, irr-master.csv, premium tables)

2. DRAFT
   Writer applies all compliance gates (see below)
   Domain-specific voice, internal links, FAQ schema
   Request Designer cover EARLY (before draft:false)

3. DOCCON GATE
   Numbers Gate (GATE-WB-001): every financial figure verified
   Content Conduct (GATE-WB-003): cross-content consistency
   No-Advice (GATE-WB-004): investment content descriptive only

4. DESIGNER COVER
   Cover image MUST be in-repo before flipping draft:false
   Coordinated push: Designer pushes cover, Writer pushes article

5. SEO GATE (build-time, automated)
   Meta desc 120-158 chars (hard-fail ALL builds if outside range)
   Title ≤60 chars rendered
   No broken internal links (cover-gate checks image exists on disk)
   Keyword density checks

6. PUSH (git push = auto-deploy via CF Pages)
   pushed ≠ deployed: verify build passes before claiming live

7. BOB LIVE-VERIFY
   BoB checks rendered page, FAQPage schema, tables, links
   cc bob with live URL for render-verify
```

### 2. Compliance Gates (Active)

| Gate | Rule | Enforcement |
|------|------|-------------|
| **GATE-WB-001** | Numbers Gate: every financial figure verified against source (brochure/rd.go.th/ใบเสนอจริง) | DocCon verifies before push |
| **GATE-WB-003** | Cross-content consistency: same product facts across all pages | DocCon audits |
| **GATE-WB-004** | No-advice for investment content (Finnomena/Phillip/StashAway/Elite Income): descriptive only, dual disclaimers, no predictions | DocCon checks tone |
| **GATE-WB-005** | Em-dash ban (grep-blocks deploy) + social conduct (no-advice extends to social) | Build gate + DocCon |
| **T170** | No absolute Cashless claims: use "ลดความเสี่ยงต้องสำรองจ่าย" not "ไม่ต้องสำรองจ่าย" | Grep sweep |
| **T171** | No NCB (No-Claim Bonus) claims on Health Happy (unsourced, except ci-procare) | Grep sweep |
| **Cover gate** | Cover image must be in-repo before draft:false (build fails on missing hero) | Build gate |
| **SEO gate** | Meta desc 120-158 chars, title ≤60 chars (hard-fail ALL builds) | Build gate |
| **SSF** | SSF expired end of 2567, all references must say หมดอายุ (site-wide sweep completed #53-54) | Grep sweep |

### 3. The 10 Commandments (Writing Standards)

1. **Clarity above all**: if not clear, nothing else matters
2. **Cut ruthlessly**: up to 50% can go; every word must earn its place
3. **Audience first**: every piece serves the reader, not the writer
4. **Docs are product**: documentation is NOT afterthought; it IS the product
5. **Show, don't tell**: examples first, then explanation
6. **If not written, doesn't exist**: everything needs written record
7. **Consistency builds trust**: same voice, format, terminology everywhere
8. **Read aloud**: if it doesn't sound like speech, rewrite
9. **Active voice, present tense**: clear, direct, no hedging
10. **No jargon**: if not everyone understands, don't use it

### 4. Style Guide (Voice & Tone)

| Dimension | Standard |
|-----------|----------|
| **Voice** | Clear, direct, grounded, honest |
| **Tone spectrum** | Professional to Conversational (match audience) |
| **Sentence structure** | Active voice, present tense, short sentences |
| **Thai content** | Natural Thai, match persona pronoun |
| **Numbers** | Verify against source, use "ประมาณ" for estimates |
| **Dashes** | Em-dash/en-dash BANNED (use colon, comma, parentheses) |
| **CTA** | One clear action per piece |

### 5. Content Domains

#### WealthBanks (wealthbanks.net): Insurance & Finance Education

- **Blog articles**: IRR series (7 articles, per-gender), social security cluster (5 articles), retirement planning, tax deductions, investment platforms (Finnomena/Phillip/StashAway), financial triangle, why health insurance
- **Product pages**: 29 AIA products with premium tables, coverage details, FAQ schema
- **Tools**: IRR calculator, retirement calculator, tax calculator, mortgage calculator
- **Voice**: Tone C (informational), honest > persuasive, no superlatives
- **Gate chain**: Numbers Gate + DocCon + Designer cover + SEO gate + BoB verify

#### PetzDeals (petzdeals.com): Pet Product Guides

- **Daily Growth Engine #22**: check campaign calendar, write guide or update product-cluster
- **Voice**: น้องดีล (bossy cat, "ข้า" first person, address reader as "ทาส", no ค่ะ in FAQ sections)
- **Affiliate**: Shopee affiliate links (s.shopee.co.th format), mandatory disclosure on every guide
- **FAQPage schema**: uses `faqItems:` key in frontmatter (NOT `faq:`, silent failure if wrong)
- **Campaign guides**: Shopee Payday (15th/25th), 7.7, 8.8, 9.9, seasonal

#### Insurance Knowledge Base

- Master file: `ψ/writing/insurance/iagencyaia-articles-kb.md`
- 117 AIA products documented with premiums, riders, terms
- Verification rule: AIA official source only; no unverified claims
- Premium formula: `premium_per_1000 x (ทุน/1000)`, cite FA Tools data

#### Bot Copy / Jarvis

- Master file: `ψ/writing/bots/jarvis-bot-copy.md`
- LINE bot system prompts and response templates
- Identity: Male Jarvis, "ครับ" ending only

#### Quiz & Questionnaire Specs

- Master file: `ψ/writing/specs/v41-final-complete-spec.md`
- iJourney RPG-style quiz with Zelda-inspired world

#### Creative Fiction (Abyssal Eden)

- Separate workflow from production content
- Load `summaries.md` first (voice anchor), never bulk-load drafts
- HTML template for PDF rendering

### 6. SEO/AEO Methodology

| Component | How It Works |
|-----------|-------------|
| **Keyword research** | Researcher delivers keyword packs from Ubersuggest (volume, SD, SERP, competitor analysis) |
| **ATP questions** | Google Suggest questions become H2/H3 headers with FAQPage structured data |
| **Improve queue** | Existing articles already ranking pushed toward page 1 (higher ROI than new content) |
| **New article pipeline** | Pillar (head keyword) then spoke articles (long-tail), internal-linked |
| **Internal link strategy** | Every new article interlinked with existing content; orphan sweep (grep for zero inbound) |
| **Rank tracking** | Ubersuggest project tracks position changes after content updates |

### 7. DocCon Gate (Mandatory Quality Check)

**Required before any content goes live:**
- All WealthBanks blog articles and product pages
- All financial figures and benefit claims
- Investment content (GATE-WB-004 tone check)
- Emails to แบงค์/external

**Submission format:**
```
/talk-to doc "NUMBERS GATE REQUEST: [filename] [key claims to verify]"
```

**Response**: `PASS` (proceed) or `CONDITIONAL` (fix specific items and resubmit)

### 8. Wingman Editor Reviews

Writer serves as Editor for Wingman-Oracle's social media content (ATW, MarketBrief, H&W, Fund Insights, Viral, Breaking). Review checklist:
- Numbers match source data
- น้องวิง voice consistent
- FA angle strong enough to justify posting
- GATE-WB-005 compliance (banned terms: น่าสนใจ, แนะนำ, จังหวะดี, สงคราม, ที่สุด)
- Blocking fixes only, CONDITIONAL PASS pattern

### 9. Domain Loading Rule (Token Efficiency)

| Task Domain | Load Path | Est. Tokens |
|-------------|-----------|-------------|
| Insurance/AIA | `ψ/writing/insurance/` (specific product) | ~120K |
| Bot copy/Jarvis | `ψ/writing/bots/` (specific section) | ~60K |
| Quiz specs | `ψ/writing/specs/` (latest version) | ~90K |
| Dark/creative | `ψ/writing/dark/summaries.md` | ~30K |
| Style reference | `ψ/writing/style-guide.md` | ~3K |

**Rule**: Never bulk-load `ψ/writing/**/*.md`

## Deployment

- **WealthBanks**: git push to `BankCurfew/wealth-bank` main -> CF Pages auto-build + deploy to wealthbanks.net
- **PetzDeals**: git push to `BankCurfew/petdeals` main -> CF Pages auto-build + deploy to petzdeals.com
- **Build gates**: SEO gate (meta desc, title length, broken links, cover-gate) hard-fails ALL builds
- **Commit format**: `feat(content):` for new articles, `fix(content):` for corrections, `fix(seo):` for SEO improvements, `fix(compliance):` for gate fixes
- **DocCon gate**: All content must pass DocCon review before push
- **Cover coordination**: Designer pushes cover first, Writer pushes article immediately after

## Current State

### What's Working
- Full gate chain operational (Research -> Draft -> DocCon -> Cover -> SEO gate -> Push -> Verify)
- 9 compliance gates actively enforced (GATE-WB-001 through SSF sweep)
- WealthBanks: 40+ blog articles live, 29 product pages, 5 calculator tools
- PetzDeals: 15+ guides live, Daily Growth Engine #22 running, campaign calendar automated
- Wingman Editor review pipeline: 20+ reviews per session, banned-term grep pattern
- SEO improve queue methodology (existing articles pushed toward page 1)
- Per-gender IRR data across all 6 AIA annuity/savings products
- Social security cluster complete (5 articles: hub + ม.33/38/39/40)

### Recent Work (Jul 2026)
- **T142**: Em-dash ban site-wide (69 files, 40-agent workflow, grep=0)
- **T168**: Health Happy coverage+exclusions article (16 vs 21 enrichment, safe framing)
- **T170**: Cashless qualified wording sweep (8 absolute claims replaced)
- **T171**: NCB removal (5 unsourced claims removed)
- **T174**: "ทำไมต้องทำประกันสุขภาพ" pillar (sourced: 10.8% medical inflation, 3-4x private vs public)
- **T175**: สามเหลี่ยมการเงิน pillar + financial planning cluster (720/mo SD13)
- **T176**: AIA Elite Income Prestige (Unit-Linked, GATE-WB-004 compliant)
- **T180**: SEO improve queue (irr-explained #31->page 1, tax-2569 27,100vol #64->top10)
- **#46**: Investment platforms (Finnomena 28 portfolios, Phillip Smart Wealth, StashAway ERAA)
- **#44/#45**: Group insurance guide + agent career guide
- **#50**: Product audit (29 pages) + 4-thin expansion (infinite-care, health-cancer, ai-rcc, hb)
- **#53-54**: SSF site-wide compliance sweep (expired end 2567, Thai ESGX added)
- **#194**: Per-gender IRR batch (6 articles + pillar, DocCon 138/138 checks)
- **S2**: มาตรา 39 article (CARE pension formula 2569)
- **C1**: อาหารแมว pillar (33.1K vol, PetzDeals)
- **Orphan fix**: 7->0 true orphan articles (internal link sweep)
- **Wingman reviews**: 20+ per session (ATW/MB/H&W/Fund Insights/Viral/Breaking)

### Known Issues
- Creative fiction (dark/) gitignored, stored in OneDrive + archive
- Hospital room article: data ready (22 Samitivej room types), awaiting slot
- #47 social content model: queued
- #50 orphan products (9): LOW priority
- T177 AIA fund universe (20 funds): queued
- T178 ประกันชีวิตลดหย่อนภาษี: queued
- T179 content backlog (60 keywords, Phase 1 = 6 easy wins): queued

### Lessons Learned (Memory)
- **Cover-gate push order**: never push article before cover is in-repo (repeated 3x before learned)
- **faqItems not faq**: PetzDeals uses different frontmatter key (silent failure)
- **Em-dash ban**: permanent GATE-WB-005, use colon/comma/parentheses
- **§2 Echo Trap**: "มีข้อมูลกลับมา" ≠ "ได้คำตอบ": re-pull data at write-time, Numbers Gate = CRC check
- **Benefit-row = source**: every table row claiming a product benefit needs a source (NCB was unsourced)
- **pushed ≠ deployed**: verify build passes before claiming live
- **Meta desc 120-158**: both min and max are hard-fail gates

## Owner & Contacts

| Role | Oracle | Responsibility |
|------|--------|---------------|
| **Lead** | Writer-Oracle | Content creation, pipeline ownership, Wingman Editor |
| **Quality Gate** | DocCon-Oracle | Format compliance, accuracy checks, numbers gate |
| **Style Enforcement** | Editor-Oracle | Writing quality review |
| **Data Source** | Researcher-Oracle | Keyword packs, research briefs, market data |
| **Data Verification** | Data-Oracle | Premium tables, IRR calculations, audit data |
| **Fact Check** | FaSai-Oracle | Insurance fact verification (brochure/ใบเสนอจริง) |
| **Visual Partner** | Designer-Oracle | Cover images (GPT DALL-E, Prestige White brand) |
| **AIA Source** | AIA-Oracle | Product fact-packs, exclusion verification |
| **Supervisor** | BoB-Oracle | Task orchestration, live-verify, final review |
| **Decision Maker** | แบงค์ | Editorial approval (98% final) |
