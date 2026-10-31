'use strict';
// Compare unmodified and candidate checkouts on the review's exact map seeds.
// node verify_elite.js <original-repo> <candidate-repo> [seeds=1500]
const path = require('path');
const fs = require('fs');
const vm = require('vm');
const assert = require('assert/strict');
const project = path.resolve(__dirname, '../../../..');
const {loadGame} = require(path.join(project,
  'contrib/codex/proposed/contrib/muse/tools/harness/game_loader.js'));
if (!process.argv[2] || !process.argv[3]) throw Error('Provide original and candidate checkout paths');
const original = path.resolve(process.argv[2]);
const candidate = path.resolve(process.argv[3]);
const seeds = Number(process.argv[4] || 1500);
assert(Number.isInteger(seeds) && seeds > 0);
const oldText = fs.readFileSync(path.join(original,'core.js'),'utf8');
const newText = fs.readFileSync(path.join(candidate,'core.js'),'utf8');
const oldExpression = "const b=c4.find(n=>n.type==='battle')||c4.find(n=>n.type==='event');";
const newExpression = "const b=c4.find(n=>n.type==='battle')||c4.find(n=>n.type==='event')||c4.find(n=>n.type==='shipyard'||n.type==='drydock');";
assert.equal(oldText.split(oldExpression).length-1,1);
assert.equal(newText,oldText.replace(oldExpression,newExpression));
const A=loadGame(original), B=loadGame(candidate);
function generate(G,seed,sector) {
  const run=G.runDefaults();
  run.sector=sector;run.foes=null;run.condsUsed=[];run.regionsUsed=[];
  G.RUN=run;G.rndSeed(seed*31+sector);
  const map=G.genSector(sector);
  return {map,canonical:JSON.stringify(map),rng:vm.runInContext('RNG_S',G._sandbox)};
}
let total=0,unchanged=0;
const repaired=[];
for(let seed=1;seed<=seeds;seed++) for(let sector=1;sector<=3;sector++) {
  const a=generate(A,seed,sector),b=generate(B,seed,sector);
  const hadElite=a.map.cols[4].some(n=>n.type==='elite');
  assert(b.map.cols[4].some(n=>n.type==='elite'),`Missing elite ${seed}/${sector}`);
  if(hadElite) {
    assert.equal(b.canonical,a.canonical,`Unrelated map changed ${seed}/${sector}`);
    assert.equal(b.rng,a.rng,`Unrelated RNG state changed ${seed}/${sector}`);
    unchanged++;
  } else repaired.push({seed,sector,original:a.map.cols[4].map(n=>n.type),candidate:b.map.cols[4].map(n=>n.type)});
  total++;
}
console.log(JSON.stringify({totalMaps:total,previouslyValidMapsByteIdentical:unchanged,
  previouslyValidRngStatesIdentical:unchanged,repairedMaps:repaired.length,remainingEliteFailures:0,
  patchChangesOnlyFallback:true,repaired},null,2));
