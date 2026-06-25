# BACKLOG — Plasma-AI task board

> Sync protocol in `_agents/masterplan.md` §7. Line format:
> `- [STATUS] task-id — short desc — @handle — note`
> `STATUS ∈ {TODO, CLAIMED, IN-PROGRESS, REVIEW, DONE, BLOCKED}`.
> To take a task: set it `[CLAIMED] @yourhandle`, commit, push. One task per agent at a time.

## Team
- **A — @anuj** (Plasma Fork Engineer, 3 repos)
- **B — @srujan** (MCP Server Engineer)
- **C — @rohan** (Orchestrator & Models Engineer)
- **D — @tarun** (Integration, Testing & Workflow Lead — build master)

---

## v0.1 — Contracts + read-only introspection

**Phase 0 (BLOCKING, all 4): sign off contracts in `docs/contracts/`. No component code
ships until these are SIGNED.** ADR-0001 (3-fork layout) is accepted.

### Phase 0 — Contracts (the gate)
- [REVIEW] CONTRACT-001 — element-id-scheme — @tarun(drives) — DECISION: opaque `win:` handles; element-ids.md finalized, pending team ack
- [CLAIMED] @anuj CONTRACT-002 — plasma-dbus.xml (org.kde.PlasmaShell.Introspect) — @anuj — spans plasma-workspace; B consumes — finalized on feat/A-CONTRACT-002-006
- [TODO] CONTRACT-003 — mcp-tools.json (Layer 1 + Layer 2 + assert_state) — @srujan — C consumes
- [TODO] CONTRACT-004 — delegate-task + result envelope schema — @rohan — B & D consume
- [TODO] CONTRACT-005 — log.jsonl.schema — @srujan — D consumes
- [CLAIMED] @anuj CONTRACT-006 — capability-registry.schema.json — @anuj — B consumes — finalized on feat/A-CONTRACT-002-006

### Phase 1 — Build chain + test bed (unblocks everyone)
- [CLAIMED] D-001 — kdesrc-build 3-module chain config (libplasma→plasma-workspace→plasma-desktop) — @tarun — unblocks Anuj
- [TODO] D-002 — test-session.sh: replace placeholder invocations with real binary paths — @tarun — unblocks integration
- [TODO] D-003 — CI: build/test per component + BACKLOG lint — @tarun

### Phase 1 — MCP server (read path)
- [TODO] B-001 — pick Rust/Python + MCP SDK; server skeleton (tool registration, transport, stubs) — @srujan
- [TODO] B-002 — AT-SPI2 client: a11y tree → element-tree markdown — @srujan
- [TODO] B-003 — KWin D-Bus client over existing org.kde.KWin (desktops/windows) — @srujan
- [TODO] B-004 — Layer 1 query tools wired — @srujan
- [TODO] B-005 — field projection + depth control (token efficiency core) — @srujan
- [TODO] B-006 — instructions + plasma://capabilities resource + introspect_capabilities() — @srujan
- [TODO] B-007 — JSONL log stream (matches CONTRACT-005) — @srujan

### Phase 1 — Orchestrator + models (read path)
- [TODO] C-001 — Ollama setup (3B always-on + 3×8B candidates) on the 6 GB box — @rohan
- [TODO] C-002 — 3-task benchmark → pick 8B on tool-call accuracy → ADR — @rohan
- [TODO] C-003 — orchestrator skeleton: MCP client to B's server + main-agent loop — @rohan
- [TODO] C-004 — main-agent prompt template (discipline layer) — @rohan

### Phase 1 — Harness + HITL
- [TODO] D-004 — task harness: 3 read-only tasks + token budgets + assert_state scoring — @tarun — THIS IS THE v0.1 GATE
- [TODO] D-005 — HITL viewer TUI (tails JSONL) — @tarun

### Phase 1 — Role A study (no code; sets up v0.3)
- [TODO] A-001 — study existing plasmashell D-Bus + Plasma::Applet; write notes in _agents/decisions/0002-applet-introspection-findings.md — @anuj — unblocks v0.3 C++ work

## v0.2 — Actions (start after v0.1 contracts land; no fork changes needed)
- [TODO] B-008 — Layer 2 action tools (invoke_action, window_tile, window_move_resize, click/hover/scroll, type_text) over AT-SPI DoAction + KWin scripting — @srujan
- [TODO] B-009 — rejected-action contract — @srujan

## v0.3 — Fork integration + orchestrator (Anuj's C++ work starts here)
- [TODO] A-002 — libplasma: Plasma::Applet base virtuals (supportedCapabilities, supportedActions, describeSelf) — @anuj
- [TODO] A-003 — plasma-workspace: org.kde.PlasmaShell.Introspect live on plasmashell — @anuj
- [TODO] A-004 — plasma-workspace: capability registry + globalCapabilities() — @anuj
- [TODO] A-005 — Exciton (plasma-desktop): per-applet describeSelf() overrides (clock, launcher, systemtray, weather) — @anuj
- [TODO] A-006 — plasma-workspace: KWin structured metadata — @anuj
- [TODO] A-007 — plasma-workspace: logging hook → JSONL — @anuj
- [TODO] B-010 — D-Bus client for PlasmaShell.Introspect + widget_transform tool — @srujan
- [TODO] C-005 — delegate_task + assert_state + schema summary handback — @rohan
- [TODO] C-006 — hybrid 3B/8B routing — @rohan
- [TODO] C-007 — sliced-doc delivery to subagents — @rohan

## v0.4 — HITL viewer (in-fork)
- [TODO] D-006 — QML HITL viewer in the fork — @tarun

## v0.5 — Model-management native app
- [TODO] C-008 / A-008 — native app: local model APIs, hybrid routing UI — @rohan/@anuj

## Future — modular adapters
- [TODO] B-011 — adapter interface (browsers, Electron, 3rd-party, optional client-side submodel) — @srujan
