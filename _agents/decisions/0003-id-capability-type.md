# 0003. Element-ID grammar: add `cap:` type + clarify two-form `act:`

- **Status:** accepted
- **Date:** 2026-06-24
- **Deciders:** @tarun (D) — drives CONTRACT-001
- **Amends:** CONTRACT-001 (element-ids.md), bumping Version 0.1.0 → **0.2.0** (additive).

## Context
While finalizing CONTRACT-006 (capability/action registry), Role A (@anuj) introduced stable IDs
for capability *classes* using a `cap:<name>` vocabulary (e.g. `cap:draggable`), and used
`act:<name>` as a registry-template form distinct from per-instance action refs. CONTRACT-001's
grammar (v0.1.0) only permitted `<type> ::= desktop | win | el | wgt | act`, with `act:` defined
solely as a per-instance ref (`act:<element-id>/<name>`). So CONTRACT-006's `cap:` was outside the
grammar, and its template-form `act:` was ambiguous with the instance form. This is a
cross-contract inconsistency the build master (D) must reconcile, since D drives CONTRACT-001 and
enforces contract consistency.

## Options considered
1. **Add `cap:` to the grammar + bless two-form `act:`** (accepted) — matches A's already-sound
   modeling; additive/backward-compatible; names the real distinction (capability *class* vs
   action *instance*).
2. **Reuse `wgt:`/`el:` for capability classes** — conflates element instances with capability
   classes; a capability is not an element instance.
3. **Drop `cap:`, name capabilities by plain string only** — loses stable, validated IDs in the
   registry and weakens CONTRACT-006's `pattern` constraints for no benefit.
4. **Reject A's `cap:` and force a CONTRACT-001-only design** — ignores that the registry genuinely
   needs class-level IDs; creates churn.

## Decision
**Option 1.** CONTRACT-001 v0.2.0:
- Grammar `<type>` gains `"cap"`.
- New `cap:` type: a capability *class* ID (e.g. `cap:draggable`), from the central registry
  (CONTRACT-006). Names a capability, NOT an instance.
- `act:` clarified as two forms: (a) registry template `act:<action-name>` (the action *class*,
  e.g. `act:rotate`); (b) per-instance ref `act:<element-id>/<action-name>` (e.g.
  `act:wgt:desktop/clock/rotate`), the form used in `invoke_action`.
- CONTRACT-006's `^cap:…` / `^act:…` `pattern` constraints now validate against this grammar.

## Consequences
- **Additive / backward-compatible:** no existing ID changes; consumers that ignore `cap:` are
  unaffected. CONTRACT-001 v0.1.0 → v0.2.0.
- **Enables:** CONTRACT-006 (capability registry) validates as-is; `introspect_capabilities()`
  (CONTRACT-003) can hand the model stable capability/action class IDs.
- **Implementer notes:** `invoke_action` (Layer 2) ALWAYS takes an element-id + action name,
  never a bare `cap:` or `act:` template id. Templates/classes live only in registry output and
  `get_actions` discovery.
- **ADR slot note:** this claims `_agents/decisions/0003`. Role A's A-001 applet-introspection
  findings (originally headed for "0002", then "0003" per the STATUS note) now go to **0004**.
