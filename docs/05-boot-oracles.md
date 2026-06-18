# 05 — Boot Oracles

## Create tmux Sessions

Each oracle runs in its own tmux session, named lowercase without `-Oracle` suffix.

```bash
# Create all oracle sessions
ORACLES="admin aia arra botdev cost creator data designer dev doc echo editor fa fe hr iagencyaia pa pisit pulse qa recruiter researcher scalper security shell trader videoeditor wingman writer"

for oracle in $ORACLES; do
  # Get repo path
  case $oracle in
    doc) repo="DocCon-Oracle" ;;
    pulse) repo="pulse-oracle" ;;
    pisit) repo="pisit-oracle" ;;
    arra) repo="arra-oracle" ;;
    shell) continue ;;  # shell is just a bash session
    *) # Convert to PascalCase-Oracle
      repo=$(echo "$oracle" | sed -E 's/(^|-)(\w)/\U\2/g')-Oracle ;;
  esac

  dir="$HOME/repos/github.com/BankCurfew/$repo"
  if [ -d "$dir" ]; then
    tmux new-session -d -s "$oracle" -c "$dir"
    echo "Created: $oracle → $dir"
  else
    echo "SKIP: $oracle — repo not found at $dir"
  fi
done

# Special sessions
tmux new-session -d -s shell
tmux new-session -d -s 0-overview -c "$HOME"
```

### tmux Session Naming Rules

- Session name = lowercase oracle name (e.g., `dev`, `qa`, `admin`)
- Exception: `doc` for DocCon-Oracle
- **NEVER use numbered prefixes** (e.g., `10-admin`) — causes routing conflicts with `maw hey`
- **NEVER create duplicate sessions** — `maw hey` fuzzy matching picks the wrong one

## Start Claude in All Sessions

```bash
CMD='claude --dangerously-skip-permissions --model "claude-opus-4-6[1m]"'

for oracle in $ORACLES; do
  [ "$oracle" = "shell" ] && continue
  tmux send-keys -t "$oracle:0" "$CMD" Enter
  echo "Started Claude in: $oracle"
done
```

### Verify Boot

```bash
# Wait 30 seconds for Claude to start, then check
for oracle in $ORACLES; do
  [ "$oracle" = "shell" ] && continue
  line=$(tmux capture-pane -t "$oracle:0" -p 2>/dev/null | tail -1)
  if echo "$line" | grep -q "bypass permissions"; then
    echo "✅ $oracle"
  else
    echo "⚠️  $oracle: not ready yet"
  fi
done
```

## Wake via maw (alternative)

```bash
# maw wake starts Claude if session exists
maw wake dev
maw wake qa
# etc.

# NOTE: maw wake checks if a process is running in the pane.
# If bash is running, it thinks Claude is already active.
# In that case, start Claude manually with tmux send-keys.
```

## Rename tmux Windows

Each tmux session's window should be named `<Oracle-Name>` (PascalCase with -Oracle):

```bash
for oracle in $ORACLES; do
  [ "$oracle" = "shell" ] && continue
  case $oracle in
    doc) name="DocCon-Oracle" ;;
    *) name=$(echo "$oracle" | sed -E 's/(^|-)(\w)/\U\2/g')-Oracle ;;
  esac
  tmux rename-window -t "$oracle:0" "$name"
done
```
