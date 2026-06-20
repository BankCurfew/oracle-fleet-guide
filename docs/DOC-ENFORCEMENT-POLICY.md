# Documentation Enforcement Policy

**Version**: 1.0 | **Date**: 2026-06-20 | **Author**: BoB-Oracle | **Approved by**: แบงค์
**Scope**: ทุก Oracle — code changes MUST update docs

---

## The Rule

**Every code change that affects API, logic, architecture, or business rules MUST update the project documentation.**

Documentation lives at: `oracle-fleet-guide/docs/projects/<slug>.md`

---

## When to Update Docs

| Trigger | Action |
|---------|--------|
| New API endpoint added | Add to API Endpoints section |
| API endpoint changed (params, response) | Update API Endpoints section |
| Business logic changed (formulas, rules) | Update Business Logic section |
| New database table/column | Update Architecture section |
| Deployment process changed | Update Deployment section |
| New feature shipped | Update Current State section |
| Bug fixed that changes behavior | Update relevant section |
| Tech stack change (new lib, framework) | Update Architecture section |
| Environment variables added/changed | Update Deployment section |

## When NOT to Update Docs

- Typo fixes, formatting, CSS-only changes
- Test-only changes (no behavior change)
- Internal refactors that don't change external behavior
- Dependency version bumps (unless breaking)

---

## How It's Enforced

### 1. Hook: `doc-change-check.sh` (PostToolUse:Bash)

Triggers on: `git commit`, `gh issue close`, `maw task done`

| Scenario | Hook Response |
|----------|--------------|
| Project doc missing | ⚠️ Warning: "Create doc" |
| Project doc > 7 days old + code changed | ⚠️ Warning: "Doc stale, update it" |
| Doc fresh + commit | 📝 Reminder: "Update if API/logic changed" |

### 2. DocCon Weekly Audit

Every Friday, DocCon audits:
- Which projects had commits this week?
- Were their docs updated?
- Any new APIs/features without doc updates?

Report format:
```
DOC AUDIT — Week of YYYY-MM-DD
| Project | Commits | Doc Updated | Status |
|---------|---------|-------------|--------|
| fa-tools | 5 | Yes | ✅ |
| maw-js | 3 | No | ❌ STALE |
```

### 3. BoB Review

When closing a task that involved code changes:
- Check if project doc was updated
- If not → reopen or create follow-up ticket

---

## Who Updates What

| Project | Primary Doc Owner | Backup |
|---------|------------------|--------|
| fa-tools | BotDev | Dev |
| fa-quiz | BotDev | Dev |
| maw-js | Dev | Admin |
| oracle-infra | BoB (delegates to Admin/Dev) | Admin |
| daily-news | Wingman | Writer |
| aia-ops | AIA | BotDev |
| customer-data-sync | Data | Dev |
| security-compliance | Security | BoB |
| content-writing | Writer | Editor |
| content-creation | Designer | Writer |
| ijourney-ads | Writer | Designer |
| curfew-migration | BoB | Admin |
| echo-federation | Echo | Dev |
| seo-backlinks | Researcher | Writer |
| lordms | Dev | Admin |
| cost-ops | Cost | BoB |

---

## Doc Update Workflow

```
Oracle commits code that changes API/logic
    ↓
Hook fires: "📝 DOC REMINDER" or "⚠️ DOC STALE"
    ↓
Oracle updates oracle-fleet-guide/docs/projects/<slug>.md
    ↓
Oracle commits doc update + pushes
    ↓
cc BoB: "cc: [project] #ticket — doc updated: <what changed>"
```

### Quick Update Template

When updating a doc, add a changelog entry at the bottom:

```markdown
## Changelog
| Date | What Changed | By |
|------|-------------|-----|
| 2026-06-20 | Added POST /fhc/create endpoint | BotDev |
| 2026-06-20 | Fixed ScoreGauge arc direction | BotDev |
```

---

## Violations

| Offense | Action |
|---------|--------|
| 1st: Doc not updated after code change | DocCon reminder |
| 2nd: Same project, still no update | BoB follow-up ticket |
| 3rd: Pattern of ignoring doc updates | HR performance note |

---

## Why This Exists

- DocCon documented 16 projects (5291 lines, 264KB) — that work is wasted if docs go stale
- แบงค์ ordered "100% correct documentation" — it stays correct only if it's maintained
- New machine migration depends on accurate docs — stale docs = broken setup
- Oracles lose context across sessions — accurate docs = faster onboarding

**If the code changed but the doc didn't, the doc is now a lie.**

---

*Last updated: 2026-06-20 by BoB-Oracle*
