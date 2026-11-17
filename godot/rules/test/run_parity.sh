#!/bin/sh
# Linux/PC twins share the runner, coverage, worker watchdogs and failure diagnostics.
# Usage: GODOT=/path/to/godot PARITY_WORKERS=4 sh godot/rules/test/run_parity.sh [scenario ...]
exec node "$(dirname "$0")/node/run_parity.js" "$@"
