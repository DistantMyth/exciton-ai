# 0002. Separate hub repo: exciton-ai

- **Status:** accepted
- **Date:** 2026-06-21
- **Deciders:** @tarun (D)
- **Supersedes:** the "all-in-repo" layout in ADR-0001 (which itself superseded the original
  single-fork assumption). ADR-0001's *three-fork* decision still holds; this ADR only
  changes *where the coordination + AI code lives*.

## Context
ADR-0001 put the coordination hub (`_agents/`, `docs/contracts/`, `harness/`, `mcp-server/`,
`orchestrator/`) inside the Exciton (plasma-desktop) fork, alongside the KDE source. With
three forks in play, this created real friction:

- Anuj (Role A) works across 3 repos but `_agents/` (the plan, tasks, ADRs) only exists in
  one of them — he'd lose context when jumping to plasma-workspace or libplasma.
- The AI-side code (Rust/Python) and the KDE C++ source have nothing in common build-wise;
  co-locating them mixes unrelated build systems.
- Upstream rebases from KDE onto Exciton become messier with extra top-level dirs.
- The "where's the plan?" question has a non-obvious answer (it's in the plasma-desktop fork).

## Options considered
1. **Separate hub repo (`exciton-ai`)** — `_agents/` + AI components live in their own repo,
   checked out as a sibling of the three Plasma forks. Clean separation; plan is always in
   one obvious place; AI build systems are isolated from KDE; upstream rebases on Exciton
   stay clean.
2. **Keep all-in-repo** (ADR-0001's layout) — single clone, but the friction above.

## Decision
**Option 1: separate hub repo `DistantMyth/exciton-ai`.**

Layout (all checked out as siblings):
```
~/Projects/
├── exciton-ai/          ← coordination hub + AI components (THIS repo)
├── Exciton/             ← plasma-desktop fork   (@anuj)
├── plasma-workspace/    ← plasma-workspace fork (@anuj)
└── libplasma/           ← libplasma fork        (@anuj)
```

- `exciton-ai` holds: `_agents/` (plan, tasks, ADRs, roles), `docs/contracts/` (the seams),
  `mcp-server/` (B), `orchestrator/` (C), `harness/` (D). **No Plasma source here.**
- The three Plasma forks are **pure source** — no `_agents/`, no coordination files.
- ADR-0001's three-fork decision, build order (libplasma → plasma-workspace → plasma-desktop),
  and cross-repo ABI rules are unchanged.

## Consequences
- **Enables:** Anuj always knows where the plan is (exciton-ai, regardless of which fork he's
  editing). Clean upstream rebases on all three Plasma forks. AI build systems isolated.
- **Costs:** Four clones instead of three (trivial). Cross-repo references in docs must point
  at sibling paths (`../Exciton`, `../plasma-workspace`, `../libplasma`).
- **Migration:** Exciton's `master` is force-pushed back to upstream-clean; its scaffold
  branch is kept for history. PR #1 on Exciton is closed with a pointer here. All AI files
  now live only in exciton-ai.
- **Branch/PR convention unchanged:** AI components PR to `exciton-ai/master`. Plasma fork
  changes PR to each fork's own `master`.
