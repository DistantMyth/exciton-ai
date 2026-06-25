# Element-ID Scheme

- **Contract:** CONTRACT-001
- **Status:** SIGNED (D drives; pending team ack on the win: decision + cap: addition below)
- **Version:** 0.2.0
- **Authors:** all (D drives)
- **Consumed by:** everyone

## Goal
Stable, human- and model-readable identifiers for every addressable DE element, used as the
bridge between query tools (Layer 1) and action tools (Layer 2/3). An ID returned by a query
MUST be valid as an argument to an action on the same element within a session.

## Grammar

```
<element-id> ::= <type> ":" <path>
<type>       ::= "desktop" | "win" | "el" | "wgt" | "act" | "cap"
<path>       ::= <segment> ( "/" <segment> )*
<segment>    ::= [A-Za-z0-9_.-]+
```

## Types

| Type | Meaning | Examples |
|------|---------|----------|
| `desktop:` | a workspace / virtual desktop | `desktop:1`, `desktop:2` |
| `win:` | a top-level window/surface | `win:42` (opaque numeric handle — see DECISION below) |
| `el:` | a UI element in an a11y/app tree (AT-SPI node or fork-described node) | `el:plasmashell/panel1/launcher`, `el:win:42/menubar/file` |
| `wgt:` | a Plasma applet/widget instance | `wgt:desktop/clock`, `wgt:panel1/digitalclock/1` |
| `act:` | a named action. **Two forms:** (a) registry template `act:<action-name>` (e.g. `act:rotate`) — the action *class*; (b) per-instance ref `act:<element-id>/<action-name>` (e.g. `act:wgt:desktop/clock/rotate`) — the action *bound to a specific element*, used in `invoke_action`. | `act:rotate`, `act:wgt:desktop/clock/rotate` |
| `cap:` | a capability *class* (what can be done to an element *kind*), from the central registry. Names a capability, NOT an instance. | `cap:draggable`, `cap:resizable`, `cap:rotatable`, `cap:configurable` |

## Rules
1. **Stable within a session.** The ID for a given element does not change while it exists.
   When the element is destroyed, its ID is never reused this session.
2. **Hierarchical where natural.** Use `/` to reflect containment: `el:win:42/menubar/file`.
3. **Opaque is OK.** Numeric handles (`win:42`) are allowed; the model must not parse them,
   only pass them back.
4. **Action IDs reference their owner.** `act:<element-id>/<action-name>`.
5. **No coordinates or state baked in.** IDs are pure references; state is queried separately.
6. **Versioning of the grammar itself** is this file's `Version:`. If the grammar changes,
   bump it and open an ADR.

## Open question (sign-off)
- Should `win:` IDs be opaque handles (`win:42`, recommended) or structured
  (`win:org.kde.dolphin/0`)? Opaque is more stable; structured is more debuggable.
  **Recommendation: opaque handles + a separate `app` field on queries.**

## DECISION — opaque `win:` handles (CONTRACT-001 sign-off)
**Resolved 2026-06-21 by D (@tarun), pending team ack.** Window IDs are **opaque numeric
handles** (`win:42`); app identity is a **separate `app` field** on query output
(already present in `mcp-tools.json` `list_windows`/`get_window`).

Rationale (rejecting structured `win:org.kde.dolphin/0`):

1. **Consistent with this contract's own rules.** Rule 3 already permits opaque handles
   and says the model must not parse them; rule 5 forbids baking state into IDs. An app
   name *is* identity/state. Opaque honors both; structured violates rule 5.
2. **Consistent with the masterplan.** `masterplan.md` §0 lists `win:42` as the canonical
   example. `mcp-tools.json` already exposes `app` as a field — a structured ID would
   duplicate it in two places and invite drift.
3. **Stability.** Opaque handles survive app renames, `.desktop` relabels, and process
   restarts within a session. Structured IDs encode mutable identity; the moment an app
   renames itself, the ID changes mid-session and violates rule 1 (stable within session).
4. **The "two windows" case already forces a handle.** Two Dolphin windows require a
   disambiguator regardless (`/0`, `/1`) — that disambiguator IS an opaque index. The
   structured form is just an opaque handle wearing an app-name costume.
5. **Debuggability is served elsewhere.** The `app` field on query output + the
   `element_ids` array in `log.jsonl.schema` (CONTRACT-005) let the HITL viewer render
   `win:42 [dolphin]` by joining data — no need to encode app into the ID.

**Consequence for implementers:** `list_windows`/`get_window` MUST populate `app` (not
nullable when known). Action tools take `win:42` and never an app-qualified string.
Uniqueness: the integer is a per-session monotonic-ish handle assigned by the MCP server
from KWin window ids; never reused after close within a session (rule 1).

**This is the only sign-off-blocking open question in CONTRACT-001.** Remaining content
above is stable at v0.1.0.

## AMENDMENT — v0.1.0 → v0.2.0 (added `cap:` type)
**Resolved 2026-06-24 by D (@tarun).** Added the `cap:` type (capability *class* IDs, e.g.
`cap:draggable`) and clarified that `act:` has two forms (registry template `act:rotate` vs
per-instance ref `act:wgt:desktop/clock/rotate`). **Additive, backward-compatible** — no existing
ID changes; existing consumers ignore `cap:` ids they don't use.

**Why:** CONTRACT-006 (the capability/action registry, authored by A) needs stable IDs to name
capability *classes* (`Draggable`, `Rotatable`, …) distinct from per-element instance refs. Without
`cap:`, the registry had no way to name a capability class without colliding with `act:` instance
refs. A also used `act:<name>` as a registry-template form, which is sound but needed the grammar
to bless the two-form `act:` explicitly. This amendment reconciles CONTRACT-001 with CONTRACT-006.

**For implementers:** the registry (CONTRACT-006) emits `cap:` and `act:` (template form) ids;
per-instance action refs remain `act:<element-id>/<name>`. `invoke_action` (Layer 2) always takes
an element-id + action name, never a bare `cap:` or `act:` template. Full ADR: `_agents/decisions/0003-id-capability-type.md`.
