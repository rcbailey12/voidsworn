#!/bin/sh
# G3: the Nemesis campaign scenarios in the JS game and in Godot, compared line by line.  GODOT=... sh run_nem_scenarios.sh
cd "$(dirname "$0")"; T=$(pwd); P=$(cd ../.. && pwd); G="${GODOT:-godot}"; mkdir -p out
node node/nem_scenarios.js out/nem_js.txt > /dev/null || { echo "FAIL: the JS scenarios did not run"; exit 1; }
"$G" --headless --path "$P" --script res://campaign/test/nem_scenarios.gd -- "$T/out/nem_gd.txt" > out/nem_godot.log 2>&1
if [ ! -s out/nem_gd.txt ]; then echo "FAIL: Godot wrote nothing (out/nem_godot.log)"; grep -E "SCRIPT ERROR|ERROR" out/nem_godot.log | head -5; exit 1; fi
if cmp -s out/nem_js.txt out/nem_gd.txt; then echo "PASS: Nemesis scenarios identical ($(wc -l < out/nem_js.txt) records)"; else echo "FAIL: first difference:"; diff out/nem_js.txt out/nem_gd.txt | head -4 | cut -c1-600; exit 1; fi
# Issue 364: a Nemesis reader asks the campaign, not the cached field (headless, real start-run and boss-advance functions).
"$G" --headless --path "$P" --script res://campaign/test/nem_read_test.gd > out/nem_read.log 2>&1
if [ $? -ne 0 ]; then echo "FAIL: Nemesis read check (out/nem_read.log)"; grep -E "^FAIL|SCRIPT ERROR" out/nem_read.log | head -5; exit 1; fi
grep -E "^Nemesis read: PASS" out/nem_read.log || { echo "FAIL: Nemesis read check wrote no PASS line (out/nem_read.log)"; exit 1; }
# Issue 344 (Muse's check of PR 349, condition 1): the campaign map only reads. Opening the map, the Dossier and the Map key
# never creates or changes the Nemesis record, the run, the save or the random stream (headless, real runs, the real screen).
"$G" --headless --path "$P" --script res://campaign/test/map_readonly_test.gd > out/map_readonly.log 2>&1
if [ $? -ne 0 ]; then echo "FAIL: map read-only check (out/map_readonly.log)"; grep -E "^FAIL|SCRIPT ERROR" out/map_readonly.log | head -8; exit 1; fi
grep -E "^Map read-only: PASS" out/map_readonly.log || { echo "FAIL: map read-only check wrote no PASS line (out/map_readonly.log)"; exit 1; }
