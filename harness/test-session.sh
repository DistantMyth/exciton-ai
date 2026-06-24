#!/usr/bin/env bash
# harness/test-session.sh — bring up/tear down an isolated nested Plasma session for testing.
#
# Owned by @tarun (Role D). See _agents/masterplan.md §8 (HOW WE TEST) + ADR-0001.
#
# What this does:
#   - runs a dedicated nested kwin_wayland session on its own WAYLAND_DISPLAY=wayland-test
#   - starts a test plasmashell against it (built from the 3 forks per ADR-0001)
#   - isolates D-Bus (DBUS_SESSION_BUS_ADDRESS) + AT-SPI2 (ATSPI bus) so model-driven
#     actions hit ONLY this session, never the dev's real desktop
#
# The 3-fork build (libplasma → plasma-workspace → plasma-desktop) is owned by
# harness/kdesrc-buildrc (task D-001). This script assumes it's already built and just
# launches the session against the built binaries.
#
# Requirements (install once, owned by @tarun):
#   - the 3 forks built via kdesrc-build (see harness/kdesrc-buildrc, task D-001)
#   - kwin_wayland, plasmashell on PATH (kdesrc-build sets this up) or set PLASMA_PREFIX
#   - dbus-run-session / dbus-daemon, at-spi2-registryd
#
# Usage:
#   ./harness/test-session.sh up     # start the session (writes env to .session.env)
#   ./harness/test-session.sh down   # tear it down
#   ./harness/test-session.sh status # is it up?
#   ./harness/test-session.sh env    # print exports to source for integration tests
#   ./harness/test-session.sh build  # kdesrc-build the 3-fork chain (libplasma→workspace→desktop)
#
# NOTE: DRAFT scaffold. @tarun fills in the real paths/flags for this machine (task D-002).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
ENV_FILE="$HERE/.session.env"
PID_FILE="$HERE/.session.pids"
LOG_DIR="$HERE/.logs"
TEST_USER="${PLASMA_AI_USER:-plasma-ai}"   # dedicated local user (masterplan §8)
WAYLAND_DISPLAY="wayland-test"

mkdir -p "$LOG_DIR"

usage() { sed -n '2,30p' "${BASH_SOURCE[0]}"; exit "${1:-0}"; }

cmd_up() {
  if [ -f "$ENV_FILE" ]; then echo "session already up? ($ENV_FILE exists)"; exit 1; fi
  echo "[$0] bringing up nested Plasma test session as user=$TEST_USER"

  # TODO(Role D): verify the fork is built (PLASMA_PREFIX) and binaries are findable.
  # TODO(Role D): decide whether to run as $TEST_USER via sudo -u or just isolate buses.

  # 1. private D-Bus session
  eval "$(dbus-launch --sh-syntax)"
  export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID

  # 2. private AT-SPI2 bus on this session (so a11y introspection is scoped here)
  # TODO(Role D): start at-spi2-registryd against the above bus.

  # 3. nested kwin_wayland on its own socket
  export WAYLAND_DISPLAY
  # TODO(Role D): real invocation, e.g.:
  #   kwin_wayland --socket="$WAYLAND_DISPLAY" --wayland --x11=none &> "$LOG_DIR/kwin.log" &
  echo "$!" > "$PID_FILE"

  # 4. test plasmashell against this session
  # TODO(Role D): real invocation, e.g.:
  #   PLASMA_USE_QT_SCALING=1 plasmashell &> "$LOG_DIR/plasmashell.log" &
  echo "kwin_pids_placeholder" >> "$PID_FILE"

  # persist env for tests / MCP server to source
  {
    echo "export WAYLAND_DISPLAY='$WAYLAND_DISPLAY'"
    echo "export DBUS_SESSION_BUS_ADDRESS='$DBUS_SESSION_BUS_ADDRESS'"
    echo "export PLASMA_AI_SESSION=1"
  } > "$ENV_FILE"

  echo "[$0] up. env written to $ENV_FILE. logs in $LOG_DIR/"
  echo "[$0] TODO: Role D replaces placeholder invocations with real binaries."
}

cmd_down() {
  [ -f "$PID_FILE" ] || { echo "no session running"; exit 0; }
  echo "[$0] tearing down nested session"
  while read -r pid; do
    [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
  done < "$PID_FILE"
  [ -n "${DBUS_SESSION_BUS_PID:-}" ] && kill "$DBUS_SESSION_BUS_PID" 2>/dev/null || true
  rm -f "$PID_FILE" "$ENV_FILE"
  echo "[$0] down."
}

cmd_status() {
  if [ -f "$ENV_FILE" ]; then echo "up"; cat "$ENV_FILE"; else echo "down"; fi
}

cmd_env() { [ -f "$ENV_FILE" ] && cat "$ENV_FILE" || { echo "no session"; exit 1; }; }

cmd_build() {
  # Build the 3-fork chain in dep order (ADR-0001). Prefer kdesrc-build + harness/kdesrc-buildrc
  # (canonical); fall back to harness/build-forks.sh (plain CMake) when kdesrc-build isn't
  # installed. Both use the same install prefix (~/Projects/AI-Workspace/.install).
  local CFG="$HERE/kdesrc-buildrc"
  local FALLBACK="$HERE/build-forks.sh"
  [ -f "$CFG" ] || { echo "[$0] missing $CFG (task D-001 not done)"; exit 1; }

  if command -v kdesrc-build >/dev/null 2>&1; then
    echo "[$0] building 3-fork chain via kdesrc-build: libplasma → plasma-workspace → plasma-desktop"
    kdesrc-build --metadata-only --no-include-dependencies \
      libplasma plasma-workspace plasma-desktop \
      || { echo "[$0] build failed; see kdesrc-build output"; exit 1; }
  elif [ -x "$FALLBACK" ]; then
    echo "[$0] kdesrc-build not installed; using CMake fallback ($FALLBACK)"
    echo "[$0] NOTE: requires KF6/Qt6/ECM deps — see harness/prerequisites.md"
    "$FALLBACK" "$@" || { echo "[$0] build failed; see $LOG_DIR/build.log"; exit 1; }
  else
    echo "[$0] no builder available: install kdesrc-build or create $FALLBACK (task D-001)"
    exit 1
  fi
}

case "${1:-}" in
  up)      cmd_up ;;
  down)    cmd_down ;;
  status)  cmd_status ;;
  env)     cmd_env ;;
  build)   cmd_build ;;
  -h|--help|help) usage 0 ;;
  *) echo "unknown command: ${1:-}"; usage 1 ;;
esac
