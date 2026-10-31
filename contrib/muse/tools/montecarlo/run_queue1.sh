#!/bin/bash
# Policy sensitivity batch, queue 1: chorus, voidsworn, hegemony x 4 policies.
cd ~/workspace/voidsworn-montecarlo || exit 1
run() { # fac seed0
  for pol in baseline rusher turtle hunter; do
    if [ ! -s "raw/pol_${pol}_$1.json" ] || ! grep -q '"done":1100' "raw/pol_${pol}_$1.json"; then
      echo "=== $1 $pol seed0=$2 $(date +%H:%M:%S) ==="
      node shard.js --out "raw/pol_${pol}_$1.json" --n 1100 --seed0 "$2" --ai veteran --fac "$1" --policy "$pol" > "raw/pol_${pol}_$1.log" 2>&1
    else
      echo "=== $1 $pol already complete, skipped ==="
    fi
  done
}
run chorus 500000
run voidsworn 400000
run hegemony 460000
echo "QUEUE1 DONE $(date +%H:%M:%S)"
