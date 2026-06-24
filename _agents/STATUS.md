# STATUS — where we are, right now

> Pinned coordination note. Maintained by **D (@tarun)**. When you start a session, read this
> FIRST, then `masterplan.md`, then your `roles/<role>.md`, then `BACKLOG.md`. Update this file
> when a PR lands, a contract is signed, or the gate moves. Date every change.

**Last updated:** 2026-06-23 by @tarun

---

## TL;DR (relay this to a new joiner)

- **Phase 0 (the contract gate) is PARTIALLY open.** CONTRACT-001 is signed and in review.
  Contracts 002–006 are still DRAFT — each owner must finalize theirs before component code ships.
- **Contracts can start in parallel now.** No strict order among them (one soft coupling:
  CONTRACT-003 ↔ CONTRACT-004 share the `assert_state` shape; B & C co-finalize).
- **Build chain is ready.** `harness/build-forks.sh` builds the 3-fork chain against the system
  packages — verified building on this box (libplasma 485/485, plasma-workspace configures). No
  kdesrc-build needed here.
- **Strict order that does exist:** C-003 (orchestrator) waits on B-001 (server skeleton).
  D-004 (the v0.1 gate) waits on B's read path + C's orchestrator. Anuj writes ZERO C++ in v0.1.

---

## Phase 0 — Contract gate (BLOCKING)

| Contract | File | Author | Consumer | Status | Where |
|----------|------|--------|----------|--------|-------|
| 001 | element-ids.md | D (drives) | all | **REVIEW** — signed by D, pending team ack | PR #1 |
| 002 | plasma-dbus.xml | A | B | DRAFT — needs A to finalize | docs/contracts/ |
| 003 | mcp-tools.json | B | C | DRAFT — needs B to finalize | docs/contracts/ |
| 004 | delegate-task.schema.json | C | B, D | DRAFT — needs C to finalize | docs/contracts/ |
| 005 | log.jsonl.schema | B | D | DRAFT — needs B to finalize | docs/contracts/ |
| 006 | capability-registry.schema.json | A | B | DRAFT — needs A to finalize | docs/contracts/ |

**CONTRACT-001 decision of record:** `win:` IDs are **opaque numeric handles** (`win:42`); app
identity is a separate `app` field. Full rationale in `element-ids.md` § DECISION. All other
contracts use this ID scheme (`win:`, `wgt:`, `el:`, `act:`).

---

## Open PRs

| # | Branch | Owner | What |
|---|--------|-------|------|
| [#1](https://github.com/DistantMyth/exciton-ai/pull/1) | feat/D-CONTRACT-001 | @tarun | CONTRACT-001: opaque `win:` handles; element-ids.md signed |
| [#2](https://github.com/DistantMyth/exciton-ai/pull/2) | feat/D-001 | @tarun | 3-fork build chain (kdesrc-buildrc + build-forks.sh + prerequisites) |

---

## What's unblocked, and for whom

**Can start NOW (parallel):**
- **A (@anuj):** finalize CONTRACT-002 + CONTRACT-006, then A-001 (read-only study → ADR).
  Zero v0.1 C++. Your C++ is v0.3; you don't block anyone's v0.1 implementation.
- **B (@srujan):** finalize CONTRACT-003 + CONTRACT-005 (co-finalize `assert_state` shape with C).
- **C (@rohan):** finalize CONTRACT-004 (co-finalize `assert_state` shape with B). PLUS C-001 +
  C-002 (Ollama setup + 8B benchmark → ADR) have **no dependencies** — start those immediately,
  in parallel with contract work.
- **D (@tarun):** D-002 (test-session real binary paths) next; D-004 (the v0.1 gate) is last.

**Strict order (the only hard cross-person deps in v0.1):**
1. CONTRACT-003/004/005 signed → unblocks B's read path (B-001→B-007).
2. B-001 (server skeleton) exists → unblocks **C-003** (orchestrator = MCP client of B's server).
3. B read path + C orchestrator done → unblocks **D-004** (the v0.1 gate: score 3 read-only tasks).
4. D-004 passes → v0.1 done. D declares it.

**A note for Anuj on A-001:** BACKLOG says write findings to `0002-applet-introspection-findings.md`,
but ADR 0002 is already taken (`0002-separate-hub-repo.md`). **Use 0003.**

---

## Build chain (D-001, ready)

- `exciton-ai/harness/build-forks.sh` — plain-CMake builder, dep order
  libplasma → plasma-workspace → plasma-desktop. Verified: libplasma builds 485/485,
  plasma-workspace configures against it.
- **System state (Arch):** KF6 + ECM at 6.27.0, Qt6 6.11.1, plasma-wayland-protocols 1.21.0 —
  all fork requirements met. See `harness/prerequisites.md`.
- **Plasma-desktop fork is checked out as `Exciton/`**, not `plasma-desktop/` — the build script
  and kdesrc-buildrc both handle this; don't be thrown by the name.
- Build prefix: `~/Projects/AI-Workspace/.install` (`$PLASMA_PREFIX`). Keep it off `/usr`.

---

## Repo layout (ADR-0001 + ADR-0002)

```
~/Projects/AI-Workspace/
├── exciton-ai/         ← COORDINATION HUB + AI components (THIS repo)
│   ├── _agents/        # plan, roles, BACKLOG, done, bugs, decisions/, STATUS.md (this)
│   ├── docs/contracts/ # the seams — sign before building
│   ├── harness/        # D — build chain, test session, task harness, HITL
│   ├── mcp-server/     # B
│   └── orchestrator/   # C
├── Exciton/            ← plasma-desktop fork (@anuj) — pure source
├── plasma-workspace/   ← plasma-workspace fork (@anuj) — pure source
└── libplasma/          ← libplasma fork (@anuj) — pure source
```
**The three Plasma forks contain NO `_agents/` and NO coordination files.** All coordination is
in exciton-ai only. If you're editing a fork, you still read the plan from `../exciton-ai/_agents/`.

---

## How to claim a task (refresher)

1. Read `BACKLOG.md`, find a `[TODO]` line you own.
2. Edit it to `[CLAIMED] @yourhandle`, commit, push.
3. Branch `feat/<role>-<task-id>` (e.g. `feat/B-003`). One task per agent at a time.
4. PR target: AI components + contracts → `exciton-ai/master`; Plasma source → that fork's master.
5. Done → move the line to `done.md` with a one-line summary + PR link.
6. Any architecture change → ADR in `_agents/decisions/` BEFORE coding. One page.
