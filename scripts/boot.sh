#!/bin/bash
# === Curfew WSL Auto-Boot Script ===
# Runs on every WSL start via /etc/wsl.conf [boot] command
# Updated: 2026-06-20 — wake full fleet, not just Echo
LOG=/tmp/oracle-boot.log
LOCK=/tmp/oracle-boot.lock

# Debounce — WSL can bounce rapidly
if [ -f "$LOCK" ]; then
  AGE=$(( $(date +%s) - $(stat -c %Y "$LOCK" 2>/dev/null || echo 0) ))
  if [ "$AGE" -lt 60 ]; then
    echo "$(date) | SKIPPED — debounce" >> "$LOG"
    exit 0
  fi
fi
touch "$LOCK"

echo "" >> "$LOG"
echo "$(date) | ========== Curfew boot starting ==========" >> "$LOG"

# 1. WireGuard route
GW=$(ip route | grep default | awk '{print $3}')
ip route add 10.10.0.0/24 via "$GW" 2>/dev/null
echo "$(date) | WireGuard route via $GW" >> "$LOG"

# 2-5 run as curfew in background (boot runs as root)
su - curfew -c 'bash -c '"'"'
export PATH=$HOME/.bun/bin:$HOME/.local/bin:$(ls -d $HOME/.nvm/versions/node/*/bin 2>/dev/null | tail -1):$PATH
LOG=/tmp/oracle-boot.log

# 2. Start PM2 (resurrect saved process list)
if pm2 pid maw >/dev/null 2>&1 && [ "$(pm2 pid maw)" != "" ]; then
  echo "$(date) | PM2 already running — skip" >> "$LOG"
else
  echo "$(date) | Starting PM2..." >> "$LOG"
  pm2 resurrect 2>/dev/null || pm2 start ~/repos/github.com/BankCurfew/maw-js/ecosystem.config.cjs
  pm2 save 2>/dev/null
  echo "$(date) | PM2 started + saved" >> "$LOG"
fi

# 2.5 Start Cloudflare tunnel
if pgrep -f cloudflared >/dev/null 2>&1; then
  echo "$(date) | Cloudflare tunnel already running — skip" >> "$LOG"
else
  echo "$(date) | Starting Cloudflare tunnel..." >> "$LOG"
  cloudflared tunnel run curfew >> "$LOG" 2>&1 &
  echo "$(date) | Cloudflare tunnel started" >> "$LOG"
fi

# 2.6 Start Ollama
if pgrep -f ollama >/dev/null 2>&1; then
  echo "$(date) | Ollama already running — skip" >> "$LOG"
else
  echo "$(date) | Starting Ollama..." >> "$LOG"
  ollama serve >> "$LOG" 2>&1 &
  echo "$(date) | Ollama started" >> "$LOG"
fi

# 2.7 Start ComfyUI (Windows-side, via cmd.exe interop)
if curl -s --max-time 3 http://localhost:8189/system_stats >/dev/null 2>&1; then
  echo "$(date) | ComfyUI already running — skip" >> "$LOG"
else
  echo "$(date) | Starting ComfyUI (Windows-side)..." >> "$LOG"
  cmd.exe /c "cd /d D:\\Stable Diffusion\\ComfyUI && start /min run_optimized_network.bat" >> "$LOG" 2>&1
  echo "$(date) | ComfyUI start triggered" >> "$LOG"
fi

# 2.8 Open ChatGPT + Gemini tabs (Designer MQTT extension needs these)
echo "$(date) | Opening ChatGPT + Gemini tabs..." >> "$LOG"
cmd.exe /c "start chrome https://chatgpt.com https://gemini.google.com" >> "$LOG" 2>&1
echo "$(date) | ChatGPT + Gemini tabs opened" >> "$LOG"

# 3. Wait for maw server — max 60s
echo "$(date) | Waiting for maw server..." >> "$LOG"
for i in $(seq 1 30); do
  curl -s --max-time 2 http://localhost:3456/ >/dev/null 2>&1 && break
  sleep 2
done
echo "$(date) | maw server ready" >> "$LOG"

# 4. Set tmux default size (prevent 24x80 pane bug — lesson #15)
tmux set-option -g default-size 200x200 2>/dev/null
echo "$(date) | tmux default-size set 200x200" >> "$LOG"

# 5. Wake FULL fleet (not just Echo)
RUNNING=$(tmux list-sessions 2>/dev/null | grep -c "^[0-9]")
if [ "$RUNNING" -ge 20 ]; then
  echo "$(date) | Fleet already running ($RUNNING sessions) — skip" >> "$LOG"
else
  echo "$(date) | Waking full fleet..." >> "$LOG"
  cd ~/repos/github.com/BankCurfew/maw-js
  bun src/cli.ts wake --all >> "$LOG" 2>&1
  echo "$(date) | Fleet woken" >> "$LOG"
fi

# 6. Resize all tmux windows (ensure 200x200 — lesson #15)
echo "$(date) | Resizing tmux windows..." >> "$LOG"
sleep 10
for session in $(tmux list-sessions -F "#{session_name}" 2>/dev/null); do
  tmux resize-window -t "$session" -x 200 -y 200 2>/dev/null
done
echo "$(date) | All windows resized to 200x200" >> "$LOG"

# 7. Send /recap --all to all oracle sessions (deep learn on boot)
echo "$(date) | Sending /recap --all to fleet..." >> "$LOG"
sleep 30  # wait for Claude sessions to bootstrap
for session in $(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -E "^[0-9]+-"); do
  # Only send to sessions that have Claude running (check for prompt)
  PANE_CMD=$(tmux display-message -t "$session:0.0" -p "#{pane_current_command}" 2>/dev/null)
  if echo "$PANE_CMD" | grep -qiE "claude|node|bun"; then
    tmux send-keys -t "$session:0.0" "/recap --all" Enter 2>/dev/null
    echo "$(date) | Sent /recap --all to $session" >> "$LOG"
    sleep 2  # stagger to avoid rate limits
  fi
done
echo "$(date) | Fleet recap complete" >> "$LOG"

echo "$(date) | ========== Curfew boot complete ==========" >> "$LOG"
'"'"'' &
