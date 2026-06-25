# 0005. assert_state verify gate: a closed `expect` match-language

- **Status:** proposed (backs CONTRACT-004 finalization; needs @tarun ack + co-sign with
  CONTRACT-003 @srujan)
- **Date:** 2026-06-25
- **Deciders:** @rohan (C, drives), @srujan (B, co-owner of `assert_state`), @tarun (D,
  harness scores against this)
- **Amends:** CONTRACT-003 (`assert_state` in `mcp-tools.json`) and CONTRACT-004
  (`delegate-task.schema.json`) — both currently type `expect` as a bare `{type: object}`.

## Context

`assert_state(query, expect)` is the machine-checked verify gate: a subagent runs a Layer 1
query, the result is matched against `expect`, and `pass`/`fail` decides whether the subagent
may emit `status: success` (masterplan §4, §5 rule 6). It is the **only** coupling between
CONTRACT-003 (B owns the tool) and CONTRACT-004 (C owns `success_criteria` + the result
envelope). D's task harness (D-004) scores pass/fail through the same path.

Today both contracts type `expect` as `{"type": "object", "$comment": "structured match or
predicate over query output"}`. That comment is a placeholder, not a contract: it specifies no
match semantics, so B cannot implement the matcher, C cannot write `success_criteria` the
model can target, and D cannot build a scorer without guessing. The masterplan §0 "verify gate"
guarantee is currently un-enforceable. We need to define what a valid `expect` **is** before
either contract can be SIGNED — this is the gate the brief calls out as the soft coupling.

Constraints that bound the choice:
- **Deterministic.** The model must not be able to make `pass` flaky; the same `(query, expect)`
  gives the same verdict on the same DE snapshot.
- **Sandbox-safe.** Nothing in the verify path executes model-supplied code on the host. No
  `eval`, no `jq` over arbitrary strings, no regex engine exposed to the model by default
  (ReDoS / catastrophic backtracking).
- **Cheap to implement (~100 LoC) and to explain to the model** in the sliced subagent doc.
- **Scoreable by D** without a second parser: the harness reuses the same matcher.
- **DE-observable only** (per masterplan §4): an `expect` must be expressible against Layer 1
  query output, never against subjective state.

## Options considered

1. **Closed minimal matcher (accepted)** — a small fixed set of match keys (`exists`, `count`,
   `field_eq`, `text_contains`) plus an optional `where` selector. One-paragraph semantics,
   closed `enum`/`oneOf` in JSON Schema, no code execution, no regex by default. Covers every
   read-only v0.1 task ("a window is focused", "desktop count is 2", "clock label shows 24h").
2. **JSONPath + free-form predicate** — maximally expressive (`$.windows[?(@.focused)].id`).
   Powerful, but turns the verify path into an interpreter the model drives, expands attack
   surface, and forces every consumer (B, C, D) to ship a JSONPath engine. Overkill for v0.1
   read-only tasks; the expressiveness isn't needed until v0.3 widget transforms.
3. **Regex `match` key** — compact for text, but exposes a regex engine to the model (ReDoS),
   is a second matcher alongside the structured one, and most v0.1 checks are structural
   (count/field-eq), not textual. Defer; `text_contains` covers the textual cases safely.
4. **Leave `expect` open, ship only examples** — fastest to "sign", but preserves exactly the
   ambiguity blocking sign-off. D's scorer stays undefined. Rejected for the same reason this
   ADR exists.

## Decision

**Option 1.** Define one canonical `expect` shape, normatively owned by CONTRACT-004
(`delegate-task.schema.json` `$defs`), and have CONTRACT-003's `assert_state` reference it
(`x-source-of-truth: CONTRACT-004 / ADR-0005`). One definition, each file stays self-contained
enough for MCP `tools/list`. The matcher is a closed set:

```
expect ::= {
  exists?:   boolean                      # the query produced ≥1 result (non-empty list / present node)
  count?:    integer | {min?: int, max?: int}   # length of a list, or a range
  field_eq?: { <jsonPointer>: <value> }   # value at a JSON Pointer equals <value> (deep-equal for objects)
  text_contains?: string | [string, ...]  # substring(s) all present in the query's rendered text/markdown
  where?:    { <jsonPointer>: <value> }   # filter the query output to matching rows BEFORE the above keys apply
}
```

- **Closed**: every key is one of the four above (plus `where`); the schema is `additionalProperties: false`.
- **Compositional**: all present keys must hold (logical AND). `where` is applied first.
- **Deterministic + side-effect-free**: pure function of `(query_output, expect)`.
- **No code execution**: JSON Pointers are *addressed*, not evaluated; no regex.
- **`field_eq` is deep-equal** for object/array values, scalar-equal otherwise.

`where` is included now (not deferred) because Layer 1 tools routinely return lists
(`list_windows`, `list_widgets`) and a check like "a focused window exists" needs to scope to
the focused row before asserting — without `where` the matcher can't express it and we'd reach
for JSONPath immediately. `text_contains` is included because Layer 1 query output is markdown
and several v0.1 checks are textual ("clock label contains `:`" → 24h). Both keep us out of
Option 2 for all of v0.1.

### Shared sub-shapes (live in CONTRACT-004 `$defs`, referenced by CONTRACT-003)

- `layer1_query` = `{ tool: string, args: object }` — the `query` half. `tool` MUST name a
  Layer 1 tool; `args` MUST match that tool's `inputSchema`. Reused by both contracts so a
  `success_criteria.query` is byte-identical to an `assert_state` call.

## Consequences

- **Enables:** CONTRACT-003 and CONTRACT-004 can be SIGNED (the `expect` ambiguity is the last
  open item on both). D-004's scorer is just "call the same matcher." B implements one matcher
  (~100 LoC). C's `success_criteria` and B's `assert_state` agree by construction.
- **Costs:** closed set means some checks need rephrasing as one of the four keys (acceptable —
  v0.1 tasks are simple). Adding a new match key later is a contract bump + ADR.
- **Status mapping (CONTRACT-004) is pinned by this gate:**
  `assert pass` ⇒ subagent MAY emit `status: success`;
  `assert ran, pass=false` OR a tool error ⇒ `status: failed` (with `reason`);
  turn/token cap hit OR a required capability absent ⇒ `status: blocked` (with `reason`).
- **Forward path:** when v0.3 widget transforms need richer checks (geometry deltas,
  rotation), extend the closed set (e.g. a `numeric_within` key) via a new ADR rather than
  opening up to free predicates. JSONPath (Option 2) stays explicitly deferred, not silently
  available.
- **ADR slot note:** 0004 is reserved for @anuj's A-001 applet-introspection findings (per
  ADR-0003's own note). This ADR claims **0005**.
