#!/bin/sh
# G3: the Nemesis campaign scenarios in the JS game and in Godot, compared line by line.  GODOT=... sh run_nem_scenarios.sh
cd "$(dirname "$0")"; T=$(pwd); P=$(cd ../.. && pwd); G="${GODOT:-godot}"; mkdir -p out
node node/nem_scenarios.js out/nem_js.txt > /dev/null || { echo "FAIL: the JS scenarios did not run"; exit 1; }
"$G" --headless --path "$P" --script res://campaign/test/nem_scenarios.gd -- "$T/out/nem_gd.txt" > out/nem_godot.log 2>&1
if [ ! -s out/nem_gd.txt ]; then echo "FAIL: Godot wrote nothing (out/nem_godot.log)"; grep -E "SCRIPT ERROR|ERROR" out/nem_godot.log | head -5; exit 1; fi
if cmp -s out/nem_js.txt out/nem_gd.txt; then echo "PASS: Nemesis scenarios identical ($(wc -l < out/nem_js.txt) records)"; else echo "FAIL: first difference:"; diff out/nem_js.txt out/nem_gd.txt | head -4 | cut -c1-600; exit 1; fi
