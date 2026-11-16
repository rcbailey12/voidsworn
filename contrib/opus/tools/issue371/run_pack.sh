#!/bin/sh
# Issue 371 balance pack, one tree at a time: sh run_pack.sh <tree root> <tag> <out dir>
# Run it once on main (tag before) and once on the branch (tag after), then:
#   node contrib/opus/tools/issue371/balance_delta.js <out dir> before after
# PAIRSEED reseeds before every battle, so both trees field the same fleets on the same draws (true pairs; see sim3d.js).
TREE=$1; TAG=$2; OUT=$3
cd "$TREE" || exit 1
for leg in "fmatrix 24" "bossmatrix 16" "campaign 60"; do
  MODE=${leg% *}; N=${leg#* }
  PAIRSEED=1000 node sim3d.js $MODE $N 2>&1 | grep -v '^\[swarm\]' | tail -60 > "$OUT/p_${TAG}_${MODE}_${N}.txt"
done
SEED=1 node sim3d.js fuzz 300 2>&1 | grep -v '^\[swarm\]' | tail -60 > "$OUT/p_${TAG}_fuzz_300.txt"
