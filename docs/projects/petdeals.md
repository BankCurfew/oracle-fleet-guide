# PetzDeals

## Overview

- **What it does**: Thai pet product affiliate site. Aggregates Shopee pet products (food, treats, litter, accessories) with commission-tracked affiliate links, SEO-optimized content, and seasonal campaign pages.
- **Who uses it**: Thai pet owners searching Google for pet product reviews, guides, and deals.
- **Where it runs**: Production at `petzdeals.com` (Cloudflare Pages, auto-deploys from git push). No backend database (static JSON + Astro SSG).
- **Owner**: Data-Oracle (pipeline + data), Writer-Oracle (content), Editor-Oracle (quality gate)

## Architecture

| Layer | Technology |
|-------|-----------|
| Framework | Astro 5 (SSG) |
| Data | Static JSON (`data/products.json`, `data/seasons.json`) |
| Hosting | Cloudflare Pages |
| Product source | Apify Shopee scraper (Starter $29/mo) |
| Affiliate | Shopee an_redir format (`affiliate_id=an_15312860014`) |
| Images | Local .webp in `public/products/` (downloaded + converted at ingest) |
| Search | Pagefind (static index) |

No Supabase. No server-side logic. All data baked at build time.

## Canonical Ops Doc

**`petdeals/docs/CONTENT-GUIDELINES.md`** (v2.0, Jul 2026) covers: brand voice, SEO rules, daily ops pipeline, automated gates, seasonal engine, deploy verification.

Do not duplicate content here. Refer to the canonical doc for operational details.

## Key Gates (scrape-offers.py)

| Gate | Function | Added |
|------|----------|-------|
| Validation | Rejects non-TH URLs, non-Thai titles, bait prices (<฿5) | Jun 2026 |
| Bait sweep (#45) | Purges ALL rows price<฿5 or discount>90% every run | Jul 2026 |
| Title gate (#46) | `sanitize_title()` caps at 55 chars (SERP truncation) | Jul 2026 |
| IMAGE GATE v3 (#44/#45) | RIFF magic verify + remote-URL reject + git-tracking auto-stage | Jul 2026 |
| Em-dash ban | `sanitizeDashes()` in generator, grep=0 enforced | Jul 2026 |

## Daily Loops

| Loop | Schedule | Action |
|------|----------|--------|
| Apify sync | Daily (manual trigger) | 7 categories x 10 items, products.json update |
| GA4/GSC/PSI | Daily | Analytics pulls for both sites |
| Auto-index | Daily | Google Indexing API submission for new URLs |

## Key Numbers

- Products: ~844 (fluctuates with sync + prune)
- Blog articles: 21
- Deal pages: 7 (payday-25, 7.7, 8.8, today, index, etc.)
- Sitemap URLs: ~900 (products + articles + category + deals)
