# orchestrator/ — agent runtime (Role C)

Owns subagent lifecycle, context isolation, the verify gate, hybrid model routing, and the
prompt templates. See `_agents/roles/C-orchestrator.md` and `_agents/masterplan.md`.

## Contracts consumed / produced
- **Produces:** `docs/contracts/delegate-task.schema.json`
- **Consumes:** `docs/contracts/mcp-tools.json` (from Role B); is an MCP client to it.

## Status
Scaffold only. v0.1 work begins once `docs/contracts/` is signed off.
First tasks: C-001 (Ollama + 8B benchmark), C-002 (skeleton: MCP client + main loop).
Layer 3 (`delegate_task` + `assert_state` + summary handback) lands in v0.3.

See `_agents/BACKLOG.md`.
