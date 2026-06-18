# 02 — Clone All Repos

## Oracle Repos (28)

```bash
cd ~/repos/github.com/BankCurfew

# Core oracles
for repo in BoB-Oracle Admin-Oracle AIA-Oracle BotDev-Oracle Cost-Oracle \
  Creator-Oracle Data-Oracle Designer-Oracle Dev-Oracle DocCon-Oracle \
  Echo-Oracle Editor-Oracle FA-Oracle FE-Oracle HR-Oracle iAgencyAIA-Oracle \
  PA-Oracle pulse-oracle QA-Oracle Recruiter-Oracle Researcher-Oracle \
  Scalper-Oracle Security-Oracle Trader-Oracle VideoEditor-Oracle \
  Wingman-Oracle Writer-Oracle; do
  ghq get BankCurfew/$repo
done

# Special oracles (not standard ψ/ structure)
ghq get BankCurfew/arra-oracle
ghq get BankCurfew/pisit-oracle
```

## Infrastructure Repos

```bash
# Fleet management
ghq get BankCurfew/maw-js              # Maw CLI + server
ghq get BankCurfew/office-v2           # Dashboard frontend
ghq get BankCurfew/oracle-dashboard    # Dashboard config
ghq get BankCurfew/oracle-fleet-guide  # This guide

# Oracle MCP (brain)
ghq get Soul-Brews-Studio/arra-oracle-v3  # Oracle-v2 MCP server

# Browser automation
ghq get BankCurfew/gemini-proxy-tools  # Gemini/ChatGPT MQTT proxy
ghq get BankCurfew/claude-browser-proxy # Chrome extension
```

## Product Repos

```bash
# Active products
ghq get BankCurfew/fa-recruitment-quiz  # iJourney RPG quiz
ghq get BankCurfew/oracle-editor        # GrapesJS website builder
ghq get BankCurfew/LordMS              # Entertainment venue system
ghq get BankCurfew/sinchai-app         # Finance app

# AIA tools
ghq get BankCurfew/AIA-Knowledge       # AIA knowledge base
ghq get BankCurfew/fa-tools            # Insurance product tools
```

## Verify Clone

```bash
# Count repos
ls ~/repos/github.com/BankCurfew/ | wc -l
# Should be ~40+

# Verify oracle repos have ψ/ directories
for dir in ~/repos/github.com/BankCurfew/*-Oracle; do
  name=$(basename "$dir")
  [ -d "$dir/ψ" ] && echo "✅ $name" || echo "❌ $name: no ψ/"
done
```

## Install Dependencies

```bash
# maw-js
cd ~/repos/github.com/BankCurfew/maw-js && bun install

# arra-oracle-v3 (MCP server)
cd ~/repos/github.com/Soul-Brews-Studio/arra-oracle-v3 && bun install

# arra-api
cd ~/repos/github.com/BankCurfew/maw-js && bun install
```
