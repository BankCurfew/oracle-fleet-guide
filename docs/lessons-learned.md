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

### 9. Statusline Colored Bars (Local-only, Lost)

**Problem**: The statusline-command.sh was enhanced on HQ to show colored visual bars (█░) for context window, 5-hour rate limit, and 7-day rate limit usage. This enhancement was never committed — only the original text-only version existed in git.

**Fix**: Rebuilt the bars and committed to `maw-js/config/statusline-command.sh`.

**Prevention**: After modifying ANY shared script (`~/.claude/`, `~/.oracle/`), immediately copy back to the source repo and commit.

## Checklist: Things to Commit BEFORE Next Migration

- [ ] Pulse CLI source code
- [ ] maw task activity logs (export to JSON)
- [ ] GPG keyring backup
- [ ] All creative writing drafts
- [ ] Any local-only tools in ψ/lab/
- [ ] Dashboard config state
- [ ] Vault credentials (encrypted backup)
