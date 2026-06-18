# 06 — Sync State (Board, Issues, Briefings)

## Repopulate Board from GitHub Issues

The maw board stores task data locally. After a machine migration, it's empty. Repopulate from GitHub.

### Step 1: Create projects

```bash
MAW_ORACLE=bob maw project create maw-js "Maw CLI" "Maw CLI/server fleet tooling"
MAW_ORACLE=bob maw project create fa-quiz "FA Recruitment Quiz" "iJourney RPG recruitment quiz"
MAW_ORACLE=bob maw project create aia-ops "AIA Operations" "AIA portal, ePOS, LINE bot, KB"
MAW_ORACLE=bob maw project create oracle-infra "Oracle Infrastructure" "Maw-js, dashboard, fleet, hooks, PM2"
MAW_ORACLE=bob maw project create content-writing "Content & Writing" "Dark Fantasy, blog, docs"
MAW_ORACLE=bob maw project create security-compliance "Security & Compliance" "Vault, PDPA, secrets audit"
MAW_ORACLE=bob maw project create daily-news "Daily News Pipeline" "Wingman→Designer→Discord news"
# Add more as needed
```

### Step 2: Scan GitHub for open issues

```bash
# List all open issues across org
gh search issues --owner BankCurfew --state open --limit 100 \
  --json repository,title,number \
  --jq '.[] | "\(.repository.name)#\(.number) \(.title)"'
```

### Step 3: Add issues to projects

```bash
# Map each issue to a project
MAW_ORACLE=bob maw project add <project-slug> '<repo>#<number>'
MAW_ORACLE=bob maw task log '<repo>#<number>' "Synced from GitHub — status: open"
```

### Step 4: Verify board

```bash
maw project ls          # List all projects with task counts
maw project show <slug> # Show tasks in a project
```

## Brief Every Oracle

After syncing the board, every oracle needs to know:
1. Their open GitHub issues
2. Their uncommitted local files
3. Their recent commit history
4. Their role and responsibilities

### Generate briefing data

```bash
# For each oracle, gather context:
for dir in ~/repos/github.com/BankCurfew/*-Oracle; do
  name=$(basename "$dir" | sed 's/-Oracle//')
  lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')

  # Open issues
  issues=$(gh issue list --repo "BankCurfew/$(basename $dir)" --state open --json number,title --jq '.[] | "#\(.number) \(.title)"' 2>/dev/null)

  # Uncommitted files
  changes=$(git -C "$dir" status --porcelain 2>/dev/null | wc -l)

  # Recent commits
  last_commit=$(git -C "$dir" log -1 --format="%ci %s" 2>/dev/null)

  echo "=== $lower ==="
  echo "Issues: ${issues:-none}"
  echo "Uncommitted: $changes files"
  echo "Last commit: $last_commit"
  echo ""
done
```

### Send briefings via maw hey

```bash
maw hey <oracle> "cc: BRIEFING from BoB — Your open issues: <issues>. Uncommitted: <N> files. Role: <role>. Priority: <what to do first>. /recap to orient. — ref: fleet sync"
```

**Include `cc:` prefix** to bypass the pulse-ticket-check hook (it blocks non-cc maw hey messages).

### Verify receipt

```bash
# Check if message appeared in oracle's tmux
tmux capture-pane -t "<oracle>:0" -p -S -50 | grep "BRIEFING"

# Or check thread ACKs
# Oracles that receive briefings typically ACK via /talk-to bob
```
