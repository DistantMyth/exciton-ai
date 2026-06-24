# harness/ — Integration, testing & HITL (Role D)

Owns the test bed everyone builds against. See `_agents/roles/D-integration.md` and
`_agents/masterplan.md` §8 (HOW WE TEST) + ADR-0001 (3-fork build order).

## Building the 3-fork chain (task D-001)

Two builders, same install prefix (`~/Projects/AI-Workspace/.install`):

### 1. CMake fallback — works today (`build-forks.sh`)
No kdesrc-build needed; uses cmake + ninja (both present). Reads the dependency gap first:
```bash
./harness/build-forks.sh            # libplasma → plasma-workspace → plasma-desktop (dep order)
./harness/build-forks.sh libplasma  # one module only
./harness/build-forks.sh --clean    # wipe build trees first
```
**Prerequisite:** the forks need KF6/Qt6/ECM at configure time. See
[`prerequisites.md`](./prerequisites.md) — on this box those are NOT fully satisfied by cmake
`find_package` yet. Install them (distro `-dev` packages or kdesrc-build's `--initial-setup`)
before the first build, or `build-forks.sh` will fail at configure.

### 2. Canonical — kdesrc-build (`kdesrc-buildrc`)
The canonical config once kdesrc-build is installed. It points at our **local** fork checkouts
via `git+file://` so it never re-clones from KDE invent:
```bash
# install once:  git clone https://invent.kde.org/sdk/kdesrc-build ~/kdesrc-build
kdesrc-build --metadata-only --no-include-dependencies libplasma plasma-workspace plasma-desktop
```
(`test-session.sh build` calls this when kdesrc-build is present, else falls back to build-forks.sh.)

Build order is fixed by ADR-0001: **libplasma → plasma-workspace → plasma-desktop** (deps flow
down). A libplasma ABI break → rebuild all three; flag in `done.md`.

## test-session.sh
Bring up / tear down an isolated nested Plasma session for testing:
```bash
./harness/test-session.sh up       # start (writes .session.env)
./harness/test-session.sh status
./harness/test-session.sh env      # print exports for the MCP server / harness
./harness/test-session.sh build    # build the 3-fork chain (kdesrc-build or build-forks.sh)
./harness/test-session.sh down
```
The session runs a dedicated `plasma-ai` user + nested `kwin_wayland` + test `plasmashell` on
its own WAYLAND_DISPLAY/D-Bus/AT-SPI buses, so model-driven actions hit ONLY this session.

## Planned (v0.1)
- `task-harness/` — known tasks + per-task token budgets; launches model → orchestrator →
  MCP → test session; scores pass/fail via `assert_state`. This is the v0.1 gate (D-004).
- `hitl-viewer/` — TUI that tails `docs/contracts/log.jsonl.schema` records (D-005).
- CI config — build/test per component + BACKLOG consistency lint (D-003).

## Files
- `kdesrc-buildrc` — canonical 3-fork kdesrc-build config (local forks via git+file://).
- `build-forks.sh` — plain-CMake fallback builder (same chain, same prefix).
- `prerequisites.md` — machine state + dependency gap (honest, verified).
- `test-session.sh` — isolated test session lifecycle.

Generated state (do not commit): `.session.env`, `.session.pids`, `.logs/`, `<fork>/build/`,
`.install/`.
