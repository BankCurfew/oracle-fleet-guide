# Daily News Pipeline

## Overview

- **What it does**: AI-powered daily financial news pipeline that sources, writes, illustrates, and publishes stories for the iAgencyAIA Discord server. Wingman-Oracle (น้องวิง) is the storyteller — transforming raw financial news into FA-relevant content with a personal, conversational Thai voice.
- **Who uses it**: Financial Advisors (FAs) in the iAgencyAIA team on Discord; Team H led by Dream (พี่ดรีม).
- **Where it runs**: Discord server (iAgencyAIA), content drafted in `ψ/writing/`, images uploaded via Discord REST API, text via `localhost:3202` bot API, logs stored in Supabase.

## Architecture

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| News Sourcing | Firecrawl MCP (`npx firecrawl-mcp`) | Web scraping + breaking news search |
| Story Writing | Wingman-Oracle (Claude Code) | Thai storytelling in น้องวิง voice |
| Poster Design | Designer-Oracle | 4-size poster generation (FB/IG/Story/Square) |
| Image Posting | Discord REST API v10 (multipart) | Image upload to channels |
| Text Posting | `localhost:3202` bot API | Plain text message posting |
| Data Logging | Supabase PostgreSQL (`heciyiepgxqtbphepalf`) | `discord_posts_log`, `discord_members`, `knowledge_base` |
| Agent Coordination | oracle-v2 MCP + `maw hey` + `/talk-to` | Cross-oracle task dispatch and QA |
| Version Control | Git | All content tracked in `ψ/writing/` |

### Pipeline Flow

```
1. Researcher-Oracle sources news (exact URLs required)
       ↓
2. Wingman-Oracle writes stories (น้องวิง voice, paragraph style)
       ↓
3. Designer-Oracle creates 4 poster sizes per story
       ↓
4. Wingman runs Pre-Post QA Checklist (15+ checks)
       ↓
5. BoB reviews + QA PASS (Wingman must thread_read to verify)
       ↓
6. Post to Discord: msg1 = image embed (REST API), msg2 = text (bot API)
       ↓
7. Log to Supabase discord_posts_log
       ↓
8. CC BoB done
```

### Key Services

| Service | Endpoint | Auth | Purpose |
|---------|----------|------|---------|
| Discord REST API | `https://discord.com/api/v10/channels/{id}/messages` | Bot token (vault) | Image upload (multipart) |
| Bot API | `http://localhost:3202/api/discord-reply` | None (local) | Text-only messages |
| Supabase | `https://heciyiepgxqtbphepalf.supabase.co` | service_role key (vault) | Post logging, dedup, member tracking |
| Firecrawl MCP | Local MCP server | API key in `.mcp.json` | News search and scraping |

### Critical Technical Rule

**Images MUST use Discord REST API multipart upload.** The `localhost:3202` bot API accepts a `files` parameter but images silently fail to display. This was discovered 2026-05-23 and is a firing-level rule.

```bash
# CORRECT — Discord REST API multipart
curl -s -X POST "https://discord.com/api/v10/channels/${CH}/messages" \
  -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  -F "payload_json=</tmp/payload.json" \
  -F "files[0]=@poster-fb.png" \
  -F "files[1]=@poster-ig.png"

# WRONG — localhost:3202 (images silently fail)
curl http://localhost:3202/api/discord-reply \
  -d '{"channelId":"CH","text":"...","files":[...]}'
```

## Code Structure

```
Wingman-Oracle/
├── CLAUDE.md                      # Oracle identity, 5 Principles, golden rules, pre-post checklist (40.3K)
├── SOP.md                         # Standard Operating Procedures v1.2 (24.3K)
├── scripts/
│   ├── setup-fa-tools-forum.ts        # Create #สอนใช้-fa-tools forum (475 lines)
│   ├── setup-forum-channels.ts        # Forum channel setup
│   ├── setup-automod.ts               # Auto-moderation rules
│   ├── manage-forum-posts.ts          # Forum post lifecycle
│   ├── breaking-news-scan.md          # Breaking news detection workflow
│   └── breaking-news-loop.md          # Firecrawl loop configuration
│
├── ψ/                             # Brain structure
│   ├── inbox/
│   │   ├── focus.md                   # Current session state
│   │   └── handoff/                   # Session handoffs
│   ├── memory/
│   │   ├── learnings/                 # 23 knowledge files
│   │   │   ├── 01-identity-and-golden-rules.md
│   │   │   ├── 02-product-status-and-chat-style.md
│   │   │   ├── 03-fa-tools-and-sales-flow.md
│   │   │   ├── 04-supabase-and-kb-access.md
│   │   │   ├── 05-discord-rich-messages.md
│   │   │   └── 2026-05-23_discord-image-multipart-only.md
│   │   ├── retrospectives/            # Session logs (by date)
│   │   └── resonance/                 # Principles + practice
│   ├── writing/                       # Content drafts (192+ files)
│   │   ├── daily-YYYYMMDD-stories.md
│   │   ├── atw-YYYYMMDD-aroundtheworld.md
│   │   ├── breaking-YYYYMMDD-*.md
│   │   ├── marketbrief-YYYYMMDD-*.md
│   │   ├── fund-holdings-YYYYMMDD.md
│   │   └── fund-insights-YYYYMMDD.md
│   └── outbox/                        # Published content archive
│
├── .mcp.json                      # MCP server config (Firecrawl + oracle-v2)
└── .claude/                       # Claude Code session config
```

### Key Files

| File | Size | Purpose |
|------|------|---------|
| `CLAUDE.md` | 40.3K | Oracle identity, 5 Principles, team roster, golden rules, pre-post checklist, DM rules |
| `SOP.md` | 24.3K | Standard Operating Procedures — primary reference for all operations |
| `scripts/setup-fa-tools-forum.ts` | 475 lines | Creates #สอนใช้-fa-tools forum with 8 teaching posts |
| `ψ/inbox/focus.md` | ~6 lines | Current session state (STATE, TASK, SINCE, BLOCKED) |
| `ψ/memory/learnings/03-fa-tools-and-sales-flow.md` | 5.6K | 8-step Sales Flow guide + tool decision tree |

## Business Logic

### Content Types & Discord Channels

| Content Type | Channel | Channel ID | Frequency |
|-------------|---------|-----------|-----------|
| Daily News Stories (ATW) | #ข่าวรายวัน | `1499713194317582537` | Daily |
| Breaking News | #ข่าวรายวัน | `1499713194317582537` | As needed (2h scan) |
| Market Brief | #ข่าวรายวัน | `1499713194317582537` | Daily |
| Fund Insights/Holdings | #ข่าวรายวัน | `1499713194317582537` | Periodic |
| AIA Events/Training | #🏢-ข่าวสาร-กิจกรรม | `1499713196129521746` | Weekly |
| Agent Promos/Contests | #🔥โปรโมชั่น-ท้าทาย-แข่งขัน | `1501896650535207012` | As announced |
| Customer Promos | #🎁-โปรโมชั่นลูกค้า | `1502269223790186496` | As released |
| Important Announcements | #📢-ประกาศ | `1499713170015523037` | Critical only |
| Weekly Summary | #สรุปรายสัปดาห์ | TBD | Saturdays 10:00 |
| Monthly Summary | #สรุปรายเดือน | `1499960810577985626` | End of month |

### Daily News Workflow

**Step 1 — Source** (Researcher-Oracle):
- Wingman dispatches Researcher via `/talk-to researcher "TASK: Daily News [date] — 3 stories"`
- Researcher returns story briefs with exact URLs (homepage URLs = reject)

**Step 2 — Write** (Wingman-Oracle):
- Writes each story in น้องวิง voice (paragraph storytelling, NOT bullets)
- Template per story:
  ```
  สวัสดีค่ะพี่ๆ 🙋‍♀️ วิงมีข่าวที่ FA ต้องรู้มาเล่าค่ะ

  **[Headline]**

  [Paragraph 1: What happened + why]
  [Paragraph 2: Impact + numbers]

  วิงว่า... [Personal take]

  💡 **FA Talking Point**: ถ้าลูกค้าถาม → ตอบว่า...

  📰 [Exact source URL]
  ```
- Saves draft to `ψ/writing/atw-YYYYMMDD-*.md`

**Step 3 — Design** (Designer-Oracle):
- Wingman dispatches Designer with story details + badge type
- Designer produces 4 poster sizes:
  - FB: 1200×630
  - IG: 1080×1350
  - Story: 1080×1920
  - Square: 1080×1080

**Step 4 — QA** (Pre-Post Checklist + BoB):
- Wingman runs mandatory checklist (see below)
- Submits to BoB for QA
- MUST `thread_read` to verify QA PASS (do not trust relay messages)

**Step 5 — Publish** (2 messages per story):
1. **Message 1**: Image embed via Discord REST API multipart upload
2. **Message 2**: Plain text via `localhost:3202` bot API

**Step 6 — Log**:
- Insert into Supabase `discord_posts_log` (dedup reference for future posts)

### Pre-Post QA Checklist (Mandatory — Firing-Level)

Every post must pass ALL checks before publishing:

**A. Images**
- [ ] 4 resolutions exist (FB/IG/Story/Square)
- [ ] Read image file to verify visually
- [ ] Text doesn't overlap or bleed edges
- [ ] Badge type correct (MARKET/COMMODITY/AIA/HEALTH)
- [ ] Numbers in poster match story text
- [ ] Logo/branding iAgencyAIA clear
- [ ] NOT reused from previous day

**B. Content**
- [ ] News within 24 hours (check source date)
- [ ] Exact source URL (not homepage)
- [ ] Numbers verified vs source (≥1 cross-check)
- [ ] FA Talking Point included
- [ ] น้องวิง voice (paragraph, not bullets)
- [ ] Internal codes stripped (MKT/ECM/PT stripped)

**C. Platform**
- [ ] Dedup check (query `discord_posts_log`)
- [ ] BoB QA PASS seen (via `thread_read`, not relay)
- [ ] Right channel selected (classify correctly)
- [ ] Image posted before text (post order)

**D. Breaking News Extra**
- [ ] True breaking (war/crisis/disaster, not opinion)
- [ ] OG image from article source (not AI-generated)
- [ ] Not duplicate of prior breaking post

**Fail any item = REJECT.** No exceptions.

### Breaking News Scan

**Frequency**: Every 2 hours (via `/loop` or manual trigger)

```
firecrawl_search source:news "breaking OR crisis OR war OR escalation OR disaster"
  (last 2 hours, rotate queries)
    ↓
FILTER:
  ✓ Real breaking: war, financial crisis, disaster, geopolitical escalation
  ✗ Skip: analysis, opinions, recaps, local crime, sports, old news
    ↓
For each match:
  1. Dedup check (discord_posts_log)
  2. Download OG image from article
  3. Post to #ข่าวรายวัน:
     - msg1: image embed (color: 15158332 = red)
     - msg2: 🚨 BREAKING: [Thai headline] + 2-3 paragraphs + FA angle + source URL
  4. Log to Supabase
    ↓
No breaking found → skip silently (don't announce)
```

### Voice & Style Rules

| Aspect | Rule |
|--------|------|
| Language | Casual Thai with "ค่ะ", natural tone |
| Format | Paragraph storytelling (NOT bullet lists) |
| Personality | Personal opinions allowed ("วิงว่า...", "อันนี้เด็ดค่ะ") |
| Emoji | 2-3 per section max, not every line |
| Freshness | News must be ≤24 hours old |
| Data | Numbers verified against source, internal codes stripped |
| Audience | FA team — always include "FA Talking Point" |

### Weekly & Monthly Summaries

**Weekly** (Saturdays 10:00, #สรุปรายสัปดาห์):
- 📊 Market recap + 🌍 Top 5-7 stories + 🚨 Breaking highlights + 🏢 AIA events + 📈 Fund performance + 💡 FA takeaway + 🔮 Preview next week

**Monthly** (End of month 10:00, #สรุปรายเดือน):
- Same as weekly but aggregated + statistics (# of posts, # breaking, # events)

## API Endpoints

### Discord REST API (Image Upload)

```
POST https://discord.com/api/v10/channels/{channelId}/messages
Authorization: Bot {DISCORD_BOT_TOKEN}
Content-Type: multipart/form-data

Fields:
  payload_json: {"embeds":[{"image":{"url":"attachment://poster.png"}}]}
  files[0]: @poster-fb.png
  files[1]: @poster-ig.png (optional, up to 4)
```

### Bot API (Text Messages)

```
POST http://localhost:3202/api/discord-reply
Content-Type: application/json

Body:
  {"channelId": "1499713194317582537", "text": "message content"}
```

### Supabase (Post Logging)

```sql
-- Dedup check before posting
SELECT * FROM discord_posts_log
WHERE channel_id = '1499713194317582537'
  AND content ILIKE '%headline%'
  AND created_at > now() - interval '7 days';

-- Log after posting
INSERT INTO discord_posts_log (channel_id, message_id, content, post_type, created_at)
VALUES (...);
```

### Firecrawl MCP (News Search)

```
firecrawl_search({
  query: "breaking crisis war escalation disaster",
  source: "news",
  recency: "2h"
})
```

## Deployment

### Publishing Flow

1. **Draft** — Stories saved in `ψ/writing/` with date-stamped filenames
2. **Poster** — Designer delivers 4 PNG sizes, saved alongside drafts
3. **QA** — Pre-post checklist + BoB approval via thread
4. **Publish** — Discord REST API (images) + bot API (text) in 2-message sequence
5. **Log** — Supabase `discord_posts_log` insert
6. **Archive** — Move to `ψ/outbox/` after posting, all preserved in git

### Dependencies

| Dependency | Required For | Failure Mode |
|-----------|-------------|--------------|
| Discord bot token | Image upload + text posting | Cannot post (vault-managed) |
| Supabase service_role | Post logging + dedup | Post without dedup (risky) |
| Firecrawl API key | Breaking news scan | No breaking news detection |
| Researcher-Oracle | Story sourcing | No raw data for stories |
| Designer-Oracle | Poster generation | Text-only posts (degraded) |
| BoB | QA approval | Cannot publish (gate) |

### Poster Sizes

| Format | Dimensions | Use Case |
|--------|-----------|----------|
| FB | 1200×630 | Facebook feed share |
| IG | 1080×1350 | Instagram feed post |
| Story | 1080×1920 | IG/FB Story format |
| Square | 1080×1080 | General purpose |

## Current State

### What's Working
- Daily news pipeline (Researcher → Wingman → Designer → Discord) fully operational
- Breaking news 2-hour scan cycle
- Pre-post QA checklist enforced
- Supabase post logging and dedup
- Multi-channel posting (news, events, promos, announcements)
- Weekly and monthly summary posts
- น้องวิง voice consistently applied

### Known Issues
- Firecrawl occasionally returns 402 errors (rate limit or auth)
- Supabase permission issues intermittently block logging
- `localhost:3202` bot API silently drops image attachments (use REST API)

### Recent Activity
- 7+ daily news posts (ATW stories) in recent sessions
- 2+ breaking news posts (geopolitical)
- Market briefs and fund insights published regularly
- SOP updated to v1.2 (added weekly/monthly summaries, buddy system)

## Owner & Contacts

| Role | Oracle | Responsibility |
|------|--------|---------------|
| **Lead** | Wingman-Oracle (น้องวิง) | Story writing, publishing, breaking scan, QA checklist |
| **Sourcing** | Researcher-Oracle | News discovery, URL verification, data gathering |
| **Design** | Designer-Oracle | 4-size poster generation per story |
| **QA Gate** | BoB-Oracle | Final approval before publish |
| **Verification** | iAgencyAIA-Oracle | Insurance data accuracy, product fact-checking |
| **Data Buddy** | Data-Oracle | Parallel work support, KB queries |
| **Conduct** | DocCon-Oracle | Discord Content Conduct + Daily News Pipeline Conduct audit |
