# harness/ — Integration, testing & HITL (Role D)

Owns the test bed everyone builds against. See `_agents/roles/D-integration.md` and
`_agents/masterplan.md` §8 (HOW WE TEST).

## test-session.sh
Bring up / tear down an isolated nested Plasma session for testing:
```bash
./harness/test-session.sh up       # start (writes .session.env)
./harness/test-session.sh status
./harness/test-session.sh env      # print exports for the MCP server / harness
./harness/test-session.sh down
```
> **DRAFT.** Role D replaces the placeholder kwin_wayland/plasmashell invocations with
> real binary paths for this machine.

## Planned (v0.1)
- `task-harness/` — known tasks + per-task token budgets; launches model → orchestrator →
  MCP → test session; scores pass/fail via `assert_state`. This is the v0.1 gate.
- `hitl-viewer/` — TUI that tails `docs/contracts/log.jsonl.schema` records.
- CI config — build/test per component + BACKLOG consistency lint.

Generated state (do not commit): `.session.env`, `.session.pids`, `.logs/`.
