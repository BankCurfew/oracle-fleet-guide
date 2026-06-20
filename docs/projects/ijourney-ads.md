# iJourney Ad Campaign

## Overview
- **What it does**: Cross-oracle advertising funnel for the iJourney FA recruitment quiz — from awareness through conversion. Coordinates Writer (ad copy), Designer (creatives), Wingman (social posting), iAgencyAIA (landing page), DocCon (compliance), and Creator (video content) to produce a complete ad campaign.
- **Who uses it**: FA recruitment pipeline, iAgencyAIA marketing team
- **Where it runs**: Multi-oracle coordination — no single repo. Work products distributed across Writer-Oracle, Designer-Oracle, Wingman-Oracle, and Creator-Oracle repos.

## Architecture

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Ad Copy | Writer-Oracle | 7 personas × 5 AICDA stages |
| Visuals | Designer-Oracle | Poster creatives, social media assets |
| Video | Creator-Oracle | HeyGen video ads, reels |
| Distribution | Wingman-Oracle | Discord, social media posting |
| Landing | iAgencyAIA (journey.iagencyaia.com) | Quiz entry point |
| Tracking | Supabase (quiz_sessions) | Conversion analytics |
| Compliance | DocCon-Oracle | Content conduct review |

### Multi-Oracle Pipeline

```
Writer creates ad copy (7 personas × 5 AICDA stages)
  → Designer creates visual assets (4 sizes per ad)
  → Creator produces video ads (HeyGen)
  → DocCon reviews compliance (content conduct)
  → Wingman distributes to channels
  → Candidates land on journey.iagencyaia.com
  → Quiz tracks conversions (quiz_sessions table)
```

## Code Structure

No single repository — work products are distributed:

| Oracle | Repo | Key Files |
|--------|------|-----------|
| Writer | Writer-Oracle | `ψ/writing/ijourney-ad-copy-all-stages.md` (85.1K — 7 personas × 5 stages) |
| Writer | Writer-Oracle | `ψ/writing/specs/v41-final-complete-spec.md` (94.8K — quiz spec) |
| Designer | Designer-Oracle | `output/ijourney-*/` (poster assets per campaign) |
| Creator | Creator-Oracle | HeyGen video scripts + storyboards |
| Wingman | Wingman-Oracle | Discord posting + social distribution |
| DocCon | DocCon-Oracle | `CLAUDE_ijourney_conduct.md` (8 rules) |

## Business Logic

### AICDA Funnel (5 Stages)

| Stage | Goal | Content Type | Channel |
|-------|------|-------------|---------|
| **Awareness** | "What is FA?" | Educational posts, inspirational stories | Facebook, Instagram, LINE |
| **Interest** | "Could I do this?" | Success stories, day-in-the-life | Facebook carousel, reels |
| **Consideration** | "Is this right for me?" | Quiz invitation, comparison content | Targeted ads, Discord |
| **Decision** | "I want to try" | Direct CTA to quiz | Landing page, LINE push |
| **Action** | "I'm taking the quiz" | Quiz completion, follow-up | journey.iagencyaia.com |

### 7 Target Personas

Each persona gets customized ad copy across all 5 AICDA stages:

1. **Fresh Graduate** — New to workforce, seeking career direction
2. **Career Changer** — Established professional considering FA
3. **Part-time Seeker** — Looking for supplemental income
4. **Entrepreneur** — Business-minded, network-rich
5. **Stay-at-home Parent** — Flexible schedule, people skills
6. **Sales Professional** — Existing sales experience
7. **Community Leader** — Trust network, influence

### Quiz Integration
- Landing page: `journey.iagencyaia.com`
- 24-question RPG assessment (see fa-quiz.md for scoring details)
- 9 career archetypes as results
- Admin dashboard tracks conversion funnel (quiz_sessions → tier distribution)

### Content Compliance
- All ad content must pass DocCon review (iJourney Conduct v1.0)
- 8 rules: scoring accuracy, card content, RPG narration quality, result page, phone recall, deploy, QA regression
- No misleading income claims
- AIA brand compliance (Brand CI v1.0)

## API Endpoints
None — this is a coordination project. See fa-quiz.md for the quiz's technical endpoints.

## Deployment
- Ad content deployed to social media channels via Wingman
- Video ads deployed via Creator (HeyGen → social platforms)
- Quiz deployed at journey.iagencyaia.com (Cloudflare Pages)
- No infrastructure to deploy — uses existing oracle capabilities

## Current State

### What's Working
- Ad copy complete: 7 personas × 5 AICDA stages (85.1K in Writer-Oracle)
- Quiz live at journey.iagencyaia.com (v6.0)
- DocCon conduct established (8 rules)
- Designer poster pipeline active

### In Progress
- HeyGen video production (Creator-Oracle)
- Social distribution campaign (Wingman-Oracle)
- Conversion tracking refinement

## Owner & Contacts

| Role | Oracle | Responsibility |
|------|--------|---------------|
| **Lead (Copy)** | Writer | Ad copy, personas, AICDA stages |
| **Lead (Visual)** | Designer | Poster creatives, social assets |
| **Lead (Video)** | Creator | HeyGen video ads |
| **Distribution** | Wingman | Social posting, Discord |
| **Compliance** | DocCon | Content conduct review |
| **Quiz Platform** | BotDev | fa-recruitment-quiz codebase |
| **Orchestrator** | BoB | Cross-oracle coordination |
