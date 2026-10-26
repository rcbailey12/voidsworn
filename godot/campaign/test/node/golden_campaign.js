// G3 campaign parity, Node side (the oracle). Runs the pinned JS game files unchanged (env.js) and plays whole runs, title to the
// end screen, with a scripted bot that clicks the same buttons a player sees. After every click it writes one record: the click,
// the buttons on screen, the PRNG state and the campaign state in canonical form (the same rules as G1's golden.js). The Godot
// port (godot/campaign/test/parity_campaign.gd) writes the same records; compare_campaign.js names the first step and field that differ.
//
//   node golden_campaign.js <seed> <out.jsonl>
//
// The bot (identical in GDScript): integer weights per button, its own 31-bit LCG, a cap on "stay" clicks in a row, and a rare
// page reload (save to JSON, load it back, continue from the title). Battles use the stub battle below until real battles are
// hooked in (both sides use the same stub, so the campaign rules are what is compared).
'use strict';
const fs = require('fs'), crypto = require('crypto');
const env = require('./env.js');
const HARNESS = String.raw`
// ---------------- recorded screen ----------------
var __PAGE='', __MODAL='', __ENDED=false;
show=function(h){ __MODAL=''; __PAGE=String(h); };
modal=function(h){ __MODAL=String(h); };
closeModal=function(){ __MODAL=''; };
toast=function(){}; hideTip=function(){}; showTip=function(){};
{ const _er=endRun; endRun=function(v,a){ _er(v,a); __ENDED=true; }; }
// ---------------- stub battle (godot/campaign/battle_stub.gd is the same, line for line) ----------------
function stubStart(cfg){
  const seed=cfg.seed!=null?(cfg.seed>>>0):Math.floor(rnd()*4294967296); rndSeed(seed);
  const enc=ENCOUNTERS[cfg.obj]?cfg.obj:'rout';
  B={seed,cfg,units:[],round:1,obj:{type:enc},shape:cfg.shape||'open',map:{map:cfg.map||'random'},deployMode:cfg.dep||'line',alt:true,boonStats:{},usage:{},partial:false,over:false,busy:false,sector:RUN.sector,log:[]};
  let n=0;
  for(const ship of RUN.fleet){ if(ship.hp<=0) continue; const d=derive(ship); n++; B.units.push({id:'s'+n,side:'player',ship,tpl:ship.tpl,t:HULLS[ship.tpl],name:ship.name,fac:RUN.fac,hp:ship.hp,maxHp:d.maxHp,dealt:0,kills:0,dead:false,weapons:d.weapons.map(w=>({k:w.k}))}); }
  const F=FACTIONS[cfg.fac]||FACTIONS.hegemony, ros=F.roster.filter(h=>HULLS[h]&&!HULLS[h].boss), list=[];
  if(cfg.kind==='boss'&&F.boss&&HULLS[F.boss]) list.push(F.boss);
  const ne=2+RUN.sector+(cfg.kind==='elite'?1:0);
  for(let i=0;i<ne;i++) list.push(pick(ros));
  for(const tpl of list){ const H=HULLS[tpl]; n++; B.units.push({id:'s'+n,side:'enemy',tpl,t:H,name:H.n,fac:cfg.fac,hp:H.hp,maxHp:H.hp,dealt:0,kills:0,dead:false,boss:!!H.boss,weapons:H.w.map(e=>({k:W[e[0]].k})),ab:H.ab||null,shMax:H.sh||0,regen:H.regen||0}); }
}
function stubResolve(o){
  const P=B.units.filter(u=>u.side==='player'), E=B.units.filter(u=>u.side==='enemy'), loss=o==='loss';
  B.round=ri(3,7);
  for(const u of P){ const dmg=Math.floor(rnd()*u.maxHp*(loss?1.2:.6)); u.hp-=dmg; u.dealt=ri(10,140); if(loss||u.hp<=0||rnd()<.06){ u.hp=0; u.dead=true; } }
  const live=P.filter(u=>!u.dead), causes=Object.keys(KILL_CAUSES);
  for(const e of E){
    if(loss){ if(rnd()<.3){ e.dead=true; e.killCause=pick(causes); } continue; }
    if(!e.boss&&live.length&&rnd()<.22){ e.captured=true; e.side='player'; e.hp=Math.max(1,Math.floor(e.maxHp*(.1+.9*rnd()))); continue; }
    if(o==='partial'&&!e.boss&&rnd()<.3){ e.dead=true; e.fled=true; continue; }
    e.dead=true; e.killCause=pick(causes); if(live.length){ const k=pick(live); k.kills++; e.killedBy=k.name; } }
  if(o==='partial') B.partial=true;
  B.over=loss?'loss':'win';
}
startBattle=stubStart;
{ const _bs=battleScreen; battleScreen=function(cfg){ _bs(cfg); __MODAL='';
  __PAGE='<button data-act="battle" data-arg="win"></button><button data-act="battle" data-arg="partial"></button><button data-act="battle" data-arg="loss"></button>'+(B.cfg.kind!=='boss'?'<button data-act="c3retreat"></button>':''); }; }
ACT.battle=o=>{ if(!B||B.over) return; stubResolve(o); ACT.c3continue(); };
// ---------------- buttons on screen ----------------
const HIDDEN={c3skirmish:1,c3settings:1};
function acts(html){ const out=[], re=/<(?:button|g|div|a|span)\b([^>]*)>/g; let m;
  while((m=re.exec(html))){ const at=m[1], a=at.match(/data-act="([^"]*)"/); if(!a) continue; if(HIDDEN[a[1]]) continue; const g=at.match(/data-arg="([^"]*)"/);
    out.push([a[1], g?g[1]:'', /(^|\s)disabled(\s|$|=)/.test(at)?0:1]); } return out; }
function screenActs(){ return acts(__MODAL||__PAGE); }
// ---------------- the bot ----------------
const STAY={closeModal:1,buyHull:1,buyMod:1,repair:1,repairAll:1,upgradeMk:1,sellShip:1,sellConfirm:1,yardFleet:1,equip:1,unequip:1,promote:1,fleetScreen:1,pickFaction:1,pickAdmiral:1,optAlt:1,optCmd:1,optHeat:1,progTab:1,buyVariant:1};
const WT={enterNode:10,c3retreat:2,c3retreatYes:1,c3retreatNo:1,prizeSet:3,prizeConfirm:4,prizeStep:1,salvageStep:1,rewardNext:1,takeSalvage:1,takeBoon:1,takeMod:1,takeRelic:1,takePerk:1,
  eventChoice:1,pickAspect:1,closeModal:1,fleetFromModal:1,buyHull:3,buyMod:3,repair:2,repairAll:3,upgradeMk:3,sellShip:1,sellConfirm:1,yardFleet:1,leaveYard:2,equip:4,unequip:1,promote:4,
  backMap:3,backShipyard:3,fleetScreen:1,saveQuit:1,continueRun:20,newRunScreen:2,pickFaction:1,pickAdmiral:2,optAlt:1,optCmd:1,optHeat:1,startRun:3,progTab:1,buyVariant:3,nextFac:0,abandonRun:0,discardBrokenRun:0};
const BATTLE_WT={win:40,partial:4,loss:1};
const BOT={s:0,streak:0,legacy:false,help:false,reloads:0};
function botNext(){ BOT.s=Number((BigInt(BOT.s)*1103515245n+12345n)%2147483648n); return BOT.s; }
function weight(a,onTitle){ const [k,arg]=a; if(k==='battle') return BATTLE_WT[arg]||0; if(STAY[k]&&BOT.streak>=8) return 0;
  if(k==='legacy') return BOT.legacy?0:3; if(k==='help') return BOT.help?0:1; if(k==='title') return onTitle?2:0; return WT[k]||0; }
function choose(list){ const on=list.filter(a=>a[2]); const onTitle=on.some(a=>a[0]==='progTab'||a[0]==='buyVariant')||(on.length===1&&on[0][0]==='title');
  const ws=on.map(a=>weight(a,onTitle)), tot=ws.reduce((x,y)=>x+y,0);
  if(!tot){ const pref=['closeModal','leaveYard','backMap','backShipyard','prizeConfirm','c3retreatNo','title']; for(const p of pref){ const f=on.find(a=>a[0]===p); if(f) return f; } return on[0]||null; }
  let r=botNext()%tot; for(let i=0;i<on.length;i++){ if(r<ws[i]) return on[i]; r-=ws[i]; } return on[on.length-1]; }
// ---------------- page reload (the browser closing and reopening: only the save survives) ----------------
function doReload(){ const data=JSON.stringify({meta:META,run:SAVED_RUN}); RUN=null; B=null; for(const k of Object.keys(window)) if(k[0]==='_') delete window[k]; curEvent=null; yardNode=null;
  const o=JSON.parse(data); META=migrateMeta(Object.assign(defaultMeta(),o.meta)); SAVED_RUN=migrateRun((o.run&&!o.run.none)?o.run:null);
  pickedAdmiral='vex'; pickedFaction=(META.opts&&META.opts.lastFac)||'voidsworn'; runOpt.alt=false; runOpt.cmdAlt=false; runOpt.heat=[]; progTab='variants'; titleScreen(); }
// ---------------- the profile each seed starts with ----------------
function seedMeta(seed){ const k=seed%4; META.backfilled=1; META.wonFix41=1; META.opts.lastFac=RUN_FACTIONS[seed%6]; if(k===0) return;
  META.renown=30+(seed%7)*15; META.stats.runs=2+k; META.stats.best=k;
  const adms=Object.keys(ADMIRALS); for(let i=0;i<adms.length;i++) if((i+seed)%3!==0) META.admirals[adms[i]]=true;
  for(let i=0;i<adms.length;i++) META.mastery[adms[i]]=((i*7+seed)%6)*10;
  const ps=Object.keys(PATRONS); for(let i=0;i<ps.length;i++) META.favour[ps[i]]=((i*5+seed)%5)*7;
  if(k>=2){ META.stats.wins=k-1; META.stats.wonFacs=[RUN_FACTIONS[seed%6]]; const L=Object.keys(LEGACY); for(let i=0;i<L.length;i++) if((i+seed)%2===0) META.unlocked[L[i]]=true;
    const V=Object.keys(HULL_VARIANTS); for(let i=0;i<V.length;i++) if((i+seed)%3===0) META.variants[V[i]]=true; } }
// ---------------- canonical state ----------------
function canonJ(v){
  if(v===null||v===undefined) return 'null';
  if(typeof v==='boolean') return v?'true':'false';
  if(typeof v==='number'){ if(Number.isInteger(v)&&Math.abs(v)<9007199254740992) return String(v===0?0:v); const b=Buffer.alloc(8); b.writeDoubleBE(v); return '"d:'+b.toString('hex')+'"'; }
  if(typeof v==='string') return JSON.stringify(v);
  if(typeof v==='function') return 'null';
  if(Array.isArray(v)) return '['+Array.from(v,x=>canonJ(x)).join(',')+']'; // Array.from: a hole in a sparse array (prizeSel) is written as null, as JSON.stringify does
  const ks=Object.keys(v).filter(k=>v[k]!==null&&v[k]!==undefined&&typeof v[k]!=='function').sort();
  return '{'+ks.map(k=>JSON.stringify(k)+':'+canonJ(v[k])).join(',')+'}';
}
const sha=s=>require('crypto').createHash('sha256').update(s).digest('hex');
function trans(){ return {rw:window._rw,relicChoice:window._relicChoice,wrecks:window._wrecks,boonOffer:window._boonOffer,modOffer:window._modOffer,aspOffer:window._aspOffer,rewardCfg:window._rewardCfg,
  ev:curEvent?curEvent.id:null,yard:yardNode?yardNode.id:null,pa:pickedAdmiral,pf:pickedFaction,opt:runOpt,tab:progTab,
  b:B?{seed:B.seed,round:B.round,over:B.over||null,partial:!!B.partial,units:B.units.map(u=>[u.id,u.side,u.tpl,u.hp,!!u.dead,!!u.captured,!!u.fled,u.kills,u.dealt,u.killCause||null,u.killedBy||null])}:null}; }
function parts(){ return {run:RUN?canonJ(Object.assign({},RUN,{map:undefined})):'null', map:RUN&&RUN.map?canonJ(RUN.map):'null', meta:canonJ(Object.assign({},META,{tel:undefined})), t:canonJ(trans()), saved:canonJ(SAVED_RUN)}; }
// ---------------- one seeded run ----------------
function runSeed(seed,write){
  UID=1; rndSeed(seed); META=defaultMeta(); seedMeta(seed); SAVED_RUN=null; RUN=null; B=null; for(const k of Object.keys(window)) if(k[0]==='_') delete window[k];
  curEvent=null; yardNode=null; pickedAdmiral='vex'; pickedFaction=(META.opts&&META.opts.lastFac)||'voidsworn'; runOpt.alt=false; runOpt.cmdAlt=false; runOpt.heat=[]; progTab='variants'; __ENDED=false;
  BOT.s=seed%2147483647; BOT.streak=0; BOT.legacy=false; BOT.help=false; BOT.reloads=0;
  titleScreen(); let last={}; const rec=(i,act,arg)=>{ const p=parts(), r={i,act,arg,acts:screenActs().map(a=>a.join(':')).join('|'),rng:RNG_S>>>0,h:{}};
    for(const k of ['run','map','meta','t','saved']){ r.h[k]=sha(p[k]).slice(0,16); if(last[k]!==p[k]){ r[k]=p[k]; last[k]=p[k]; } } write(r); };
  rec(0,'start','');
  for(let i=1;i<=4000;i++){
    if(__ENDED){ write({i,act:'end',arg:''}); return i; }
    if(botNext()%100<2&&BOT.reloads<3&&RUN&&SAVED_RUN){ BOT.reloads++; doReload(); rec(i,'reload',''); continue; }
    const a=choose(screenActs()); if(!a){ write({i,act:'stuck',arg:''}); return -i; }
    if(a[0]==='legacy') BOT.legacy=true; if(a[0]==='help') BOT.help=true; BOT.streak=STAY[a[0]]?BOT.streak+1:0;
    const fn=ACT[a[0]]; if(!fn){ write({i,act:'noact',arg:a[0]}); return -i; }
    fn(a[1]===''?undefined:a[1]); rec(i,a[0],a[1]); }
  write({i:4001,act:'cap',arg:''}); return -4001; }
globalThis.__C={runSeed};
`;
env.load(HARNESS);
const seed = +process.argv[2], outp = process.argv[3];
const lines = []; const n = __C.runSeed(seed, r => lines.push(JSON.stringify(r)));
fs.writeFileSync(outp, lines.join('\n') + '\n');
console.log('seed ' + seed + ': ' + (n > 0 ? n + ' steps' : 'FAILED at step ' + (-n)));
if (n < 0) process.exit(1);
