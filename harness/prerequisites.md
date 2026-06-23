# Build prerequisites — machine state (verified 2026-06-23)

Task D-001. Honest record of what this box has and what it needs to build the 3-fork chain.
Maintained by @tarun (Role D). Re-verify after any toolchain change and update the date.

> **2026-06-23 correction:** the first version of this file (2026-06-21) claimed cmake could
> not find Qt6/KF6/Plasma and concluded kdesrc-build was required. That was wrong — it was
> based on a flawed `cmake --find-package` probe that misreported, and on a misreading of Arch
> package layout (Arch ships headers in the base package, there is no separate `-dev`). The
> real situation is documented below. **kdesrc-build is NOT required on this box.** The full
> chain configures and the base module (libplasma) builds against the upgraded system packages.

## Toolchain present ✓

| tool | path / version |
|------|----------------|
| cmake | `/usr/bin/cmake` |
| ninja | `/usr/bin/ninja` |
| gcc / g++ | `/usr/bin/{gcc,g++}` (GCC 15.x) |
| msgfmt | `/usr/bin/msgfmt` (gettext) |
| git | present |

## System: Arch Linux — provides the full dependency closure

This box runs Arch Linux with KDE Plasma 6 installed from the `extra` repo. Crucially:
- **No `-dev` split on Arch** — headers ship in the base package. `qt6-base`, `kconfig`,
  `extra-cmake-modules` etc. carry everything needed to `find_package` them.
- **KF6 frameworks use classic package names** (`kconfig`, `kcoreaddons`, `kcmutils` …),
  grouped in pacman as `(kf6)`, NOT a `kf6-` prefix.
- **All dependencies our forks declare are satisfiable from `extra`.** No kdesrc-build needed.

### Current versions (verified 2026-06-23, after `pacman -Syu`)

| dependency | installed | required by forks | status |
|------------|-----------|-------------------|--------|
| extra-cmake-modules | 6.27.0-1 | ≥ 6.26.0 | ✓ |
| kconfig / kcoreaddons / … (all 34 KF6 frameworks) | 6.27.0-1 | ≥ 6.26.0 | ✓ |
| qt6-base / declarative / svg / wayland | 6.11.1-1 | ≥ 6.10.0 | ✓ |
| plasma-wayland-protocols | 1.21.0-1 | ≥ 1.10 / ≥ 1.21 | ✓ |
| wayland | 1.25.0-1 | ≥ 1.9 | ✓ |
| wayland-protocols | 1.49-1 | ≥ 1.46 | ✓ |
| plasma-activities | 6.7.0-1 | ≥ 6.6.90 | ✓ |

### What was done to reach this state (history, not a recurring step)
1. System was one minor behind: KF6/ECM at **6.25.0**, forks want **≥ 6.26.0**.
   `find_package(ECM 6.26.0)` rejected 6.25.0 at configure time (confirmed empirically).
2. `plasma-wayland-protocols` was genuinely **not installed** — installed it from `extra`.
3. `pacman -Syu` brought all KF6 frameworks + ECM to **6.27.0** (plus Qt6 6.11.1 etc.). This
   was a large upgrade (815 pkgs incl. linux 6.19→7.0.12, gcc/glibc 15→16); needed a reboot.

## Verified: the chain builds against the system packages

Proven empirically on 2026-06-23 (not assumed):
- **libplasma** — `cmake -S . -B build` then `cmake --build .` → **485/485 targets, exit 0**.
  All 13 KF6 components, ECM, Qt6, PlasmaWaylandProtocols, Wayland, PlasmaActivities resolved.
- **plasma-workspace** — `cmake` configure against the freshly-built libplasma (via
  `CMAKE_PREFIX_PATH=…/.install`) → **exit 0**, "Configuring done". Found Plasma/PlasmaQuick/
  PlasmaActivities from our prefix. Only optional/runtime extras unmet (KIOExtras, KIOFuse,
  PackageKit — none block the build).
- **plasma-desktop (Exciton)** — not yet built this session, but its `find_package` set is a
  subset of plasma-workspace's (Plasma5Support, Plasma, PlasmaQuick, PlasmaActivities) and all
  are present; expected to configure the same way.

So `build-forks.sh` works today with no kdesrc-build and no source dependency closure.

## kdesrc-build — optional, NOT installed

`kdesrc-build` is not on `PATH`. It is **not needed** here because the system packages already
satisfy the dependency closure. `harness/kdesrc-buildrc` remains available as the canonical
config for anyone who prefers it or is on a distro without packaged KF6; install with:
```bash
git clone https://invent.kde.org/sdk/kdesrc-build ~/kdesrc-build
ln -s ~/kdesrc-build/kdesrc-build ~/.local/bin/kdesrc-build
```
It points at our local fork checkouts via `git+file://`, so it never re-clones from KDE invent.

## Paths (canonical, machine-confirmed)

- forks (siblings of exciton-ai): `~/Projects/AI-Workspace/{libplasma,plasma-workspace,Exciton}`
  (note: plasma-desktop fork is checked out as `Exciton/`)
- build prefix (kept off `/usr`): `~/Projects/AI-Workspace/.install` (`$PLASMA_PREFIX`)
- build trees: `<fork>/build/` per module (incremental-friendly)
- system Plasma (reference only, never the test target): `/usr/bin/{kwin_wayland,plasmashell}`

## ABI / re-build triggers (from ADR-0001, owned by D)

- `Plasma::Applet` ABI (soname) change in libplasma → rebuild **all three**; flag in `done.md`.
- `org.kde.PlasmaShell.Introspect.Version` change in plasma-workspace → no rebuild needed,
  but record in `done.md` + ADR (it's a wire-protocol version, not a build dep).

## How to build now

```bash
cd ~/Projects/AI-Workspace/exciton-ai
./harness/build-forks.sh            # libplasma → plasma-workspace → plasma-desktop (dep order)
# or one module:  ./harness/build-forks.sh libplasma
# or via kdesrc-build if installed:  ./harness/test-session.sh build
```
The first build installs libplasma to `.install/` so downstream modules resolve it via
`CMAKE_PREFIX_PATH` — that's the chain linkage, verified working.
