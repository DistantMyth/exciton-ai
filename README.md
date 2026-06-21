# exciton-ai

**Token-efficient desktop introspection & control for KDE Plasma** — an LLM operates the
desktop by querying structured state and invoking semantic actions, not by taking
screenshots. The DE describes itself in cheap markdown; the model reasons over that and acts.

> **This repo is the coordination hub.** It holds the plan, the contracts, the agent
> tooling, and the AI-side components (MCP server, orchestrator, harness). The Plasma
> source-level changes live in three **sibling forks** checked out alongside this one.

## The four repos (check them all out as siblings)

```
~/Projects/
├── exciton-ai/          ← YOU ARE HERE — coordination hub + AI components
├── Exciton/             ← plasma-desktop fork  (per-applet overrides; @anuj)
├── plasma-workspace/    ← plasma-workspace fork (plasmashell D-Bus, KWin, registry; @anuj)
└── libplasma/           ← libplasma fork (Plasma::Applet base virtuals; @anuj)
```

| Repo | What's there | Role |
|------|--------------|------|
| `exciton-ai` | `_agents/` (plan + tasks), `docs/contracts/` (the seams), `mcp-server/`, `orchestrator/`, `harness/` | everyone |
| `Exciton` | plasma-desktop fork — per-applet `describeSelf()` overrides, KCMs, containments | A = @anuj |
| `plasma-workspace` | plasma-workspace fork — `org.kde.PlasmaShell.Introspect`, KWin, capability registry | A = @anuj |
| `libplasma` | libplasma fork — `Plasma::Applet` base virtuals | A = @anuj |

## Start here (every session, every agent — human or AI)
1. Read `_agents/masterplan.md` (the canonical spec).
2. Read your role file in `_agents/roles/{A,B,C,D}.md`.
3. Read `_agents/BACKLOG.md` (the task board) and `_agents/decisions/` (ADRs).

## Team
- **A — @anuj** (Plasma Fork Engineer, 3 forks)
- **B — @srujan** (MCP Server Engineer)
- **C — @rohan** (Orchestrator & Models Engineer)
- **D — @tarun** (Integration, Testing & Workflow Lead — build master)

## Status
v0.1 — contracts + read-only introspection. **Phase 0 contracts in `docs/contracts/` block
everything; no component code ships until they're SIGNED.**

## License
TBD (AI-side tooling). The Plasma forks retain KDE's licensing.
