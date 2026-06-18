# 01 — Machine Setup

## Required Software

| Software | Version | Install | Purpose |
|----------|---------|---------|---------|
| Node.js | v24+ | `nvm install 24` | Claude Code, maw-js |
| Bun | latest | `curl -fsSL https://bun.sh/install \| bash` | oracle-v2 MCP, arra-api |
| Claude Code | latest | `npm i -g @anthropic-ai/claude-code` | AI agent runtime |
| PM2 | latest | `npm i -g pm2` | Process manager |
| Mosquitto | 2.0+ | `sudo apt install mosquitto` | MQTT broker for browser proxy |
| ghq | latest | `go install github.com/x-motemen/ghq@latest` | Git repo manager |
| RTK | 0.38+ | See RTK docs | Token savings CLI |
| tmux | 3.0+ | `sudo apt install tmux` | Session manager |
| Playwright | latest | `npx playwright install chromium` | Browser automation |
| Python 3 | 3.10+ | system | Scripts, dig.py |
| jq | latest | `sudo apt install jq` | JSON processing |

## Critical Symlinks

```bash
# bun-linux — ALL oracle MCP configs reference this path
ln -sf ~/.bun/bin/bun ~/.local/bin/bun-linux

# Verify
ls -la ~/.local/bin/bun-linux
# Should show: bun-linux -> /home/<user>/.bun/bin/bun
```

**WARNING**: If `bun-linux` is a stub script instead of a symlink to real bun, ALL oracle-v2 MCP servers will silently fail. This happened during the 2026-06-17 migration and broke MCP for the entire fleet.

## Directory Structure

```bash
# Create base directories
mkdir -p ~/repos/github.com/BankCurfew
mkdir -p ~/repos/github.com/Soul-Brews-Studio
mkdir -p ~/.oracle/{security,inbox/pending,tools,hooks,feed}
mkdir -p ~/.config/maw
mkdir -p ~/.cache/ms-playwright
mkdir -p ~/.maw/inbox
```

## Environment Variables

```bash
# In ~/.bashrc or ~/.zshrc
export GHQ_ROOT=~/repos
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"
```

## MQTT/Mosquitto Setup

```bash
# Install
sudo apt install mosquitto mosquitto-clients

# Enable websocket (needed for browser proxy)
sudo tee /etc/mosquitto/conf.d/websocket.conf << 'EOF'
listener 1883
listener 9001
protocol websockets
allow_anonymous true
EOF

sudo systemctl restart mosquitto
```

## Cloudflared (Tunnel)

```bash
# Install cloudflared
# Configure tunnel to match your domain
# Start in tmux:
tmux new-session -d -s cloudflared 'cloudflared tunnel run <tunnel-name>'
```

## Playwright Chrome

```bash
# Install for all oracles
npx playwright install chromium

# Each oracle gets its own user data dir at:
# ~/.cache/ms-playwright/mcp-chrome-<oracle-name>
```
