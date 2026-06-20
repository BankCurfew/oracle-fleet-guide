# Cost Optimization Notes

> Read this before starting work to avoid burning tokens on work that's already done.

## Core principles

1. **Check existing deliverables first.** Before writing new work, scan `ψ/writing/`, `ψ/active/`, OneDrive folders, or any project-specific output dir. If the deliverable already exists, continue from where you left off — do not redo it.

2. **Prefer cheaper approaches when equivalent.**
   - Use `Read` / `Grep` / `Glob` tools directly for simple lookups — avoid spawning `Agent` sub-tasks for a single file search.
   - Use `pw-cli.sh` instead of Playwright MCP for browser automation (4.6x cheaper — screenshots go to disk, only paths enter context).
   - Use RTK-rewritten commands (`git status` → `rtk git status` via PreToolUse hook) for 60-90% token savings on dev ops.

3. **Don't repeat searches across sessions.** If you already learned something in a previous session, it should live in memory (`~/.claude/projects/<project>/memory/`), a retrospective, or a handoff — read those first instead of re-exploring.

4. **Batch parallel work.** If you need 3 independent searches, run them in a single message with 3 tool calls — not 3 separate messages.

5. **Escalate-to-cheaper when possible.**
   - Reading a small file (<200 lines)? Use `Read` directly.
   - Grep for a known string? Use `Grep`, not `Agent`.
   - Broad open-ended exploration? Use `Agent` with `subagent_type=Explore` — it runs in a sub-context, protecting your main context window.

6. **Stop duplicating oracle work.** Before starting a task, check if another oracle has already done it by searching the inbox threads and recent commits. Takeover Protocol (Global Rule #6): `/recap` → read thread → `git log` → THEN work.

## Heartbeat cadence

Long-running tasks (>10min) MUST ping HB every 5min per Rule #9 so the dashboard can distinguish "stuck" from "done" — a silent agent is the most expensive failure mode.

## When you're about to burn tokens

If you feel yourself about to:
- Re-explore a codebase you've explored before
- Rewrite a deliverable you suspect exists
- Run a search that overlaps with a previous session's work

— STOP. Check memory, handoffs, `ψ/`, and recent commits first. Ten seconds of reading saves hundreds of tokens of re-work.
