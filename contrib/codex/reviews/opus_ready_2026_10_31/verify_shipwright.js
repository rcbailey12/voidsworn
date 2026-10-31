'use strict';
// Run against the candidate scratch checkout or a checkout after adoption.
const path = require('path');
const assert = require('assert/strict');
const project = path.resolve(__dirname, '../../../..');
const gameDir = path.resolve(process.argv[2] || project);
const { loadCampaign } = require(path.join(project,
  'contrib/codex/proposed/contrib/muse/tools/findings_tests/campaign_loader.js'));
let passed = 0;
function scenario(label, count, outcome, check, maxMark) {
  const G = loadCampaign(gameDir);
  const run = G.runDefaults();
  run.fac = 'voidsworn'; run.admiral = 'vex';
  run.fleet = Array.from({length:count}, () => G.newShip('warden'));
  for (let i=0; i<count; i++) {
    run.fleet[i].name = 'Same display name';
    if (maxMark && i===0) run.fleet[i].mk=3;
    run.fleet[i].hp=Math.round(G.derive(run.fleet[i]).maxHp*[.2,.5,.8][i]);
  }
  run.flagUid=run.fleet[0].uid; G.RUN=run;
  const before=run.fleet.map(s=>({uid:s.uid,hp:s.hp,mk:s.mk}));
  G.applyOutcome(outcome);
  const full=i=>run.fleet[i].hp===G.derive(run.fleet[i]).maxHp;
  check({run,before,full});
  console.log('PASS '+label); passed++;
}
scenario('three same-named ships repair the two worst hulls',3,{upgradeOne:1,repairOne:1},({run,before,full})=>{
  assert(full(0)&&full(1)); assert.equal(run.fleet[2].hp,before[2].hp);
});
scenario('two ships both repaired',2,{upgradeOne:1,repairOne:1},({full})=>assert(full(0)&&full(1)));
scenario('single ship remains safe',1,{upgradeOne:1,repairOne:1},({full})=>assert(full(0)));
scenario('repair-only keeps its original target',2,{repairOne:1},({run,before,full})=>{
  assert(full(0)); assert.equal(run.fleet[1].hp,before[1].hp);
});
scenario('upgrade-only leaves the companion untouched',2,{upgradeOne:1},({run,before,full})=>{
  assert(full(0)); assert.equal(run.fleet[1].hp,before[1].hp);
});
scenario('max-Mark upgrade still repairs a distinct companion',3,{upgradeOne:1,repairOne:1},({run,before,full})=>{
  assert.equal(run.fleet[0].mk,3); assert(full(0)&&full(1)); assert.equal(run.fleet[2].hp,before[2].hp);
},true);
console.log(passed+'/6 shipwright scenarios passed');
