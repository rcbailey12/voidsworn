#!/usr/bin/env node
'use strict';
// JS async boundaries have no synchronous-Godot animation equivalent. Report separately.
const assert=require('assert/strict'),vm=require('vm'),{fs,path,ROOT,BASE,put}=require('./common');
const {loadGame}=require(path.join(ROOT,'contrib/muse/tools/harness/game_loader'));
const results=[];
function fresh(){
 const G=loadGame(ROOT),s=G._sandbox,go=code=>vm.runInContext(code,s);
 go(`Date.now=()=>0; SPEED=0; RUN=runDefaults(); RUN.admiral='vex'; RUN.fac='voidsworn'; RUN.fleet=[newShip('warden'),newShip('harrow')]; RUN.flagUid=RUN.fleet[0].uid;
 function animWeapon(){} function animExplode(){} function animPath(){} function animRotate(){} function animMove(){}
 function fixtureStart(){startBattle({seed:2718,kind:'battle',fac:'hegemony',col:0,obj:'rout',shape:'open',map:'open',dep:'line',enemies:[{tpl:'h_picket'},{tpl:'h_picket'}]}); B.side='player';B.busy=false;}
 fixtureStart();var me=alive('player')[0],target=alive('enemy')[0];target.q=me.q+1;target.r=me.r;B.terrain={};SOLID=null;
 function measured(){return JSON.stringify({round:B.round,side:B.side,over:B.over,units:B.units.map(u=>({id:u.id,q:u.q,r:u.r,facing:u.facing,hp:u.hp,sh:u.sh,mp:u.mp,turnsLeft:u.turnsLeft,dead:u.dead,weapons:u.weapons.map(w=>({fired:w.fired,cdLeft:w.cdLeft,off:w.off}))}))});}
 var shot=me.weapons.findIndex(w=>w.k!=='torp'&&w.k!=='flak'&&canFire(me,w,target));if(shot<0)throw Error('Fixture has no legal direct shot');
 `);
 return {G,s,go};
}
async function check(id,fn){try{await fn();results.push({id,pass:true});console.log('PASS lifecycle '+id);}catch(e){results.push({id,pass:false,error:e.stack});console.error('FAIL lifecycle '+id+': '+e.message);}}
(async()=>{
 await check('previews-preserve-state-and-rng',async()=>{const {go}=fresh(),before=go('measured()'),rng=go('RNG_S');go('computeReach(me);expectedVs(me,me.weapons[shot],target);hitChance(me,me.weapons[shot],target)');assert.equal(go('measured()'),before);assert.equal(go('RNG_S'),rng);});
 await check('duplicate-pending-fire-rejected',async()=>{const {s,go}=fresh();let resume;s.__pause=new Promise(r=>{resume=r;});go('animWeapon=()=>__pause');const first=go('fireWeapon(me,shot,target)'),rng=go('RNG_S');assert.equal(await go('fireWeapon(me,shot,target)'),false);assert.equal(go('RNG_S'),rng);resume();assert.equal(await first,true);});
 await check('epoch-abandoned-shot-restores-gun',async()=>{const {s,go}=fresh();let resume;s.__pause=new Promise(r=>{resume=r;});const before=go('JSON.stringify([me.weapons[shot].fired,me.weapons[shot].cdLeft,me.sureUsed,me.postFire,me.postMp,target.hp,target.sh])');go('animWeapon=()=>__pause');const pending=go('fireWeapon(me,shot,target)');go('B.epoch=(B.epoch||0)+1');resume();assert.equal(await pending,false);assert.equal(go('JSON.stringify([me.weapons[shot].fired,me.weapons[shot].cdLeft,me.sureUsed,me.postFire,me.postMp,target.hp,target.sh])'),before);});
 await check('old-shot-cannot-damage-new-battle',async()=>{const {s,go}=fresh();let resume;s.__pause=new Promise(r=>{resume=r;});go('animWeapon=()=>__pause');const pending=go('fireWeapon(me,shot,target)');go('fixtureStart()');const before=go('measured()'),rng=go('RNG_S');resume();assert.equal(await pending,false);assert.equal(go('measured()'),before);assert.equal(go('RNG_S'),rng);});
 await check('epoch-abandoned-move-does-not-commit',async()=>{const {s,go}=fresh();let resume;s.__pause=new Promise(r=>{resume=r;});go('animPath=()=>__pause;var state=computeReach(me).states.find(s=>s.path.length&&s.path.some(p=>!p.rot));if(!state)throw Error("No reachable movement fixture")');const before=go('measured()'),pending=go('moveUnit(me,state)');go('B.epoch=(B.epoch||0)+1');resume();await pending;assert.equal(go('measured()'),before);});
 await check('stale-late-fire-callback-does-not-run',async()=>{const {s,go}=fresh();let resume;s.__pause=new Promise(r=>{resume=r;});go('var late=null,calls=0;animPath=(u,p,opt)=>{late=opt.onLate;return __pause;};var state=computeReach(me).states.find(s=>s.path.length&&s.path.some(p=>!p.rot));if(!state)throw Error("No reachable movement fixture")');const pending=go('moveUnit(me,state,{onLate:()=>{calls++;}})');go('fixtureStart()');const before=go('measured()'),rng=go('RNG_S');go('late()');resume();await pending;assert.equal(go('calls'),0);assert.equal(go('measured()'),before);assert.equal(go('RNG_S'),rng);});
 const summary={status:results.every(x=>x.pass)?'PASS':'FAIL',scope:'Six current-JS asynchronous action contracts. No renderer, timer-driven stallGuard or native async-equivalence claim.',results,limits:['Only the listed authoritative fields are compared. Preview caches and the B.prog watchdog counter are excluded.','An abandoned shot may already have consumed RNG and usage telemetry; no rollback of those fields is asserted.','This does not cover GPU animation playback, native scene cancellation, every ability/Command or rejected animation promises.']};
 put(path.join(BASE,'evidence/lifecycle_summary.json'),JSON.stringify(summary,null,2)+'\n');process.exitCode=summary.status==='PASS'?0:1;
})().catch(e=>{console.error(e.stack);process.exitCode=2;});
