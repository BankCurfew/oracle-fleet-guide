# WealthBanks

## Overview

- **What it does**: Thai insurance and financial planning education site. SEO-driven articles (IRR analysis, tax deductions, retirement planning, product deep-dives), interactive calculators, and AIA product pages with premium tables.
- **Who uses it**: Thai consumers researching insurance/financial products via Google, FA (Financial Advisors) using articles as client education tools.
- **Where it runs**: Production at `wealthbanks.net` (Cloudflare Pages, auto-deploys from git push after SEO gate + cover gate pass). Domain is `.net` not `.com` (CAR-2026-07-11-canonical).
- **Owner**: Writer-Oracle (content), Dev-Oracle (build/infra), Data-Oracle (premium tables/analytics), Designer-Oracle (covers)

## Architecture

| Layer | Technology |
|-------|-----------|
| Framework | Astro (SSG) |
| Data | Generated JSON (`src/data/generated/*.json`: premium tables per product) |
| Hosting | Cloudflare Pages |
| Content | Markdown with frontmatter (`src/content/blog/`, `src/content/products/`) |
| Search | Pagefind (#51, static index at build time) |
| Analytics | GA4 + GSC (Data-Oracle daily pulls, retry with backoff: 3 attempts at 5/15/30s for transient API failures) |
| Article Register | Per-article GSC stock view (v3: 57 articles, index_status + URL inspection, branded/generic query_type column, #70) |
| SEO monitoring | Ubersuggest MCP (kept 1 month per แบงค์ Jul 2026) |
| Premium source | FA Tools DB via Data-Oracle compute-irr-batch.py |

No Supabase backend for content. Premium tables generated from brochure-verified DB, rendered by ProductTables Astro component (#50).

## Canonical Docs

| Topic | Location |
|-------|----------|
| **Content pipeline** | `oracle-fleet-guide/docs/projects/content-writing.md` (Writer lead) |
| **Compliance gates** | `content-writing.md` > Compliance Gates table (9 gates) |
| **SEO/AEO methodology** | `content-writing.md` > SEO/AEO Methodology section |
| **Product page template** | `wealth-bank/WEALTHBANKS-VOICE.md` + `PRODUCT-PAGE-TEMPLATE` |
| **Cover ops** | `wealth-bank/docs/COVER-COPY-SHEET.md` + `SOP-WB-002` |
| **Daily SEO intel** | `Data-Oracle/output/wb-daily-intel-YYYY-MM-DD.html` |

Do not duplicate pipeline/gate content here. Refer to content-writing.md for operational details.

## Build Gates (auto, npm run build)

| Gate | What it checks | Fail = |
|------|---------------|--------|
| **SEO gate** | Meta desc 120-158 chars (trimmed ≤158, A2 gate pass), title ≤60, no broken internal links, glob covers `programs/` path | Hard-fail, blocks ALL pages |
| **Cover gate** | Frontmatter `image:` path exists on disk | Hard-fail per article |
| **Content schema** | Frontmatter fields per `src/content.config.ts` | Build error |

## Compliance Gates (manual, enforced by DocCon/Editor)

See `content-writing.md` > Compliance Gates for full table. Key ones:

- **GATE-WB-001**: Numbers Gate (every financial figure source-cited)
- **GATE-WB-004**: No-advice for investment articles (Finnomena/Phillip/StashAway/Elite Income)
- **GATE-WB-005**: Em-dash ban (grep-blocks, cleanup applied W32), social conduct
- **T170**: No absolute Cashless claims
- **T171**: No NCB claims (except ci-procare)
- **SSF**: Expired end of 2567, all references must say หมดอายุ

## Tools Pages

| Path | Tool | Notes |
|------|------|-------|
| `/tools/retirement-calculator` | Retirement planner | Client-side JS, links from retirement-planning-guide |
| `/tools/irr-calculator` | IRR calculator | Links from irr-explained + IRR article series |
| `/tools/tax-calculator` | Tax calculator | Links from tax-deductions-2569 |
| `/tools/mortgage-calculator` | Mortgage calculator | Standalone |
| `/tools/loan-calculator` | Loan calculator | Standalone |

## Content Inventory (Aug 2026)

| Type | Count | Key examples |
|------|-------|-------------|
| Blog articles | 57 | irr-insurance-savings-annuity (pillar), tax-deductions-2569, why-health-insurance, social-security cluster (5) |
| Product pages | 29 | aia-health-happy, aia-ci-procare, aia-annuity-fix, aia-elite-income-prestige |
| Calculator tools | 5 | retirement, irr, tax, mortgage, loan |

## Key Loops

| Loop | Schedule | Owner | Does |
|------|----------|-------|------|
| **fund-json-regen** | On DB change | Data | Regenerate `src/data/generated/*.json` premium tables from brochure-verified DB |
| **GSC daily pull** | 08:00 daily | Data | Pull GSC/GA4/PSI metrics, generate daily SEO intel HTML. Fund NAV refresh (22 AIA funds + 24 fund JSONs) |
| **SEO rank tracking** | Weekly | Data (Ubersuggest) | Track keyword positions, flag improve opportunities |
| **Tax audit** | Yearly (Dec) | Writer + Researcher | Verify all tax deduction figures match rd.go.th for new tax year |

## Deploy Flow

```
Writer edits src/content/ → git push
  → CF Pages auto-build (npm run build)
    → SEO gate check (meta desc, links, schema)
    → Cover gate check (image files exist)
    → Build passes → deploy to wealthbanks.net
    → BoB live-verify (render + content spot-check)
```

If build fails: check `npm run build` output for SEO gate errors or missing covers. Common causes: meta desc out of 120-158 range, missing hero image, broken internal link to unpublished article.

## Recent Changes (W32 Audit, Jul 25 - Aug 11 2026)

| Change | Detail | Ref |
|--------|--------|-----|
| **CLS Performance Fix** | Desktop CLS improved from 0.0856 to 0.0003 via LINE Seed Sans TH font metric optimization | `b3c13eb` |
| **Article Register v1-v3** | Per-article GSC stock view for 57 articles: v1 base, v2 added index_status + URL inspection, v3 added branded/generic query_type column | #70 |
| **SEO Gate widened** | Glob now includes `programs/` path. Meta descriptions trimmed to ≤158 chars (A2 gate pass). Em-dash cleanup (GATE-WB-005) | |
| **Analytics Retry** | GA4+GSC pull scripts now retry with backoff (3 attempts, 5/15/30s delay) for transient API failures | |
| **T104 SEO Recovery** | 5 articles rewritten with FAQ expansion + variant keywords: irr-explained, life-insurance-types, surrender-value, financial-triangle, tax-deductions-2569 | T104 |
| **Daily Ops** | Regular GA4+GSC+PSI daily pulls, fund NAV refreshes (22 AIA funds + 24 fund JSONs) | |

## Owner and Contacts

| Role | Oracle | Responsibility |
|------|--------|---------------|
| **Content** | Writer-Oracle | Articles, product pages, compliance |
| **Build/Infra** | Dev-Oracle | Astro config, components, CF Pages |
| **Data/Premium** | Data-Oracle | Premium tables, analytics, SEO intel |
| **Covers** | Designer-Oracle | GPT cover generation per COVER-COPY-SHEET |
| **Quality** | DocCon-Oracle | Numbers gate, conduct gate, audit |
| **Numbers verify** | FaSai-Oracle | Insurance figure verification (brochure/ใบเสนอ) |
| **Supervisor** | BoB-Oracle | Dispatch, live-verify, rank tracking |
