# mcp-server/ — plasma-ai MCP server (Role B)

The model-facing layer. See `_agents/roles/B-mcp-server.md` and `_agents/masterplan.md`.

This is a TRANSLATOR + CACHE + PROJECTOR over the desktop's real state — it never invents
state. It exposes Layer 1 query tools + Layer 2 action tools + `assert_state`, plus the
auto-generated agent briefing (`instructions`, `resources`, `introspect_capabilities`).

## Contracts consumed / produced
- **Produces:** `docs/contracts/mcp-tools.json`, `docs/contracts/log.jsonl.schema`
- **Consumes:** `docs/contracts/plasma-dbus.xml` (from Role A)

## Status
Scaffold only. v0.1 work begins once `docs/contracts/` is signed off (CONTRACT-001…006).
Pick Rust or Python + the MCP SDK, then start on BACKLOG tasks B-001…B-007.

See `_agents/BACKLOG.md`.
