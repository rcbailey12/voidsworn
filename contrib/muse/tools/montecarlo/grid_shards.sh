#!/bin/bash
# Phase 3a/3b grid shards. Run AFTER the main batch finishes (CPU contention).
# Process A runs the chorus/eclipse price+CP rows; process B the healing rows.
cd /home/hatch/workspace/voidsworn-montecarlo
if [ "$1" = "a" ]; then
  node shard.js --out raw/grid_chorus_p80.json    --n 300 --seed0 20000 --ai veteran --fac chorus   --priceMult 0.8
  node shard.js --out raw/grid_chorus_p80cp.json  --n 300 --seed0 21000 --ai veteran --fac chorus   --priceMult 0.8 --cpDelta 4
  node shard.js --out raw/grid_chorus_cp.json     --n 300 --seed0 22000 --ai veteran --fac chorus   --cpDelta 4
  node shard.js --out raw/grid_eclipse_p125.json  --n 300 --seed0 23000 --ai veteran --fac deathless --priceMult 1.25
  node shard.js --out raw/grid_eclipse_p125cp.json --n 300 --seed0 24000 --ai veteran --fac deathless --priceMult 1.25 --cpDelta -2
  echo GRID_A_DONE
else
  node shard.js --out raw/grid_heal_post0.json   --n 300 --seed0 30000 --ai veteran --fac voidsworn --replace 'campaign3d.js:::Math.round(mx*.15):::Math.round(mx*0)'
  node shard.js --out raw/grid_heal_post30.json  --n 300 --seed0 31000 --ai veteran --fac voidsworn --replace 'campaign3d.js:::Math.round(mx*.15):::Math.round(mx*.3)'
  node shard.js --out raw/grid_heal_tr0.json     --n 300 --seed0 32000 --ai veteran --fac voidsworn --replace 'campaign_run.js:::d.maxHp*.4*repairMult():::d.maxHp*0*repairMult()'
  node shard.js --out raw/grid_heal_tr20.json    --n 300 --seed0 33000 --ai veteran --fac voidsworn --replace 'campaign_run.js:::d.maxHp*.4*repairMult():::d.maxHp*.2*repairMult()'
  node shard.js --out raw/grid_heal_pay07.json   --n 300 --seed0 34000 --ai veteran --fac voidsworn --replace 'campaign_run.js:::(25+12*s+3*(cfg.col||0)):::(25+12*s+3*(cfg.col||0))*.7'
  node shard.js --out raw/grid_heal_pay15.json   --n 300 --seed0 35000 --ai veteran --fac voidsworn --replace 'campaign_run.js:::(25+12*s+3*(cfg.col||0)):::(25+12*s+3*(cfg.col||0))*1.5'
  echo GRID_B_DONE
fi
