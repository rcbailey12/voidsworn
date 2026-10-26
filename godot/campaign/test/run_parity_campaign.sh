#!/bin/sh
# G3 campaign parity, cloud / Linux twin of tools/pc/parity_campaign.bat. Same steps, same PASS/FAIL.
#   GODOT=/path/to/godot sh godot/campaign/test/run_parity_campaign.sh [first_seed] [last_seed]     (default seeds 1 to 24)
# 1. checks the campaign tables still match the pinned oracle (re-exports and compares the checksum);
# 2. Node plays each seeded run with the pinned JS files (golden/), Godot plays the same runs (out/);
# 3. compares them step by step and prints PASS, or the first step and field that differ.
cd "$(dirname "$0")"; T=$(pwd); P=$(cd ../.. && pwd); G="${GODOT:-godot}"; F=0; A=${1:-1}; Z=${2:-24}
mkdir -p golden out
node node/export_campaign.js out/tables_check.json > /dev/null || F=$((F+1))
if node -e "const a=require('./out/tables_check.json').sha256,b=require('../data/campaign_tables.json').sha256; process.exit(a===b?0:1)"; then echo "  tables: PASS (match the pinned oracle)"; else echo "  tables: FAIL (campaign_tables.json is stale: run node godot/campaign/test/node/export_campaign.js)"; F=$((F+1)); fi
SEEDS=$(seq "$A" "$Z")
for s in $SEEDS; do node node/golden_campaign.js "$s" "golden/c$s.jsonl" > /dev/null || { echo "  seed $s: the JS run did not finish"; F=$((F+1)); }; done
"$G" --headless --path "$P" --script res://campaign/test/parity_campaign.gd -- "$T/out" $SEEDS > out/godot.log 2>&1
grep -E "SCRIPT ERROR|ERROR:" out/godot.log | head -5
N=0
for s in $SEEDS; do N=$((N+1))
  if [ ! -f "out/c$s.jsonl" ]; then echo "  seed $s: FAIL (Godot wrote nothing; see godot/campaign/test/out/godot.log)"; F=$((F+1)); continue; fi
  if node node/compare_campaign.js "golden/c$s.jsonl" "out/c$s.jsonl" > out/cmp.txt; then echo "  seed $s: $(cat out/cmp.txt)"; rm -f "out/c$s.jsonl" "golden/c$s.jsonl"; else echo "  seed $s: $(cat out/cmp.txt)"; F=$((F+1)); fi
  done
if [ $F -eq 0 ]; then echo "PASS: the Godot campaign matches the game on all $N seeded runs."; else echo "FAIL: $F check(s) differ."; exit 1; fi
