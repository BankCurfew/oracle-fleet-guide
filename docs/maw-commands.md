# Maw CLI — Complete Command Reference

> `maw` — Multi-Agent Workflow CLI. The nervous system of the Oracle fleet.

## Quick Reference

```
maw --version              # Show version
maw --help                 # Show all commands
maw serve [port]           # Start web UI (default: 3456)
```

---

## 1. Communication

The most-used commands. How oracles talk to each other.

| Command | Description |
|---------|-------------|
| `maw hey <agent> <msg>` | Send message to agent's tmux pane (alias: `tell`, `send`) |
| `maw hey <agent> <msg> --force` | Send even if agent has no active Claude session |
| `maw talk-to <agent> <msg>` | Thread + hey — persistent thread AND real-time delivery |
| `maw peek [agent]` | Peek at agent's screen (or all agents if no name) |
| `maw <agent>` | Shorthand for `maw peek <agent>` |
| `maw <agent> <msg>` | Shorthand for `maw hey <agent> <msg>` |
| `maw meeting "goal"` | Hold a meeting — wakes relevant agents, collects input |
| `maw meeting "goal" --oracles dev,qa` | Limit meeting participants |
| `maw meeting "goal" --dry-run` | Show participants without waking |
| `maw broadcast "msg"` | Send message to all oracles |

**Migration-critical**: `hey`, `peek`, `talk-to` — test these first after migration.

### Examples

```bash
maw hey dev "Fix the login bug in auth.ts"
maw peek designer                    # See what Designer is doing
maw dev                              # Shorthand for peek dev
maw dev "what's your status"         # Shorthand for hey dev
maw meeting "Plan the landing page" --oracles dev,designer,writer
```

---

## 2. Fleet Management

Starting, stopping, and monitoring the oracle fleet.

| Command | Description |
|---------|-------------|
| `maw wake <oracle>` | Wake oracle — start Claude in tmux |
| `maw wake <oracle> <task>` | Wake with an initial task prompt |
| `maw wake <oracle> --issue N` | Wake with GitHub issue as prompt |
| `maw wake <oracle> --new <name>` | Create worktree + wake |
| `maw wake all` | Wake fleet (skips dormant 20+) |
| `maw wake all --all` | Wake ALL including dormant |
| `maw wake all --resume` | Wake + send /recap for active board items |
| `maw wake all --recap-all` | Wake + /recap to ALL oracles |
| `maw sleep <oracle>` | Gracefully stop one oracle |
| `maw stop` | Stop ALL fleet sessions |
| `maw done <window>` | Clean up finished worktree window |
| `maw oracle ls` | Fleet status (awake/sleeping/worktrees) |
| `maw overview` | War-room: all oracles in split panes |
| `maw overview dev,designer` | Specific oracles only |
| `maw overview --kill` | Tear down overview |
| `maw about <oracle>` | Oracle profile — session, worktrees, fleet config |
| `maw ls` | List all tmux sessions + windows |

**Migration-critical**: `wake`, `wake all`, `oracle ls`, `ls` — needed to bring fleet online.

### Fleet Init & Config

| Command | Description |
|---------|-------------|
| `maw fleet init` | Scan ghq repos, generate fleet/*.json configs |
| `maw fleet ls` | List fleet configs with conflict detection |
| `maw fleet renumber` | Fix numbering conflicts (sequential) |
| `maw fleet validate` | Check for problems (dupes, orphans, missing repos) |
| `maw fleet sync` | Add unregistered windows to fleet configs |

### Budding (Oracle Reproduction)

| Command | Description |
|---------|-------------|
| `maw bud <name> --approved-by <human>` | Spawn new child oracle |
| `maw bud <name> --from <oracle>` | Spawn from specific parent |
| `maw bud <name> --dry-run` | Preview plan without executing |

---

## 3. Project Management

Tracking work across oracles and repos.

### Projects

| Command | Description |
|---------|-------------|
| `maw project ls` | List all projects with task counts |
| `maw project show <id>` | Project tree view with tasks |
| `maw project create <id> "name" "desc"` | Create a project (BoB only) |
| `maw project add <id> #<issue>` | Add task/issue to project |
| `maw project add <id> #<issue> --parent #<p>` | Add as subtask |
| `maw project remove <id> #<issue>` | Remove task from project |
| `maw project auto-organize` | Auto-group unassigned tasks |
| `maw project comment <id> "msg"` | Comment on project (cross-oracle visible) |
| `maw project complete <id>` | Mark project completed |
| `maw project archive <id>` | Archive project |
| `maw project focus <id> --oracle <name>` | Set oracle's active project focus |
| `maw project repos <id>` | List repos linked to project |
| `maw project sync <id>` | Sync project state with GitHub |
| `maw project scaffold <id>` | Auto-scaffold GitHub repo structure |

### Tasks

| Command | Description |
|---------|-------------|
| `maw task ls` | Board + activity counts |
| `maw task show #<issue>` | Full activity timeline for a task |
| `maw task log #<issue> "msg"` | Log activity on a task |
| `maw task log #<issue> --commit "hash msg"` | Log a commit |
| `maw task log #<issue> --blocker "desc"` | Log a blocker |
| `maw task comment #<issue> "msg"` | Comment (cross-oracle visible) |
| `maw task own #<issue>` | Assign task to yourself |

### Pulse (Board)

| Command | Description |
|---------|-------------|
| `maw pulse ls` | Board table in terminal |
| `maw pulse ls --sync` | Board + update daily thread checkboxes |
| `maw pulse add "title" --oracle <name>` | Create issue + wake oracle |
| `maw pulse add "title" --oracle <name> --wt <repo>` | + worktree |
| `maw pulse scan` | Anti-pattern health check (Zombie/Island) |
| `maw pulse scan --json` | JSON output for dashboard |
| `maw pulse cleanup [--dry-run]` | Clean stale/orphan worktrees |
| `maw board done #<issue> "msg"` | Mark board item Done + close issue |

**Migration-critical**: `project ls`, `project create`, `project add`, `task ls` — needed to repopulate board.

---

## 4. Monitoring & Diagnostics

| Command | Description |
|---------|-------------|
| `maw syslog` | Last 20 system events from feed.log |
| `maw syslog --since "1h ago"` | Filter by time |
| `maw syslog --type restart` | Filter by event type |
| `maw syslog --service maw` | Filter by service |
| `maw syslog --json` | JSON output |
| `maw tokens` | Token usage stats (from Claude sessions) |
| `maw tokens --rebuild` | Rebuild token index |
| `maw tokens --json` | JSON for API |
| `maw health` | System health check |
| `maw ping [node]` | Ping federation peer |
| `maw log` | Message log |
| `maw log chat [oracle]` | Chat view — conversation bubbles |
| `maw chat [oracle]` | Shorthand for log chat |
| `maw log export --date YYYY-MM-DD` | Export logs |
| `maw audit` | Fleet audit — compliance, conduct, issues |
| `maw costs` | Token cost breakdown per agent |
| `maw avengers status` | Rate limit monitor (ARRA-01 accounts) |
| `maw avengers best` | Account with most capacity |
| `maw avengers health` | Quick connectivity check |

**Migration-critical**: `syslog`, `health` — verify services after migration.

---

## 5. Loops (Scheduled Tasks)

| Command | Description |
|---------|-------------|
| `maw loop` | Show loop status (all scheduled tasks) |
| `maw loop history [id]` | Loop execution history |
| `maw loop trigger <id>` | Manually fire a loop |
| `maw loop add '{json}'` | Add/update a loop definition |
| `maw loop remove <id>` | Remove a loop |
| `maw loop enable <id>` | Enable a loop |
| `maw loop disable <id>` | Disable a loop |
| `maw loop on` | Enable loop engine |
| `maw loop off` | Disable loop engine |

### Loop JSON Format

```json
{
  "id": "my-check",
  "oracle": "dev",
  "tmux": "dev:0",
  "schedule": "0 9 * * *",
  "prompt": "Run daily check",
  "requireIdle": true,
  "enabled": true,
  "description": "Daily dev check"
}
```

**Migration-critical**: `loop` — check which loops exist and if they fire correctly.

---

## 6. Setup & Configuration

| Command | Description |
|---------|-------------|
| `maw setup hooks [path]` | Generate .claude/settings.json with hooks |
| `maw setup hooks --oracle <name>` | For specific oracle |
| `maw setup hooks --force` | Overwrite existing |
| `maw setup hooks --dry-run` | Preview without writing |
| `maw setup tmux` | Install scroll-fix block into ~/.tmux.conf |
| `maw setup tmux --dry-run` | Preview |
| `maw auth setup <user> <pass>` | Enable web UI auth |
| `maw auth disable` | Disable auth |
| `maw completions [shell]` | Generate shell completions |

**Migration-critical**: `setup hooks`, `setup tmux` — needed on new machines.

---

## 7. Sovereign (ψ/ Management)

| Command | Description |
|---------|-------------|
| `maw sovereign status` | Show ψ/ migration status for all oracles |
| `maw sovereign migrate <oracle>` | Move ψ/ to ~/.oracle/ψ/{name}/ with symlinks |
| `maw sovereign migrate --all` | Migrate all oracles |
| `maw sovereign rollback <oracle>` | Restore original layout |
| `maw sovereign verify` | Health check all symlinks |

---

## 8. Advanced / Special

| Command | Description |
|---------|-------------|
| `maw think` | Oracles scan work + propose ideas (GitHub issues) |
| `maw think --oracles hr,dev` | Limit which oracles think |
| `maw review` | BoB reviews proposals → sends to inbox |
| `maw corrections add <oracle> 'wrong' 'correct' ['reason']` | Add correction |
| `maw corrections list [oracle]` | List corrections |
| `maw corrections search <oracle> 'query'` | Search corrections |
| `maw soul-sync` | Sync ψ/ learnings between oracles |
| `maw fleet doctor` | Federation config health check |
| `maw fleet consolidate` | Consolidate fleet configs |
| `maw find <query>` | Find oracles/repos/files across fleet |
| `maw park <oracle>` | Park an oracle (save state for later) |
| `maw take <oracle>` | Take over parked oracle's work |
| `maw workon <oracle>` | Switch to oracle's worktree |
| `maw reunion` | Reunite split oracle worktrees |
| `maw rename <old> <new>` | Rename tmux session |
| `maw assign <oracle> --issue N` | Assign issue to oracle + wake |
| `maw pr <oracle>` | Show oracle's open PRs |
| `maw inbox` | Show BoB's pending inbox items |
| `maw contacts` | Manage contact directory |
| `maw archive <oracle>` | Archive dormant oracle |
| `maw mega` | Mega view — full fleet dashboard |
| `maw tab` | List tabs in current session |
| `maw tab N` | Peek tab N |
| `maw tab N <msg>` | Send message to tab N |
| `maw triggers` | Show trigger definitions and history |
| `maw transport` | Transport layer status |
| `maw workspace` | Workspace management |

---

## Federation (Multi-Node)

| Command | Description |
|---------|-------------|
| `maw ping <node>` | Ping a peer node |
| `maw hey node:agent "msg"` | Send message to remote agent |
| `maw fleet doctor` | Check federation config health |
| `maw soul-sync` | Sync ψ/ across nodes |
| `maw federation sync` | Full federation state sync |

---

## Migration Checklist — Essential Commands

After setting up a new machine, run these in order:

```bash
# 1. Verify maw works
maw --version
maw ls

# 2. Check fleet
maw oracle ls
maw fleet validate

# 3. Wake everyone
maw wake all --all

# 4. Test communication
maw hey dev "ping"
maw peek

# 5. Check projects
maw project ls
maw task ls

# 6. Check loops
maw loop

# 7. Check services
maw health
maw syslog

# 8. Setup hooks (if new machine)
maw setup hooks
maw setup tmux
```
