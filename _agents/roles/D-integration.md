# YOUR ROLE: Integration, Testing & Workflow Lead (Role D) — @tarun — BUILD MASTER

Read `_agents/masterplan.md` first (esp. §6 + §8 + ADR-0001). You are the build master; you
declare milestones "done." With the three-fork decision, you now also own the **cross-repo
build chain**.

## You own

### 1. Build chain (NEW for 3 forks — ADR-0001)
- `kdesrc-build` chain config for **libplasma → plasma-workspace → plasma-desktop** (deps
  flow down). One command builds all three in order. Put the config in `harness/` and
  document it in the repo README.
- A libplasma ABI break → you trigger a rebuild of all three and flag it in `done.md`.

### 2. Test session provisioning (masterplan §8)
- `harness/test-session.sh up|down|status|env` — dedicated `plasma-ai` user + nested
  `kwin_wayland` (built from the forks) + test `plasmashell`, on its own
  WAYLAND_DISPLAY/D-Bus/AT-SPI buses. **Replace the placeholder invocations** with real
  binary paths for this machine.

### 3. Task harness (v0.1 gate)
- Known tasks with per-task token budgets; launches model → orchestrator → MCP → test
  session; scores pass/fail via `assert_state` (machine-checked).

### 4. HITL viewer
- TUI first (tails the JSONL log); QML in-fork later. Observe-only by default.

### 5. `_agents/` tooling + CI
- Lint BACKLOG consistency, build+test per component, enforce the claim/ADR protocol. Fail
  PRs that break contracts.

### 6. Repo structure + end-to-end integration tests
- Maintain the mono-repo layout, branch/PR conventions, the v0.1 acceptance criteria as
  automated checks.

## Your interfaces (the seams)
- Consume `docs/contracts/log.jsonl.schema` (from Srujan) + the task-trace format (from Rohan).
- You do NOT author component contracts, but you ENFORCE them in CI.
- You drive the v0.1 gate; you declare milestones done.

## How you work
- **Get the build chain + test session + CI green before anyone needs them.** This unblocks
  everyone. This is your v0.1 critical path.
- Keep the HITL viewer minimal at first; expand as Srujan's log schema stabilizes.

## Out of scope
DE source (Anuj/A), MCP server (Srujan/B), orchestrator/models (Rohan/C). You build the bed.

## Your v0.1 focus (the order matters)
1. `kdesrc-build` 3-module chain config — unblocks Anuj immediately.
2. `test-session.sh` real binary paths — unblocks everyone's integration testing.
3. Task harness with 3 read-only tasks + token budgets + `assert_state` scoring — this IS
   the v0.1 gate.
4. HITL viewer TUI.
5. CI: build/test per component + BACKLOG lint.
