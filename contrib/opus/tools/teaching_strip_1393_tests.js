// Issue 1393 (R366, Ryan Nov 20 2026): on a first run Battle 2 opens on Battle 1's open strip, and keeps its Corsairs and the
// forced round 3 to 4 enemy reinforcements. Godot twin: godot/campaign/test/onboarding_test.gd. Run from the repo root.
'use strict';
const vm = require('node:vm');
require('../../../godot/campaign/test/node/env.js').load();
vm.runInThisContext(String.raw`
let pass=0, fail=0;
function check(name, ok){ if(ok){ pass++; console.log('ok    '+name); } else { fail++; console.log('FAIL  '+name); } }
META=defaultMeta(); RUN=null; SAVED_RUN=null; rndSeed(1393); newRun('vex','voidsworn'); RUN.teachingGate=true; RUN.sector=1;
const b1=teachingBattle({node:'a',kind:'battle',fac:'chorus'}), b2=teachingBattle({node:'b',kind:'battle',fac:'chorus'}), b3=teachingBattle({node:'c',kind:'battle',fac:'chorus'});
const strip=c=>c.shape==='open'&&c.arena==='strip'&&c.dep==='line'&&c.edgeFeature===true;
check('Battle 1 is the open strip against the Navy', strip(b1)&&b1.fac==='hegemony');
check('Battle 2 is the open strip too (R366)', strip(b2)&&b2.teachingBattle===2);
check('Battle 2 still fights the Corsairs', b2.fac==='corsair');
const ev=rollBattleEvent(b2,null);
check('Battle 2 still gets the round 3 to 4 enemy reinforcements', !!ev&&ev.k==='reinf_enemy'&&ev.r>=3&&ev.r<=4);
check('Battle 3 keeps its own layout', !strip(b3)&&b3.teachingBattle==null);
console.log(pass+' ok, '+fail+' failed'); if(fail) process.exitCode=1;
`);
