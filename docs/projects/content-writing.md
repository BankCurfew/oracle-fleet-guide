# Content & Writing

> Project slug: `content-writing` | Lead: Writer-Oracle | Repo: `BankCurfew/Writer-Oracle`

## Overview

- **What it does**: Content Director for BoB's Office — owns every word representing the organization across insurance education, bot dialogue, quiz narratives, marketing copy, creative fiction, and internal documentation.
- **Who uses it**: All oracles (content consumers), FA team (insurance KB), customers (bot responses via Jarvis), แบงค์ (editorial review).
- **Where it runs**: Git-based content repository. No deployed application — Writer-Oracle produces Markdown artifacts consumed by other systems (FA Tools bot, Discord, social media, PDF generation).
- **Born**: 2026-03-13
- **Philosophy**: "Strip every sentence to its cleanest components" — William Zinsser

## Architecture

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Content Format** | Markdown | All content authored and versioned as `.md` files |
| **Knowledge Memory** | oracle-v2 MCP (FTS5 + vector) | Cross-agent knowledge sharing, persistent memory |
| **Browser Automation** | Playwright MCP | Fallback for web research, portal access |
| **Email** | Gmail MCP | Outbound email template drafting |
| **Database** | Supabase (hztjrqlxrdsmxbkxojqg) | Product data queries (insurance_products table) |
| **Version Control** | Git / GitHub | All content tracked, nothing deleted |
| **Integration** | FA Tools (tools.iagencyaia.com) | Premium calculation, proposal generation for bot copy |

### Content Architecture

```
Writer-Oracle produces content → consumed by:
├── iAgencyAIA-Oracle (Jarvis bot) → LINE customer responses
├── Wingman-Oracle → Discord news posts
├── Designer-Oracle → Poster text overlays
├── Data-Oracle → KB chunks for embedding
├── FA Tools → Product descriptions, FAQ
└── แบงค์ → Direct editorial review
```

## Code Structure

```
Writer-Oracle/
├── CLAUDE.md                           # Identity, 10 Commandments, laws (23.5K)
├── SOP.md                              # Master SOP index
├── README.md                           # Public overview (4.6K)
├── CLAUDE_workflows.md                 # Daily patterns, oracle-v2 tools
├── CLAUDE_safety.md                    # Git/file safety rules
├── CLAUDE_quiz.md                      # Quiz writing standards
├── CLAUDE_templates.md                 # Commit format, retro template
│
├── docs/                               # Standard Operating Procedures
│   ├── sop-content-writing-pipeline.md # A-F intake→research→write→review→deliver (8.2K)
│   ├── sop-editing-review-workflow.md  # 4-pass editing, DocCon submission (5.9K)
│   ├── sop-dark-fantasy-process.md     # Creative fiction workflow (5.9K)
│   ├── sop-insurance-kb-pipeline.md    # AIA product KB creation (6.3K)
│   └── sop-health-wealth-series.md     # Health/wellness episode production
│
├── AIA-Knowledge/                      # Integration reference
│   └── fa-tools/integration-guide.md   # FA Tools 7-tool ecosystem guide
│
├── ψ/                                  # Brain structure
│   ├── writing/                        # Content library (~1.2MB, 16.9K lines)
│   │   ├── insurance/                  # AIA products KB, FAQ, guides (~349K)
│   │   │   ├── iagencyaia-articles-kb.md   # Master KB (348.9K)
│   │   │   ├── iagencyaia-products-kb.md   # 117 products
│   │   │   ├── iagencyaia-faq-guide.md     # Common questions
│   │   │   ├── insurance-glossary-th-en.md # Bilingual glossary
│   │   │   └── kb-gap-fill-7-critical.md   # Critical KB gaps
│   │   ├── bots/                       # Chatbot copy (~284K)
│   │   │   ├── jarvis-bot-copy.md          # LINE bot system prompts (166.7K)
│   │   │   ├── bob-brain-system-prompt.md  # BoB brain prompt
│   │   │   └── v-pisit-style-guide.md      # V. Pisit voice
│   │   ├── specs/                      # Product & quiz specs (~200K)
│   │   │   ├── v41-final-complete-spec.md  # iJourney v4.1 spec (94.8K)
│   │   │   ├── ijourney-v6-rpg-world-maps.md  # RPG world (52.5K)
│   │   │   ├── ijourney-v6-dev-handoff.md     # Dev handoff (35.8K)
│   │   │   └── questionnaire-story-arc.md     # Narrative structure
│   │   ├── style-guide.md             # 10 Commandments, voice, formatting (9.4K)
│   │   ├── ijourney-ad-copy-all-stages.md  # 7 personas x 5 AICDA stages (85.1K)
│   │   └── [100+ additional content files]
│   ├── memory/
│   │   ├── learnings/                  # Pattern discoveries (10+ files)
│   │   ├── retrospectives/            # Session summaries
│   │   └── resonance/writer.md        # Identity anchor
│   ├── inbox/
│   │   ├── focus.md                   # Current state
│   │   └── handoff/                   # Session handoffs (9+ files)
│   └── outbox/                        # Deliverables
```

### Key Files

| File | Size | Purpose |
|------|------|---------|
| `CLAUDE.md` | 23.5K | Identity, 10 Commandments, scope, philosophy |
| `ψ/writing/style-guide.md` | 9.4K | Voice, tone spectrum, quality checklist |
| `ψ/writing/insurance/iagencyaia-articles-kb.md` | 348.9K | Master AIA knowledge base |
| `ψ/writing/bots/jarvis-bot-copy.md` | 166.7K | LINE bot system prompts & response templates |
| `ψ/writing/specs/v41-final-complete-spec.md` | 94.8K | iJourney quiz complete specification |
| `docs/sop-content-writing-pipeline.md` | 8.2K | Content creation workflow A-F |
| `docs/sop-editing-review-workflow.md` | 5.9K | 4-pass editing + DocCon gate |

## Business Logic

### 1. Content Creation Pipeline (A-F Workflow)

**Five content types routed through the same pipeline:**

| Type | Example | Quality Chain |
|------|---------|---------------|
| Insurance KB | AIA product Q&A, FAQ | Research → Write → DocCon → QA → Publish |
| Website Articles | Unitlink explainers, SEO | Research → Write → DocCon → แบงค์ → Publish |
| Bot Copy | Jarvis scripts, flow responses | Real data → Write → DocCon → Dev deploy |
| Quiz/Questionnaire | iJourney quiz, FA recruitment | Spec → Write narrative → DocCon → Dev integrate |
| Health & Wealth | Episode scripts, reel narration | Research → Write → DocCon → Designer → Publish |

**Pipeline stages:**

```
A. INTAKE
   Task arrives → ACK immediately → Create ticket (maw task add)
   Rule: Never ask "should I do this?" — task received = do it

B. RESEARCH
   Self-research: Read existing ψ/writing/ (don't duplicate)
   Delegate complex: /talk-to researcher "TASK: [topic]"
   Verify: financial figures from AIA official sources only

C. WRITE
   Apply 10 Commandments (see below)
   Domain-specific voice (insurance=precise, bot=conversational, quiz=narrative)

D. REVIEW (4-Pass Self-Edit)
   Pass 1: Structural — clear beginning/middle/end, logical flow
   Pass 2: Clarity & Cut — remove filler, active voice (aim: 30-50% cut)
   Pass 3: Accuracy — all numbers verified, time-sensitive data qualified
   Pass 4: Read Aloud — if it stumbles, rewrite

E. DELIVER
   Submit to DocCon: /talk-to doc "review doc: [title]"
   Wait for: "DOCCON COMPLIANT" or corrections
   Commit + push + close ticket + CC BoB

F. QUALITY CHAIN
   Research (data) → Writer (80%) → DocCon (90%) → Editor/แบงค์ (98%)
```

### 2. The 10 Commandments (Writing Standards)

1. **Clarity above all** — If not clear, nothing else matters
2. **Cut ruthlessly** — Up to 50% can go; every word must earn its place
3. **Audience first** — Every piece serves the reader, not the writer
4. **Docs are product** — Documentation is NOT afterthought; it IS the product
5. **Show, don't tell** — Examples first, then explanation
6. **If not written, doesn't exist** — Everything needs written record
7. **Consistency builds trust** — Same voice, format, terminology everywhere
8. **Read aloud** — If it doesn't sound like speech, rewrite
9. **Active voice, present tense** — Clear, direct, no hedging
10. **No jargon** — If not everyone understands, don't use it

### 3. Style Guide (Voice & Tone)

| Dimension | Standard |
|-----------|----------|
| **Voice** | Clear, direct, grounded, honest |
| **Tone spectrum** | Professional ↔ Conversational (match audience) |
| **Sentence structure** | Active voice, present tense, short sentences |
| **Thai content** | Natural Thai, match persona pronoun (ครับ/ค่ะ by character) |
| **Numbers** | Verify against source, use "ประมาณ" for estimates |
| **Jargon** | Banned unless audience is technical |
| **CTA** | One clear action per piece |

### 4. Content Domains (5 Major)

#### Insurance Knowledge Base (~349K)
- **Master file**: `ψ/writing/insurance/iagencyaia-articles-kb.md` (348.9K)
- 117 AIA products documented with premiums, riders, terms
- FAQ guide, bilingual glossary, gap-fill articles
- Verification rule: AIA official source only; no unverified claims
- Premium formula: `premium_per_1000 × (ทุน/1000)` — cite FA Tools data

#### Bot Copy / Jarvis (~284K)
- **Master file**: `ψ/writing/bots/jarvis-bot-copy.md` (166.7K)
- LINE bot system prompts and response templates
- Identity: Male Jarvis, "ครับ" ending only
- 10 hard rules (Thai default, exact premiums, warm tone, security)
- AICDA stage templates (Awareness → Consideration → Decision → Action → Advocacy)
- Premium response template: "Health Happy 5M ชาย 30 ปี = 18,300 บาท/ปี (วันละ 50 บาท)"

#### Quiz & Questionnaire Specs (~200K)
- **Master file**: `ψ/writing/specs/v41-final-complete-spec.md` (94.8K)
- iJourney RPG-style quiz with Zelda-inspired world
- Adaptive questions (360+ pooled), 12 result clusters
- Narrative immersion: questions as story choices, not test items
- Writing rule: 2nd person active voice ("You discover...")

#### Social & Marketing (~150K)
- Ad copy: 7 personas × 5 AICDA stages (85.1K)
- Unitlink social media batches (64.1K)
- Scene breakdown library (95.4K)

#### Creative Fiction (Abyssal Eden)
- Separate workflow from production content
- Load `summaries.md` first (voice anchor), never bulk-load drafts
- HTML template for PDF rendering (white bg + black text standard)
- Voice continuity: Thai pronouns matched to character personality

### 5. DocCon Gate (Mandatory Quality Check)

**Required before external delivery:**
- Emails to แบงค์/external
- Reports and proposals
- Bot templates
- Financial/medical claims

**Submission format:**
```
/talk-to doc "review [type]: [title] — Audience: [who] — File: [path]"
```

**Response**: `DOCCON COMPLIANT` (proceed) or structured corrections (fix and resubmit)

### 6. Domain Loading Rule (Token Efficiency)

| Task Domain | Load Path | Est. Tokens |
|-------------|-----------|-------------|
| Insurance/AIA | `ψ/writing/insurance/` (specific product) | ~120K |
| Bot copy/Jarvis | `ψ/writing/bots/` (specific section) | ~60K |
| Quiz specs | `ψ/writing/specs/` (latest version) | ~90K |
| Dark/creative | `ψ/writing/dark/summaries.md` | ~30K |
| Style reference | `ψ/writing/style-guide.md` | ~3K |

**Rule**: Never bulk-load `ψ/writing/**/*.md` (~375K tokens waste)

## API Endpoints

Writer-Oracle has no deployed API. It produces content artifacts consumed by other systems:

| Consumer | Content Type | Delivery Method |
|----------|-------------|-----------------|
| FA Tools bot (Jarvis) | System prompts, response templates | Git → Data-Oracle ingestion |
| Data-Oracle | KB articles for embedding | Git → `build-iagencyaia-chunks.py` |
| Wingman-Oracle | News story text | `/talk-to wingman` + Git |
| Designer-Oracle | Text overlays, copy briefs | `/talk-to designer` + Git |
| iJourney (fa-quiz) | Quiz questions, narrative, card lore | Git → Dev integration |

## Deployment

- **No application deployment** — content repository only
- **Git workflow**: Feature branch → commit → push → PR (if code-adjacent)
- **Commit format**: `docs: [brief description]` or `feat: [content type]`
- **Delivery**: Content pushed to Git, then consumed by downstream systems
- **DocCon gate**: All external content must pass DocCon review before delivery
- **Integration**: FA Tools integration guide at `AIA-Knowledge/fa-tools/integration-guide.md`

## Current State

### What's Working
- Full content pipeline (A-F) operational
- Insurance KB complete (348.9K master, 117 products)
- Bot copy comprehensive (166.7K Jarvis system)
- Quiz specs delivered (v4.1 + v6 RPG)
- Style guide established and enforced
- DocCon quality gate active
- 4-pass editing workflow documented

### Known Issues
- Creative fiction (dark/) gitignored — stored in OneDrive + archive
- FA Tools iPlan API integration in progress (Phase 2)
- iCompare/iLink automation not yet integrated (Phase 3)
- Total content ~1.2MB — domain loading rule critical for token management

### Recent Work
- NotebookLM teaching documentation
- iJourney ad copy compliance fixes
- Editor feedback incorporation
- Bampenpien solo practice (cutting fear, number verification)

## Owner & Contacts

| Role | Oracle | Responsibility |
|------|--------|---------------|
| **Lead** | Writer-Oracle | Content creation, pipeline ownership |
| **Quality Gate** | DocCon-Oracle | Format compliance, accuracy checks |
| **Style Enforcement** | Editor-Oracle | Writing quality review |
| **Data Source** | Researcher-Oracle | Research briefs, market data |
| **Visual Partner** | Designer-Oracle | Poster text, visual content |
| **Supervisor** | BoB-Oracle | Task orchestration, final review |
| **Decision Maker** | แบงค์ | Editorial approval (98% final) |
