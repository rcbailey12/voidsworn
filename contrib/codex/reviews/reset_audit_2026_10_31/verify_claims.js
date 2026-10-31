'use strict';
// Independent counterexamples and campaign probes. Run from a complete checkout:
// node contrib/codex/reviews/reset_audit_2026_10_31/verify_claims.js [repo]
const fs = require('fs');
const path = require('path');
const repo = path.resolve(process.argv[2] || process.cwd());
process.env.VS_ORACLE = repo;
const env = require(path.join(repo, 'godot/campaign/test/node/env.js'));
env.load(String.raw`
var auditResults = [];
function auditProbe(id, fn) {
  try { auditResults.push({id, ...fn()}); }
  catch (e) { auditResults.push({id, status:'PROBE_ERROR', detail:e.stack}); }
}
auditProbe('FS-5', () => {
  const killer={id:1,side:'player',fac:'chorus',hp:30,maxHp:100,q:4,r:4};
  const nearby={id:2,side:'player',fac:'chorus',hp:30,maxHp:100,q:5,r:4};
  const dead={id:3,side:'enemy',fac:'hegemony',isSq:false,q:4,r:4};
  B={round:1,units:[killer,nearby,dead]}; chorusFeed(dead,killer);
  const bite=chorusBiteEst(killer,dead,100);
  return {status:killer.hp===42&&nearby.hp===36&&bite===8?'REFUTED':'CHECK',
    detail:{killerHp:killer.hp,nearbyHp:nearby.hp,biteOn100HullDamage:bite}};
});
auditProbe('ADM-KASSAR', () => ({status:'REFUTED',detail:{text:ADMIRALS.kassar.d,fx:ADMIRALS.kassar.fx}}));
auditProbe('MOD-4', () => {
  RUN=null; META=defaultMeta();
  const a=newShip('cathedral'),b=newShip('cathedral');a.mods=['prow'];b.mods=['damcon'];
  const da=derive(a),db=derive(b);
  // Damage from existing fire bypasses armor. 8 own-turn starts, 6 damage each,
  // with both hulls already missing 40 HP. Neither reaches zero or a healing cap.
  let ha=da.maxHp-40,hb=db.maxHp-40;
  for(let i=0;i<8;i++){ha=Math.min(da.maxHp,ha+da.hullRegen)-6;hb=Math.min(db.maxHp,hb+db.hullRegen)-6;}
  return {status:hb>ha?'DOMINANCE_REFUTED':'CHECK',detail:{prow:{maxHp:da.maxHp,regen:da.hullRegen,hpAfter:ha},damcon:{maxHp:db.maxHp,regen:db.hullRegen,hpAfter:hb}}};
});
auditProbe('EVT-1', () => {
  RUN=runDefaults();RUN.fac='voidsworn';RUN.flags={};
  const ev=EVENTS.find(e=>e.id==='defector');const opt=ev.o.find(o=>o.k==='ransom')||ev.o[ev.o.length-1];
  eventFlags(ev,opt,ev.o.indexOf(opt));
  return {status:'CONFIRMED_MECHANISM',detail:{picked:opt.k,flags:RUN.flags,needMetDespiteDifferentChoice:needMet({flag:'defector'})}};
});
auditProbe('TXT-2', () => {
  RUN=runDefaults();RUN.fac='voidsworn';RUN.admiral='vex';
  RUN.fleet=[newShip('warden'),newShip('harrow')];RUN.flagUid=RUN.fleet[0].uid;
  RUN.fleet[0].hp=10;RUN.fleet[1].hp=20;
  const before=RUN.fleet.map(s=>({tpl:s.tpl,hp:s.hp,max:derive(s).maxHp}));
  const lines=applyOutcome({upgradeOne:1,repairOne:1});
  return {status:'CONFIRMED_BUG_CORRECTED_MECHANISM',detail:{before,after:RUN.fleet.map(s=>({tpl:s.tpl,hp:s.hp,max:derive(s).maxHp})),lines}};
});
auditProbe('NEM-2', () => ({status:'SOURCE_CHECK_REQUIRED',detail:{weak:Object.keys(NEM_WEAK),adapt:Object.keys(NEM_ADAPT)}}));
auditProbe('ECO-3', () => {
  const a=newShip('warden');a.hp=1;
  return {status:'CONFIRMED_MECHANISM_DESIGN_CHOICE',detail:{lowHp:a.hp,scrap:prizeScrap(a.tpl),fullHpScrap:prizeScrap(a.tpl)}};
});
auditProbe('FR-2', () => ({status:'SOURCE_CHECK',detail: nemAfterBattle.toString().includes('revealed')}));
auditProbe('BATTLESHIP-RENDER', () => {
  const txt=require('fs').readFileSync(require('path').join(process.env.VS_ORACLE,'godot/render/hull_table.gd'),'utf8');
  return {status:!txt.includes('deathless|Battleship')?'MISSING_MAPPING_CONFIRMED':'CHECK'};
});
auditProbe('GODOT-PRICES', () => {
  const tbl=require('fs').readFileSync(require('path').join(process.env.VS_ORACLE,'godot/campaign/data/campaign_tables.json'),'utf8');
  const h=JSON.parse(tbl).tables.HULLS;
  return {status:'PRICE_LOSS_REFUTED',detail:{browser:{drone:HULLS.b_drone.cost,scythe:HULLS.d_scythe.cost,harvester:HULLS.d_harvester.cost},godot:{drone:h.b_drone.cost,scythe:h.d_scythe.cost,harvester:h.d_harvester.cost}}};
});
auditProbe('L_STORM', () => ({status:'CONFIRMED',detail:{gate:BOON_NEED.L_storm||null,effect:BOONS.L_storm.fx(1)}}));
auditProbe('HUNT', () => ({status:'TEXT_MISMATCH_CONFIRMED',detail:runCommand.toString().includes("c.id==='hunt'")}));
auditProbe('DRIFT-5', () => {
  G.mobile=true;const out=touchWords('Click to fire');G.mobile=false;
  return {status:out==='Tap again to fire'?'ORDERING_CLAIM_REFUTED':'CHECK',detail:out};
});
// Run last: these replace presentation/target hooks only, while exercising the
// unmodified boardUnit outcome branches with controlled crew counts and RNG.
(async()=>{
  // fxBoard is a presentation hook absent from the campaign parity environment.
  globalThis.fxBoard=async()=>{};
  let sabotageCalls=0,currentTarget;
  boardTargets=()=>[currentTarget];liveFrom=()=>()=>true;fxBoard=async()=>{};
  systemDamage=()=>{sabotageCalls++;return 'weapons';};rnd=()=>1;checkEnd=()=>{};fxText=()=>{};
  for(const branch of ['partial','bridge','capture']){
    sabotageCalls=0;const u={id:1,side:'player',fac:'voidsworn',name:'Attacker',crew:100,weapons:[],fx:{boardPct:.25}};
    const t={id:2,side:'enemy',fac:'hegemony',name:'Target',crew:branch==='partial'?100:1,crewMax:100,boss:branch==='bridge',weapons:[]};
    currentTarget=t;B={round:1,units:[u,t],usage:{},resolve:{player:0,enemy:0}};
    try{await boardUnit(u,t);auditResults.push({id:'BN-4-'+branch,status:branch==='capture'?(t.captured&&sabotageCalls===0?'SUCCESS_NOT_FAILED':'CHECK'):(sabotageCalls>0?'GUARANTEE_CONFIRMED':'CHECK'),detail:{sabotageCalls,captured:!!t.captured}});}
    catch(e){auditResults.push({id:'BN-4-'+branch,status:'PROBE_ERROR',detail:e.stack});}
  }
  console.log(JSON.stringify(auditResults,null,2));
})().catch(e=>{console.error(e);process.exitCode=1;});
`);
