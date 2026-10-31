#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path'),vm=require('vm'),assert=require('assert');
const ROOT=path.resolve(__dirname,'../../../..');
const {loadCampaign}=require(path.join(ROOT,'contrib/muse/tools/findings_tests/campaign_loader'));
const {loadUI}=require(path.join(ROOT,'contrib/muse/tools/findings_tests/ui_loader'));
const probe=require(path.join(ROOT,'contrib/muse/tools/findings_tests/battle_probe'));
const Model=require('../src/lineage').create(require('../data/catalog.json'),require('../data/roster.json'));
const Pilot=require('../src/pilot');
function hex(v){const b=Buffer.alloc(8);b.writeDoubleBE(v);return b.toString('hex');}
function clean(v){if(typeof v==='number'&&(!Number.isInteger(v)||Math.abs(v)>=9007199254740992))return 'd:'+hex(v);if(Array.isArray(v))return v.map(clean);if(v&&typeof v==='object'){const o={};for(const k of Object.keys(v).sort())if(!['t','ship','log','prog','cfg'].includes(k)&&v[k]!==null&&v[k]!==undefined&&typeof v[k]!=='function')o[k]=clean(v[k]);return o;}return v;}
function encode(v){if(typeof v==='number'&&(!Number.isInteger(v)||Math.abs(v)>=9007199254740992))return '#d:'+hex(v);if(Array.isArray(v))return v.map(encode);if(v&&typeof v==='object')return Object.fromEntries(Object.entries(v).map(([k,x])=>[k,encode(x)]));return v;}
function fixture(repo,mode,distance,seed,option={}){
 const G=loadCampaign(repo),runIn=probe.installBattleProbe(G);G.META=G.defaultMeta();runIn('Date.now=()=>0;');G.rndSeed(seed*37);
 probe.probeBattle(G,{player:option.boundary?['i_song']:option.intent==='flak'?['i_song','i_blade','warden']:['i_song','i_blade'],enemies:option.boundary?['h_picket']:['h_picket','h_picket'],fac:'hegemony',seed,map:null,obj:'rout'});probe.clearTerrain(G);
 G.RUN.admiral=option.other?'vex':'vaelen';G.RUN.fac='ithar';if(option.alt)G.RUN.cmdOverride={id:'barrage',n:'Alternate Command'};
 if(mode!==null)G.RUN.lineagePilot={version:1,admiral:'vaelen',xpQ:300,picks:[mode]};
 if(option.boundary)G.B.units.find(u=>u.side==='player').weapons=G.B.units.find(u=>u.side==='player').weapons.slice(0,1);
 const players=G.B.units.filter(u=>u.side==='player'&&!u.isSq),enemies=G.B.units.filter(u=>u.side==='enemy'&&!u.isSq);
 players.forEach((u,i)=>{probe.place(u,5+i,8+i*2,0);u.postFire=false;u.postMp=2;u.weapons.forEach(w=>{w.fired=true;w.cdLeft=2;});});
 enemies.forEach((u,i)=>{probe.place(u,5+i+distance,8+i*2,3);u.hp=u.maxHp=10000;u.shMax=0;u.sh=[0,0,0,0];u.ev=0;});
 G.B.round=3;G.B.side='player';G.B.cmdUsed=false;G.B.activeUnit=null;
 if(option.intent){const u=option.intent==='flak'?players.find(x=>x.weapons.some(w=>w.k==='flak')):players[0];G.B.lineageIntent={[u.id]:option.intent==='invalid'?-1:option.intent==='flak'?u.weapons.findIndex(w=>w.k==='flak'):u.weapons.findIndex(w=>w.k==='lance')};}
 G.rndSeed(seed);
 return {G,runIn,players,enemies};
}
async function run(work){
 const dirs=JSON.parse(fs.readFileSync(path.join(work,'paths.json'))),input={battles:[],rewards:[],snapshots:[]},rows=[],controls=[];
 for(let seed=1;seed<=8;seed++)for(const [label,mode,distance,option] of [
  ['off',null,6,{}],['off-near',null,3,{boundary:true}],['long-near',Pilot.KEYS[0],3,{boundary:true}],['long-far',Pilot.KEYS[0],6,{}],
  ['single',Pilot.KEYS[1],6,{intent:'single'}],['normal-option',Pilot.KEYS[1],6,{}],
  ['invalid-index',Pilot.KEYS[1],6,{intent:'invalid'}],['invalid-flak',Pilot.KEYS[1],6,{intent:'flak'}],
  ['no-target',Pilot.KEYS[1],20,{intent:'single'}],['alternate',Pilot.KEYS[0],6,{alt:true}],['other-admiral',Pilot.KEYS[0],6,{other:true}]
 ]){
  const {G,runIn,players}=fixture(dirs.overlay,mode,distance,seed,option),before=JSON.parse(JSON.stringify(G.B));
  const globals=runIn('({BW,BH,UID,CUT:CUT?[...CUT]:null,SOLID:SOLID?[...SOLID]:null,ARENA})');
  input.battles.push({id:label+':'+seed,battle:before,run:JSON.parse(JSON.stringify(G.RUN)),globals,seed});
  const weapons=players.map(u=>u.weapons.map(w=>[w.fired,w.cdLeft,w.shots]));
  const ok=await runIn("useCommand('player')");
  if(label.startsWith('invalid')||label==='no-target'){assert.equal(ok,false);assert.equal(G.B.cmdUsed,false);assert.equal(runIn('RNG_S>>>0'),seed);}
  else assert.equal(ok,true,label);
  assert.deepEqual(players.map(u=>u.weapons.map(w=>[w.fired,w.cdLeft,w.shots])),weapons,'Command restoration '+label);
  const state=clean(G.B),rng=runIn('RNG_S>>>0');rows.push({kind:'pilot_battle',case:label+':'+seed,ok,state,rng});
  if(['off','off-near','normal-option','alternate','other-admiral'].includes(label)){
   const control=fixture(ROOT,mode,distance,seed,option);const baselineOk=await control.runIn("useCommand('player')");
   assert.equal(baselineOk,ok);try{assert.deepEqual(clean(control.G.B),state,'off/control native behavior '+label);}catch(e){fs.writeFileSync(path.join(work,'control_diff.json'),JSON.stringify({baseline:clean(control.G.B),candidate:state},null,2));throw e;}assert.equal(control.runIn('RNG_S>>>0'),rng);
   controls.push(label+':'+seed);
  }
 }
 for(const [i,profile] of [
  {id:'early',xp:74,stats:{battles:1,elites:0,bosses:0,kills:0,lost:0},win:false,heat:[]},
  {id:'win',xp:74,stats:{battles:12,elites:3,bosses:3,kills:0,lost:0},win:true,heat:[]},
  {id:'heat',xp:74,stats:{battles:4,elites:1,bosses:1,kills:0,lost:0},win:false,heat:['h_coffers','h_repair']},
  {id:'overflow',xp:598,stats:{battles:12,elites:3,bosses:3,kills:0,lost:0},win:true,heat:[]},
  {id:'disabled',xp:74,stats:{battles:1,elites:0,bosses:0,kills:0,lost:0},win:false,heat:[],disabled:true}
 ].entries()){
  const G=loadCampaign(dirs.overlay);G.META=G.defaultMeta();G.META.stats.runs=1;G.META.mastery.vaelen=profile.xp;G.META.opts.lineagePilot=!profile.disabled;
  G.META.lineageV1=Model.newState(G.META.mastery);G.META.keepThis='original metadata';G.RUN=G.runDefaults();Object.assign(G.RUN,{admiral:'vaelen',fac:'ithar',t0:1000+i,sector:1,stats:profile.stats,heat:profile.heat});
  input.rewards.push({profile,meta:JSON.parse(JSON.stringify(G.META)),run:JSON.parse(JSON.stringify(G.RUN))});
  const ended=G.RUN;G.endRun(profile.win);const state=G.META.lineageV1;const expected=profile.stats.battles+profile.stats.elites*2+profile.stats.bosses*5+(profile.win?10:0)+(profile.disabled?0:2*profile.heat.reduce((n,k)=>n+G.HEAT[k].w,0));
  assert.equal(ended.carry.mxGain,expected);assert.equal(G.META.keepThis,'original metadata');
  const carry={mxGain:ended.carry.mxGain,mx0:ended.carry.mx0,mx1:ended.carry.mx1};G.Persist.saveLocal();G.Persist.loadLocal();assert.deepEqual(G.META.lineageV1,state,'native save retained lineage namespace');
  rows.push({kind:'pilot_reward',case:profile.id,namespace:G.META.lineageV1,legacyMastery:G.META.mastery.vaelen,masteryXP:vm.runInContext("masteryXP('vaelen')",G._sandbox),carry,keepThis:G.META.keepThis});
 }
 for(const profile of [{id:'enabled',admiral:'vaelen',fac:'ithar',enabled:true},{id:'disabled',admiral:'vaelen',fac:'ithar',enabled:false},{id:'other-admiral',admiral:'vex',fac:'voidsworn',enabled:true}]){
  const G=loadCampaign(dirs.overlay);vm.runInContext('Date.now=()=>0;',G._sandbox);G.META=G.defaultMeta();G.META.mastery.vaelen=75;G.META.opts.lineagePilot=profile.enabled;
  G.META.lineageV1=Model.choose(Model.newState(G.META.mastery),'vaelen',Pilot.KEYS[1]);input.snapshots.push({profile,meta:JSON.parse(JSON.stringify(G.META))});G.rndSeed(90210);
  G._sandbox.__profile=profile;vm.runInContext('newRun(__profile.admiral,__profile.fac,{});',G._sandbox);
  const snapshot=JSON.parse(JSON.stringify(G.RUN.lineagePilot)),persisted=JSON.parse(JSON.stringify(G.SAVED_RUN.lineagePilot));G.META.lineageV1.lines.vaelen.picks=[];
  assert.deepEqual(G.RUN.lineagePilot,snapshot,'native run must not alias META choices');assert.deepEqual(G.SAVED_RUN.lineagePilot,persisted);
  rows.push({kind:'pilot_snapshot',case:profile.id,snapshot,persisted,detached:true});
 }
 // Exercise the actual browser picker and actual Command cancellation handler.
 const UI=loadUI(dirs.overlay),uiErrors=[];UI._sandbox.console={...console,error:(...args)=>uiErrors.push(args.map(String).join(' '))};const doc=UI._sandbox.document;doc.body.appendChild=e=>{const ids=[e.id,...Array.from((e.innerHTML||'').matchAll(/id="([^"]+)"/g),m=>m[1])];for(const id of ids)UI.uiEls[id]=e;e.remove=()=>{for(const id of ids)if(UI.uiEls[id]===e)delete UI.uiEls[id];};return e;};
 UI.META=UI.defaultMeta();UI.META.mastery.vaelen=75;UI.META.renown=100;UI.RUN=null;UI.SAVED_RUN=null;
 UI.ACT.lineagePilotChoose(Pilot.KEYS[0]);assert.equal(UI.META.lineageV1.lines.vaelen.picks[0],Pilot.KEYS[0]);
 UI.ACT.lineagePilotRespec();assert.equal(UI.META.renown,75);UI.ACT.lineagePilotChoose(Pilot.KEYS[1]);assert(UI.uiEls.modal.innerHTML.includes('Back to mastery'));assert(!UI.uiEls.modal.innerHTML.includes('Current: adm.'));UI.ACT.lineagePilotClose();assert(!UI.uiEls.modal);
 vm.runInContext("newRun('vaelen','ithar',{});",UI._sandbox);assert.equal(UI.RUN.lineagePilot.picks[0],Pilot.KEYS[1]);
 const frozen=JSON.stringify(UI.RUN.lineagePilot),saved=JSON.stringify(UI.META.lineageV1);UI.ACT.lineagePilotRespec();assert.equal(JSON.stringify(UI.META.lineageV1),saved);assert.equal(JSON.stringify(UI.RUN.lineagePilot),frozen);
 UI.META.lineageV1.lines.vaelen.picks=[];assert.equal(JSON.stringify(UI.RUN.lineagePilot),frozen,'run owns a snapshot, not a live meta alias');
 // Reset with a real probe battle but keep the full UI and its real action handlers.
 probe.installBattleProbe(UI);probe.probeBattle(UI,{player:['i_song'],enemies:['h_picket'],seed:42,map:null});UI.RUN.admiral='vaelen';UI.RUN.lineagePilot={version:1,admiral:'vaelen',xpQ:300,picks:[Pilot.KEYS[1]]};UI.B.round=3;
 vm.runInContext('lineageCommandPrompt();',UI._sandbox);assert(UI.uiEls.modal.innerHTML.includes('One Lens'));const beforeCancel=clean(UI.B);
 UI.ACT.lineageCommandCancel();assert.equal(UI.B.cmdUsed,beforeCancel.cmdUsed);assert(!UI.uiEls.modal);assert(!UI.B.lineageIntent);assert(!UI.B.lineageDraft);
 const ship=UI.B.units.find(u=>u.side==='player'),enemy=UI.B.units.find(u=>u.side==='enemy');probe.clearTerrain(UI);probe.place(ship,5,8,0);probe.place(enemy,9,8,3);enemy.hp=enemy.maxHp=10000;
 vm.runInContext('lineageCommandPrompt();',UI._sandbox);UI.ACT.lineageWeapon(ship.id+':0');assert.equal(UI.B.lineageDraft[ship.id],0);assert(!UI.B.lineageIntent);
 UI.runInUI('onKey({target:{tagName:"DIV"},key:"Escape",preventDefault(){}});');assert(!UI.uiEls.modal);assert(!UI.B.lineageDraft);assert(!UI.B.cmdUsed);
 vm.runInContext('lineageCommandPrompt(); const __pilotRealAct=act; act=fn=>{globalThis.__pilotAction=__pilotRealAct(fn);return globalThis.__pilotAction;};',UI._sandbox);
 UI.ACT.lineageWeapon(ship.id+':0');UI.ACT.lineageCommandFire();await UI._sandbox.__pilotAction;assert(UI.B.cmdUsed);assert.equal(UI.B.usage.kind.lance,1);assert.deepEqual(uiErrors,[]);assert(!UI.B.lineageIntent);assert(!UI.B.lineageDraft);
 const pickerResult={actualPicker:true,betweenRunRespec:true,nativeSave:true,runSnapshot:true,actualCommandCancel:true,actualEscapeCancel:true,actualCommandFire:true};
 // Intent/factor boundaries are independent of RNG outcomes.
 const context={mode:Pilot.KEYS[0],weapons:{}};assert.equal(Pilot.factor(context,{id:'p'},{r:8},{},4),1);assert.equal(Pilot.factor(context,{id:'p'},{r:8},{},5),1.2);
 const s={mode:Pilot.KEYS[1],weapons:{p:0}};assert.equal(Pilot.factor(s,{id:'p'},{r:8},{},2),1.25);assert.equal(Pilot.allows(s,{id:'p'},1),false);
 // An exception during a real native Command must restore all temporary weapon state.
 const ex=fixture(dirs.overlay,Pilot.KEYS[1],6,19,{intent:'single'});const ew=ex.players.map(u=>u.weapons.map(w=>[w.fired,w.cdLeft,w.shots]));
 ex.runIn('fireWeapon=async function(u){u.postFire=true;u.postMp=0;throw new Error("injected shot failure");};');await assert.rejects(()=>ex.runIn("useCommand('player')"));
 assert.deepEqual(ex.players.map(u=>u.weapons.map(w=>[w.fired,w.cdLeft,w.shots])),ew);assert.equal(ex.G.B.volleyMul,null);assert.equal(ex.players[0].postMp,2);
 for(let seed=1;seed<=8;seed++){const near=rows.find(r=>r.case==='long-near:'+seed),baseline=rows.find(r=>r.case==='off-near:'+seed);assert.deepEqual(near.state,baseline.state,'no long-range bonus at the half-range boundary');assert.equal(near.rng,baseline.rng);}
 fs.writeFileSync(path.join(dirs.project,'codex/pilot_input.json'),JSON.stringify(encode(input)));fs.writeFileSync(path.join(work,'pilot_js.jsonl'),rows.map(r=>JSON.stringify(r)).join('\n')+'\n');
 fs.writeFileSync(path.join(work,'pilot_js_summary.json'),JSON.stringify({records:rows.length,unchangedNativeControls:controls.length,controls,pickerResult,exceptionCleanup:true,rangeBoundary:true,singleProjectile:true},null,2)+'\n');
 console.log(rows.length+' native JS pilot records, '+controls.length+' exact unchanged controls; actual picker/save/respec/cancel and exception cleanup pass');
}
if(require.main===module)run(path.resolve(process.argv[2])).catch(e=>{console.error(e.stack);process.exitCode=1;});module.exports={run,clean};
