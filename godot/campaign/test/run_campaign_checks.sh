#!/bin/sh
# Issue 1654 (R405): the campaign checks after the browser twin's retirement. Godot only; replaces run_parity_campaign.sh and
# run_nem_scenarios.sh in CI.   GODOT=/path/to/godot sh godot/campaign/test/run_campaign_checks.sh [first_seed] [last_seed]
# 1. the two table files carry current checksums (reseal_tables.gd check);
# 2. the seeded bot runs and the Nemesis scenarios match the reviewed saved results (node/saved_campaign.js);
# 3. the Nemesis read check and the map read-only check (unchanged, Godot only).
cd "$(dirname "$0")"; T=$(pwd); P=$(cd ../.. && pwd); G="${GODOT:-godot}"; F=0; mkdir -p out
"$G" --headless --path "$P" --script res://rules/tools/reseal_tables.gd -- check > out/reseal.log 2>&1 || { echo "FAIL: table checksums (out/reseal.log)"; grep FAIL out/reseal.log | head -3; F=$((F+1)); }
GODOT="$G" node node/saved_campaign.js check "${1:-1}" "${2:-30}" || F=$((F+1))
"$G" --headless --path "$P" --script res://campaign/test/nem_read_test.gd > out/nem_read.log 2>&1
grep -E "^Nemesis read: PASS" out/nem_read.log || { echo "FAIL: Nemesis read check (out/nem_read.log)"; grep -E "^FAIL|SCRIPT ERROR" out/nem_read.log | head -5; F=$((F+1)); }
"$G" --headless --path "$P" --script res://campaign/test/map_readonly_test.gd > out/map_readonly.log 2>&1
grep -E "^Map read-only: PASS" out/map_readonly.log || { echo "FAIL: map read-only check (out/map_readonly.log)"; grep -E "^FAIL|SCRIPT ERROR" out/map_readonly.log | head -8; F=$((F+1)); }
if [ $F -eq 0 ]; then echo "PASS: campaign checks (Godot only)"; else echo "FAIL: $F campaign check(s)"; exit 1; fi
