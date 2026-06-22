# Element-ID Scheme

- **Contract:** CONTRACT-001
- **Status:** SIGNED (D drives; pending team ack on the win: decision below)
- **Version:** 0.1.0
- **Authors:** all (D drives)
- **Consumed by:** everyone

## Goal
Stable, human- and model-readable identifiers for every addressable DE element, used as the
bridge between query tools (Layer 1) and action tools (Layer 2/3). An ID returned by a query
MUST be valid as an argument to an action on the same element within a session.

## Grammar

```
<element-id> ::= <type> ":" <path>
<type>       ::= "desktop" | "win" | "el" | "wgt" | "act"
<path>       ::= <segment> ( "/" <segment> )*
<segment>    ::= [A-Za-z0-9_.-]+
```

## Types

| Type | Meaning | Examples |
|------|---------|----------|
| `desktop:` | a workspace / virtual desktop | `desktop:1`, `desktop:2` |
| `win:` | a top-level window/surface | `win:42`, `win:org.kde.dolphin/0` |
| `el:` | a UI element in an a11y/app tree (AT-SPI node or fork-described node) | `el:plasmashell/panel1/launcher`, `el:win:42/menubar/file` |
| `wgt:` | a Plasma applet/widget instance | `wgt:desktop/clock`, `wgt:panel1/digitalclock/1` |
| `act:` | a named action exposed by an element (reference, used in invoke_action) | `act:wgt:desktop/clock/rotate` |

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
