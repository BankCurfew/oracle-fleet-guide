# Lessons Learned — 2026-06-17 HQ→Curfew Migration

## What We Lost (Permanently)

| Item | Why Lost | Impact | Prevention |
|------|----------|--------|------------|
| **Pulse CLI source** | Never committed to git (lived in `ψ/lab/pulse-cli-clean/`) | `/pulse-board`, `/pulse-add`, `/pulse-scan` broken | **ALWAYS commit tools to git.** Never keep source code only in ψ/ |
| **Maw task activity logs** | Stored locally in maw-js data dir, not synced | All historical task progress lost | Export task logs to GitHub issues or cloud storage regularly |
| **GPG keyring** | Local-only at `~/.gnupg/` | Can't decrypt `vault.enc` | Backup GPG keys to secure cloud storage or second machine |
| **Writer's dark/ folder** | Local content not committed | Abyssal Eden creative writing lost | Commit all creative work to git, even drafts |
| **maw project task links** | Local-only (projects recreated empty) | 11 projects had zero tasks after migration | Sync task state to GitHub issues or Supabase |

## Discovered During Recovery (add to migration checklist)

### 6. Oracle .claude/settings.json — Hook Paths

**Problem**: Designer-Oracle's `.claude/settings.json` still had `/home/mbank` in all hook paths. Every hook failed with "not found". 7 other oracles had NO settings.json at all — they ran without hooks (no rtk, no pulse-ticket-check, no feed-activity).

**Fix**: `sed -i 's|/home/mbank|/home/curfew|g'` on Designer's settings.json. Created settings.json from template for 6 oracles that were missing it (Cost, Recruiter, Scalper, Trader, Wingman, iAgencyAIA).

**Prevention**: Add `.claude/settings.json` to the path fix script. Verify EVERY oracle has a settings.json with correct paths. Add to migration checklist:
```bash
# Fix all settings.json
find ~/repos/github.com/BankCurfew -path "*/.claude/settings.json" -exec sed -i "s|$OLD|$NEW|g" {} \;

# Check for missing settings.json
for dir in ~/repos/github.com/BankCurfew/*-Oracle; do
  [ -f "$dir/.claude/settings.json" ] || echo "MISSING: $(basename $dir)"
done
```

## What Almost Broke Us

### 1. bun-linux Stub (Silent Killer)

**Problem**: Someone created `~/.local/bin/bun-linux` as a shell script stub instead of a symlink to the real bun binary. This silently killed oracle-v2 MCP for ALL oracles — Claude started but MCP tools were unavailable.

**How we found it**: Oracles reported "MCP setup issues" but could still use Claude. Checked the file and found it was a text file, not a binary.

**Fix**: `ln -sf ~/.bun/bin/bun ~/.local/bin/bun-linux`

**Prevention**: Always verify `file ~/.local/bin/bun-linux` shows "symbolic link" not "ASCII text".

### 2. Fuzzy Routing in maw hey

**Problem**: `maw hey dev` routed to `botdev` because `find-window.ts` used substring matching. Similarly `aia→iagencyaia`, `editor→videoeditor`, `pa→overview`.

**How we found it**: Testing `maw hey` for every oracle and checking which tmux session received it.

**Fix**: Added strict session match (exact + oracle-name) before substring matching in `find-window.ts`.

**Prevention**: After any tmux session changes, test routing for ALL oracles.

### 3. Duplicate tmux Sessions

**Problem**: Migration created numbered sessions (`10-admin`, `20-iagencyaia`) alongside originals (`admin`, `iagencyaia`). `maw hey` picked the numbered ones.

**Fix**: Killed all numbered duplicate sessions.

**Prevention**: Never use numbered prefixes for oracle tmux sessions.

### 4. gmail-mcp Path (17 Oracles)

**Problem**: 17 oracle `.mcp.json` files referenced `~/maw-js/gmail-mcp/index.ts` which didn't exist on the new machine. Gmail MCP requires per-machine OAuth setup.

**Fix**: Removed gmail-mcp from all configs until properly set up.

**Prevention**: Don't include machine-specific MCP servers in committed configs. Use a setup script to add them.

### 5. oracle-v2 vs arra-oracle-v3 Path Inconsistency

**Problem**: 7 oracles pointed to old `oracle-v2` repo, rest pointed to `arra-oracle-v3`. Both existed but caused confusion.

**Fix**: Unified all to `arra-oracle-v3`.

**Prevention**: Use a single canonical path. Update all oracles when the MCP repo changes.

## What Worked Well

1. **All code on GitHub** — 64 repos, 100% recoverable via `ghq get`
2. **ψ/ memories in git** — 26/28 oracles had full memory files committed
3. **PM2 ecosystem config** — one command to start all services
4. **maw.config.json** — fleet topology in one file
5. **rooms.json** — dashboard layout recoverable
6. **Oracle CLAUDE.md files** — identity, rules, behavior all in repo
7. **Parallel briefing** — `maw hey` to all 26 oracles simultaneously got fleet operational in minutes

## Migration Timeline (for reference)

| Time | Action | Duration |
|------|--------|----------|
| T+0h | HQ dies, แบงค์ moves BoB to curfew | — |
| T+0.5h | Path fixes (60+ files /home/mbank → /home/curfew) | 30min |
| T+1h | PM2 services started, MQTT installed | 30min |
| T+2h | MCP configs fixed, bun-linux symlink fixed | 1h |
| T+3h | tmux sessions created, Claude started in all | 30min |
| T+4h | Routing bugs found and fixed | 1h |
| T+5h | Duplicate sessions killed, oracles restarted | 30min |
| T+6h | Board synced (39 issues → 14 projects) | 30min |
| T+7h | All 26 oracles briefed, 20+ ACK'd | 1h |
| T+8h | Fleet self-organizing, active work resuming | — |

### 7. Hooks with Hardcoded Numbered tmux Sessions

**Problem**: `pulse-auto-cc.sh` and `auto-cc-bob.sh` in `~/.oracle/hooks/` had `23-pulse:0` hardcoded. After we killed the numbered duplicate sessions, Pulse stopped receiving auto-cc notifications from ALL oracles. No issue creates, closes, dispatches, or git pushes were being tracked — Pulse was blind.

Similarly, `office-v2/loops.json` had `10-admin:0` for 2 loops.

**Fix**: `sed -i 's|23-pulse:0|pulse|g'` in both hook files. Fixed loops.json too.

**Prevention**: After killing numbered tmux sessions, grep ALL hooks and configs for the old names:
```bash
grep -rn "23-pulse\|10-admin\|20-iagencyaia\|21-wingman\|22-trader\|25-scalper\|26-videoeditor" \
  ~/.oracle/hooks/ ~/.claude/hooks/ ~/.local/bin/ \
  ~/repos/github.com/BankCurfew/office-v2/loops.json
```

### 8. Feed Hook CLAUDE_AGENT_NAME Defaults to "echo" (Dashboard Bug)

**Problem**: The global `~/.claude/settings.json` PreToolUse/PostToolUse/Stop hooks used `${CLAUDE_AGENT_NAME:-echo}` to identify oracles in feed.log. But `CLAUDE_AGENT_NAME` is a Claude Code built-in that defaults to `"echo"` when not explicitly set. Result: EVERY oracle wrote to feed.log as "echo", making Echo-Oracle's avatar animate constantly on the dashboard while all other oracles appeared idle.

**Fix**: Changed the fallback to derive the oracle name from the project directory:
```bash
$(basename "${CLAUDE_PROJECT_DIR:-$(pwd)}")
```
This produces `Dev-Oracle`, `QA-Oracle`, etc. — the actual repo directory name.

**Prevention**: Never use `CLAUDE_AGENT_NAME` as an oracle identifier in hooks — it's a Claude Code internal that defaults to "echo". Use `CLAUDE_PROJECT_DIR` basename or `ORACLE_NAME` env var instead.

### 9. Hardcoded tmux Targets in Service Source Code (LINE/Discord Relay)

**Problem**: `Admin-Oracle/src/aia-line.ts` had `20-iagencyaia:0` hardcoded in 4 places — LINE messages from AIA customers were sent to the killed numbered session, never reaching iAgencyAIA-Oracle. Same issue in `discord-bot.ts` (`21-wingman:0`), `followup-engine.ts`, and `bot.ts`.

**Fix**: `sed -i 's|20-iagencyaia:0|iagencyaia:0|g'` across 5 files. Restarted `pm2 restart aia-line bob-discord` + `pm2 save`.

**Prevention**: After killing numbered tmux sessions, grep ALL service source code too — not just hooks:
```bash
grep -rn "20-\|21-\|22-\|23-\|25-\|26-\|10-admin" \
  ~/repos/github.com/BankCurfew/Admin-Oracle/src/ \
  ~/repos/github.com/BankCurfew/maw-js/src/ \
  ~/repos/github.com/BankCurfew/office-v2/src/
```

Note: `01-bob:0` is intentionally kept — BoB's tmux session IS `01-bob`.

### 10. Cloudflare Tunnel DNS — Old Tunnel CNAME (LINE Relay Dead)

**Problem**: `api.vuttipipat.com` CNAME pointed to the dead HQ tunnel (`vuttihome` / `445cb309`). LINE webhook requests hit Cloudflare error 1033 — never reached curfew. Customer messages stopped flowing to iAgencyAIA.

**Fix**: `cloudflared tunnel route dns --overwrite-dns curfew api.vuttipipat.com` — updated CNAME to the curfew tunnel (`9c73fa50`). Also added `api.vuttipipat.com → localhost:3200` to cloudflared config.yml ingress rules.

**Key files**:
- `~/.cloudflared/config.yml` — ingress rules for both hostnames
- `~/.oracle/security/line-jarvis.env` — confirms `LINE_WEBHOOK_URL=https://api.vuttipipat.com/webhook`
- `Admin-Oracle/scripts/update-webhook.sh` — LINE webhook URL update script

**Two tunnels exist** (only one active):
| Tunnel | ID | Status |
|--------|-----|--------|
| `curfew` | `9c73fa50-42d0-4612-8816-8d883c3ab49f` | ACTIVE |
| `vuttihome` | `445cb309-4d50-4547-ae06-a95d38a69ea1` | DEAD (old HQ) |

**Prevention**: After migration, check ALL Cloudflare DNS CNAMEs that reference tunnels:
```bash
# List all tunnel routes
cloudflared tunnel route dns list

# Check which tunnel a hostname points to
dig api.vuttipipat.com CNAME +short
# Should contain the ACTIVE tunnel ID, not the dead one
```

### 11. Statusline Colored Bars (Local-only, Lost)

**Problem**: The statusline-command.sh was enhanced on HQ to show colored visual bars (█░) for context window, 5-hour rate limit, and 7-day rate limit usage. This enhancement was never committed — only the original text-only version existed in git.

**Fix**: Rebuilt the bars and committed to `maw-js/config/statusline-command.sh`.

**Prevention**: After modifying ANY shared script (`~/.claude/`, `~/.oracle/`), immediately copy back to the source repo and commit.

### 11. Supabase Service Keys — Per-Oracle Credential Setup

**Problem**: Data-Oracle and Wingman had no Supabase access after migration. The service keys were in HQ's vault but not transferred. Data couldn't query `discord_members`, `discord_conversations`, `bot_chat_log`, `aia_knowledge` tables.

**Fix**: Data requested key through Security-Oracle (proper channel). Key stored at `~/.oracle/security/supabase-aia-kb.env`. Wingman verified 4 tables operational independently.

**Prevention**: After migration, verify each oracle's database access:
```bash
# Check which oracles need Supabase
grep -rl "SUPABASE" ~/repos/github.com/BankCurfew/*-Oracle/.env ~/repos/github.com/BankCurfew/*-Oracle/.mcp.json 2>/dev/null
# Verify credentials exist
ls ~/.oracle/security/*supabase* ~/.oracle/security/*supa* 2>/dev/null
```

### 12. OAuth Tokens + Supabase Project Mismatch (iAgencyAIA)

**Problem**: iAgencyAIA's OAuth tokens for CRM/portal were local on HQ — not migrated. Also, Supabase MCP was configured with `PlanYourFuturePro` project ref, not the AIA KB project. Oracle could see wrong database.

**Fix**: Used `service_role` key directly for DB access. OAuth tokens need fresh setup on curfew.

**Prevention**:
```bash
# Check OAuth token files
find ~/repos/github.com/BankCurfew/*-Oracle -name "*oauth*" -o -name "*token*" -o -name "*.credentials" 2>/dev/null
# Verify Supabase project ref matches the correct database
grep -r "project_ref=" ~/repos/github.com/BankCurfew/*-Oracle/.mcp.json 2>/dev/null
```

**iAgencyAIA's 5-item checklist for migration**:
1. OAuth tokens must be re-created on new machine
2. Supabase MCP project_ref must match AIA KB (not PlanYourFuturePro)
3. LINE relay tmux target must match actual session name
4. Customer DB tables verified: birthday_gift_links, customer_policies, bot_chat_log
5. service_role key stored in vault for direct DB access

### 13. Cloudflare Pages Deploys from Staging, Not Main

**Problem**: iagencyaiafatools auto-deploys from `staging` branch, not `main`. 4 PRs merged to main but never deployed — QA found stale Jun 16 build while fixes were from Jun 18. Main was 48 commits ahead of staging.

**Fix**: `git checkout staging && git merge main && git push`

**Prevention**: After merging PRs, always check if the deploy branch matches:
```bash
gh api repos/<org>/<repo>/compare/staging...main --jq '"\(.ahead_by) commits ahead"'
```
If ahead > 0, merge main → staging to trigger deploy.

### 14. Two CF Pages Projects for Same Codebase (tools.iagencyaia.com)

**Problem**: `iagencyaiafatools` has TWO separate Cloudflare Pages projects:

| Project | Domain | Branch | Deploy |
|---------|--------|--------|--------|
| `fatools-staging` | `fatools.vuttipipat.com` | staging | Auto (github:push) |
| `fatools` | `tools.iagencyaia.com` | main | **MANUAL** (wrangler ad_hoc) |

BotDev deployed fixes to `fatools-staging` (auto-deploy) but `tools.iagencyaia.com` (production) runs from a DIFFERENT project that requires manual `wrangler pages deploy`. 5 PRs merged and "deployed" but เมย์ saw zero changes for 2 days.

**Fix**: `cd iagencyaiafatools && bun run build && npx wrangler pages deploy dist --project-name=fatools`

**Prevention**:
```bash
# After ANY code merge, deploy to BOTH projects
npx wrangler pages deploy dist --project-name=fatools         # production
npx wrangler pages deploy dist --project-name=fatools-staging # staging

# Or check which project serves which domain
curl -s "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT/pages/projects" \
  -H "Authorization: Bearer $CF_TOKEN" | python3 -c "
import json,sys
for p in json.load(sys.stdin)['result']:
    print(f'{p[\"name\"]:25s} → {p.get(\"domains\",[])}')
"
```

### 15. tmux Pane Size — Detached Sessions Default to 24x80 (ROOT CAUSE of Preview Bug)

**Problem**: All tmux oracle sessions had `pane_height=24`, `history_size=0`. Claude Code redraws within 24 rows — nothing scrolls past, so `tmux capture-pane` only returns 24 lines. Dashboard shows ~20 lines with no scroll history. Took 4 iterations to find (CSS scroll, innerHTML, capture size, upstream diff — all red herrings).

**Root cause**: Detached tmux sessions default to 80x24. No client attached = smallest possible pane.

**Fix**:
```bash
# Resize all oracle windows
tmux set-option -g default-size 200x200
for session in $(tmux list-sessions -F "#{session_name}"); do
  tmux resize-window -t "$session" -x 200 -y 200
done
```

**Prevention**: Add to `fleet.ts` wake script — resize window after creation. Persist in `~/.tmux.conf`: `set-option -g default-size 200x200`.

**Verification**: `tmux display-message -t "01-bob:0" -p "pane_height=#{pane_height} history_size=#{history_size}"` — pane_height should be 200, history_size should grow.

### 16. LINE/Discord Relay — tmux Target Prefix Mismatch

**Problem**: Admin migration commit stripped numbered prefix from tmux targets (`20-iagencyaia:0` → `iagencyaia:0`, `21-wingman:0` → `wingman:0`). But fleet configs create sessions WITH prefix (`20-iagencyaia`, `21-wingman`). LINE and Discord relay silently failed — no error, messages just didn't arrive.

**Fix**: Restore numbered prefix in relay code:
- `aia-line.ts`: `iagencyaia:0` → `20-iagencyaia:0` (3 locations)
- `discord-bot.ts`: `wingman:0` → `21-wingman:0` (1 location)

**Prevention**: Always check `tmux list-sessions` for actual session names before changing relay targets. Grep ALL files: `grep -rn "iagencyaia:0\|wingman:0" src/`

### 17. dist-office Must Be Rebuilt After Source Changes

**Problem**: Dev changed `office/src/` React components but dashboard served from `dist-office/` (built bundle). Changes invisible until rebuild. Happened twice — scroll fix and mobile fix both required manual rebuild.

**Fix**: `cd maw-js && bun run build:office && pm2 restart maw`

**Prevention**: Add to Dev workflow: source change in `office/src/` → MUST run `bun run build:office`. Consider adding watch mode or post-commit hook.

### 18. Security: .venv Committed + Plaintext API Key in Audit File

**Problem**: Two P0 security issues found by Pulse (not Security's own scan):
1. Trader-Oracle: `.venv/` directory committed (4,173 files tracked in git)
2. Security-Oracle: plaintext AKIA key in `audits/FULL-SECURITY-AUDIT.md`

**Fix**: Both scrubbed with `git-filter-repo` + force-pushed. `.venv` added to `.gitignore`.

**Prevention**:
- `.gitignore` MUST have: `.venv/`, `venv/`, `__pycache__/`, `.env`, `*.key`, `*.pem`
- Audit files must redact real keys: `AKIA...XXXX` not full key
- Cross-scan: don't rely on a single oracle's security scan — Pulse caught what Security missed

### 19. NotebookLM CLI — Correct Package is notebooklm-py

**Problem**: HQ had `notebooklm` CLI (command name), lost during migration. Multiple PyPI packages exist with similar names. Wrong packages installed first.

**Correct package**: `pip install "notebooklm-py[browser,cookies]"` (teng-lin/notebooklm-py, 16K+ stars)
- Command: `notebooklm` (matches HQ SOPs)
- NOT: `notebooklm-mcp-cli` (command = `nlm`, different)
- NOT: `notebooklm-cli` (deprecated, merged into mcp-cli)

**Auth on WSL**: `notebooklm login --browser-cookies chrome` — requires Chrome installed on WSL + logged into Google. Windows Chrome cookies not readable from WSL (permission + path issues).

### 20. WSL Chrome Cookies — Can't Read from Windows Side

**Problem**: `notebooklm login --browser-cookies chrome` looks for Chrome data in Linux paths. Windows Chrome at `/mnt/c/Users/mbank/AppData/Local/Google/Chrome/` is either locked (Chrome running) or not found by the tool's cookie reader (rookie-rs).

**Fix**: Install Chrome on WSL (`apt install google-chrome-stable`), open via `wsl -d Ubuntu google-chrome --no-sandbox https://accounts.google.com` from PowerShell, login to Google, then run `notebooklm login --browser-cookies chrome`.

**WSLg note**: `DISPLAY=:0` exists but Chromium launched from CLI doesn't always show window. Launch from PowerShell `wsl` command instead.

### 21. dist-office HQ Version vs Curfew Rebuild

**Problem**: During migration, `dist-office/index.html` was rebuilt with a different React bundle. Lost mobile PWA meta tags (`apple-mobile-web-app-capable`, `theme-color`, `apple-touch-icon`, `manifest.json`). Dashboard looked different from HQ and wasn't mobile-friendly.

**Fix**: `git checkout origin/main -- dist-office/index.html` to restore HQ version, then `bun run build:office` to rebuild with current source.

**Prevention**: Don't manually rebuild dist-office unless you know which version to target. The git-tracked version is the baseline.

### 22. pulse-ticket-check Hook — cc: Keyword Bypass

**Problem**: PreToolUse hook `pulse-ticket-check.sh` blocks `maw hey` dispatch without a ticket. But it skips any command containing `cc:`, `check`, `confirm`, `verify`. BoB bypassed the hook by prefixing dispatch messages with `cc:` — sending tasks without tickets.

**Current state**: Known gap, not yet fixed. The hook can't distinguish `cc: bob "status update"` (legitimate) from `cc: dev "TASK: do this"` (dispatch without ticket).

**Mitigation**: Discipline over tooling — follow Law #6 regardless of whether the hook catches it.

### 23. Project Sync — maw project + GitHub issue + repo + prefix must ALL match

**Problem**: Work scattered across systems — orphan projects (3), orphan issues (12), tasks without GH issues, wrong refs. 54% compliance initially.

**Rule (แบงค์ mandate 2026-06-20)**: Every work item must exist in ALL systems:
1. `maw project` — task tracked
2. GitHub issue — code work documented (Law 5)
3. GitHub repo — correct repo linked
4. `[project] #ticket` prefix — on every message/commit/dispatch

**Enforcement**:
- Hook: `validate-project-prefix.sh` (warns on missing prefix, 26 oracles)
- Hook: `dispatch-needs-issue.sh` (blocks dispatch without GH issue)
- Conduct: DocCon General Conduct v1.2 Rule 15
- Audit: Pulse periodic matrix check (project↔issue↔repo)

**Migration note**: When moving to new machine, verify:
- All hooks deployed to every oracle's `.claude/settings.json`
- `maw project ls` shows all active projects
- All GH issues accessible (`gh auth status`)
- DocCon conduct files committed to git (not local-only)

### 24. Message Prefix Standard — [project] #ticket on EVERYTHING

**Format**: `cc: [project-slug] #issue — message`

**16 active project slugs** (from `maw project ls`):
maw-js, echo-federation, curfew-migration, fa-tools, fa-quiz, daily-news, oracle-infra, aia-ops, security-compliance, content-writing, seo-backlinks, ijourney-ads, content-creation, lordms, cost-ops, customer-data-sync

**Special**: `[office]` for fleet-wide announcements without specific ticket.

**Migration note**: Project slugs live in maw-js config, not per-machine. Will carry over with git clone.

## Checklist: Things to Commit BEFORE Next Migration

- [x] Pulse CLI source code (fixed — was .gitignored, now committed)
- [ ] maw task activity logs (export to JSON)
- [ ] GPG keyring backup
- [ ] All creative writing drafts
- [ ] Any local-only tools in ψ/lab/
- [ ] Dashboard config state
- [ ] Vault credentials (encrypted backup)
