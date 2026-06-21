# docs/contracts/ — the shared seams

This directory holds the **interface contracts** all four roles build against. Per
`_agents/masterplan.md` §9 (v0.1 gate): **no component code ships until the relevant
contract here is signed off.**

## Status legend
Each file carries a `STATUS:` line at the top:
- `DRAFT` — proposed, awaiting sign-off
- `SIGNED` — agreed; build against it. Changing it requires an ADR + bumping the version.

## Files & ownership

| File | Contract ID | Author (Role) | Consumed by |
|------|-------------|---------------|-------------|
| `element-ids.md` | CONTRACT-001 | all (D drives) | everyone |
| `plasma-dbus.xml` | CONTRACT-002 | A | B |
| `mcp-tools.json` | CONTRACT-003 | B | C |
| `delegate-task.schema.json` | CONTRACT-004 | C | B, D |
| `log.jsonl.schema` | CONTRACT-005 | B | D |
| `capability-registry.schema.json` | CONTRACT-006 | A | B |

## Versioning
Every contract has a `Version:` field. Consumers MUST handle unknown versions defensively
(greater-than-known → `introspect_capabilities()` fallback). Bump on any breaking change;
record an ADR in `_agents/decisions/`.
