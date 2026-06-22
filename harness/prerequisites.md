# Build prerequisites — machine state (verified 2026-06-21)

Task D-001. Honest record of what this box has and what it needs to build the 3-fork chain.
Maintained by @tarun (Role D). Re-verify after any toolchain change and update the date.

## Toolchain present ✓

| tool | path / version |
|------|----------------|
| cmake | `/usr/bin/cmake` |
| ninja | `/usr/bin/ninja` |
| gcc / g++ | `/usr/bin/{gcc,g++}` |
| msgfmt | `/usr/bin/msgfmt` (gettext) |
| git | present |

## kdesrc-build — NOT installed ✗

`kdesrc-build` is not on `PATH` and `~/kdesrc-build` does not exist. This matters because
kdesrc-build is normally what pulls the **entire KF6/Qt6/ECM dependency closure** that our
three forks need. Two paths forward:

1. **Install kdesrc-build** (preferred — matches ADR-0001 + the canonical config):
   ```bash
   git clone https://invent.kde.org/sdk/kdesrc-build ~/kdesrc-build
   ln -s ~/kdesrc-build/kdesrc-build ~/.local/bin/kdesrc-build
   kdesrc-build --initial-setup    # sets up dependencies via distro packages
   ```
   Then `harness/kdesrc-buildrc` builds our forks (it points at the local checkouts via
   `git+file://`, so kdesrc-build never re-clones from KDE invent).

2. **CMake fallback** (`harness/build-forks.sh`) — works with cmake+ninja only, BUT only if
   the KF6/Qt6/ECM dependencies are satisfied by the system (see gap below).

## Dependency gap (the real blocker)

Our forks' `find_package` needs (verified from each CMakeLists.txt):

- **libplasma**: ECM, Qt6 (Quick/Gui/Qml/Svg/QuickControls2/DBus/GuiPrivate), KF6,
  PlasmaWaylandProtocols 1.10, Qt6WaylandClient.
- **plasma-workspace**: ECM, Qt6, KF6, **Plasma** (= libplasma ✓ our chain), PlasmaQuick,
  PlasmaActivities.
- **plasma-desktop** (Exciton): ECM, Qt6, KF6, Plasma5Support, **Plasma** (= libplasma ✓),
  PlasmaQuick, PlasmaActivities.

cmake `find_package` probe results on this box (2026-06-21):

| package | cmake find_package | pkg-config |
|---------|--------------------|------------|
| ECM | **found** | — |
| Qt6 | **NOT found** | no |
| KF6 (umbrella) | **NOT found** | partial (KF6CoreAddons 6.25.0 present) |
| Plasma / PlasmaQuick / Plasma5Support / PlasmaActivities | **NOT found** | partial (PlasmaActivities 6.6.4) |
| PlasmaWaylandProtocols | **NOT found** | no |

**Conclusion:** a plain CMake build will currently FAIL at configure time on missing Qt6/KF6.
Either (a) install kdesrc-build and let it provision the dependency closure, or
(b) install the distro development packages (`extra-cmake-modules`, `qt6-base -dev`,
`kf6-* -dev`, `plasma-wayland-protocols`) before running `build-forks.sh`.

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
