# ROADMAP — version-mapped work plan (canonical)

> **What's in each version.** This file is the authoritative mapping of every task to its
> version, owner, dependencies, and that version's definition-of-done. Maintained by **D
> (@tarun)** as build master. Derived from `masterplan.md` §9 (milestones) + §10 (v0.1
> acceptance) + the live `BACKLOG.md`. When a version ships, D marks it DONE here.
>
> Read order on starting a session: `STATUS.md` (where are we) → **this file** (what's in each
> version) → `masterplan.md` → `roles/<role>.md` → `BACKLOG.md`.

**Last updated:** 2026-06-23 by @tarun

---

## Version gates (the order is strict)

```
 v0.1 ──► v0.2 ──► v0.3 ──► v0.4 ──► v0.5 ──► Future
  │        │        │        │        │
 gates:   gates:   gates:   gates:   gates:
 D-004    B-009    A-007 +  D-006    C-008/
 passes   lands    C-007 +  ships    A-008
                   B-010             ships
```

**No version's component work starts until the previous version is declared DONE by D**, EXCEPT:
- v0.1 **Phase 0** (contracts) can start immediately and in parallel — see below.
- Anuj's **A-001** study (v0.1) deliberately runs early to de-risk v0.3 — it's read-only.
- Rohan's **C-001/C-002** (Ollama + benchmark, v0.1) have no Plasma/MCP dependency.

---

## v0.1 — Contracts + read-only introspection

**Goal (masterplan §9):** `docs/contracts/` signed off; MCP server serves Layer 1 over AT-SPI2 +
existing KWin D-Bus; `instructions` + `plasma://capabilities` shipped. **No fork changes yet.**

**Definition of done (masterplan §10) — D-004 is the gate that proves ALL of this:**
1. `docs/contracts/` exists and all 4 roles build against it.
2. Model bootstraps its DE understanding from auto-generated doc + `introspect_capabilities()`
   alone (zero hand-told tool details in its base prompt).
3. ≥3 read-only desktop tasks done with **zero screenshots**, under the agreed per-task token budget.
4. Field projection demonstrably cuts tokens vs. a naive dump.
5. Every reply verifiable in the HITL viewer.

### v0.1 chart

| Phase | Task | Title | Owner | Depends on | Status |
|-------|------|-------|------|------------|--------|
| **0 (gate)** | CONTRACT-001 | element-id-scheme | D (@tarun) | — | REVIEW (PR #1) |
| **0 (gate)** | CONTRACT-002 | plasma-dbus.xml | A (@anuj) | CONTRACT-001 (ID scheme) | TODO |
| **0 (gate)** | CONTRACT-003 | mcp-tools.json (Layer 1+2, assert_state) | B (@srujan) | CONTRACT-001; co-finalize `assert_state` with CONTRACT-004 | TODO |
| **0 (gate)** | CONTRACT-004 | delegate-task + result envelope | C (@rohan) | CONTRACT-001; co-finalize `assert_state` with CONTRACT-003 | TODO |
| **0 (gate)** | CONTRACT-005 | log.jsonl.schema | B (@srujan) | — | TODO |
| **0 (gate)** | CONTRACT-006 | capability-registry.schema.json | A (@anuj) | CONTRACT-001 | TODO |
| **1 (build)** | D-001 | kdesrc-build 3-module chain config | D (@tarun) | — | ✅ ready (PR #2, verified building) |
| **1 (build)** | D-002 | test-session.sh real binary paths | D (@tarun) | D-001 (needs built forks) | next |
| **1 (build)** | D-003 | CI: build/test per component + BACKLOG lint | D (@tarun) | D-001 | TODO |
| **1 (MCP)** | B-001 | pick Rust/Python + MCP SDK; server skeleton | B (@srujan) | CONTRACT-003, 005 signed | TODO |
| **1 (MCP)** | B-002 | AT-SPI2 client → element-tree markdown | B (@srujan) | B-001, D-002 | TODO |
| **1 (MCP)** | B-003 | KWin D-Bus client (existing org.kde.KWin) | B (@srujan) | B-001, D-002 | TODO |
| **1 (MCP)** | B-004 | Layer 1 query tools wired | B (@srujan) | B-002, B-003 | TODO |
| **1 (MCP)** | B-005 | field projection + depth control (token core) | B (@srujan) | B-004 | TODO |
| **1 (MCP)** | B-006 | instructions + plasma://capabilities + introspect_capabilities() | B (@srujan) | B-004 | TODO |
| **1 (MCP)** | B-007 | JSONL log stream (matches CONTRACT-005) | B (@srujan) | B-001, CONTRACT-005 | TODO |
| **1 (orch)** | C-001 | Ollama setup (3B + 3×8B candidates) on 6 GB box | C (@rohan) | — | TODO |
| **1 (orch)** | C-002 | 3-task benchmark → pick 8B → ADR | C (@rohan) | C-001 | TODO |
| **1 (orch)** | C-003 | orchestrator skeleton: MCP client to B + main-agent loop | C (@rohan) | **B-001** (strict), CONTRACT-004 | TODO |
| **1 (orch)** | C-004 | main-agent prompt template (discipline layer) | C (@rohan) | C-003 | TODO |
| **1 (harness)** | D-004 | task harness: 3 read-only tasks + budgets + assert_state | D (@tarun) | **B read path + C orchestrator** (strict) | TODO |
| **1 (harness)** | D-005 | HITL viewer TUI (tails JSONL) | D (@tarun) | CONTRACT-005, B-007 | TODO |
| **1 (study)** | A-001 | study plasmashell D-Bus + Plasma::Applet → ADR | A (@anuj) | — | TODO |

**v0.1 critical path (longest dependency chain):**
`CONTRACT-003/004/005 signed → B-001 → B-002 → B-004 → C-003 → C-004 → D-004 (gate)`.
D-002 runs in parallel (build infra); A-001 and C-001/C-002 run fully parallel from day one.

---

## v0.2 — Actions

**Goal (masterplan §9):** Layer 2 over AT-SPI DoAction + KWin scripting. Drive native apps.
**No fork changes** — actions ride on AT-SPI's existing `DoAction` + KWin scripting; the fork
hooks that enable *widget* actions are deferred to v0.3.

**Gate:** B-009 (rejected-action contract) lands; the model can act on real app UI and recover
from unsupported actions in one turn.

### v0.2 chart

| Task | Title | Owner | Depends on | Status |
|------|-------|------|------------|--------|
| B-008 | Layer 2 action tools (invoke_action, window_tile, window_move_resize, click/hover/scroll, type_text) over AT-SPI DoAction + KWin scripting | B (@srujan) | **v0.1 done**; CONTRACT-003 Layer 2 schemas | TODO |
| B-009 | rejected-action contract (structured error listing supported actions) | B (@srujan) | B-008 | TODO |

**v0.2 starts only after v0.1 is DONE.** Critical path: `v0.1 → B-008 → B-009`.

---

## v0.3 — Fork integration + orchestrator

**Goal (masterplan §9):** Role A ships applet introspection + capability registry +
`describeSelf()` for core widgets; Role C ships `delegate_task` + `assert_state` + summary
handback; hybrid 3B/8B routing. **This is where Anuj's C++ work begins** (A-002 → A-007).

**Gate:** fork-built `plasmashell` exposes `org.kde.PlasmaShell.Introspect`; the orchestrator can
spawn scoped subagents that act + verify + hand back a schema-validated summary with a tiny
main-context footprint; hybrid routing picks 3B for triage and 8B for multi-step.

### v0.3 chart

| Task | Title | Owner | Depends on | Status |
|------|-------|------|------------|--------|
| A-002 | libplasma: Plasma::Applet base virtuals (supportedCapabilities, supportedActions, describeSelf) | A (@anuj) | **A-001** (findings), D-001 build chain; ABI bump → ADR | TODO |
| A-003 | plasma-workspace: org.kde.PlasmaShell.Introspect live on plasmashell | A (@anuj) | A-002; CONTRACT-002 signed | TODO |
| A-004 | plasma-workspace: capability registry + globalCapabilities() | A (@anuj) | A-002; CONTRACT-006 signed | TODO |
| A-005 | Exciton (plasma-desktop): per-applet describeSelf() overrides (clock, launcher, systemtray, weather) | A (@anuj) | A-002 | TODO |
| A-006 | plasma-workspace: KWin structured metadata | A (@anuj) | A-003 | TODO |
| A-007 | plasma-workspace: logging hook → JSONL | A (@anuj) | CONTRACT-005 | TODO |
| B-010 | D-Bus client for PlasmaShell.Introspect + widget_transform tool | B (@srujan) | **A-003, A-004** (strict — client of Anuj's interface) | TODO |
| C-005 | delegate_task + assert_state + schema summary handback | C (@rohan) | CONTRACT-004 signed; **B-001** | TODO |
| C-006 | hybrid 3B/8B routing | C (@rohan) | C-002 (model pick), C-005 | TODO |
| C-007 | sliced-doc delivery to subagents | C (@rohan) | B-006 (doc resources), C-005 | TODO |

**v0.3 critical path:** `A-001 → A-002 → A-003 → B-010` (Anuj ships the D-Bus iface, then Srujan
binds it) runs alongside `C-005 → C-006 → C-007` (orchestrator). **B-010 strictly waits on
A-003+A-004** — that's the only cross-team fork hard dependency.

---

## v0.4 — HITL viewer (in-fork)

**Goal (masterplan §9):** HITL viewer as a native QML component in the fork (not the v0.1 TUI).

**Gate:** D-006 ships — the JSONL-tailing viewer is a first-class Plasma widget.

### v0.4 chart

| Task | Title | Owner | Depends on | Status |
|------|-------|------|------------|--------|
| D-006 | QML HITL viewer in the fork | D (@tarun) | **v0.3 done** (fork + logging hook A-007) | TODO |

**v0.4 starts only after v0.3.** Single task.

---

## v0.5 — Model-management native app

**Goal (masterplan §9):** native app in the fork exposing local model APIs + hybrid routing UI.

**Gate:** C-008/A-008 ships.

### v0.5 chart

| Task | Title | Owner | Depends on | Status |
|------|-------|------|------------|--------|
| C-008 / A-008 | native app: local model APIs, hybrid routing UI | C (@rohan) + A (@anuj) | **v0.4 done**; C-006 (routing) | TODO |

---

## Future — modular adapters

**Goal (masterplan §9):** browsers, Electron, third-party apps, optional client-side submodel
fallback. Adapter interface abstract from day one (so it's designed for, not bolted on).

| Task | Title | Owner | Depends on | Status |
|------|-------|------|------------|--------|
| B-011 | adapter interface (browsers, Electron, 3rd-party, optional client-side submodel) | B (@srujan) | v0.5 | TODO |

---

## Cross-repo ABI rules (span versions — from ADR-0001)

These version-bumps are triggered across forks regardless of which v0.x we're in:

- **`Plasma::Applet` soname change** (libplasma, A-002) → rebuild **all three** forks; D flags in
  `done.md` + follow-up ADR. First fires in **v0.3**.
- **`org.kde.PlasmaShell.Introspect.Version` change** (plasma-workspace, A-003/A-004) → no
  rebuild needed (wire protocol, not a build dep), but record in `done.md` + ADR. First fires in **v0.3**.

---

## Strict-dependency summary (the only "must wait" rules)

1. **v0.x → v0.(x+1):** no next-version component work until D declares the prior version DONE.
   Exceptions: v0.1 contracts (parallel from day one); A-001 study; C-001/C-002 (no deps).
2. **CONTRACT-001 ID scheme** → all other contracts use it (so contracts co-finalize together).
3. **CONTRACT-003 ↔ CONTRACT-004:** co-finalize the shared `assert_state(query, expect)` shape.
4. **B-001 → C-003:** orchestrator is the MCP *client* of B's server (strict, within v0.1).
5. **B read path + C orchestrator → D-004:** the v0.1 gate can't score tasks against a DE that
   isn't introspectable yet (strict, within v0.1).
6. **A-001 → A-002:** Anuj's v0.3 C++ builds on his v0.1 study findings (strict, across versions).
7. **A-003 + A-004 → B-010:** Srujan's v0.3 D-Bus client binds Anuj's shipped interface (strict).

Everything else is parallelizable within its version.
