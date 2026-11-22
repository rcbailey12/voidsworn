#!/bin/sh
# Compare Godot cache on/off on a seeded set of battles drawn from the live rules tables.
# Usage: GODOT=/path/to/godot sh godot/rules/test/run_sweep.sh [count] [seed]
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)" || exit 1
exec node "$HERE/safety/run_cache_check.js" --cache-only --sweep "${1:-200}" "${2:-1}"
