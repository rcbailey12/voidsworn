#!/bin/sh
# Cloud / Linux twin of tools/pc/parity.bat: same steps, same PASS/FAIL. Usage: GODOT=/path/to/godot sh run_parity.sh
cd "$(dirname "$0")"; R=$(pwd); G="${GODOT:-godot}"; F=0; mkdir -p golden out
gd() { "$G" --headless --path "$R" --script res://main.gd -- "$@" >> out/godot.log 2>&1; }
node node/export_data.js data/tables.json || F=$((F+1))
for s in 1001 7 4242424242; do node node/golden.js prng $s 10000 golden/prng_$s.txt >/dev/null; gd prng $s 10000 "$R/out/prng_$s.txt"
  if node node/compare.js same golden/prng_$s.txt out/prng_$s.txt > out/cmp.txt; then echo "  seed $s: PASS"; else echo "  seed $s: FAIL"; cat out/cmp.txt; F=$((F+1)); fi; done
node node/golden.js math golden/math.txt >/dev/null
if "$G" --headless --path "$R" --script res://main.gd -- math "$R/golden/math.txt" > out/math.txt 2>&1; then echo "  math: PASS ($(grep '^math' out/math.txt))"; else echo "  math: FAIL"; grep '^math' out/math.txt; F=$((F+1)); fi
for b in s1 s2 s3 s4 s5; do node node/golden.js scenario $b golden/$b.jsonl >/dev/null; gd scenario $b "$R/out/$b.jsonl"
  if node node/compare.js scenario golden/$b.jsonl out/$b.jsonl > out/cmp.txt; then echo "  battle $b: PASS ($(head -1 out/cmp.txt))"; else echo "  battle $b: FAIL"; cat out/cmp.txt; F=$((F+1)); fi; done
echo "Enemy think time (report only; game bar: worst under about 0.5 s):"; for b in s4 s5; do node node/timing.js $b golden/$b.jsonl.timing.json out/$b.jsonl.timing.json; done
if [ $F -eq 0 ]; then echo "PASS: the Godot port matches the game's rules exactly."; else echo "FAIL: $F check(s) differ."; exit 1; fi
