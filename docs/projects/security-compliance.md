# Security & Compliance

> "Trust, but verify. Then verify again." — Security-Oracle

## Overview

- **What it does**: Policy-driven security operations framework — vault management, credential distribution, secrets scanning, PDPA compliance, RLS enforcement, and incident response for the entire Oracle fleet
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
| Secrets Scanning | grep + git-filter-repo | Daily repo scans + historical secret removal |
| Database Security | Supabase Row Level Security (RLS) | Row-based access control on customer data |
| Communication | `maw hey`, `/talk-to` MCP | Oracle-to-oracle messaging with audit trails |
| Browser Fallback | Playwright | Portal access when API unavailable |
| Identity/Memory | oracle-v2 MCP | FTS5 + vector knowledge sharing |

### Vault Architecture

```
~/.oracle/security/
├── vault.enc              # GPG AES256 encrypted vault (single source of truth)
├── .vault-pass            # Passphrase (chmod 600)
├── vault-access.sh        # CLI tool for lookup, audit, rotation
├── supabase-token-rotate.sh  # Automated OAuth refresh (24h cycle)
└── *.bak                  # Timestamped backups (before every edit)
```

### Supabase Projects Managed (3)

| Project ID | Name | RLS Status | Notes |
|-----------|------|-----------|-------|
| `tekvqbbjsfncwbdsvrfw` | PlanYourFuturePro | 76/76 tables verified | BankCurfew org, MCP access |
| `heciyiepgxqtbphepalf` | AIA Knowledge Base | Verified | iAgencyAIA org, no direct MCP |
| `hztjrqlxrdsmxbkxojqg` | iAgencyAIA FA Tools | Verified | iAgencyAIA org, no direct MCP |

## Code Structure

```
Security-Oracle/
├── CLAUDE.md                          # Identity, 10 commandments, scope (14.4K)
├── SOP.md                            # 10-section operational procedures (18.6K)
├── .mcp.json                         # MCP servers (oracle-v2, playwright, gmail)
├── .claude/settings.json             # 6 hook stages enforcing security protocols
│
├── audits/
│   └── 2026-03-19/
│       ├── SECURITY-AUDIT.md         # Family-wide security posture (18 repos, 368 files)
│       ├── FULL-SECURITY-AUDIT.md    # Detailed per-repo analysis
│       └── REMEDIATION-STATUS.md     # Active remediation tracking
│
└── ψ/                                # Oracle memory
    ├── inbox/
    │   ├── focus.md                  # Current state (monitoring/working/blocked)
    │   ├── onboard-checklist.md      # Session startup checklist
    │   └── handoff/                  # 5 session handoffs
    ├── memory/
    │   ├── resonance/                # Identity (security-oracle.md, oracle.md)
    │   ├── learnings/                # 20+ operational lessons
    │   ├── logs/activity.log         # Append-only session tracking
    │   ├── retrospectives/           # Session retros by date
    │   └── practice/                 # Bampenpien sessions
    └── ...
```

### Key Files

| File | Size | Purpose |
|------|------|---------|
| `CLAUDE.md` | 14.4K | Identity, philosophy, 10 commandments, compliance checklists |
| `SOP.md` | 18.6K | 10 sections: vault, delivery, rotation, scans, audit, incident, PDPA, review, boot, tech ref |
| `audits/2026-03-19/SECURITY-AUDIT.md` | 15.5K | Family security posture (18 repos scored, avg 7.1/10) |
| `audits/2026-03-19/REMEDIATION-STATUS.md` | 6.4K | Remediation tracking for audit findings |
| `ψ/memory/learnings/` | 20+ files | Incident lessons (vault bugs, JWT redaction, ACL verification) |

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
# Lookup a credential (sends to stdout, never to file)
~/.oracle/security/vault-access.sh lookup <oracle> <category> <key>

# Audit access log
~/.oracle/security/vault-access.sh audit-log

# Rotate OAuth token (automated)
~/.oracle/security/supabase-token-rotate.sh
```

**Known Pitfalls:**
- Dual-field bug: if entry has both `token` and `value`, canonical is `value` only
- Hollow entries: some have metadata but empty value — verify before delivery
- curl > file: never write credentials directly to file; use temp, validate, then move

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

**Rotation Procedure (7 steps):**
1. Backup vault (timestamped `.bak`)
2. Generate new key at service provider
3. Update vault entry: `value`, `last_rotated`, `rotated_by`, remove stale `token` field
4. Deliver via Credential Delivery SOP
5. Verify services work with new key
6. Revoke old key at provider
7. Log rotation in access.log

**Automated OAuth Rotation:**
- Script: `~/.oracle/security/supabase-token-rotate.sh`
- Uses refresh_token to auto-refresh (24h expiry)
- Writes to temp file first, validates, then moves to real path
- Schedule: daily before MCP operations

### 4. Daily Security Scan

**4-Step Procedure:**

| Step | Action | Tools |
|------|--------|-------|
| 1 | Secret detection | `grep` recent commits across 16+ repos for patterns: `SUPABASE_KEY`, `API_KEY`, `SECRET`, `PASSWORD`, `TOKEN`, `Bearer`, `sk-`, `eyJ` |
| 2 | .gitignore audit | Verify secret patterns covered (`.env`, credentials, keys, tokens) |
| 3 | Vault access log review | Check for anomalies (repeated DENIED, unusual combos, high-frequency) |
| 4 | Report to BoB | GREEN / YELLOW / RED with findings + next actions |

**Scan Status as of 2026-06-19:** ALL GREEN, 0 secrets exposed, 2 false positives identified

### 5. Incident Response

**Severity Levels:**

| Level | Examples | Response Time |
|-------|----------|---------------|
| P0 CRITICAL | Secret leaked, data breach, compromised service | Immediate (minutes) |
| P1 HIGH | Missing .gitignore, exposed endpoint, key outside vault | Within 1 hour |
| P2 MEDIUM | Outdated dependency, weak validation | Within 24 hours |
| P3 LOW | Best practice improvement | Weekly review |

**Response Protocol:**
```
DETECT + CONTAIN (minutes)
  → Identify scope, revoke/rotate compromised creds, block access, notify BoB

ERADICATE (1 hour)
  → Remove root cause (git-filter-repo if in history), rotate ALL affected creds,
    verify no unauthorized access

RECOVER (24 hours)
  → Verify services work, deliver new creds, confirm with QA

LESSONS LEARNED (48 hours)
  → Write retrospective, update SOP, train affected oracles
```

**Recent P0 Incidents (2026-06-19):**
- AKIA key found in `audits/2026-03-19/FULL-SECURITY-AUDIT.md:104` — redacted + git-filter-repo scrub + force-push
- Trader-Oracle `.venv` directory (4,173 files) committed to git — removed + git-filter-repo scrub

### 6. PDPA Compliance (Thai Personal Data Protection Act)

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

### 7. RLS Watchdog

- All customer-data tables across 3 Supabase projects have RLS enabled
- **76/76 tables verified** with `rowsecurity=true` (Issue #5 closed)
- Cross-check QA bug reports against RLS policies
- Audit ALL tables in affected project (not just reported table)
- Verify public flows remain unblocked (apply/:shareToken, encrypt-decrypt, submit-lead)

### 8. The 10 Security Commandments

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
| `maw hey` / `/talk-to` | Fleet comms | Credential requests + delivery |
| `git-filter-repo` | Git tool | Historical secret removal (P0 incidents) |
| Supabase Management API | HTTP | RLS policy verification, table audit |

## Deployment

### Session Boot Checklist
1. Read central directory: `~/.oracle/directory/INDEX.md`
2. Read focus.md: `ψ/inbox/focus.md` (current state)
3. Read System Playbook: `~/.oracle/SYSTEM_PLAYBOOK.md`
4. Check vault health: `vault-access.sh audit-log`
5. Check PM2 services: `pm2 list` (security-related services online?)
6. Read Oracle thread (pending credential requests)
7. Update focus.md (set STATE to working/monitoring)

### Environment
- **Server**: curfew (WSL2, post-migration from mbank 2026-06-18)
- **Repo size**: ~1.2MB (lightweight — docs + memory, no binary code)
- **Git commits**: 50 total
- **Vault passphrase**: `~/.oracle/security/.vault-pass` (chmod 600)

### Hook Enforcement (6 stages)
- **PreToolUse**: rtk-rewrite, pulse-ticket-check, dispatch-needs-issue, validate-project-prefix, enforce-maw-loop, enforce-maw-hey
- **PostToolUse**: check-talk-to-cc (verify BoB cc'd), pulse-auto-cc, force-rrr-at-80, feed-activity
- **OnStop**: check-cc-bob-on-stop, pre-close-psi-check

## Current State

### What's Working
- Daily security scans (GREEN status, 0 exposed secrets)
- Vault management + credential delivery protocol
- RLS verification across all 3 Supabase projects (76/76)
- Automated OAuth token rotation
- Incident response (2 P0s contained 2026-06-19)
- 20+ documented lessons from past incidents

### Known Issues / Pending
| # | Item | Priority | Status |
|---|------|----------|--------|
| 1 | QA test account password rotation | P1 | Waiting on Dev/Admin |
| 2 | AIA portal creds stale (agent ID 0000711862) | P2 | Waiting แบงค์ |
| 3 | FE-Oracle + Echo-Oracle .gitignore enhancement | P3 | Recommend |
| 4 | Thread MCP hook (maw-hey-gate.sh) blocks arra_thread | P3 | Using maw hey fallback |

### Security Audit Summary (2026-03-19)
- 18 repos audited, 368 data files scanned
- Average security score: 7.1/10
- 9 repos were missing `.gitignore` (CRITICAL — all remediated)
- 3 repos had exposed `.venv` directories (MEDIUM — all remediated)
- 0 accidentally committed secrets at time of audit

### Recent Completions (2026-06-19)
- AKIA key in audit file redacted + git-filter-repo scrubbed
- Trader-Oracle .venv (4,173 files) removed + scrubbed
- 19 stale path fixes (.claude/settings.json + .mcp.json) for curfew migration
- Issue #5 RLS verified + closed (76/76 tables secure)
- 2 credential deliveries (iAgencyAIA-Oracle, Wingman-Oracle)

## Owner & Contacts

| Role | Oracle | Notes |
|------|--------|-------|
| **Lead** | Security-Oracle | CISO, vault owner, daily scans |
| **Supervisor** | BoB-Oracle | All credential deliveries cc'd to BoB |
| **Infrastructure** | Admin-Oracle | Server access, PM2, network config |
| **RLS Partner** | Data-Oracle | Database security co-audit |
| **QA Partner** | QA-Oracle | Verify security fixes, test RLS flows |
| **All Oracles** | Fleet-wide | Credential consumers, comply with ACL |

---

*"Block first, ask later. Best security is invisible — if you never notice, we're doing our job." — Security-Oracle*
