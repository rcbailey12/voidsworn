#!/bin/sh
# Issue 1333 audit: campaign parity with many more save-and-reload steps than the standing check (2% per click, at most 3).
#   RELP=30 RELN=999 GODOT=godot sh run.sh <out_dir> <first_seed> <last_seed>
# Prints one line per seed whose browser and Godot records differ, then DONE. Seeds 1 to 120 at RELP=30: only seed 91 differs (finding F1).
H=$(cd "$(dirname "$0")" && pwd); R=$(cd "$H/../../../../.." && pwd); O=$1; A=$2; Z=$3; G=${GODOT:-godot}
mkdir -p "$O/g" "$O/o"; cd "$R/godot/campaign/test"
for s in $(seq $A $Z); do node "$H/golden_stress.js" $s "$O/g/c$s.jsonl" > /dev/null 2>"$O/g/err$s.txt" || echo "seed $s: JS failed"; done
$G --headless --path "$R/godot" --script "$H/parity_stress.gd" -- "$O/o" $(seq $A $Z) > "$O/godot.log" 2>&1
for s in $(seq $A $Z); do r=$(node node/compare_campaign.js "$O/g/c$s.jsonl" "$O/o/c$s.jsonl" 2>&1 | head -3); case "$r" in PASS*) ;; *) echo "seed $s: $r";; esac; done
echo DONE
