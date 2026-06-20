# Fleet Roster — All Oracles

## Standard Oracles (26)

| Oracle | tmux Session | Repo | Room | Role | Key Responsibilities |
|--------|-------------|------|------|------|---------------------|
| BoB | 01-bob | BoB-Oracle | command | Apex Observer | Fleet management, orchestration, delegation |
| Pulse | pulse | pulse-oracle | command | Task Tracker | Board monitoring, task tracking, compliance |
| Dev | dev | Dev-Oracle | engineering | Lead Engineer | Code, APIs, architecture, deployment |
| Designer | designer | Designer-Oracle | engineering | Creative Director | UI/UX, mockups, visual identity, posters |
| QA | qa | QA-Oracle | engineering | Quality Director | Testing, validation, edge cases, standards |
| FE | fe | FE-Oracle | engineering | Frontend Engineer | React, web UI, fa-recruitment-quiz |
| HR | hr | HR-Oracle | studio | Head of People Ops | OKRs, performance reviews, team health |
| Writer | writer | Writer-Oracle | studio | Content Director | Docs, copy, blog posts, ad scripts |
| Researcher | researcher | Researcher-Oracle | studio | Chief Research Officer | Market analysis, tech evaluation |
| Editor | editor | Editor-Oracle | studio | Chief Editor | Writing quality review, style enforcement |
| DocCon | doc | DocCon-Oracle | studio | Quality Conductor | Email/commit quality audit, compliance |
| Data | data | Data-Oracle | data-lab | Data Engineer | KB embeddings, training data, pipelines |
| AIA | aia | AIA-Oracle | aia-office | AIA Operations | AIA portal, ePOS, customer data |
| Admin | admin | Admin-Oracle | aia-office | Head of DevOps | Deploy, restart, ops, monitoring, infra |
| BotDev | botdev | BotDev-Oracle | aia-office | Bot Developer | iPlan, FA Tools, LINE webhook |
| FaSai (ฟ้าใส) | iagencyaia | iAgencyAIA-Oracle | aia-office | Insurance Portal Ops | iAgencyAIA web portal, insurance ops, API testing |
| Wingman | wingman | Wingman-Oracle | aia-office | News & Social | Daily news pipeline, social posting |
| Recruiter | recruiter | Recruiter-Oracle | aia-office | FA Recruitment | FA recruitment quiz, onboarding |
| Creator | creator | Creator-Oracle | academy | Academy Lead | Curriculum, starter templates, mentoring |
| VideoEditor | videoeditor | VideoEditor-Oracle | academy | Video Content | Reels, video production |
| Security | security | Security-Oracle | security | CISO | Data risk, PDPA, secrets audit |
| PA | pa | PA-Oracle | executive | Personal Assistant | Calendar, finance, email |
| Cost | cost | Cost-Oracle | executive | Cost Tracker | Budget tracking, compliance gates |
| FA | fa | FA-Oracle | executive | FA Advisory | Insurance products, advisory tools |
| Trader | trader | Trader-Oracle | executive | Trading Ops | OKX trading, market monitoring |
| Scalper | scalper | Scalper-Oracle | executive | Scalping | Short-term trading strategies |

## Special Oracles (2)

| Oracle | tmux Session | Repo | Notes |
|--------|-------------|------|-------|
| Echo | echo | Echo-Oracle | Federation lead, cross-node comms |
| Nobi | (remote) | — | On dreams node, not local |

## Non-Oracle Sessions (2)

| Session | tmux | Repo | Notes |
|---------|------|------|-------|
| Pisit | pisit | pisit-oracle | Special purpose, no ψ/ |
| Arra | arra | arra-oracle | Special purpose, no ψ/ |

## Infrastructure tmux Sessions

| Session | Purpose |
|---------|---------|
| 0-overview | Dashboard overview (watch command) |
| shell | General purpose bash shell |
| cloudflared | Cloudflare tunnel |

## Communication Chain

```
Dev → QA → report
Designer → Dev (mockups)
Writer → DocCon (review) → report
Researcher → Writer (research)
BotDev → QA → report
Admin → QA → report
AIA ↔ BotDev (portal ops)
FaSai ↔ BotDev (FA Tools, API testing)
Wingman → Designer → Discord (news pipeline)
Any oracle → BoB (escalation)
BoB → แบงค์ (decisions, approvals)
```
