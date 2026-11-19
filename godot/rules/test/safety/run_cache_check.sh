#!/bin/sh
# Godot-only rules safety net. Node only splits files and supervises processes.
# GODOT=/path/to/godot sh godot/rules/test/safety/run_cache_check.sh [options]
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec node "$HERE/run_cache_check.js" "$@"
