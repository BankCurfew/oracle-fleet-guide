# Hooks Reference — All 31 Oracle Hooks

**Version**: 1.0 | **Date**: 2026-06-20 | **Location**: `~/.oracle/hooks/`
**Total**: 31 hooks (8 blocking, 22 warning/auto, 1 disabled)

---

## Summary Table

| # | Hook | Type | Triggers On | Behavior | Scope | Rule |
|---|------|------|-------------|----------|-------|------|
| 1 | auto-cc-bob | Post | Bash, MCP | Auto-sends cc to BoB after inter-oracle comms | All | #1 |
| 2 | auto-cross-notify | Post | Bash, MCP | Auto-notifies other oracles when their work is referenced | All | — |
| 3 | auto-project-focus | UserPromptSubmit | Prompt | Auto-focuses oracle on the right project when dispatched a task | All | #2 |
| 4 | bob-monitor-needs-loop | Post | Bash | Warns when BoB says "monitoring" without a maw loop | BoB only | #9 |
| 5 | bob-must-cc-pulse | **Pre** | Bash | **BLOCKS** BoB dispatch unless Pulse cc'd first (30s TTL marker) | BoB only | #6.1 |
| 6 | bob-self-work-ticket | Pre | Bash | Warns when BoB does work without a ticket | BoB only | #12 |
| 7 | cc-bob-enforcer | Stop | Session end | Checks if oracle cc'd BoB during session, logs warning if not | All | #1 |
| 8 | cc-bob-on-thread | Post | MCP thread | Auto-cc BoB when oracle posts to any thread (except bob channel) | All | #1 |
| 9 | comm-compliance-log | Post | MCP thread | Logs every thread write to comm-compliance.jsonl for audit | All | #8 |
| 10 | context-guardian | Post | All | Monitors context usage, warns at high % | All | #10 |
| 11 | daily-upstream-check | Cron/loop | Bash | Compares maw-js fork vs upstream for updates | System | — |
| 12 | dispatch-needs-issue | **Pre** | Bash | **BLOCKS** task dispatch via maw hey unless GitHub issue exists | All | #12 |
| 13 | doc-change-check | Post | Bash | Warns when code commits happen and project doc is stale (>7d) | All | Doc Policy |
| 14 | enforce-maw-hey | Pre | All | Enforces structured maw hey format (WHAT + WHY required) | All | #8 |
| 15 | enforce-maw-loop | **Pre** | Bash | **BLOCKS** manual scheduling (CronCreate, while+sleep) — must use maw loop | All | #10 |
| 16 | feed-activity | Post | All | Writes oracle activity to feed.log for dashboard (lightweight) | All | — |
| 17 | force-rrr-at-80 | — | — | **DISABLED** — previously forced /rrr at 70%, now auto-compact handles it | — | — |
| 18 | gh-rate-guard | Pre | Bash | Guards against GitHub API rate limit exhaustion | All | — |
| 19 | maw-hey-gate | **Pre** | MCP thread | **BLOCKS** thread writes unless caller is BoB or Pulse | Non-BoB | — |
| 20 | on-subagent-stop | Notification | SubagentStop | Logs subagent completion to feed.log | All | — |
| 21 | on-task-complete | Notification | TaskCompleted | Logs task completion to feed.log | All | — |
| 22 | peek-cc-bob | Post | Bash | Reminds HR to /talk-to bob with peek summary | HR only | — |
| 23 | playwright-limiter | **Pre** | Bash | **BLOCKS** Playwright if 2 sessions already active | All | #5 |
| 24 | playwright-release | Post | Bash | Releases Playwright session lock after tool completes | All | #5 |
| 25 | pre-close-psi-check | Stop | Session end | Warns if untracked/uncommitted ψ/ files before session ends | All | — |
| 26 | pulse-auto-cc | Post | Bash, MCP | Auto-forwards task events to Pulse Oracle | All | #6 |
| 27 | pulse-ticket-check | **Pre** | Bash | **BLOCKS** task dispatch without a pulse ticket | All | #6.1 |
| 28 | safety-guardian | **Pre** | Bash | **BLOCKS** dangerous commands (rm -rf, force push, drop table) | All | Safety |
| 29 | subagent-comm-block | **Pre** | Agent | **BLOCKS** subagents being used as messengers to other oracles | All (BoB exempt) | LAW #1 |
| 30 | talk-to-enforcer | Post | Bash | Reminds oracle to cc BoB after inter-oracle communication | All | #1 |
| 31 | validate-project-prefix | **Pre** | Bash | **BLOCKS** maw hey without [project] #ticket prefix | All | #12 |

---

## Detailed Reference

### 1. auto-cc-bob.sh
- **Type**: PostToolUse (Bash + MCP thread tools)
- **What**: Automatically sends `maw hey bob "cc: ..."` after any inter-oracle communication. No manual cc needed — the hook does it.
- **Scope**: All oracles (skips if caller is BoB or target is BoB)
- **Behavior**: Auto-action (sends maw hey), 15s debounce
- **Rule**: Golden Rule #1 (CC BOB)

### 2. auto-cross-notify.sh
- **Type**: PostToolUse (Bash + MCP thread tools)
- **What**: When oracle A's action references oracle B (e.g., mentioning their name or project), auto-notifies oracle B via maw hey.
- **Scope**: All oracles
- **Behavior**: Auto-action (cross-notification)
- **Known oracles**: dev, qa, researcher, writer, designer, hr, aia, data, admin, botdev, creator, doc, doccon, editor, security, fe, pa, fa, cost, fasai, iagencyaia, wingman, recruiter, trader, scalper, videoeditor

### 3. auto-project-focus.sh
- **Type**: UserPromptSubmit
- **What**: When oracle receives a dispatched task with issue reference (e.g., "TASK: maw-js#44"), auto-focuses the oracle on the right project directory.
- **Scope**: All oracles
- **Behavior**: Auto-action (sets project context)

### 4. bob-monitor-needs-loop.sh
- **Type**: PostToolUse (Bash)
- **What**: Warns when BoB says "monitoring", "awaiting", or "รอ" but hasn't set a `maw loop`. If you say you're monitoring, prove it with a loop.
- **Scope**: BoB only
- **Behavior**: Warning message
- **Rule**: LAW #9 (Loop Follow-Up)

### 5. bob-must-cc-pulse.sh
- **Type**: PreToolUse (Bash) — **BLOCKING**
- **What**: BLOCKS BoB's task dispatches (maw hey to oracles) unless Pulse was cc'd first. Uses a marker file with 30s TTL — cc Pulse once, dispatch freely for 30s.
- **Scope**: BoB only
- **Behavior**: BLOCK (exit 2) until Pulse cc'd
- **Rule**: LAW #6.1 (Dispatch Checklist)
- **Bypass**: Messages to bob/pulse, short pings (<10 chars), cc: status reports

### 6. bob-self-work-ticket.sh
- **Type**: PreToolUse (Bash)
- **What**: Warns when BoB does significant work (git commit, file writes) without first establishing a GitHub issue ticket.
- **Scope**: BoB only
- **Behavior**: Warning message
- **Rule**: LAW #12 (Board-Driven Work)

### 7. cc-bob-enforcer.sh
- **Type**: Stop hook (session end)
- **What**: When an oracle session stops, checks if they cc'd BoB during the session. If not, logs a warning and auto-reports to BoB via maw server.
- **Scope**: All oracles
- **Behavior**: Warning + auto-report
- **Rule**: Golden Rule #1 (CC BOB)

### 8. cc-bob-on-thread.sh
- **Type**: PostToolUse (MCP thread tools)
- **What**: Auto-cc BoB when any oracle posts to any thread (except BoB's own channel). Catches /talk-to which bypasses Bash-only hooks.
- **Scope**: All oracles
- **Behavior**: Auto-action
- **Rule**: Golden Rule #1 (CC BOB)

### 9. comm-compliance-log.sh
- **Type**: PostToolUse (MCP thread tools)
- **What**: Logs every MCP thread write to `~/.oracle/comm-compliance.jsonl`. Cross-references with maw hey usage for compliance auditing.
- **Scope**: All oracles
- **Behavior**: Silent logging
- **Rule**: Golden Rule #8 (Report Contract)

### 10. context-guardian.sh
- **Type**: PostToolUse (all tools)
- **What**: Monitors context window usage. Warns when context is high.
- **Scope**: All oracles
- **Behavior**: Warning message
- **Rule**: Golden Rule #10 (Read Status Bar)

### 11. daily-upstream-check.sh
- **Type**: Cron/loop triggered
- **What**: Compares BankCurfew/maw-js fork against upstream Soul-Brews-Studio/maw-js for new updates.
- **Scope**: System (run by maw loop)
- **Behavior**: Silent check

### 12. dispatch-needs-issue.sh
- **Type**: PreToolUse (Bash) — **BLOCKING**
- **What**: BLOCKS task dispatch via maw hey or /talk-to unless a GitHub issue exists first. Parses message content — `cc:` prefix alone does NOT bypass if content looks like a task assignment.
- **Scope**: All oracles
- **Behavior**: BLOCK (exit 2)
- **Rule**: LAW #12 (Board-Driven Work)

### 13. doc-change-check.sh
- **Type**: PostToolUse (Bash)
- **What**: When oracle commits code, closes an issue, or marks a task done, checks if the project documentation is stale (>7 days). Warns to update docs.
- **Scope**: All oracles
- **Behavior**: Warning message (missing doc, stale doc, or gentle reminder)
- **Rule**: Doc Enforcement Policy

### 14. enforce-maw-hey.sh
- **Type**: PreToolUse (all tools)
- **What**: Enforces structured maw hey communication. Every maw hey MUST contain WHAT + WHY at minimum.
- **Scope**: All oracles
- **Behavior**: Warning message
- **Rule**: Golden Rule #8 (Report Contract)

### 15. enforce-maw-loop.sh
- **Type**: PreToolUse (Bash) — **BLOCKING**
- **What**: BLOCKS manual scheduling and polling patterns (CronCreate, while+sleep loops, /schedule). Must use `maw loop add` instead for persistence.
- **Scope**: All oracles
- **Behavior**: BLOCK (exit 2)
- **Rule**: LAW #10 (Use maw loop, not CronCreate)

### 16. feed-activity.sh
- **Type**: PostToolUse (all tools)
- **What**: Writes oracle activity to `~/.oracle/feed.log` on every tool use. Dashboard uses this to show oracle as active (green/yellow/red).
- **Scope**: All oracles
- **Behavior**: Silent logging (lightweight — name + tool only)

### 17. force-rrr-at-80.sh
- **Type**: **DISABLED**
- **What**: Previously forced /rrr → /forward → /exit at 70% context. Now disabled — auto-compact handles context naturally. Oracles keep working uninterrupted.
- **Scope**: N/A
- **Behavior**: No-op

### 18. gh-rate-guard.sh
- **Type**: PreToolUse (Bash) / sourceable utility
- **What**: Guards against GitHub API rate limit exhaustion. Can be sourced before gh commands for a `gh_guard` wrapper, or used as a hook.
- **Scope**: All oracles
- **Behavior**: Warning or block depending on remaining rate

### 19. maw-hey-gate.sh
- **Type**: PreToolUse (MCP thread tools) — **BLOCKING**
- **What**: BLOCKS write operations to Oracle threads unless the caller is BoB or Pulse. Read operations (no message field) always allowed.
- **Scope**: Non-BoB oracles
- **Behavior**: BLOCK (exit 2) for unauthorized thread writes

### 20. on-subagent-stop.sh
- **Type**: Notification (SubagentStop)
- **What**: Logs background agent completion to feed.log. Prevents fire-and-forget — oracle sees completion notification.
- **Scope**: All oracles
- **Behavior**: Silent logging

### 21. on-task-complete.sh
- **Type**: Notification (TaskCompleted)
- **What**: Logs background task completion to feed.log. Same as on-subagent-stop but for TaskCreate-based tasks.
- **Scope**: All oracles
- **Behavior**: Silent logging

### 22. peek-cc-bob.sh
- **Type**: PostToolUse (Bash)
- **What**: After HR runs `maw peek`, reminds them to /talk-to bob with a summary of what they found (who's doing what, who's idle, who's stuck).
- **Scope**: HR only
- **Behavior**: Warning message

### 23. playwright-limiter.sh
- **Type**: PreToolUse (Bash) — **BLOCKING**
- **What**: Limits Playwright browser sessions to max 2 concurrent across all oracles. If 2 sessions are active, BLOCKS the third and tells oracle to wait.
- **Scope**: All oracles
- **Behavior**: BLOCK (exit 2)
- **Rule**: Golden Rule #5 (Browser Automation)

### 24. playwright-release.sh
- **Type**: PostToolUse (Bash)
- **What**: Releases Playwright session lock file after the tool completes. Companion to playwright-limiter.sh.
- **Scope**: All oracles
- **Behavior**: Auto-action (cleanup)

### 25. pre-close-psi-check.sh
- **Type**: Stop hook (session end)
- **What**: Warns oracle if there are untracked or uncommitted ψ/ (brain) files before session ends. Prevents losing work.
- **Scope**: All oracles
- **Behavior**: Warning message

### 26. pulse-auto-cc.sh
- **Type**: PostToolUse (Bash + MCP thread tools)
- **What**: Auto-forwards task events to Pulse Oracle via actual maw hey. Detects: maw hey dispatches, maw task state changes, gh issue create/close, git commits.
- **Scope**: All oracles
- **Behavior**: Auto-action (forwards to Pulse)
- **Rule**: LAW #6 (Pulse Task Tracking)

### 27. pulse-ticket-check.sh
- **Type**: PreToolUse (Bash) — **BLOCKING**
- **What**: BLOCKS task dispatch via maw hey or /talk-to without a pulse ticket existing first. Forces oracles to create tickets before dispatching.
- **Scope**: All oracles
- **Behavior**: BLOCK (exit 2)
- **Rule**: LAW #6.1 (Dispatch Checklist)
- **Bypass**: Pings, status checks, cc: messages, follow-ups

### 28. safety-guardian.sh
- **Type**: PreToolUse (Bash) — **BLOCKING**
- **What**: BLOCKS dangerous commands: `rm -rf`, `git push --force`, `DROP TABLE`, `pkill`, destructive operations. Suggests safe alternatives.
- **Scope**: All oracles
- **Behavior**: BLOCK (exit 2)
- **Rule**: Git Safety (CLAUDE_safety.md)

### 29. subagent-comm-block.sh
- **Type**: PreToolUse (Agent tool) — **BLOCKING**
- **What**: BLOCKS subagents being used as messengers to other oracles. Detects oracle names + action verbs in agent prompts. Forces use of /talk-to or maw hey instead.
- **Scope**: All oracles (BoB exempt — orchestrator role)
- **Behavior**: BLOCK (exit 2)
- **Rule**: LAW #1 (/talk-to is primary, not subagents)

### 30. talk-to-enforcer.sh
- **Type**: PostToolUse (Bash)
- **What**: After any inter-oracle communication via Bash (maw hey), reminds oracle to cc BoB. Fires a warning hint.
- **Scope**: All oracles
- **Behavior**: Warning hint
- **Rule**: Golden Rule #1 (CC BOB)

### 31. validate-project-prefix.sh
- **Type**: PreToolUse (Bash) — **BLOCKING**
- **What**: BLOCKS maw hey messages without `[project] #ticket` prefix. Validates project slug against `maw project ls`. Allows known oracle names and aliases (office, proxy, poster, browser) as exceptions.
- **Scope**: All oracles
- **Behavior**: BLOCK (exit 2)
- **Rule**: Golden Rule #12 (Message Prefix Standard)

---

## Hook Categories

### Blocking Hooks (8) — exit 2, prevent action
- bob-must-cc-pulse, dispatch-needs-issue, enforce-maw-loop, maw-hey-gate, playwright-limiter, pulse-ticket-check, safety-guardian, subagent-comm-block, validate-project-prefix

### Auto-Action Hooks (7) — do something automatically
- auto-cc-bob, auto-cross-notify, auto-project-focus, cc-bob-on-thread, playwright-release, pulse-auto-cc

### Warning Hooks (9) — remind/nudge, don't block
- bob-monitor-needs-loop, bob-self-work-ticket, context-guardian, doc-change-check, enforce-maw-hey, peek-cc-bob, talk-to-enforcer

### Logging Hooks (5) — silent tracking
- comm-compliance-log, feed-activity, on-subagent-stop, on-task-complete

### Session Lifecycle (2) — fire on session start/stop
- cc-bob-enforcer (stop), pre-close-psi-check (stop)

### Utility (1) — helper functions
- gh-rate-guard (sourceable)

### Disabled (1)
- force-rrr-at-80 (replaced by auto-compact)

---

## Installation

All hooks are installed in `~/.oracle/hooks/` and registered in each oracle's `.claude/settings.json` under the `hooks` key. Fleet-wide hooks are stored in `oracle-fleet-guide/hooks/` for migration.

To install a new hook on all oracles:
1. Write the hook script to `~/.oracle/hooks/<name>.sh`
2. `chmod +x ~/.oracle/hooks/<name>.sh`
3. Copy to `oracle-fleet-guide/hooks/` and push
4. Add to each oracle's settings.json (or use fleet-wide settings)

---

*Last updated: 2026-06-20 by BoB-Oracle*
