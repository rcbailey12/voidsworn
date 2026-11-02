'use strict';
const fs = require('node:fs'), vm = require('node:vm');
require('../godot/campaign/test/node/env.js').load();
vm.runInThisContext(String.raw`
const gateAssert=require('node:assert/strict');
// A reference sector generator with the onboarding override removed. Compare complete maps and RNG states.
const legacySectorSource=genSector.toString().replace('function genSector(', 'function legacyGenSector(')
  .replace(/^ *if\(RUN&&RUN\.teachingGate===true&&s===1\).*\n/m, '');
require('node:vm').runInThisContext(legacySectorSource);
function legacyFaction(n){
  const main=RUN.map.fac;
  if(!RUN.foes||n.type!=='battle') return main;
  let h=0; for(const ch of String(n.id)+RUN.sector) h=(h*31+ch.charCodeAt(0))>>>0;
  return h%5===0?RUN.foes[3+(h>>3)%2]:main;
}
function legacyEvent(cfg,force){
  if(!cfg||cfg.kind==='boss') return null;
  if(!force&&rnd()>.45) return null;
  return {k:force&&BEVENTS[force]?force:pick(Object.keys(BEVENTS)),warnR:2,r:ri(3,4)};
}
for(let seed=1;seed<=30;seed++){
  META=defaultMeta(); RUN=null; SAVED_RUN=null; rndSeed(seed); newRun('vex','voidsworn');
  gateAssert.equal(RUN.teachingGate,undefined);
  const before=JSON.stringify(RUN), state=RNG_S;
  const current=genSector(1), end=RNG_S;
  RUN=JSON.parse(before); RNG_S=state;
  gateAssert.deepEqual(current,legacyGenSector(1)); gateAssert.equal(RNG_S,end);
  RUN.map=current;
  for(const n of current.cols.flat()) gateAssert.equal(nodeFaction(n),legacyFaction(n));
  const cfg={node:'0-0',kind:'battle',fac:'chorus'};
  gateAssert.deepEqual(teachingBattle(cfg),cfg); gateAssert.equal(RUN.teachingBattles,undefined);
  for(const teachingBattle of [1,2]) for(const force of [null,'flare','reinf_enemy']){
    const cfg={kind:'battle',teachingBattle}, state=RNG_S;
    const current=rollBattleEvent(cfg,force), end=RNG_S; RNG_S=state;
    gateAssert.deepEqual(current,legacyEvent(cfg,force)); gateAssert.equal(RNG_S,end);
  }
}
console.log('PASS: gate off matches pre-onboarding maps, factions, events and RNG draws for 30 seeds');
// The browser adapter is deliberately absent from bot and parity bundles.
ACT.tipOff=()=>{ META.opts.tipsOff=true; };
`);
const boot = fs.readFileSync(require('node:path').join(__dirname, '..', 'main3d.js'), 'utf8');
vm.runInThisContext(boot.slice(0, boot.indexOf('(async function(){')));
vm.runInThisContext(String.raw`
for(const finished of [0,1,2,3]) for(const tipsOff of [false,true]){
  META=defaultMeta(); META.stats.finishedRuns=finished; META.stats.runs=finished+10; META.opts.tipsOff=tipsOff;
  RUN=null; SAVED_RUN=null; newRun('vex','voidsworn');
  gateAssert.equal(RUN.teachingGate===true,!tipsOff&&finished<2);
  syncTeachingGate(); gateAssert.equal(RUN.teachingGate===true,!tipsOff&&finished<2);
}
META=defaultMeta(); META.stats.runs=2; RUN=null; SAVED_RUN={over:false};
initFinishedRuns(); gateAssert.equal(META.stats.finishedRuns,1);
newRun('vex','voidsworn'); gateAssert.equal(RUN.teachingGate,true); gateAssert.equal(META.stats.finishedRuns,1);
const generatedShape=RUN.map.cols[0][0].teachingShape;
ACT.tipOff(); gateAssert.equal(RUN.teachingGate,false); gateAssert.equal(RUN.map.cols[0][0].shape,generatedShape);
gateAssert.equal('teachingShape' in RUN.map.cols[0][0],false);
META.opts.tipsOff=false; syncTeachingGate(); gateAssert.equal(RUN.teachingGate,true);
endRun(false); gateAssert.equal(META.stats.finishedRuns,2);
newRun('vex','voidsworn'); gateAssert.equal(RUN.teachingGate,undefined);
console.log('PASS: browser gate, tips switch, finished-run threshold and old-save migration');
`);
