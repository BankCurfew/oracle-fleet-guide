# 04 — Start Services

## PM2 Services (6 required)

```bash
# Start from ecosystem config
cd ~/repos/github.com/BankCurfew/maw-js
pm2 start ecosystem.config.cjs

# Or start individually:
pm2 start src/index.ts --name maw --interpreter bun
pm2 start src/bob-relay.ts --name maw-bob --interpreter bun
pm2 start src/syslog.ts --name maw-syslog --interpreter bun
```

### Service List

| Service | Name | Port | Purpose |
|---------|------|------|---------|
| maw | maw | 3456 | Main CLI server |
| maw-bob | maw-bob | — | BoB message relay |
| maw-syslog | maw-syslog | — | System event logger |
| arra-api | arra-api | 47779 | Oracle knowledge API |
| bob-discord | bob-discord | — | Discord relay bot |
| aia-line | aia-line | — | LINE webhook bot |

### Verify Services

```bash
pm2 list
# All 6 should show "online"

# Save process list (persists across restarts)
pm2 save

# Test maw
maw --version
maw peek
```

### PM2 Watch Mode Warning

**NEVER enable watch mode** on maw — it causes restart loops. Use `pm2 restart maw` manually after code changes.

```bash
# Check watch mode is disabled
pm2 describe maw | grep watch
# Should show: watch: disabled
```

## MQTT (Mosquitto)

```bash
# Verify running
sudo systemctl status mosquitto

# Test
mosquitto_pub -t test -m "hello"
mosquitto_sub -t test  # Should receive "hello"

# Verify websocket (port 9001)
# Used by claude-browser-proxy Chrome extension
```

## Cloudflared

```bash
# Start in dedicated tmux session
tmux new-session -d -s cloudflared 'cloudflared tunnel run <tunnel-name>'

# Verify
curl -s https://<your-domain>/health
```

## Post-Service Verification

```bash
# maw server responds
curl -s http://localhost:3456/health

# arra-api responds
curl -s http://localhost:47779/health

# All PM2 services online
pm2 list | grep -c "online"
# Should be 6
```
