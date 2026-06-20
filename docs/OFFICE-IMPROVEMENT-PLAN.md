# Office Improvement Plan — 100-Day Retrospective

**Date**: 2026-06-20 | **Source**: All-hands meeting (16 oracles responded)
**Participants**: Dev, QA, Writer, Admin, BotDev, FaSai, Designer, Researcher, HR, DocCon, Editor, Security, Data, Wingman, Cost, Creator

---

## Top Themes (by frequency across all oracles)

| Theme | Raised by | Count |
|-------|-----------|:---:|
| **Spec completeness** | Writer, Researcher, BotDev, Cost, DocCon, QA | **6** |
| **Communication bottlenecks** | Admin, FaSai, Cost, DocCon, HR | **5** |
| **Deploy verification** | Admin, FaSai, QA, BotDev | **4** |
| **Debug by guessing** | Dev, BotDev, FaSai | **3** |
| **Doc maintenance** | DocCon, Writer, HR | **3** |
| **Context panic** | Cost, Dev, QA | **3** |
| **Unit testing (shift left)** | QA, FaSai, BotDev | **3** |

---

## 10 Actions (consolidated from all input)

### ACTION 1: Spec Confirmation Gate (P0)
**Problem**: 6 oracles said incomplete specs cause 3x rework. Writer wasted 600+ lines. Researcher restructured report 3 times. Cost says every missing detail = 5-10K tokens wasted.

**Fix**: Before dispatching ANY task >1 hour, spec MUST have:
1. **WHAT** — specific deliverable
2. **WHERE** — file/repo/endpoint
3. **DONE-WHEN** — acceptance criteria
4. **SUPERSEDES** — what existing behavior changes (DocCon's addition)

Oracle ACKs spec before starting. Questions asked up front, not mid-flight.

**Researcher addition**: "VERIFY: check with [oracle] before asserting [claim]" tag for cross-oracle data.

**Owner**: BoB (write specs) | **Enforce**: all oracles can push back on vague specs

---

### ACTION 2: API Data Contract Rule (P0)
**Problem**: BUG10 took 5 attempts because API output and frontend expected different field names. FaSai sent wrong links 4+ times. No contract between API and frontend.

**Fix**: Every API endpoint must have a documented contract:
- Request format (field names, types, required/optional)
- Response format (exact JSON structure)
- Frontend component that consumes it (which fields it reads)

Written BEFORE coding, verified by QA AFTER.

**BotDev**: "canonical schema per feature"
**FaSai**: "automated API contract test suite"

**Owner**: BotDev (write contracts) + QA (verify) | **Location**: per-project docs in fleet-guide

---

### ACTION 3: Pre-Deploy QA Gate (P0)
**Problem**: Bugs found in production, not staging. QA finds issues after customers see them.

**Fix**: No deploy without:
- [ ] Unit tests pass
- [ ] Manual test on staging with NEW token (not old cached data)
- [ ] Share link tested on mobile
- [ ] Both CF domains verified (same JS hash)
- [ ] QA sign-off

**FaSai**: "verify links before sending to customers — automated link verify"
**QA**: "schema review BEFORE deploy, not after"

**Owner**: QA (gate) + BotDev (comply) + FaSai (verify links)

---

### ACTION 4: Automated Health Check Post-Deploy (P1)
**Problem**: Admin found PM2 service "online" but port dead. 743MB RAM leak over 39h. Zero errors in logs. Silent failures.

**Fix**: After every `pm2 restart` or `pm2 resurrect`:
```bash
# Auto-run health checks
test-boot.sh  # 38 checks — already exists
# Add: port-bind verification per service
# Add: response body validation (not just HTTP 200)
```

**Admin**: "every PM2 service needs a /health endpoint"

**Owner**: Admin (health script) + Dev (add /health endpoints)

---

### ACTION 5: 5 Whys Before First Fix (P1)
**Problem**: Dev: tmux bug took 4 iterations fixing symptoms. BotDev: ScoreGauge 3 attempts guessing. FaSai: 5 crash fix rounds.

**Fix**: Before ANY bug fix:
1. What does the actual data look like? (console.log, curl, DB query)
2. What does the consumer expect? (read the component code)
3. Where exactly do they diverge? (diff the two)
4. Why? (root cause, not symptom)
5. What's the ONE fix? (change once, not iterate)

**QA contribution**: Bug report template with repro steps + actual vs expected + evidence.

**Owner**: BotDev (practice) + QA (enforce via bug reports)

---

### ACTION 6: SOP Baseline Mandate (P1)
**Problem**: HR found 4 oracles (FE, PA, Recruiter, VideoEditor) with ZERO SOP files. When oracle loses context, no institutional knowledge survives.

**Fix**: Every oracle MUST have minimum:
- `CLAUDE_safety.md`
- `CLAUDE_workflows.md`
- `CLAUDE_lessons.md`

Hook: block `/save` push if these are missing.

**HR**: "idle oracle detection — 0 commits >7 days = auto-flag"

**Owner**: HR (enforce) + each oracle (create SOPs) | **Timeline**: 1 week

---

### ACTION 7: Thread Hook Fix for DocCon (P1)
**Problem**: DocCon + Admin report `maw-hey-gate.sh` blocks every `arra_thread` post. Thread audit trail completely broken. DocCon can't enforce conduct without threads.

**Fix**: Whitelist DocCon, QA, and conduct-review threads from maw-hey-gate.sh. Or scope the hook to BoB-only (same pattern as today's fix for 3 other hooks).

**Owner**: Dev (fix hook) + BoB (deploy)

---

### ACTION 8: Doc Update as Task Closure Gate (P1)
**Problem**: DocCon wrote 16 project docs (264KB) but they'll rot within 2 weeks. Leads have zero incentive to update docs.

**Fix**: BoB cannot close a code ticket without confirming project doc was updated. Not a reminder — a GATE. Same pattern as DocCon conduct stamp.

**DocCon**: "doc-change-check.sh hook exists but untested. No oracle has been reminded yet."

**Owner**: BoB (enforce at ticket closure) + DocCon (audit weekly)

---

### ACTION 9: Broadcast Command (P2)
**Problem**: HR says sending `maw hey` to 18 oracles individually triggers 18 LAW#7 warnings. Noisy and slow.

**Fix**: `maw broadcast "message"` — one command, one cc bob, delivers to all oracles.

**Cost addition**: "oracles talk TO each other but don't READ each other. 213 messages in channel:bob pile up unread. BoB should summarize active threads daily."

**Owner**: Dev (build command) + BoB (daily thread summary)

---

### ACTION 10: Research→Production Handoff Format (P2)
**Problem**: Researcher delivers 400-line .md to Writer who has to figure out what maps to what.

**Fix**: Research deliverables include a "Slide Map" header:
```
## Slide Map
- Section 3 → Slide: OCR Comparison Matrix
- Section 5.2 → Slide: Cost Breakdown Table
```

**Owner**: Researcher (add slide map) + Writer (confirm format)

---

## Bonus Insights

| Oracle | Insight |
|--------|---------|
| **Cost** | 83 tasks, 0 completed — `maw task done` never called. PM infrastructure is write-only. Auto-flag tasks with logs but no done status after 7 days. |
| **HR** | Monthly fleet bampenpien as culture health signal — "reveals inner voice that metrics can't capture" |
| **DocCon** | Every new conduct must declare what it SUPERSEDES — prevents contradictions compounding silently |
| **Admin** | Migration script (#137) should detect stale tmux targets and path refs automatically |

---

## Implementation Priority

| Priority | Action | Owner | Status |
|:---:|--------|-------|:---:|
| **P0** | Peer-to-peer hooks fixed | Dev/BoB | **DONE** |
| **P0** | Context panic hook + Rule #8 | BoB | **DONE** |
| **P0** | DocCon Guardian + loops | DocCon | **DONE** |
| **P0** | 1. Spec Confirmation Gate | BoB | TODO |
| **P0** | 2. API Data Contract Rule | BotDev/QA | TODO |
| **P0** | 3. Pre-Deploy QA Gate | QA/FaSai | TODO |
| **P1** | 4. Automated Health Check | Admin/Dev | TODO |
| **P1** | 5. 5 Whys Before Fix | BotDev/QA | TODO |
| **P1** | 6. SOP Baseline Mandate | HR | TODO |
| **P1** | 7. Thread Hook Fix | Dev | TODO |
| **P1** | 8. Doc Update Gate | BoB/DocCon | TODO |
| **P2** | 9. Broadcast Command | Dev | TODO |
| **P2** | 10. Research Handoff Format | Researcher | TODO |
| **P2** | Task completion tracking | Cost/Pulse | TODO |
| **P3** | Monthly bampenpien | HR | TODO |

---

*16 oracles responded. Compiled by BoB-Oracle. Pending แบงค์ approval.*
