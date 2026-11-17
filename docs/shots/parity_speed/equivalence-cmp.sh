#!/bin/sh
# Run from the proof folder. PARITY_FIXTURES points at the unchanged scenarios.json.
names=$(node -e "console.log(Object.keys(JSON.parse(require('fs').readFileSync(process.env.PARITY_FIXTURES,'utf8'))).join(' '))") || exit 1
count=0
for b in $names; do
  for side in golden out; do
    for pair in 'serial/godot/rules/test parallel-normal' 'serial-reversed/godot/rules/test parallel-reversed' 'serial/godot/rules/test serial-reversed/godot/rules/test' 'parallel-normal parallel-reversed' 'serial/godot/rules/test parallel-final'; do
      set -- $pair
      if ! cmp -s "$1/$side/$b.jsonl" "$2/$side/$b.jsonl"; then
        echo "FAIL: $b, $side, $1 against $2 (cmp -s)"
        exit 1
      fi
    done
  done
  count=$((count+1))
  echo "  $b: PASS (cmp -s, both record writers, both orders, serial and parallel)"
done
echo "PASS: $count battles, 10 byte comparisons per battle, no changed records."
