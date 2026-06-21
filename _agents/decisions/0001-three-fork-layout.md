# 0001. Three-fork layout: plasma-desktop + plasma-workspace + libplasma

- **Status:** accepted (the *three-fork* decision holds). The *layout* — "Exciton is the
  coordination hub" — is **superseded by ADR-0002** (separate `exciton-ai` hub repo).
- **Date:** 2026-06-21
- **Deciders:** @tarun (D), role assignments A=@anuj B=@srujan C=@rohan
- **Supersedes:** the single-fork assumption in the original masterplan §6.

## Context
Role A's core source-level changes (masterplan §6) don't all live in `plasma-desktop`:

- `org.kde.PlasmaShell.Introspect` D-Bus interface is implemented **in plasmashell**, which
  lives in **plasma-workspace**, not plasma-desktop.
- `Plasma::Applet` base virtuals (`supportedCapabilities()`, `describeSelf()`) live in
  **libplasma**, the Plasma core library.
- Only the **per-applet overrides** (clock, launcher, etc.) and KCMs/containments live in
  plasma-desktop.

So `plasma-desktop` alone is insufficient for Layer 6. We had three options: fork all three;
constrain v0.1 to plasma-desktop-only; or push base virtuals + D-Bus upstream as KDE MRs.

## Options considered
1. **Fork all three** — full power, most work, coherent. Exciton stays coordination hub.
2. **plasma-desktop only** — fastest start, but Layer 6 partially stubbed (no base virtuals,
   no plasmashell D-Bus). Painted into a corner by v0.3.
3. **plasma-desktop + upstream MRs** — cleanest long-term, but blocked on KDE review cycles.

## Decision
**Option 1: fork all three.** (Layout amended by ADR-0002 — see below.)

- `DistantMyth/Exciton` (plasma-desktop fork) — Role A's per-applet overrides.
- `DistantMyth/plasma-workspace` (new fork) — plasmashell D-Bus interface, KWin, capability
  registry, logging hook.
- `DistantMyth/libplasma` (new fork) — `Plasma::Applet` base virtuals.
- `DistantMyth/exciton-ai` (new, per ADR-0002) — **coordination hub**: `_agents/`,
  `docs/contracts/`, AI components live here, not in Exciton.

All four checked out as siblings (e.g. under `~/Projects/`). The three Plasma forks are pure
source with no `_agents/`; all coordination happens in exciton-ai.

## Consequences
- **Enables:** Layer 6 in full; clean ABI for `Plasma::Applet`; real plasmashell D-Bus.
- **Costs:** Role A works across 3 repos; cross-repo ABI must be versioned; build chain
  order matters (**libplasma → plasma-workspace → plasma-desktop**, deps flow down).
- **Cross-repo ABI rule:** bump `org.kde.PlasmaShell.Introspect.Version` when the D-Bus iface
  or capability registry changes; bump `Plasma::Applet` soname when base virtuals change.
  Either → record in `done.md` + a follow-up ADR.
- **Build tooling:** `kdesrc-build` with a 3-module chain config (Role D owns it).
- **Open risk:** three forks drift from upstream; schedule periodic upstream rebases.
