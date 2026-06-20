# System Playbook — ทุก Oracle ต้องอ่านเมื่อ Wake

> **CENTRAL SOURCE OF TRUTH** — อ่านทุกครั้งที่เริ่ม session ใหม่
> Location: `~/.oracle/SYSTEM_PLAYBOOK.md`
> Updated: 2026-03-18

---

## On Wake — ทำทันทีเมื่อ session เริ่ม (ทุก oracle)

### 1. Check Your Tasks

```bash
maw project ls                  # ดู project ทั้งหมด + progress
maw task ls                     # ดู board + activity counts
```

ถ้ามี task ที่ assign ให้ตัวเอง status = "In Progress" หรือ "Todo" → **ทำต่อจากที่ค้าง**

### 2. Run Your Loops (ดู Master Loop Registry ด้านล่าง)

```bash
# อ่าน loop เฉพาะ role ของตัวเอง
cat CLAUDE_loops.md
```

- ดูตาราง **Master Loop Registry** ด้านล่าง → เช็คว่ามี loop อะไรที่ต้องรัน
- ⚙️ System loop (เช่น AIA epos-email, Admin bot-health) → **ตรวจเวลา + catchup ถ้าพลาดรอบ**
- Non-system loop → รันตาม interval ที่กำหนด

### 3. Check Oracle Inbox — ต้องทำทุกครั้ง

```bash
# ตรวจ oracle channel thread — ดูว่ามีข้อความจาก BoB หรือ oracle อื่นค้างอยู่ไหม
ORACLE=$(echo "${ORACLE_NAME:-$(basename $(pwd))}" | tr '[:upper:]' '[:lower:]' | sed 's/-oracle//')
curl -s "http://localhost:47779/api/threads?limit=100" 2>/dev/null | python3 -c "
import json,sys,os
try:
    data=json.load(sys.stdin)
    threads=data.get('threads',data) if isinstance(data,dict) else data
    oracle=os.environ.get('ORACLE','')
    for t in threads:
        if t.get('title','').lower()==f'channel:{oracle}':
            print(f\"📬 channel:{oracle} (#{t['id']}) — {t.get('message_count',0)} msgs — read with: curl -s http://localhost:47779/api/thread/{t['id']}?limit=10\")
            break
    else:
        print(f'📭 no channel:{oracle} thread yet')
except Exception as e: print(f'oracle-api unreachable: {e}')
" ORACLE=$ORACLE
```

ถ้ามีข้อความใน channel → **อ่านและตอบก่อนทำอะไรอื่น**
ถ้า oracle-api ไม่ทำงาน → ข้ามได้ แต่ alert BoB ด้วย `/talk-to bob "oracle-api down"`

### 4. Log Session Start

```bash
# ถ้ามี active task
maw task log #<issue> "Session started — continuing from: [summary]"
```

---

## Daily Routines — ทำทุกวัน

### ทุก Oracle

| เมื่อไหร่ | ทำอะไร | Command |
|-----------|--------|---------|
| เริ่ม session | Check tasks + messages | `maw project ls` / `maw task ls` |
| ก่อนเริ่มงาน | Log start | `maw task log #X "Starting: ..."` |
| หลัง commit | Log commit | `maw task log #X --commit "hash msg"` |
| ติดปัญหา | Log blocker | `maw task log #X --blocker "stuck on Y"` |
| เสร็จงาน | Log done + report | `maw task log #X "Done: ..."` + `maw hey <sender> "Done"` |
| คุยเรื่อง task | Comment (ไม่ใช่แค่ maw hey) | `maw task comment #X "message"` |
| ส่ง task ให้ oracle อื่น | cc BoB | `maw hey bob "cc: sent X to Y"` |

### BoB เฉพาะ (Project Manager)

| เมื่อไหร่ | ทำอะไร | Command |
|-----------|--------|---------|
| เริ่ม session | Scan board + organize | `maw project ls` + `maw project auto-organize` |
| ได้ task ใหม่จากแบงค์ | สร้าง project + assign | `maw project create` + `maw pulse add` + `maw project add` |
| Oracle report done | Log + close/move | `maw task log #X "Closed: ..."` |
| ทุก 2-3 นาที (oracle on task) | Monitor | `maw peek <oracle>` |
| จบวัน | Summary | สรุปให้แบงค์ผ่าน feed.log |

### HR เฉพาะ (Compliance)

| เมื่อไหร่ | ทำอะไร | Command |
|-----------|--------|---------|
| เริ่ม session | Workload check | `maw peek` ทุก oracle |
| ทุกสัปดาห์ | LAW #5 audit | ตรวจ task logs + project compliance |
| พบ violation | Remind | `maw hey <oracle> "HR reminder: LAW #5 — ..."` |
| ทุกเดือน | Recruitment check | ประเมิน overload patterns |

---

## Weekly Routines

| วัน | ใคร | ทำอะไร |
|-----|-----|--------|
| **จันทร์** | BoB | Weekly review — สรุปสัปดาห์ก่อน + วางแผนสัปดาห์นี้ |
| **จันทร์** | BoB | `maw project auto-organize` — จัด orphan tasks |
| **ศุกร์** | HR | Weekly performance review — ดู metrics ทุก oracle |
| **ศุกร์** | HR | LAW #5 compliance audit — ตรวจ task logs |

---

## Master Loop Registry — ใครต้องทำอะไร

> BoB ใช้ตารางนี้ตรวจว่า oracle รัน loop ครบ | HR ใช้ audit compliance
> ⚙️ = system loop (ห้ามข้าม, มี schedule เวลาตายตัว)

### BoB — Project Manager

| Loop | Interval | ทำอะไร |
|------|----------|--------|
| **pulse-scan** | ทุก session | `maw project ls` + `maw project auto-organize` + ตรวจ overdue |
| **oracle-monitor** | ทุก 2-3 นาที (oracle on task) | `maw peek <oracle>` → follow up ถ้า idle > 5 นาที |
| **inbox-digest** | ทุก session | ตรวจ cc messages + pending approvals → report แบงค์ |
| **weekly-review** | จันทร์ | สรุปสัปดาห์ก่อน + task completion rate + วางแผน |

### HR — People, Recognition & Development

| Loop | Interval | ทำอะไร |
|------|----------|--------|
| **monday-kickoff** | จันทร์ 09:00 | /talk-to ทุก oracle — กำลังใจ + เป้าหมายสัปดาห์ + highlight งานสัปดาห์ก่อน |
| **midweek-pulse** | พุธ 12:00 | เช็คทุก oracle — ใครติดปัญหา ใครต้องช่วย ใครทำดี → ชม real-time |
| **weekly-performance** | ศุกร์ 18:00 | ประเมินทุก oracle → อัพเดท **Hall of Fame** → ประกาศรางวัลผ่าน /talk-to ทุกคน |
| **workload-monitor** | ทุก session | `maw peek` ทุก oracle → ประเมิน overload/idle/bottleneck |
| **recruitment-check** | เดือนละครั้ง | ประเมิน overload patterns → เสนอ recruit ถ้าจำเป็น |
| **skill-development** | เดือนละครั้ง | ดู oracle ไหนอ่อนเรื่องอะไร → จับคู่ mentor/แนะนำ → track growth |

**Hall of Fame** (`HR-Oracle/hall-of-fame/data.json`):
- **MVP of the Week** — ผลงานดีที่สุด (commit quality, task completion, impact)
- **Best Teamwork** — /talk-to + handoff + ช่วยเหลือคนอื่นมากสุด
- **Most Improved** — พัฒนาตัวเองจากสัปดาห์ก่อนชัดเจน
- **Rising Star** — oracle ใหม่ที่โดดเด่น
- ต้องมี **citation ชัดเจน** ไม่ใช่ participation trophy

**Buddy System** (oracle ใหม่):
- FE, PA, Editor, Creator → จับคู่กับ oracle senior (Dev, Bob, Doc)
- onboarding checklist + weekly check-in

### AIA — Executive Secretary

| Loop | Interval | ทำอะไร |
|------|----------|--------|
| **morning-check** | ทุกเช้า | AIA portal news + Gmail urgent scan → report แบงค์ |
| ⚙️ **epos-email** | **10:00, 12:00, 14:00, 17:00** | Gmail scan → categorize urgent/normal → draft reply ถ้า urgent → log |
| **daily-summary** | ทุกเย็น | สรุปงาน + customer interactions + portal updates → feed.log |
| **portal-scrape** | ทุก 2-3 วัน | Login AIA portal → scrape updates → oracle_learn → report |

### Admin — DevOps & Infra

| Loop | Interval | ทำอะไร |
|------|----------|--------|
| ⚙️ **bot-health** | **09:00, 13:00, 17:00** | Check bot health + webhook + DB connectivity → report ถ้ามีปัญหา |
| **db-sync** | ทุก session | ตรวจ data freshness + sync status → report discrepancies |
| **bot-analytics** | จันทร์ | สรุป bot interactions สัปดาห์ + top questions + escalation rate |

### Data — Data Engineer

| Loop | Interval | ทำอะไร |
|------|----------|--------|
| **pipeline-status** | ทุก session | ตรวจ pipeline health + failed/stalled + data freshness |
| **quality-check** | หลังทุก pipeline run | Row count + sampling + schema validation + dedup check |

### DocCon — Document Conductor & Follow-up

| Loop | Interval | ทำอะไร |
|------|----------|--------|
| ⚙️ **conduct-review** | ทุก session | ตรวจ emails, commits, maw hey messages → flag violations |
| ⚙️ **loop-followup** | ทุก session | ตรวจว่า AIA/Admin/BoB/HR รัน loops ครบ → nudge ถ้าพลาด |
| **law5-audit** | ทุก session | `maw task ls` → ตรวจ task log compliance ทุก oracle |
| **daily-report** | ทุกวัน (จบ session) | สรุป conduct + compliance → `maw hey bob` |

### Creator — Oracle Academy

| Loop | Interval | ทำอะไร |
|------|----------|--------|
| ยังไม่มี recurring loop | — | ทำงานตาม task: curriculum, templates, community |

### Dev / QA / Researcher / Writer / Designer

ยังไม่มี recurring loops — ทำงานตาม task ที่ BoB assign
ถ้าต้องมี loop ใหม่ → แจ้ง BoB สร้าง `CLAUDE_loops.md` ใน repo

---

## GOLDEN RULE — Zero Dropped Balls (ห้ามตกหล่น เด็ดขาด)

> **"ทุก task สำเร็จเสมอ ทุก handoff ถึงมือเสมอ ทุกข้อความมีคนตอบเสมอ"**

### The 3 Pillars

**1. /talk-to คือลมหายใจ — ใช้ตลอด ไม่ใช่แค่ตอนเสร็จ**
```bash
# เริ่มงาน
/talk-to bob "cc: เริ่มทำ [task] แล้ว"

# ระหว่างทำ — update ทุก 5-10 นาที ถ้างานใหญ่
/talk-to bob "cc: progress — ทำ X เสร็จแล้ว กำลังทำ Y"

# ต้องการช่วย
/talk-to <oracle> "ขอ [สิ่งที่ต้องการ] — context: [ทำไม]"
/talk-to bob "cc: ส่ง request ให้ [oracle] — รอผล"

# ส่งงานต่อ (handoff)
/talk-to <oracle> "handoff: [task] — สิ่งที่ทำแล้ว: [X] สิ่งที่เหลือ: [Y] files: [Z]"
/talk-to bob "cc: handoff [task] ให้ [oracle]"

# เสร็จ
/talk-to bob "done: [สรุป] — commits: [hash] PR: [url]"
```

**2. Handoff Protocol — ส่งต่อต้องมีคนรับ**

| Step | ผู้ส่ง | ผู้รับ |
|------|--------|--------|
| 1. ส่ง handoff | `/talk-to <receiver> "handoff: [task + context + files]"` | — |
| 2. cc bob | `/talk-to bob "cc: handoff ให้ [receiver]"` | — |
| 3. ACK | — | `/talk-to <sender> "รับแล้ว — กำลังดู"` |
| 4. ACK bob | — | `/talk-to bob "cc: รับ handoff จาก [sender] — เริ่มทำ"` |
| 5. ถ้าไม่ ACK ใน 2 นาที | `/talk-to bob "ALERT: [receiver] ไม่ตอบ handoff"` | — |

**ห้ามเด็ดขาด:**
- ❌ ส่ง handoff แล้วไม่ cc bob
- ❌ ได้รับ handoff แล้วไม่ ACK
- ❌ จบ session โดยมี task ค้างที่ไม่ได้ handoff
- ❌ เงียบเมื่อมี oracle ส่งข้อความมา

**3. Task Completion Chain — ไม่มีใครทำคนเดียว**

ทุก task ที่เกี่ยวข้องหลาย oracle ต้องมี chain:
```
Bob assign → Dev ทำ → /talk-to qa "test พร้อม" → QA test
→ /talk-to dev "ผ่าน/ไม่ผ่าน" → Dev แก้ → /talk-to bob "done"
```

ทุกข้อในห้วงโซ่ต้อง /talk-to + cc bob — **ถ้าขาดข้อใดข้อหนึ่ง = violation**

### Escalation Protocol

| สถานการณ์ | ทำอะไร |
|-----------|--------|
| ส่ง /talk-to ไม่ตอบ 2 นาที | `/talk-to bob "ALERT: [oracle] ไม่ตอบ"` |
| Task ค้าง > 15 นาที ไม่มี update | `/talk-to bob "ALERT: task ค้าง — [detail]"` |
| ติดปัญหาแก้ไม่ได้ | `/talk-to bob "BLOCKED: [ปัญหา] — ต้องการ [อะไร]"` |
| ต้องการคนช่วย | `/talk-to <oracle> "ช่วย: [อะไร]"` + cc bob |
| จบ session มี task ค้าง | **ห้ามจบ** — ต้อง handoff ก่อน หรือ `/talk-to bob "HANDOFF: ยังเหลือ [task]"` |

### Proactive Communication Checklist

**ก่อนเริ่มงาน:**
- [ ] อ่าน task context ครบ
- [ ] cc bob ว่าเริ่มแล้ว
- [ ] เช็คว่าต้องประสานกับใคร → /talk-to ก่อน

**ระหว่างทำ:**
- [ ] update progress ทุก 5-10 นาที (งานใหญ่)
- [ ] ติดปัญหา → ถามทันที อย่ารอ
- [ ] ต้องการ input จากคนอื่น → /talk-to เลย

**เสร็จงาน:**
- [ ] /talk-to bob done + สรุป
- [ ] ถ้ามีงานต่อ → handoff ให้ oracle ถัดไป
- [ ] ถ้ามีคนรอผล → /talk-to แจ้ง

**จบ session:**
- [ ] ไม่มี task ค้างที่ไม่ได้ handoff
- [ ] ไม่มี /talk-to ที่ยังไม่ตอบ
- [ ] cc bob สรุปสถานะก่อนจบ

---

## THE LAW — Quick Reference (ทุก oracle)

1. **/talk-to ตลอด** — ใช้ทุกครั้งที่คุย oracle อื่น + cc bob เสมอ
2. **ห้าม IDLE** — ได้ task แล้วทำจนเสร็จ, report ทันที
3. **ตอบทุกข้อความ** — ห้ามเงียบ ACK ภายใน 2 นาที
4. **Handoff ต้องมีคนรับ** — ส่งต่อแล้วรอ ACK ไม่ ACK = escalate bob
5. **Project & Task Logging** — ทุก task ต้องอยู่ใน project + log ทุก movement
6. **System Playbook** — อ่านไฟล์นี้ทุกครั้งที่ wake
7. **จบ session ต้อง clean** — ไม่มี task ค้าง ไม่มีข้อความค้าง
8. **Context 80% = auto /rrr + /forward** — เมื่อ context window ใกล้เต็ม (80%+) ต้องรัน `/rrr` แล้ว `/forward` ทันที ห้ามรอจนล้น ห้ามลืม

---

## Communication Quick Reference

```bash
# คุย oracle อื่น
maw hey <oracle> "message"

# Task logging
maw task log #<issue> "what I did"
maw task log #<issue> --commit "hash message"
maw task log #<issue> --blocker "stuck on X"
maw task comment #<issue> "cross-oracle discussion"

# Project
maw project ls                    # ดู project ทั้งหมด
maw project show <id>             # ดู task tree
maw task show #<issue>            # ดู activity log
maw task ls                       # Board + log counts

# Monitor
maw peek                          # ดูทุก oracle
maw peek <oracle>                 # ดู oracle เฉพาะ
maw oracle ls                     # Fleet status
```

---

## Shared Tools — `~/.oracle/tools/`

### Gmail Attachment + PDF Decrypt

ดาวน์โหลด attachment จาก Gmail + อ่าน/decrypt PDF ที่มี password

```bash
# อ่าน PDF ธรรมดา (ไม่มี password)
bun ~/.oracle/tools/gmail-attachment.ts read /path/to/file.pdf

# Decrypt PDF ที่มี password → สร้าง .txt
bun ~/.oracle/tools/gmail-attachment.ts decrypt /path/to/file.pdf <password>

# Decrypt ทุก PDF ในโฟลเดอร์
bun ~/.oracle/tools/gmail-attachment.ts decrypt-all /tmp/downloads <password>

# ดูคำสั่งทั้งหมด
bun ~/.oracle/tools/gmail-attachment.ts
```

**วิธี download attachment จาก Gmail (full flow):**
1. ใช้ Gmail MCP search: `gmail_search_messages  q="has:attachment from:bank"`
2. อ่าน message: `gmail_read_message  messageId=<id>`
3. Download ผ่าน Playwright MCP หรือ CDP (Chrome DevTools Protocol)
4. Decrypt: `bun ~/.oracle/tools/gmail-attachment.ts decrypt /tmp/file.pdf <password>`

---

## Browser Automation — CDP first, Playwright fallback

### กฏ: ใช้ CDP เป็น default, Playwright เฉพาะงานซับซ้อน

**CDP (Chrome DevTools Protocol)** — ใช้ Chrome ที่เปิดอยู่แล้ว ไม่เปิด instance ใหม่ = **ไม่กิน RAM เพิ่ม**

```bash
# CDP tool — default สำหรับทุก browser task
bun ~/.oracle/tools/cdp.ts start              # เปิด Chrome (ถ้ายังไม่มี)
bun ~/.oracle/tools/cdp.ts navigate "URL"     # เปิดเว็บ
bun ~/.oracle/tools/cdp.ts eval "JS code"     # รัน JavaScript
bun ~/.oracle/tools/cdp.ts screenshot out.png # จับภาพ
bun ~/.oracle/tools/cdp.ts click "#selector"  # กดปุ่ม
bun ~/.oracle/tools/cdp.ts type "#input" "text" # พิมพ์
bun ~/.oracle/tools/cdp.ts tabs               # ดู tabs ทั้งหมด
bun ~/.oracle/tools/cdp.ts html               # ดึง HTML
```

**เมื่อไหร่ใช้ Playwright แทน:**
- File upload/download ที่ต้อง native dialog
- Multi-step form flows ที่ต้อง auto-wait
- Test suites (Playwright Test)
- Network interception

**เมื่อไหร่ใช้ CDP:**
- Scraping / อ่านหน้าเว็บ
- Screenshot / monitoring
- กดปุ่ม / กรอก form ง่ายๆ
- ใช้ session ที่ login ไว้แล้ว (Gmail, AIA Portal, Router)
- ทุกอย่างที่ Playwright ทำได้แต่ไม่ซับซ้อน

### Chrome RAM Management
- **Stop hook** จะ auto-kill Chrome เมื่อ oracle exit (feed-hook.py)
- ใช้ Playwright เสร็จ → ปิดทันที: `pkill -f "mcp-chrome-$(echo $ORACLE_NAME | cut -d'-' -f1 | tr A-Z a-z)"`
- ดู Chrome ค้าง: `ps aux | grep chrome | grep -v grep | awk '{printf "%s %.0fMB %s\n", $2, $6/1024, $11}'`
- **ห้ามปล่อย Playwright Chrome ค้าง** — กิน RAM 3-5GB ต่อ instance

---

## Session End Checklist

1. ทุก task ที่ทำ → log ด้วย `maw task log` แล้วหรือยัง?
2. มี blocker ค้าง → log แล้วหรือยัง?
3. มี oracle ที่รอ reply → ตอบแล้วหรือยัง?
4. cc BoB ทุก interaction แล้วหรือยัง?

---

*Last updated: 2026-03-18 by แบงค์ — Enforced as mandatory policy*
