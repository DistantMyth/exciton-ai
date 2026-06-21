# YOUR ROLE: Plasma Fork Engineer (Role A) — @anuj

Read `_agents/masterplan.md` first (esp. §6 + ADR-0001 + ADR-0002). This overlay defines
your ownership.

> **Repo layout (ADR-0002):** `exciton-ai` is the coordination hub (where `_agents/` and
> `docs/contracts/` live); the three forks you edit are siblings. Read the plan from
> `../exciton-ai/_agents/`; author contracts into `../exciton-ai/docs/contracts/`. Your C++
> changes go into the forks, PR'd to each fork's own `master`.

## You own C++/Qt/KDE source across THREE forks (ADR-0001)

**Build order is fixed: libplasma → plasma-workspace → plasma-desktop** (deps flow down).
Use `kdesrc-build` with the chain config Tarun (D) provides
(`../exciton-ai/harness/kdesrc-buildrc`). Check out all three as siblings.

### `DistantMyth/libplasma` — base classes
1. `Plasma::Applet` **base virtuals**:
   - `virtual Capabilities supportedCapabilities() const;` → `{Draggable, Resizable,
     Rotatable, Configurable, …}` (sane defaults: just `Configurable`).
   - `virtual QList<ActionDef> supportedActions() const;` → action defs, each with a JSON
     param schema.
   - `virtual QString describeSelf(Depth depth) const;` → semantic markdown (default impl:
     name + role only — widgets override).
2. Bump `Plasma::Applet` **soname** when these change. Record in `done.md` + follow-up ADR.

### `DistantMyth/plasma-workspace` — plasmashell + KWin
3. New D-Bus interface `org.kde.PlasmaShell.Introspect` **on plasmashell**:
   `listContainments()`, `listApplets(c)`, `appletInfo(id, fields)`, `appletActions(id)`,
   `appletCapabilities(id)`, `appletDescribe(id, depth)`, `appletTransform(id, op, args)`,
   `globalCapabilities()`.
4. Central capability/action registry backing `globalCapabilities()`.
5. KWin: consolidate/document structured workspaces/outputs/tiling + per-surface metadata.
6. Logging hook: every introspection query + action → JSONL stream.
7. Bump `org.kde.PlasmaShell.Introspect.Version` property when (3) or (4) change.

### `DistantMyth/Exciton` (plasma-desktop fork, sibling) — per-applet overrides
8. Per-applet `describeSelf()` / `supportedCapabilities()` / `supportedActions()` overrides:
   digital clock, launcher, systemtray, weather. (The base virtuals from libplasma live
   elsewhere; you implement the overrides here.)
9. Any plasma-desktop KCM/containment changes you need.

## Your interfaces (the seams — get into docs/contracts/ FIRST)
- **Author** `../exciton-ai/docs/contracts/plasma-dbus.xml` (every method/signal you add to
  `org.kde.PlasmaShell.Introspect`). Srujan (B) generates client bindings from it.
  **Author** `../exciton-ai/docs/contracts/capability-registry.schema.json`.
- Keep the `Version` property current so B's client can adapt per-build.
- Cross-repo ABI: libplasma changes affect plasma-workspace + plasma-desktop (ABI break →
  rebuild both). Coordinate rebuilds with Tarun (D).

## How you work & test
- `kdesrc-build` the chain; run in the `plasma-ai` nested session (masterplan §8).
- Smoke-test new D-Bus methods with `dbus-send` / `qdbus` before handing to Srujan.
- Claim tasks in `_agents/BACKLOG.md` under `feat/A-*` branches (PRs go to each fork's own
  `master`, except per-applet overrides which PR to Exciton).

## Out of scope
MCP server (B), orchestrator/models (C), test-session/CI plumbing (D). You implement the DE
side of every contract; you don't consume it.

## Your v0.1 focus
**v0.1 does NOT require fork changes** — it proves the read path over existing AT-SPI2 +
KWin D-Bus. Your v0.1 work is **contracts only**: `plasma-dbus.xml` +
`capability-registry.schema.json`, signed off. Your C++ work starts at v0.3. Use v0.1/v0.2
to study the existing plasmashell D-Bus + `Plasma::Applet` so you're ready.
