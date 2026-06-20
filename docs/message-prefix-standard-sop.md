# Message Prefix Standard — SOP & Guide

**Version**: 1.0
**Effective**: 2026-06-20
**Approved by**: แบงค์
**Enforced by**: Hook (PreToolUse BLOCK) + DocCon + Pulse
**Scope**: ทุก Oracle ทุก message ไม่มีข้อยกเว้น

---

## ทำไมต้องมี Prefix?

ก่อนมี standard นี้ ข้อความจาก oracle กระจัดกระจาย — ไม่รู้ว่าเกี่ยวกับ project ไหน ticket ไหน ตามงานไม่ได้ แบงค์มองไม่เห็นภาพรวม Pulse track ไม่ได้

**หลัง standard**: ทุกข้อความ traceable กลับไปหา project, issue, repo ได้ทันที

---

## Format มาตรฐาน

```
cc: [project-slug] #issue — message
```

### ตัวอย่างที่ถูกต้อง ✅

```
cc: [fa-tools] #109 — filter group insurance fix merged
cc: [maw-js] #79 — color-code terminal commands done
cc: [cashflow] #132 — PDF v13 delivered to OneDrive
cc: [daily-news] #poster — ATW 3 stories posted to Discord
cc: [office] — ต้องการ project ใหม่สำหรับ LINE bot integration
```

### ตัวอย่างที่ผิด ❌ (จะถูก BLOCK)

```
cc: fixed the bug                          ← ไม่มี [project] ไม่มี #ticket
cc: [fa-tools] — filter fix done           ← มี [project] แต่ไม่มี #ticket
cc: done                                    ← ไม่มีอะไรเลย
sent task to dev                            ← ไม่มี cc: ไม่มี prefix
```

---

## [project-slug] คืออะไร?

ต้องตรงกับ `maw project ls` — 16 projects ที่ active:

| Slug | ชื่อ Project | Repo หลัก |
|------|------------|-----------|
| `maw-js` | Maw CLI | BankCurfew/maw-js |
| `fa-tools` | FA Tools | BankCurfew/iagencyaiafatools |
| `fa-quiz` | FA Recruitment Quiz | iAgencyAIA/iJourney |
| `daily-news` | Daily News Pipeline | BankCurfew/Wingman-Oracle |
| `oracle-infra` | Oracle Infrastructure | BankCurfew/BoB-Oracle |
| `aia-ops` | AIA Operations | BankCurfew/AIA-Oracle |
| `customer-data-sync` | Customer Data Sync | BankCurfew/Data-Oracle |
| `security-compliance` | Security & Compliance | BankCurfew/Security-Oracle |
| `content-writing` | Content & Writing | BankCurfew/Writer-Oracle |
| `content-creation` | Content Creation | BankCurfew/Designer-Oracle |
| `ijourney-ads` | iJourney Ad Campaign | BankCurfew/Writer-Oracle |
| `curfew-migration` | CURFEW Migration | BankCurfew/BoB-Oracle |
| `echo-federation` | Echo Federation | BankCurfew/echo-oracle |
| `seo-backlinks` | SEO & Backlinks | — |
| `lordms` | LordMS | BankCurfew/LordMS |
| `cost-ops` | Cost Operations | BankCurfew/Cost-Oracle |

### Special: `[office]` = Catch-All

`[office]` ใช้ได้เสมอ **ไม่ต้องมี #ticket**:

```
cc: [office] — ต้องการ project ใหม่สำหรับ X
cc: [office] — แจ้งทุกคน: standard ใหม่
cc: [office] — ถามเรื่องทั่วไป
```

**ใช้ [office] เมื่อ**:
- ยังไม่มี project สำหรับงานนี้
- เป็นเรื่องทั่วไปของ office ไม่เจาะจง project
- ต้องการขอ BoB สร้าง project ใหม่

---

## ขั้นตอนก่อนส่ง message

### ถ้ามี project + issue แล้ว:
```
maw hey <oracle> "cc: [project] #issue — message"
```

### ถ้ามี project แต่ยังไม่มี issue:
```
1. สร้าง issue:   gh issue create --repo <repo> --title "<title>"
2. Map เข้า project: maw project add <slug> '#<issue>'
3. ส่ง message:   maw hey <oracle> "cc: [project] #issue — message"
```

### ถ้ายังไม่มี project เลย:
```
1. ใช้ [office] ขอ BoB:  maw hey bob "cc: [office] — ต้องการ project ใหม่: <อธิบาย>"
2. รอ BoB สร้าง project + issue
3. ได้ [project] #issue แล้วค่อยส่ง message จริง
```

### ถ้าเป็นเรื่องทั่วไป:
```
maw hey <oracle> "cc: [office] — message"
```

---

## Hook Enforcement

### validate-project-prefix.sh (PreToolUse:Bash)

**ทำงานอัตโนมัติ**: ทุกครั้งที่ oracle ใช้ `maw hey` hook จะตรวจ:

| ตรวจอะไร | ผ่าน | ไม่ผ่าน |
|----------|------|---------|
| มี `[project]`? | ✅ ต่อไป | 🚫 BLOCK + แจ้งสร้าง |
| `[office]`? | ✅ ผ่านเลย | — |
| มี `#ticket`? | ✅ ผ่านเลย | 🚫 BLOCK + แนะนำ [office] |
| project ตรง maw? | ✅ ผ่านเลย | 🚫 BLOCK + แจ้งสร้าง project |

**ไม่ตรวจ**:
- ข้อความสั้น < 10 ตัวอักษร (ping, ACK, OK)
- Heartbeat / status
- คำสั่งที่ไม่ใช่ `maw hey`

---

## สำหรับ Commit Messages

```
fix(fa-tools): #109 filter group insurance
feat(maw-js): #79 color-code terminal
docs(office): /save skill rebuilt
```

Format: `type(project): #issue description`

---

## สำหรับ File Names

ใส่ ticket ref ใน filename หรือ header:

```
customer-portfolio-analysis-122.md       ← #122
cashflow-plan-v13.pdf                    ← #132
hook-audit-117-2026-06-19.md             ← #117
```

---

## Pulse Tracking

Pulse monitor compliance:
- ทุก cc message ตรง format ไหม?
- ทุก project มี issue ไหม?
- ทุก issue อยู่ใน project ไหม?
- Orphan projects (0 tasks) → flag
- Orphan issues (ไม่มี project) → flag

---

## QA Audit

QA ตรวจ periodic:
- Hook ทำงานจริงไหม? (test block + pass)
- Oracle ใช้ถูก format ไหม?
- Project ↔ issue ↔ repo sync กันไหม?
- สิ่งที่ขาด → สร้าง

---

## เมื่อย้ายเครื่อง (Migration)

สิ่งที่ต้อง verify หลังย้าย:
1. Hook file อยู่ที่ `~/.oracle/hooks/validate-project-prefix.sh`
2. ทุก oracle settings.json reference hook นี้
3. `maw project ls` แสดง projects ครบ
4. `gh auth status` ใช้ได้
5. DocCon conduct committed ใน git

---

## ข้อห้าม

1. **ห้ามส่ง task ถึง oracle อื่นโดยไม่มี [project] #ticket** — hook จะ BLOCK
2. **ห้ามสร้าง project เองถ้าไม่ใช่ BoB** — ใช้ [office] ขอ BoB สร้าง
3. **ห้ามใช้ project slug ที่ไม่มีใน maw project ls** — hook จะ BLOCK
4. **ห้ามใช้ [office] แทนทุกอย่าง** — ถ้ามี project อยู่แล้วต้องใช้ project จริง
5. **ห้ามข้าม #ticket** — ถ้ามี project ต้องมี ticket ด้วย (ยกเว้น [office])

---

*Version 1.0 — แบงค์ approved 2026-06-20*
*Enforced by: validate-project-prefix.sh (PreToolUse BLOCK)*
*Maintained by: DocCon-Oracle*
