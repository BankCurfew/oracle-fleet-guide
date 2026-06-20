# Playwright CLI — Browser Automation for All Oracles

## Why This Replaces cdp.ts and Playwright MCP

| Approach | Tokens per 30 actions | Context usage | Screenshots |
|----------|----------------------|---------------|-------------|
| Playwright MCP | ~115,000 | 57% | Streamed into context (5-8K tokens each) |
| **playwright-cli** | **~25,000** | **12%** | **Saved to disk (~50 tokens = file path)** |
| cdp.ts | ~80,000 (est.) | ~40% | Base64 in context |

**4.6x token reduction**. Snapshots are accessibility YAML files on disk. Screenshots are PNG files on disk. Only file paths enter the context.

## Installation (already done)

```bash
npm install -g @playwright/cli@latest
playwright-cli install
playwright-cli install-browser
```

## Quick Start

```bash
# Wrapper script (centralized state management)
pw=~/.oracle/tools/pw-cli.sh

$pw open                              # open browser
$pw goto https://example.com          # navigate
$pw snapshot                          # get accessibility tree → .playwright-cli/*.yml
$pw fill e16 "example text"           # fill by element ref
$pw click e26                         # click by element ref
$pw screenshot                        # screenshot → .playwright-cli/*.png
$pw state-save work                   # save session → ~/.oracle/browser-states/work.json
$pw close                             # close browser
```

## Element Refs

After running `snapshot`, every element gets a ref like `e16`, `e20`, `e26`. Use these in commands:

```bash
$pw click e26                    # click element e26
$pw fill e16 "text"              # fill input e16
$pw hover e4                     # hover element e4
$pw check e23                    # check checkbox e23
```

Refs are **accessibility-based** (role + name), not CSS selectors. More resilient to UI changes.

## Named Sessions (parallel browsers)

```bash
$pw -s=work open                 # work session
$pw -s=research open             # research session
$pw -s=mail open                 # email session
```

Each session is an independent browser instance.

## State Persistence (login reuse)

```bash
# After logging in to a site:
$pw state-save work              # saves cookies + localStorage

# Next session — skip login:
$pw open
$pw state-load work              # restore session
$pw goto https://example.com     # already logged in!
```

States saved to `~/.oracle/browser-states/<name>.json`.

## Common Workflows

### Authenticated Scrape
```bash
$pw open
$pw state-load work                   # restore login
$pw goto https://example.com
$pw snapshot                          # check page state
$pw click e5                          # navigate
$pw snapshot                          # get element refs
$pw eval "document.querySelector('.data-table').innerHTML"  # extract data
$pw state-save work                   # save refreshed cookies
$pw close
```

### Form Submission
```bash
$pw -s=research open
$pw goto https://example.com/form
$pw snapshot                          # find form refs
$pw fill e10 "Name"
$pw fill e12 "email@example.com"
$pw fill e14 "Message text..."
$pw click e16                         # submit
$pw close
```

### Web Mail UI (when MCP fails)
```bash
$pw open
$pw state-load mail
$pw goto https://mail.example.com
$pw snapshot
# ... interact with email UI
$pw state-save mail
$pw close
```

## All Commands (50+)

### Core
open, close, goto, go-back, go-forward, reload

### Interaction
click, dblclick, fill, type, hover, drag, select, upload, check, uncheck

### Page State
snapshot, screenshot, pdf, eval

### Keyboard/Mouse
press, keydown, keyup, mousemove, mousedown, mouseup, mousewheel

### Tabs
tab-list, tab-new, tab-close, tab-select

### Storage
state-save, state-load, cookie-list/get/set/delete/clear, localstorage-list/get/set/delete/clear, sessionstorage-*

### Network
route, route-list, unroute, network-state-set

### DevTools
console, network, run-code, tracing-start/stop, video-start/stop, show

### Session Management
list, close-all, kill-all, delete-data

## Output Files

All output goes to `.playwright-cli/` in the working directory:
- `page-*.yml` — accessibility snapshots
- `page-*.png` — screenshots
- `console-*.log` — console messages
- `network-*.log` — network requests

## Migration from cdp.ts

| cdp.ts command | playwright-cli equivalent |
|----------------|--------------------------|
| `navigate <url>` | `goto <url>` |
| `click <selector>` | `click <ref>` (use snapshot refs) |
| `type <selector> <text>` | `fill <ref> <text>` |
| `screenshot` | `screenshot` (to disk, not base64) |
| `eval <js>` | `eval <js>` |
| `html` | `snapshot` (accessibility tree, smaller) |
| `tabs` | `tab-list` |
| `start` | `open` |
| `close` | `close` |

**Key difference**: cdp.ts uses CSS selectors, playwright-cli uses element refs from `snapshot`. Always run `snapshot` first to get refs.
