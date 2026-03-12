#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
TOP="verilog_practical_starter"
OPEN_WAVE=0

if [[ "${1:-}" == "--wave" ]]; then
    OPEN_WAVE=1
fi

if ! command -v iverilog >/dev/null 2>&1; then
    echo "error: 'iverilog' is not installed or not in PATH" >&2
    exit 1
fi

if ! command -v vvp >/dev/null 2>&1; then
    echo "error: 'vvp' is not installed or not in PATH" >&2
    exit 1
fi

mkdir -p "$BUILD_DIR"

pushd "$BUILD_DIR" >/dev/null
iverilog -o "${TOP}.out" "../${TOP}.v"
vvp "${TOP}.out"
popd >/dev/null

echo "simulation complete: $BUILD_DIR/${TOP}.vcd"

if [[ "$OPEN_WAVE" -eq 1 ]]; then
    if ! command -v gtkwave >/dev/null 2>&1; then
        echo "error: 'gtkwave' is not installed or not in PATH" >&2
        exit 1
    fi

    gtkwave "$BUILD_DIR/${TOP}.vcd"
fi
