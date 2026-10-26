#!/bin/sh
# The G1 parity sweep (cloud / Linux twin of tools/pc/parity_sweep.bat): N random battles, every field varied, each compared
# record by record. Usage: GODOT=/path/to/godot sh godot/rules/test/run_sweep.sh [count] [seed]
cd "$(dirname "$0")"; T=$(pwd); P=$(cd ../.. && pwd); G="${GODOT:-godot}"; N="${1:-200}"; SEED="${2:-1}"
mkdir -p golden/sweep out/sweep; rm -f golden/sweep/*.jsonl out/sweep/*.jsonl
node node/export_data.js ../data/tables.json >/dev/null || exit 1
node node/sweep_gen.js "$N" "$SEED" out/sweep.json
node node/golden.js batch out/sweep.json golden/sweep
"$G" --headless --path "$P" --script res://rules/test/parity_main.gd -- batch "$T/out/sweep.json" "$T/out/sweep" > out/sweep_godot.log 2>&1
grep -m5 'SCRIPT ERROR\|NOT PORTED' out/sweep_godot.log
node node/sweep_check.js out/sweep.json golden/sweep out/sweep
