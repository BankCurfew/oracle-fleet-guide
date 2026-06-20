#!/bin/bash
# === Unit Test: Curfew Boot Script ===
# Tests that all boot components are correctly configured
# Run: bash ~/test-boot.sh

PASS=0
FAIL=0
WARN=0

check() {
  if eval "$2" >/dev/null 2>&1; then
    echo "  ✅ $1"
    ((PASS++))
  else
    echo "  ❌ $1"
    ((FAIL++))
  fi
}

warn() {
  if eval "$2" >/dev/null 2>&1; then
    echo "  ✅ $1"
    ((PASS++))
  else
    echo "  ⚠️  $1 (optional)"
    ((WARN++))
  fi
}

echo ""
echo "=== Curfew Boot Unit Test ==="
echo ""

echo "--- 1. WSL Config ---"
check "/etc/wsl.conf exists" "[ -f /etc/wsl.conf ]"
check "[boot] command set" "grep -q 'command=/home/curfew/boot.sh' /etc/wsl.conf"
check "systemd=true" "grep -q 'systemd=true' /etc/wsl.conf"
check "default user=curfew" "grep -q 'default=curfew' /etc/wsl.conf"

echo ""
echo "--- 2. Boot Script ---"
check "boot.sh exists" "[ -f /home/curfew/boot.sh ]"
check "boot.sh executable" "[ -x /home/curfew/boot.sh ]"
check "boot.sh wakes full fleet (--all)" "grep -q 'wake --all' /home/curfew/boot.sh"
check "boot.sh NOT just echo" "! grep -q 'wake echo' /home/curfew/boot.sh"
check "boot.sh sets tmux 200x200" "grep -q 'default-size 200x200' /home/curfew/boot.sh"
check "boot.sh resizes windows" "grep -q 'resize-window' /home/curfew/boot.sh"
check "boot.sh starts cloudflared" "grep -q 'cloudflared' /home/curfew/boot.sh"
check "boot.sh starts ollama" "grep -q 'ollama' /home/curfew/boot.sh"

echo ""
echo "--- 3. PM2 ---"
check "PM2 installed" "which pm2"
check "PM2 dump exists" "[ -f ~/.pm2/dump.pm2 ]"
check "PM2 startup systemd" "systemctl --user is-enabled pm2-curfew 2>/dev/null || [ -f /etc/systemd/system/pm2-curfew.service ]"
check "PM2 maw running" "pm2 pid maw | grep -q '[0-9]'"
check "PM2 maw-bob running" "pm2 pid maw-bob | grep -q '[0-9]'"
check "PM2 aia-line running" "pm2 pid aia-line | grep -q '[0-9]'"
check "PM2 bob-discord running" "pm2 pid bob-discord | grep -q '[0-9]'"
check "PM2 arra-api running" "pm2 pid arra-api | grep -q '[0-9]'"
check "PM2 maw-syslog running" "pm2 pid maw-syslog | grep -q '[0-9]'"

echo ""
echo "--- 4. Cloudflare Tunnel ---"
check "cloudflared installed" "which cloudflared"
check "cloudflared running" "pgrep -f cloudflared"
check "config.yml exists" "[ -f ~/.cloudflared/config.yml ]"
check "curfew tunnel in config" "grep -q 'curfew.vuttipipat.com' ~/.cloudflared/config.yml"
check "api tunnel in config" "grep -q 'api.vuttipipat.com' ~/.cloudflared/config.yml"
warn "dream tunnel in config" "grep -q 'dream.vuttipipat.com' ~/.cloudflared/config.yml"

echo ""
echo "--- 5. Maw Server ---"
check "maw :3456 responding" "curl -s --max-time 3 http://localhost:3456/ | grep -q ''"
check "maw-bob :3457 responding" "curl -s --max-time 3 -o /dev/null -w '%{http_code}' http://localhost:3457/ | grep -qE '(200|302)'"
check "aia-line :3200 responding" "curl -s --max-time 3 http://localhost:3200/health | grep -q 'ok'"

echo ""
echo "--- 6. Tmux Fleet ---"
SESSIONS=$(tmux list-sessions 2>/dev/null | wc -l)
check "tmux sessions exist" "[ $SESSIONS -gt 0 ]"
check "tmux sessions >= 20" "[ $SESSIONS -ge 20 ]"
check "tmux default-size 200x200" "tmux show-option -g default-size 2>/dev/null | grep -q '200x200'"
check "bob pane height >= 100" "[ $(tmux display-message -t '01-bob:0' -p '#{pane_height}' 2>/dev/null || echo 0) -ge 100 ]"

echo ""
echo "--- 7. Key Services ---"
warn "Ollama running" "pgrep -f ollama"
warn "ComfyUI :8189 responding" "curl -s --max-time 3 http://localhost:8189/system_stats"
check "curfew.vuttipipat.com reachable" "curl -s --max-time 10 -o /dev/null -w '%{http_code}' https://curfew.vuttipipat.com | grep -q '200'"

echo ""
echo "--- 7.5 Service Response Body Checks ---"
check "maw dashboard HTML valid" "curl -s --max-time 5 http://localhost:3456/ | grep -q '<html'"
check "maw API /api/fleet-config responds JSON" "curl -s --max-time 5 http://localhost:3456/api/fleet-config | grep -q '{'"
check "arra-api responds" "curl -s --max-time 5 http://localhost:47779/api/threads?limit=1 | grep -qE 'threads|total'"
warn "maw-bob port 3457 bound" "curl -s --max-time 3 http://localhost:3457/ | grep -q '.'"
check "tools.iagencyaia.com live" "curl -s --max-time 10 https://tools.iagencyaia.com | grep -q 'iAgencyAIA'"
check "fatools.vuttipipat.com live" "curl -s --max-time 10 https://fatools.vuttipipat.com | grep -q 'iAgencyAIA'"
warn "tools vs fatools same build" "[ \"$(curl -s https://tools.iagencyaia.com | grep -oE 'index-[a-zA-Z0-9]+\.js' | head -1)\" = \"$(curl -s https://fatools.vuttipipat.com | grep -oE 'index-[a-zA-Z0-9]+\.js' | head -1)\" ]"

echo ""
echo "--- 7.6 Credential Files ---"
check "cloudflare.env exists" "[ -f ~/.oracle/security/cloudflare.env ]"
check "discord.env exists" "[ -f ~/.oracle/security/discord.env ]"
check "line-jarvis.env exists" "[ -f ~/.oracle/security/line-jarvis.env ]"
warn "vault backup < 7d old" "find /mnt/c/Users/mbank/OneDrive/vault/ -name 'oracle-vault-*.enc' -mtime -7 2>/dev/null | grep -q '.'"

echo ""
echo "--- 8. Boot Log ---"
check "boot log exists" "[ -f /tmp/oracle-boot.log ]"
warn "boot log < 24h old" "[ $(( $(date +%s) - $(stat -c %Y /tmp/oracle-boot.log 2>/dev/null || echo 0) )) -lt 86400 ]"

echo ""
echo "=== Results ==="
echo "  ✅ PASS: $PASS"
echo "  ❌ FAIL: $FAIL"
echo "  ⚠️  WARN: $WARN"
echo ""

if [ $FAIL -eq 0 ]; then
  echo "  🟢 ALL CRITICAL TESTS PASSED"
else
  echo "  🔴 $FAIL CRITICAL TEST(S) FAILED"
fi
echo ""
