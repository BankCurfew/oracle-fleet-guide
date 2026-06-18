# Lessons Learned — 2026-06-17 HQ→Curfew Migration

## What We Lost (Permanently)

| Item | Why Lost | Impact | Prevention |
|------|----------|--------|------------|
| **Pulse CLI source** | Never committed to git (lived in `ψ/lab/pulse-cli-clean/`) | `/pulse-board`, `/pulse-add`, `/pulse-scan` broken | **ALWAYS commit tools to git.** Never keep source code only in ψ/ |
| **Maw task activity logs** | Stored locally in maw-js data dir, not synced | All historical task progress lost | Export task logs to GitHub issues or cloud storage regularly |
| **GPG keyring** | Local-only at `~/.gnupg/` | Can't decrypt `vault.enc` | Backup GPG keys to secure cloud storage or second machine |
| **Writer's dark/ folder** | Local content not committed | Abyssal Eden creative writing lost | Commit all creative work to git, even drafts |
| **maw project task links** | Local-only (projects recreated empty) | 11 projects had zero tasks after migration | Sync task state to GitHub issues or Supabase |

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

## Checklist: Things to Commit BEFORE Next Migration

- [ ] Pulse CLI source code
- [ ] maw task activity logs (export to JSON)
- [ ] GPG keyring backup
- [ ] All creative writing drafts
- [ ] Any local-only tools in ψ/lab/
- [ ] Dashboard config state
- [ ] Vault credentials (encrypted backup)
