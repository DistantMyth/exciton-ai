# Element-ID Scheme

- **Contract:** CONTRACT-001
- **Status:** DRAFT
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
