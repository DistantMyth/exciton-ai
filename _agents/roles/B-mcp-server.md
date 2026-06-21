# YOUR ROLE: MCP Server Engineer (Role B) — @srujan

Read `_agents/masterplan.md` first. This overlay defines your ownership.

## You own (in `mcp-server/`, Rust or Python)
1. Layer 1 query tools + Layer 2 action tools, each a JSON-Schema'd MCP tool.
2. Element-ID registry + cache (IDs stable across queries within a session; invalidation
   on window/widget lifecycle events).
3. Field projection + depth control (the token-efficiency core).
4. Clients: AT-SPI2 (a11y bus), D-Bus (Role A's `org.kde.PlasmaShell.Introspect` + KWin),
   and the fork-hook client. You are a TRANSLATOR + CACHE + PROJECTOR — never invent state.
5. JSONL event log stream (every request/response/action).
6. Agent briefing layer: MCP `instructions` (compact), `resources` (`plasma://capabilities`,
   `plasma://tools/<name>`, `plasma://format`, `plasma://examples`), and
   `introspect_capabilities()`. All AUTO-GENERATED from your tool schemas + Role A's
   capability registry — never hand-written.
7. `assert_state(query, expect)` tool (machine-checked verify; used by C's subagents).

## Your interfaces (the seams — get these into docs/contracts/ first)
- Author `docs/contracts/mcp-tools.json` (every tool's JSON-Schema; Layer 1, Layer 2,
  `assert_state`). Role C's orchestrator is your client.
- Author `docs/contracts/log.jsonl.schema`. Role D's HITL viewer + task harness read it.
- Consume `docs/contracts/plasma-dbus.xml` from Role A.

## How you work & test
- Stand up a mock D-Bus/AT-SPI2 fixture early so you can build before Anuj's real iface lands.
- Run against the `plasma-ai` user's nested session for real integration.
- Claim tasks under `feat/B-*`.

## Your v0.1 focus (the order matters)
1. **Author the contracts you own:** `mcp-tools.json` + `log.jsonl.schema`. Sign-off is the
   gate for everyone.
2. MCP server skeleton: pick Rust or Python + the MCP SDK; tool registration + transport +
   empty stubs.
3. AT-SPI2 client (a11y tree → element-tree markdown).
4. KWin D-Bus client (desktops/windows) over the **existing** `org.kde.KWin` — no fork
   changes needed for v0.1.
5. Layer 1 query tools wired.
6. Field projection + depth control (token-efficiency core).
7. `instructions` + `plasma://capabilities` resource + `introspect_capabilities()`.
8. JSONL log stream.

## Out of scope
DE source changes (A), subagent lifecycle/models (C), test session provisioning/CI (D).
