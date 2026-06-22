#!/usr/bin/env bash
# harness/build-forks.sh — plain-CMake build of the 3-fork chain (task D-001 fallback).
#
# Owned by @tarun (Role D). This is the NO-kdesrc-build fallback: it builds the exact same
# dep-order chain (libplasma → plasma-workspace → plasma-desktop, per ADR-0001) using only
# cmake + ninja, which ARE present on this box (kdesrc-build is not, yet).
#
# Why a fallback exists: kdesrc-build is the canonical tool and harness/kdesrc-buildrc is the
# canonical config, but kdesrc-build isn't installed here today (see kdesrc-buildrc header).
# This script unblocks Anuj (Role A) immediately and keeps the install prefix identical
# (~/Projects/AI-Workspace/.install) so test-session.sh is agnostic to which builder ran.
#
# What it does:
#   - for each fork in dep order: cmake -B build -DCMAKE_INSTALL_PREFIX=.install (with
#     CMAKE_PREFIX_PATH chained so plasma-workspace sees libplasma, desktop sees both),
#     then cmake --build + --install.
#   - leaves per-fork build trees at <fork>/build/ for fast incremental rebuilds.
#   - one module failing aborts the whole chain (deps flow down — never build on a broken base).
#
# Usage:
#   ./harness/build-forks.sh                # build all three in order
#   ./harness/build-forks.sh libplasma      # build just one (must already have deps installed)
#   ./harness/build-forks.sh --clean        # wipe build trees first
#   PLASMA_PREFIX=/where ./harness/build-forks.sh   # override install prefix
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd "$HERE/.." && pwd)"
# All three forks are siblings of exciton-ai under the same workspace dir.
PREFIX="${PLASMA_PREFIX:-$WORKSPACE/.install}"
CLEAN=0

usage() { sed -n '2,30p' "${BASH_SOURCE[0]}"; exit "${1:-0}"; }

# dep-ordered list: name -> checkout dir (Exciton is the plasma-desktop fork)
declare -a ORDER=(libplasma plasma-workspace plasma-desktop)
declare -A DIR=( [libplasma]="$WORKSPACE/libplasma" [plasma-workspace]="$WORKSPACE/plasma-workspace" [plasma-desktop]="$WORKSPACE/Exciton" )

while [ $# -gt 0 ]; do
  case "$1" in
    --clean) CLEAN=1; shift ;;
    -h|--help|help) usage 0 ;;
    *) break ;;
  esac
done

# optional: restrict to a subset passed on the command line
if [ $# -gt 0 ]; then
  for m in "$@"; do
    [ -n "${DIR[$m]:-}" ] || { echo "unknown module: $m (known: ${ORDER[*]})"; exit 1; }
  done
  ORDER=("$@")
fi

echo "[build-forks] install prefix: $PREFIX"
echo "[build-forks] chain order:    ${ORDER[*]}"
mkdir -p "$PREFIX"

for mod in "${ORDER[@]}"; do
  src="${DIR[$mod]}"
  build="$src/build"
  [ -d "$src" ] || { echo "[build-forks] missing checkout: $src"; exit 1; }

  echo
  echo "==================== $mod ===================="
  echo "[build-forks] src: $src"

  if [ "$CLEAN" -eq 1 ] && [ -d "$build" ]; then
    echo "[build-forks] cleaning $build"
    rm -rf "$build"
  fi

  # Chain the prefix so each module links against the previously-installed forks.
  # QTDIR/ECM are expected from the system or the user's env; we only chain our own prefix.
  cmake -S "$src" -B "$build" -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DBUILD_TESTING=OFF

  cmake --build "$build"
  cmake --install "$build"

  echo "[build-forks] installed $mod -> $PREFIX"
done

echo
echo "[build-forks] done. chain built: ${ORDER[*]}"
echo "[build-forks] export for the test session:"
echo "  export PLASMA_PREFIX=$PREFIX"
echo "  export PATH=$PREFIX/bin:\$PATH"
