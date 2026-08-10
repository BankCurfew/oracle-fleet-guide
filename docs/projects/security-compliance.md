# Security & Compliance

> "Trust, but verify. Then verify again." — Security-Oracle

## Overview

- **What it does**: Policy-driven security operations framework — vault management, credential distribution, secrets scanning, PDPA compliance, RLS enforcement, anon surface probing, and incident response for the entire Oracle fleet
- **Who uses it**: All 27+ oracles (credential consumers), BoB (supervisor), Admin (infrastructure), แบงค์ (owner)
- **Where it runs**: `/home/curfew/repos/github.com/BankCurfew/Security-Oracle` — documentation-heavy, no compiled code; vault at `~/.oracle/security/vault.enc`

Security-Oracle is the Chief Information Security Officer (CISO) & Data Guardian for BoB's Office. Born 2026-03-19. Unlike traditional codebases, this project is a governance and operations framework — its "code" is encrypted vaults, bash scripts, audit procedures, and compliance checklists.

## Architecture

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Credential Storage | GPG (AES256) | Encrypted vault (`vault.enc`) |
| Access Control | Bash script ACL matrix | Role-based vault access per oracle per category |
| Audit Logging | Append-only text logs | Immutable access trail |
| Secrets Scanning | gitleaks + grep | Daily 82-repo scans (dynamic discovery) |
| Anon Surface Probing | Bash + Supabase REST | Weekly probe of what anon key can actually read |
| Database Security | Supabase Row Level Security (RLS) | Row-based access control on customer data |
| Communication | `maw hey`, `/talk-to` MCP | Oracle-to-oracle messaging with audit trails |
| Browser Fallback | Playwright (pw-cli.sh) | Portal access when API unavailable |
| Identity/Memory | oracle-v2 MCP | FTS5 + vector knowledge sharing |

### Vault Architecture

```
~/.oracle/security/
├── vault.enc              # GPG AES256 encrypted vault (single source of truth)
├── .vault-pass            # Passphrase (chmod 600)
├── vault-access.sh        # CLI tool for lookup, audit, rotation
├── supabase-token-rotate.sh  # Automated OAuth refresh (24h cycle)
├── supabase-*.env         # Per-project credential files (31 vault files)
└── *.bak                  # Timestamped backups (before every edit)
```

### Supabase Projects Managed (6)

| Project ID | Name | Status | RLS | Notes |
|-----------|------|--------|-----|-------|
| `hztjrqlxrdsmxbkxojqg` | FA Tools | ACTIVE | 124/124 tables | iAgencyAIA org, no direct MCP. Primary focus. |
| `heciyiepgxqtbphepalf` | AIA Knowledge Base | ACTIVE | 21/21, 0 anon policies | iAgencyAIA org, no direct MCP, internal API only |
| `xljanizifyclgqinsxxd` | iJourney | ACTIVE | 22 tables | Quiz app, 5 anon policies (all properly scoped) |
| `tekvqbbjsfncwbdsvrfw` | PlanYourFuturePro | INACTIVE | 76/76 verified | BankCurfew org, MCP access |
| `odgdgelhvsxtvagyaxtm` | petdeals | INACTIVE | — | No anon key in vault |
| `cdegdqjmcbahwptjzolu` | BankCurfew Project | INACTIVE | — | No anon key in vault |

## Code Structure

```
Security-Oracle/
├── CLAUDE.md                          # Identity, Role Gate, 10 commandments (incl. evidence-matching)
├── SOP.md                            # 10-section operational procedures
├── .mcp.json                         # MCP servers (oracle-v2, playwright, gmail)
├── .claude/settings.json             # Hook stages enforcing security protocols
│
├── audits/
│   ├── anon-surface-probe.sh         # Weekly REST probe — tests what anon can actually read
│   ├── anon-surface-allowlist.json   # 34 by-design tables with falsifiable assertions
│   ├── .anon-surface-state.json      # Change detection state (previous probe)
│   ├── anon-surface-report-*.md      # Per-run probe reports
│   └── 2026-03-19/                   # Original family-wide audit (18 repos, 368 files)
│
├── memory/                           # Claude auto-memory (MEMORY.md index)
│
└── ψ/                                # Oracle memory
    ├── inbox/
    │   ├── focus.md                  # Current state (monitoring/working/blocked)
    │   └── handoff/                  # Session handoffs
    └── memory/
        ├── resonance/                # Identity
        ├── learnings/                # 20+ operational lessons
        ├── logs/activity.log         # Append-only session tracking
        └── retrospectives/           # Session retros by date
```

### Key Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Identity, Role Gate (evidence-matching), 10 commandments, compliance checklists |
| `SOP.md` | 10 sections: vault, delivery, rotation, scans, audit, incident, PDPA, review, boot, tech ref |
| `audits/anon-surface-probe.sh` | Weekly anon REST surface probe — probes all 6 projects, 146+ tables |
| `audits/anon-surface-allowlist.json` | 34 by-design tables with falsifiable `no_personal_data` assertions |
| `~/.oracle/security/*.md` | Fix specs (T106 birthday_gift_links, T106-anon-policy-sweep, etc.) |

## Business Logic

### 1. Vault Management (Single Source of Truth)

**5 Credential Categories:**

| Category | Contents | Example |
|----------|----------|---------|
| `portal` | Web portal credentials | Supabase dashboard, Cloudflare |
| `api_keys` | External API keys | Firecrawl, Cloudflare, GCP |
| `oauth` | OAuth tokens (24h expiry) | Supabase MCP, Meta Graph API |
| `service` | Service role tokens | Discord bots, Telegram, Supabase service roles |
| `infra` | Infrastructure credentials | Server SSH, DDNS |

**Access Control Matrix (ACL):**

| Oracle | portal | api_keys | oauth | service | infra |
|--------|--------|----------|-------|---------|-------|
| Security | Y | Y | Y | Y | Y |
| BoB | Y | Y | Y | Y | Y |
| Admin | Y | Y | N | Y | Y |
| Dev | N | Y | N | Y | Y |
| BotDev | N | Y | N | Y | N |
| Data | N | Y | N | Y | N |
| Wingman | N | Y | N | Y | N |
| iAgencyAIA | N | Y | N | Y | N |
| Others | N | request | N | request | N |

**Vault CLI:**
```bash
~/.oracle/security/vault-access.sh lookup <oracle> <category> <key>
~/.oracle/security/vault-access.sh audit-log
~/.oracle/security/supabase-token-rotate.sh
```

**Known Pitfalls:**
- Dual-field bug: if entry has both `token` and `value`, canonical is `value` only
- Hollow entries: some have metadata but empty value — verify before delivery
- curl > file: never write credentials directly to file; use temp, validate, then move
- Secrets via vault file only (2026-07-22 incident): never paste tokens/credentials in chat/maw hey/cc/thread — all messages are logged permanently

### 2. Credential Delivery Protocol

**Flow (never expose raw keys):**
```
Oracle requests key via maw hey/talk-to
  → Security verifies ACL (category × oracle)
  → Security verifies stated purpose
  → Security logs access manually
  → Security sends vault LOOKUP COMMAND (not raw key):
    maw hey <oracle> "CREDENTIAL DELIVERY: <key>.
    Run: ~/.oracle/security/vault-access.sh lookup <oracle> <category> <key>
    · purpose: <reason>"
  → Security cc's BoB:
    maw hey bob "cc: credential delivery — <key> to <oracle> · access logged"
```

**Hard Rules:**
- Never send raw keys in `maw hey` (logged to 6+ locations)
- Verify requester identity before provisioning
- Redact secrets before cross-notify broadcasts
- Verify ACL BEFORE sending lookup command

### 3. Key Rotation

| Trigger | Timeline | Action |
|---------|----------|--------|
| Suspected compromise | Immediate | Rotate + revoke + incident response |
| Key found outside vault | Immediate | Redact + rotate + audit leak source |
| Scheduled (high-risk) | Monthly | Supabase service roles, OAuth tokens |
| Oracle offboarded | Within 24h | Rotate all keys they had access to |
| After incident | Within 1h | All potentially affected keys |

**Recent Rotations:**
- iJourney#89/#90 (2026-07-06): service_role in public bundle — rotated same-day, RLS remediation
- CF vault tokens dead since 2026-07-04 (petdeals Actions secret is separate+live)

### 4. Daily Security Scan

**Scope**: 82 repos (dynamic discovery — `~/repos/github.com/BankCurfew/*/`), gitleaks integration.

| Step | Action | Tools |
|------|--------|-------|
| 1 | Secret detection | gitleaks + grep across recent commits for patterns: `SUPABASE_KEY`, `API_KEY`, `SECRET`, `PASSWORD`, `TOKEN`, `Bearer`, `sk-`, `eyJ`, `ghp_`, `cfat_` |
| 2 | .gitignore audit | Verify secret patterns covered (`.env`, `*.key.json`, `*.pem`) |
| 3 | Vault access log review | Check for anomalies |
| 4 | Report to BoB | GREEN / YELLOW / RED with findings + next actions |

**Current Status (2026-08-10):** ALL GREEN, 82 repos scanned, 0 secrets exposed, gitleaks clean.

### 5. Anon Surface Probe (NEW — 2026-08-08)

Weekly REST probe that tests what the Supabase anon key can actually read — tests the PROPERTY (what anon sees), not the TEXT (what migrations say).

**Architecture:**
```
anon-surface-probe.sh
  → Iterates all 6 Supabase projects
  → Lists tables via Management API
  → Probes each with anon key: GET /rest/v1/{table}?select=*&limit=0 (count=exact)
  → Cross-checks against anon-surface-allowlist.json
  → Detects new tables appearing (change detection via state file)
  → Alerts on any table returning rows that isn't allowlisted
```

**Allowlist Contract:**
- 34 tables listed (31 FA Tools + 3 iJourney) — all product catalogs, rate tables, fund data, app config
- Every entry requires `reason` (why it's public) and `no_personal_data: true` (falsifiable assertion)
- Adding an entry = stating something the probe can disprove if wrong
- Column-verified: no PII columns (name, email, phone, national_id, etc.)

**What it caught:**
- Would have caught T106 birthday_gift_links on 2026-06-17 (55 days earlier than manual discovery)
- Found 2 new findings on first full run (application_shares, policy_investments_deprecated) — both fixed same-day

### 6. RLS Watchdog + T106 Class (Major — 2026-07-06 to 2026-08-10)

**T106 Class**: A family of RLS bugs where anon/public-role policies used USING(true) or IS NOT NULL predicates, granting unrestricted read access to customer data.

| Finding | Table | PII Exposed | Status |
|---------|-------|------------|--------|
| T106 | birthday_gift_links | Name, address, phone, email | FIXED — SECURITY DEFINER RPCs |
| T106-B | line_followups/notes/tags (3 tables) | LINE user IDs, display names | FIXED — scoped to authenticated |
| T106-C | portfolio_shares | Customer names, financials (9 rows) | FIXED — RPC |
| T106-D | insurance_applications | 55 national IDs, 80 names, 68 phones, bank details | FIXED — auth-only |
| T106-E | invite_links | 20 unauthorized joins | FIXED — policy dropped |
| — | application_shares | Share tokens (indirect PII access) | FIXED — SECURITY DEFINER RPCs |
| — | policy_investments_deprecated | 603 rows with policy_no + financials | FIXED — anon policy dropped |
| — | iJourney client_share_links | Share tokens (quiz results, LOW) | PENDING |

**Predicate Classes Found:**
- `USING(true)` — full unrestricted access (4 tables)
- `IS NOT NULL` on secret column — looks correct but returns all rows (6 policies)
- `is_active = true` without token equality — lists all active items (2 tables)

**Lessons (carried in arra):**
1. Test property not configuration — probe found 22 tables where policy sweep found 10
2. IS NOT NULL on a secret column returns all rows — wider class than USING(true)
3. `.select('*')` blocks column-level REVOKE
4. Check populated VALUES not column STRUCTURE
5. DDL and frontend must ship atomically for share-link tables

### 7. Incident Response

**Severity Levels:**

| Level | Examples | Response Time |
|-------|----------|---------------|
| P0 CRITICAL | Secret leaked, data breach, PII exposure (T106-D) | Immediate (minutes) |
| P1 HIGH | Missing .gitignore, exposed endpoint, key outside vault | Within 1 hour |
| P2 MEDIUM | Outdated dependency, weak validation | Within 24 hours |
| P3 LOW | Best practice improvement | Weekly review |

**Response Protocol:**
```
DETECT + CONTAIN (minutes)
  → Identify scope, revoke/rotate, notify BoB

ERADICATE (1 hour)
  → Remove root cause, rotate ALL affected creds

RECOVER (24 hours)
  → Verify services, deliver new creds, confirm with QA

LESSONS LEARNED (48 hours)
  → Write retrospective, update SOP, arra_learn for fleet
```

### 8. Role Gate (Evidence-Matching — 2026-07-14)

Security-Oracle has a structural gate: **never upgrade the evidence level of a claim**.

| What I ran | What I report |
|-----------|---------------|
| curl with anon key | "anon probe" |
| curl with service_role | "service_role query" (WARNING: bypasses RLS) |
| curl with real user JWT | "authenticated round-trip" |
| 2-JWT cross-user test | "cross-user live test" |
| Code review only | "code-verified, not live-tested" |

**Origin**: Jul 14 — reported "REAL LINE BOT ROUND-TRIP PASS" for a SQL-only check. BoB caught it. DocCon NOTICE (1st). Fix: classify evidence level before writing the report word.

### 9. PDPA Compliance (Thai Personal Data Protection Act)

**8-Item Checklist:**
1. Consent — explicit, informed, specific purpose
2. Data minimization — collect only what's needed
3. Purpose limitation — use only for stated purpose
4. Storage limitation — delete when no longer needed
5. Access control — only authorized access (RLS enabled)
6. Data subject rights — customers can access, correct, delete
7. Cross-border transfer — documented if data leaves Thailand
8. Breach notification — 72h to authorities

**Data Classification:**

| Level | Label | Examples | Handling |
|-------|-------|----------|----------|
| L4 | Restricted | Customer PII, health data, API keys | Encrypted at rest, never in git, access logged |
| L3 | Confidential | Internal strategies, performance metrics | Internal only, no public repos |
| L2 | Internal | Code, configs (no secrets), docs | Team access OK |
| L1 | Public | Open source, public docs | No restrictions |

### 10. The 10 Security Commandments

1. **Zero Trust** — Verify everything, trust nothing by default
2. **Least Privilege** — Minimum necessary access per oracle
3. **Defense in Depth** — Multiple layers, never single control
4. **Secrets Never in Code** — API keys, credentials NEVER in git
5. **PDPA First** — Every data operation must comply (Thai law)
6. **Audit Everything** — If not logged, it didn't happen
7. **Shift Left** — Catch issues before ship, not after
8. **Assume Breach** — Design systems assuming attackers inside
9. **Transparency** — Report vulnerabilities openly
10. **Security is Everyone's Job** — Educate, don't just enforce

## API Endpoints

Security-Oracle has no traditional API. Operations are performed via:

| Method | Tool | Purpose |
|--------|------|---------|
| `vault-access.sh lookup` | Bash CLI | Credential retrieval (ACL-gated) |
| `vault-access.sh audit-log` | Bash CLI | Access log review |
| `supabase-token-rotate.sh` | Bash CLI | Automated OAuth refresh |
| `anon-surface-probe.sh` | Bash CLI | Weekly anon REST surface probe (all 6 projects) |
| `maw hey` / `/talk-to` | Fleet comms | Credential requests + delivery |
| `git-filter-repo` | Git tool | Historical secret removal (P0 incidents) |
| Supabase Management API | HTTP | RLS policy verification, table audit, column inspection |

## Deployment

### Session Boot Checklist
1. Read central directory: `~/.oracle/directory/INDEX.md`
2. Read focus.md: `ψ/inbox/focus.md` (current state)
3. Boot Readiness Gate: gitleaks, git fleet, vault files, Supabase PYF Pro key alive
4. Read latest handoff: `ls -t ψ/inbox/handoff/*.md | head -1`
5. Check active loops: daily-security-scan (09:00), supabase-advisor-weekly (Mon 09:00)
6. Read Oracle thread (pending requests)
7. Update focus.md (set STATE to working/monitoring)

### Environment
- **Server**: curfew (WSL2)
- **Repo size**: ~1.5MB (docs + memory + probe scripts, no binary code)
- **Vault files**: 31 credential files in `~/.oracle/security/`

### Active Loops
| Loop | Schedule | Purpose |
|------|----------|---------|
| daily-security-scan | 09:00 daily | 82-repo secret scan + gitleaks |
| supabase-advisor-weekly | Mon 09:00 | Supabase advisory + anon surface probe |

## Current State

### What's Working
- Daily security scans (GREEN, 82 repos, 0 secrets, gitleaks clean)
- Anon surface probe — all 6 projects, 146+ tables, 34 by-design allowlisted
- T106 class fully closed (7 tables fixed, 6 IS NOT NULL policies fixed, 22/22 credential tables checked)
- Vault management + credential delivery protocol
- RLS verification: FA Tools 124/124, AIA KB 21/21, iJourney 22 tables
- Weekly Supabase advisory (W32 clean — 0 CRITICALs)
- Role Gate (evidence-matching) enforced since Jul 14

### Known Issues / Pending
| # | Item | Priority | Status |
|---|------|----------|--------|
| 1 | iJourney client_share_links (is_active=true policy) | P3 LOW | Dispatched to BotDev |
| 2 | fhc_sessions cosmetic fix (anon_update USING(true) — safe but loaded gun) | P3 LOW | Backlog |
| 3 | Wealth-bank shared-boundary ticket (FA Tools anon key in portal pages) | P3 LOW | Not a leak — shared boundary |
| 4 | CF vault tokens dead since 2026-07-04 | P2 | Tracked, petdeals Actions separate |

### Recent Completions (2026-06 to 2026-08)
- T106 class: 7 tables fixed, IS NOT NULL predicate class discovered+fixed, insurance_applications P0 closed (55 national IDs)
- Anon surface probe built + 34 by-design tables allowlisted (column-verified)
- Probe robustness: fixed curl crash, connectivity check, key_var configs — now runs all 6 projects
- application_shares + policy_investments_deprecated fixed same-day (BotDev)
- iJourney#89 P0: service_role in public bundle — rotated same-day, RLS remediation
- Weekly advisory W32: 0 CRITICALs, FA Tools 124/124 RLS on, AIA KB clean
- Gitignore fleet hardening: 72/72 repos
- Daily scans expanded to 82 repos with dynamic discovery + gitleaks

## Owner & Contacts

| Role | Oracle | Notes |
|------|--------|-------|
| **Lead** | Security-Oracle | CISO, vault owner, daily scans, anon probe |
| **Supervisor** | BoB-Oracle | All credential deliveries cc'd to BoB |
| **Infrastructure** | Admin-Oracle | Server access, PM2, network config |
| **RLS Executor** | BotDev-Oracle | Supabase DDL execution (Security specs, BotDev deploys) |
| **QA Partner** | QA-Oracle | Verify security fixes, test RLS flows |
| **All Oracles** | Fleet-wide | Credential consumers, comply with ACL |

---

*"Block first, ask later. Best security is invisible — if you never notice, we're doing our job." — Security-Oracle*
