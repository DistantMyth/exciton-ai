# PROJECT: Plasma-AI — token-efficient desktop introspection & control

> **Canonical spec.** Change only via an ADR in `_agents/decisions/`. Every agent (human
> or AI) reads this file + its own role file in `_agents/roles/` + the current
> `BACKLOG.md` before starting a session.

You are part of a 4-person team building, on a **forked KDE Plasma (`plasma-desktop`,
modified at the source level)**, a system that lets an LLM operate the desktop by
**querying structured state and invoking semantic actions** — not by taking screenshots.
The DE describes itself in cheap markdown; the model reasons over that and acts. No
client-side vision model in the core path.

---

## 0. LOCKED DECISIONS (do not re-litigate)

- **Target:** forked KDE Plasma (`plasma-desktop`), source-level changes. No Hyprland.
- **Transport:** an **MCP server** the model talks to; every query/action is an MCP tool.
- **Introspection base:** **AT-SPI2** (Qt/KDE a11y element tree: roles/states/actions/DoAction)
  + **KWin/Plasma D-Bus** (workspaces/windows/tiling) + **fork-added hooks** (applets/widgets).
- **Output:** structured **markdown with stable per-element IDs**
  (`win:42`, `el:…`, `wgt:desktop/clock`).
- **HITL:** **observe-only**. Every request/response/action → JSONL log a viewer tails.
  Non-blocking. `--review` (blocking approval) is optional/later.
- **Inference:** **Ollama** on a 6 GB VRAM RTX 4050. Hybrid: always-on `qwen2.5:3b`
  triage, `qwen2.5:7b` / `llama3.1:8b` / `qwen3:8b` (Q4_K_M, ctx 8192, flash-attn) for
  multi-step reasoning. Final 8B pick decided by a 3-task benchmark (ADR).
- **Subagent pattern:** ephemeral scoped subagents with **schema-bound summary handback**
  + a machine-checked verify gate against DE state. Main context stays tiny.

---

## 1. ARCHITECTURE

```
User goal → Main agent (small long-lived context)
              │  delegate_task(...)
              ▼
        Agent orchestrator   ── owns: main ctx, subagent lifecycle, verify gate,
              │                     model routing (3B/8B), summary injection, JSONL log
       spawns │  fresh ctx, scoped tools, capped turns
              ▼
        Subagent (ctx DROPPED after handback) ── plan → act(MCP) → verify(assert_state)
              │  MCP
              ▼
   plasma-ai MCP server  ── tools (Layer 1/2) + briefing (instructions/resources)
        │  AT-SPI2   │  D-Bus   │  fork hooks
        ▼            ▼          ▼
   app trees   KWin+Shell   applet/widget tree, caps, describeSelf(), actions
```

**Key principle:** the MCP server is a TRANSLATOR + CACHE + PROJECTOR, never a source of
truth. It shapes existing DE state into cheap markdown — it never invents it.

---

## 2. LAYER 1 — QUERY TOOLS (nouns)

Every query takes `fields[]` and `depth` so the model fetches ONLY what it needs. Defaults
are minimal. All returned elements carry stable IDs usable in Layer 2.

| Tool | Params | Returns |
|------|--------|---------|
| `list_desktops()` | — | count, ids, names, current |
| `list_windows(desktop, fields)` | `desktop: id\|"current"\|"all"` | requested fields only |
| `get_window(id, fields)` | — | as above for one window |
| `get_window_contents(id, depth, include_tooltips)` | `depth∈{bar,sidebar,menu,full}` | semantic markdown: top bar / sidebar / menus / hover-detail, depth-scoped |
| `get_element_tree(root, depth, prune, fields)` | `root: element_id\|"window:id"` | AT-SPI subtree as indented markdown w/ IDs |
| `get_element(id, include_tooltips)` | — | one node, full detail |
| `get_actions(target)` | `target: element_id\|window_id\|widget_id` | supported actions + each param schema |
| `list_widgets(containment, fields)` | — | applets: plugin, geometry, supported transforms |
| `get_widget(id, fields)` | — | one widget, full detail |
| `describe_hover(id)` | — | tooltip/hover-detail semantics |
| `screenshot(region?)` | — | escape hatch ONLY, discouraged, logged as fallback |

---

## 3. LAYER 2 — ACTION TOOLS (verbs)

| Tool | Params | Notes |
|------|--------|-------|
| `invoke_action(element_id, action, args)` | — | generic dispatch (AT-SPI DoAction + registered) |
| `window_tile(id, side)` | `side∈{left,right,top,bottom,maximize,minimize,fullscreen}` | KWin |
| `window_move_resize(id, x,y,w?,h?, unit)` | `unit∈{px,percent}` | respects min/max hints |
| `widget_transform(id, move?, resize?, rotate_deg?)` | — | per-axis only if widget declared support |
| `focus(id)` / `activate(id)` / `close(id)` | — | — |
| `click` / `hover` / `scroll` | `element_id, button?, count?` | semantic; prefer `invoke_action` |
| `type_text(element_id?, text)` / `key(keysym)` | — | input synthesis fallback |

**Rejected-action contract:** if an action is unsupported, return a structured error
listing what IS supported for that element, so the model self-corrects in one turn.

---

## 4. LAYER 3 — SUBAGENT ORCHESTRATION (context isolation)

`delegate_task(goal, success_criteria, tools[], model_hint, max_turns)` → spawns a fresh
context with a scoped tool whitelist (least privilege), capped turns/tokens.

- Subagent plans → acts via MCP → verifies with `assert_state(query, expect)` → emits a
  schema-validated result envelope → its context is DROPPED.
- Only the summary (~1–3 lines) enters the main context; everything else stays in the log.
- `success_criteria` MUST be DE-observable ("a 24h digital clock exists top-right"), never
  subjective ("the desktop looks aesthetic").
- Hard turn/token cap; exceed → `blocked`, not a hung loop.
- Result envelope: `{status, summary, changes:[{element_id,before,after}], evidence, tokens_used}`.

---

## 5. AGENT BRIEFING LAYER (how the model learns its role + talks to the DE)

The DE self-describes; the doc is AUTO-GENERATED, never hand-written:

- MCP `instructions` → compact rules string injected into every session.
- `resources/list` + `resources/read` → full doc, on-demand (`plasma://capabilities`,
  `plasma://tools/<name>`, `plasma://format`, `plasma://examples`). Overview always loaded,
  detail fetched as needed. **Subagents get a SLICED doc** (only their whitelisted tools).
- `introspect_capabilities()` → live, versioned "what does THIS build support".

Rules baked into `instructions`:
1. Discover before assume — call `introspect_capabilities()` at session start.
2. Query only what you need — use `fields`/`depth`; default to minimal.
3. Reuse element IDs in actions; don't re-describe.
4. Prefer `invoke_action` over `click` — it's semantic and verifiable.
5. Delegate multi-step goals via `delegate_task`; act only on the schema summary.
6. Verify every change with `assert_state` — never claim success without it.

---

## 6. PLASMA FORK — SOURCE-LEVEL CHANGES REQUIRED (Role A)

**Three forks** (see ADR-0001). Changes split by where they actually live:

| # | Change | Repo |
|---|--------|------|
| 1 | `org.kde.PlasmaShell.Introspect` D-Bus interface (`listContainments()`, `listApplets(c)`, `appletInfo(id)`, `appletActions(id)`, `appletCapabilities(id)`) — **on plasmashell** | **plasma-workspace** |
| 2 | `Plasma::Applet` base virtuals: `supportedCapabilities()` → `{Draggable,Resizable,Rotatable,Configurable,…}` and `supportedActions()` → action defs with JSON param schemas | **libplasma** |
| 3 | `Applet::describeSelf()` base virtual (returns semantic markdown) | **libplasma** |
| 4 | Per-applet `describeSelf()` **overrides** (digital clock, launcher, systemtray, weather) | **plasma-desktop** |
| 5 | KWin: consolidate/document structured workspaces/outputs/tiling + per-surface metadata | **plasma-workspace** (KWin) |
| 6 | Central capability/action registry the MCP server enumerates in one call | **plasma-workspace** |
| 7 | Logging hook: every introspection query + action → JSONL stream | **plasma-workspace** |

Fork repos (all under `DistantMyth` on GitHub):
- `DistantMyth/exciton-ai` ← **coordination hub** (this repo): plan, contracts, AI components
- `DistantMyth/Exciton` ← plasma-desktop fork — Role A's per-applet overrides
- `DistantMyth/plasma-workspace` ← plasmashell D-Bus interface, KWin, registry
- `DistantMyth/libplasma` ← `Plasma::Applet` base virtuals

Cross-repo ABI rule: bump `org.kde.PlasmaShell.Introspect.Version` when (1) or (6) changes;
bump `Plasma::Applet` ABI (soname) when (2) or (3) changes. Record in an ADR + done.md.

---

## 7. HOW THE TEAM COORDINATES

**Four repos** (ADR-0001 + ADR-0002). `exciton-ai` is the coordination hub; the three Plasma
forks are siblings checked out alongside. **All coordination (`_agents/`, `docs/contracts/`)
lives only in exciton-ai** — the Plasma forks are pure source.

```
~/Projects/
├── exciton-ai/         ← THIS repo — COORDINATION HUB + AI components
│   ├── _agents/        # masterplan.md (THIS), roles/, BACKLOG, done, bugs, decisions/
│   ├── docs/contracts/ # shared IDLs/schemas (the seams) — all 4, D drives
│   ├── harness/        # test session, task harness, HITL viewer, CI   [Role D]
│   ├── mcp-server/     #                                            [Role B]
│   └── orchestrator/   #                                            [Role C]
├── Exciton/            ← plasma-desktop fork — per-applet overrides, KCMs  [Role A]
├── plasma-workspace/   ← plasma-workspace fork — plasmashell D-Bus, KWin, registry  [Role A]
└── libplasma/          ← libplasma fork — Plasma::Applet base virtuals  [Role A]
```

Each dev checks out all four. AI components and coordination files live **only** in
exciton-ai. The three Plasma forks contain no `_agents/` — they're pure source.

**Sync protocol:**
1. `git pull`. Diff `_agents/` since your last pull — that's how you learn what changed.
2. `BACKLOG.md` line format:
   `- [STATUS] task-id — short desc — @handle — note`
   `STATUS ∈ {TODO, CLAIMED, IN-PROGRESS, REVIEW, DONE, BLOCKED}`.
3. To take a task: set it `[CLAIMED] @yourhandle`, commit, push. One task per agent at a time.
4. Work on branch `feat/<role>-<task-id>`. **PR target depends on the repo**: AI components
   and contracts PR to `exciton-ai/master`; Plasma source changes PR to the relevant fork's
   own `master` (Exciton / plasma-workspace / libplasma). CI (Role D) must pass. One human review.
5. On completion: move the line to `done.md` with a one-line summary; update `docs/contracts/`
   (in exciton-ai) if you changed an interface; open an ADR if you changed architecture.
6. Any architecture change → write an ADR in `exciton-ai/_agents/decisions/` BEFORE
   implementing. 1 page.

---

## 8. HOW WE TEST

- **Isolated test session, never your real desktop.** Each dev creates a dedicated local
  user (e.g. `plasma-ai`) on their own machine. Under that user, run a **nested
  `kwin_wayland`** built from the forks + a test `plasmashell`, on its own
  `WAYLAND_DISPLAY=wayland-test` and its own D-Bus + AT-SPI2 session buses. Model-driven
  actions hit ONLY this session. **Build order matters: libplasma → plasma-workspace →
  plasma-desktop** (deps flow down). `kdesrc-build` handles this with a chain config.
- **Models:** Ollama runs on the host (shared across the test user). Main + triage models
  preloaded per the locked decisions.
- **MCP server** (Role B's build) is pointed at the test session's buses.
- **Task harness** (Role D): launches model → orchestrator → MCP → test session for a set
  of known tasks, records tokens used, and scores pass/fail via `assert_state`
  (machine-checked, not vibes). Each task has an agreed token budget.
- **HITL viewer** (Role D): tails the JSONL log so you watch what the DE returned and what
  the model did. Observe-only by default; `--review` (blocking approval) optional.
- **Why nested-session not a VM:** faster iteration, no VM-Wayland quirks. Full VM is the
  fallback only if nested kwin proves unreliable for someone's setup.

Bootstrap script: `harness/test-session.sh up` / `down` (Role D owns and maintains it).

---

## 9. MILESTONES (the gate order)

- **v0.1 — Contracts + read-only introspection.** `docs/contracts/` signed off; MCP server
  serves Layer 1 over AT-SPI2 + existing KWin D-Bus; `instructions` +
  `plasma://capabilities` shipped. No fork changes yet. Gate: model answers 3 read-only
  tasks, zero screenshots, under token budget.
- **v0.2 — Actions.** Layer 2 over AT-SPI DoAction + KWin scripting. Drive native apps.
- **v0.3 — Fork integration + orchestrator.** Role A ships applet introspection +
  capability registry + `describeSelf()` for core widgets; Role C ships `delegate_task` +
  `assert_state` + summary handback; hybrid 3B/8B routing.
- **v0.4 — HITL viewer** (in-fork later).
- **v0.5 — Model-management native app** in the fork (local APIs, hybrid routing UI).
- **Future — modular adapters:** browsers, Electron, third-party apps, optional client-side
  submodel fallback. Adapter interface abstract from day one.

---

## 10. v0.1 ACCEPTANCE (definition of done for the first milestone)

- `docs/contracts/` exists and all 4 roles build against it.
- Model bootstraps its DE understanding from auto-generated doc + `introspect_capabilities()`
  alone (zero hand-told tool details in its base prompt).
- ≥3 read-only desktop tasks done with zero screenshots, under the agreed per-task token budget.
- Field projection demonstrably cuts tokens vs. a naive dump.
- Every reply verifiable in the HITL viewer.

---

## 11. FOR THIS SESSION / FIRST TASK

Do NOT start writing components yet. First deliverable is `docs/contracts/`:
element-ID scheme, D-Bus IDL XML, MCP tool JSON-Schemas (Layer 1 + Layer 2 +
`delegate_task`, `assert_state`, result envelope), JSONL log schema. Propose them for
review. Then implement strictly within your role boundary; touch a contract → open an ADR → coordinate.
