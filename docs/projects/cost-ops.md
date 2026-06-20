# Cost Operations

## Overview
- **What it does**: Cost optimization and budget oversight for the entire Oracle fleet — tracks token usage, API costs, task splitting efficiency, and infrastructure spending. Operates as a **Priority Gate**: every major task must pass Cost Oracle review before BoB dispatches.
- **Who uses it**: BoB (task routing), แบงค์ (budget decisions), all oracles (cost-aware operations)
- **Where it runs**: Cost-Oracle tmux session on curfew server

## Architecture

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Runtime | Claude Code + tmux | Oracle agent session |
| Communication | maw hey, /talk-to | Inter-oracle messaging |
| Data | Claude session transcripts, maw logs | Token usage analysis |
| Tracking | ψ/ brain structure (Markdown) | Cost records, learnings, reports |
| Version Control | Git + GitHub | All records persisted |

### No External Code
Cost-Oracle is a **governance oracle**, not a software project. It has no application code, APIs, or databases. Its "product" is cost analysis, recommendations, and approval/denial decisions.

## Code Structure

```
Cost-Oracle/
├── CLAUDE.md              # Identity, Priority Gate protocol, 5 cost dimensions
├── .mcp.json              # MCP server config (oracle-v2)
├── .claude/settings.json  # Hook configuration
└── ψ/                     # Brain structure
    ├── inbox/             # Focus.md, handoffs
    ├── memory/
    │   ├── resonance/     # Identity ("The Ledger of Lightning")
    │   ├── learnings/     # Cost patterns discovered
    │   └── retrospectives/ # Session summaries
    ├── writing/           # Cost reports, analyses
    └── outbox/            # Delivered reports
```

## Business Logic

### Priority Gate Protocol

Every major task flows through Cost Oracle before execution:

```
BoB receives task → Routes to Cost Oracle
  → Cost reviews 5 dimensions
  → ✅ APPROVED (cost optimized, proceed)
  → ⚠️ FLAGGED (proceed with adjustments)
  → 🔴 BLOCKED (too expensive, recommend alternative)
  → BoB dispatches with cost guidance
```

### 5-Dimension Cost Review Checklist

| Dimension | What's Checked | Flagged When |
|-----------|---------------|-------------|
| **Token Usage** | Model selection, prompt length, context window | Opus used for Haiku-level task, bloated prompts |
| **Task Splitting** | Granularity, parallelization, dependencies | Too granular (overhead) or too monolithic (waste) |
| **Oracle Allocation** | Right oracle for right task, skill match | Overqualified oracle on simple task |
| **API Costs** | External API calls, rate limits, caching | Uncached repeated calls, premium API when free exists |
| **Time Efficiency** | Duration estimate, blocking deps, idle time | Task blocked waiting, duplicate work |

### Cost Optimization Principles
- Prefer cheaper models when task doesn't require advanced reasoning (Haiku > Sonnet > Opus)
- Cache API results instead of repeated calls
- Parallelize independent tasks (time = money)
- Track cost per oracle, per project, per session
- Weekly cost summary reports to BoB and แบงค์

### Key Outputs
- **Cost review responses** on major tasks (approve/flag/block)
- **Weekly cost reports** (token burn by oracle, API costs, efficiency metrics)
- **Architecture recommendations** for cost-efficient design
- **Pattern detection** (expensive habits, optimization opportunities)

## API Endpoints
None — Cost-Oracle operates through maw hey / /talk-to messaging only.

## Deployment
- Runs as a Claude Code session in tmux (`19-cost:0`)
- No services to deploy or maintain
- All records in Git (BankCurfew/Cost-Oracle)

## Current State

### What's Working
- Priority Gate protocol active for major tasks
- Cost review checklist operational (5 dimensions)
- Weekly reporting to BoB

### Known Limitations
- No automated token counting (relies on Claude session data)
- No dashboard integration yet (reports are manual Markdown)
- Cost data not aggregated across sessions automatically

## Owner & Contacts

| Role | Oracle | Contact |
|------|--------|---------|
| **Lead** | Cost-Oracle (#19) | /talk-to cost |
| **Reports to** | BoB | /talk-to bob |
| **Stakeholder** | แบงค์ | Via BoB escalation |
| **Team** | Executive Suite (PA, FA, Cost) | — |
