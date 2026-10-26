// A3 rules parity, Node side (the oracle). Runs the game's own data.js, core.js and battle.js unchanged, headless the way sim3d.js does,
// and writes one state record per activation: turn index, round, who acted, the PRNG state, the whole battle state in canonical form, and a
// SHA-256 of that canonical text. The Godot port writes the same records; compare.js finds the first turn and field that differ.
//
//   node golden.js scenario <name> <out.jsonl> [seed]   one scenario from data/scenarios.json (seed overrides its own, for sweeps)
//   node golden.js prng <seed> <count> <out.txt>   the first <count> PRNG draws from <seed>, one per line, as raw 32-bit state and draw
//   node golden.js math <out.txt>                 V8's results for sin, cos, atan2, exp, hypot, round and pow on about 280,000 inputs (Godot checks its port)
//
// Canonical form (identical on both sides): objects with keys sorted, keys whose value is null or undefined left out, integers printed as
// integers, any other number printed as 'd:' + the 16 hex digits of its IEEE 754 double, references to another ship printed as '@' + its id.
// The harness changes nothing in the game files: it only gives them a fixed clock (Date.now()=0, so ship ids are x01, x02 ...) and no-op
// presentation calls, exactly like sim3d.js.
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm'), crypto = require('crypto');
// the rules oracle: the pinned copy in ../oracle (VS_ORACLE overrides, for example the live repo root when catching up a rules change)
const ROOT = process.env.VS_ORACLE ? path.resolve(process.env.VS_ORACLE) : path.resolve(__dirname, '..', 'oracle');
Date.now = () => 0;
global.require = require; global.Buffer = Buffer;
global.window = {}; global.document = undefined; global.performance = { now: () => 0 };

const HARNESS = String.raw`
// ---- presentation stubs (as sim3d.js), each one a per-action hash point ----
var HOOK=null; function hook(kind,u){ if(HOOK) HOOK(kind,u); }
function log(m,c){ if(B&&B.log) B.log.push({m,c}); } function fxText(){} function fxShield(){} function fxFlash(){}
async function animPath(u,path,opt){ hook('move',u); if(opt&&opt.onLate) await opt.onLate(); }
async function animMove(u,q,r,f){ u.q=q; u.r=r; u.facing=f; } async function animRotate(u,f){ hook('rotate',u); }
async function animWeapon(u){ hook('fire',u); } async function animExplode(t){ hook('death',t); } async function animNova(u){ hook('nova',u); } async function animBlink(u){ hook('blink',u); }
async function fxRam(u){ hook('ram',u); } async function fxBoard(u){ hook('board',u); }
function onCapture(){} function fxShieldBreak(){} function fxWithdraw(){}
SPEED=0;
// actions with no presentation hook of their own get one after they finish
{ const _ua=useAbility; useAbility=async function(u,a){ const r=await _ua(u,a); hook('ability',u); return r; };
  const _go=giveOrder; giveOrder=function(u,o){ const r=_go(u,o); hook('order',u); return r; };
  const _st=startSideTurn; startSideTurn=function(side){ const r=_st(side); hook('tick '+side,null); return r; };
  const _uc=useCommand; useCommand=async function(side){ const r=await _uc(side); hook('command '+side,null); return r; }; }

// ---- the game's turn flow (ui3d.js guard, act, endActivation, aiStep, nextRound), alternating activations, no UI ----
function pendingP(){ return alive('player').filter(u=>!u.isSq&&!u.activated&&u!==B.activeUnit); }
function pendingE(){ return alive('enemy').filter(u=>!u.isSq&&!u.activated); }
function canUseF(u){ if(!B.alt||u.isSq) return true; if(u.activated) return false; return !B.activeUnit||B.activeUnit===u; }
function guardF(u){ if(!u||u.side!=='player') return false; if(canUseF(u)){ if(B.alt&&!u.isSq&&!B.activeUnit) B.activeUnit=u; return true; } return false; }
function isDoneRawF(u){ if(u.dead||u.braced) return true; return !(u.mp>0) && !u.weapons.some(w=>weaponReady(w)&&alive('enemy').some(t=>canFire(u,w,t))); }
async function actF(fn){ if(!B||B.busy) return; B.busy=true; await fn(); B.busy=false; if(B.over) return; if(B.alt&&B.activeUnit&&(B.activeUnit.dead||isDoneRawF(B.activeUnit))) await endActivationF(); }
async function endActivationF(manual,sel){ if(!B||B.over||B.side!=='player'||(B.busy&&manual)) return;
  if(B.activeUnit){ B.activeUnit.activated=true; B.activeUnit=null; } else if(manual&&sel&&sel.side==='player'&&!sel.isSq&&!sel.activated){ sel.activated=true; }
  B.sel=null; B.reach=null; B.armed=null; B.mode=null; hook('end activation',null); await aiStepF(); }
var TM=null, SNAPMS=0;
async function aiStepF(){ if(!B||B.over) return; const pe=pendingE(), pp=pendingP();
  if(pe.length){ B.busy=true; B.side='enemy'; const sqs=alive('enemy').filter(u=>u.isSq&&!u.activated); const batch=pp.length?[aiPickActivation(pe.sort((a,b)=>b.speed-a.speed))]:pe;
    for(const u of [...sqs,...batch]){ if(B.over) break; const s0=SNAPMS, t0=process.hrtime.bigint(); await aiUnit(u); const ms=Number(process.hrtime.bigint()-t0)/1e6-(SNAPMS-s0); if(!u.isSq&&TM){ TM.acts.push({round:B.round,ms}); TM.rounds[B.round]=(TM.rounds[B.round]||0)+ms; } u.activated=true; hook('activation',u); }
    B.aiActive=null; B.side='player'; B.busy=false; if(B.over) return; }
  if(!pendingP().length&&!pendingE().length){ await nextRoundF(); return; }
  if(!pendingP().length){ await aiStepF(); return; } }
async function nextRoundF(){ if(!B||B.over) return; B.round++; for(const x of B.units) x.activated=false; B.activeUnit=null;
  B.busy=true; await roundStartBoth(); if(B.over){ B.busy=false; return; } // battle.js owns the round start: ticks, then travelling torpedoes
  B.busy=true; await swarmPhase('player'); if(!B.over) await swarmPhase('enemy'); B.busy=false; hook('round',null); }

// ---- Classic mode (B.alt false): ui3d.js endTurn. The whole enemy turn is the game's own aiTurn ----
async function endTurnF(){ if(!B||B.busy||B.side!=='player'||B.over) return;
  B.busy=true; B.sel=null; B.armed=null; B.mode=null; B.inspect=null; B.reach=null;
  B.side='enemy'; await turnStart('enemy'); hook('end turn',null);
  await aiTurn();
  B.aiActive=null; if(B.over){ B.busy=false; return; }
  B.round++; B.side='player'; await turnStart('player'); if(B.over){ B.busy=false; return; }
  await swarmPhase('player'); B.busy=false; hook('round',null); }

// ---- your side's bot: sim3d.js botUnit without commands, abilities or tactics, through the game's command path ----
async function pBotF(u){
  if(B.over||u.dead) return;
  const foes=alive('enemy'); if(!foes.length) return;
  const {states}=computeReach(u); let best=null,bs=-1e9;
  for(const s of states){ const v=stateView(u,s); const off=evalOffense(v,u.weapons.filter(weaponReady),foes); const th=evalThreat(v,foes); const nd=Math.min(...foes.map(f=>hdist(v,f))); const sc=off-th*.3-(off>0?0:nd*3); if(sc>bs){bs=sc;best=s;} }
  if(best&&best.path.length&&guardF(u)) await actF(()=>moveUnit(u,best));
  for(let i=0;i<u.weapons.length;i++){ if(B.over||B.side!=='player'||u.activated) break; let bt=null,bv=0; for(const t of alive('enemy')){ if(canFire(u,u.weapons[i],t)){ const e=expectedVs(u,u.weapons[i],t); const v=e.hull+e.shield*.3+(e.hull>=t.hp?20:0); if(v>bv){bv=v;bt=t;} } } if(bt&&guardF(u)) await actF(()=>fireWeapon(u,i,bt)); }
  if(!B.over&&B.side==='player'&&!u.activated&&B.alt) await endActivationF(true,u);
}

// ---- ui3d.js attack-move (attackMovePlan, firingSet, tap an enemy out of reach): burn to the best hex for the shot, fire on the way.
// B.reach is the selected ship's computeReach and B.armed is null (every gun) here.
function attackPlanF(s,t){ if(!B||!s||s.isSq||s.braced||t.dead) return null; let best=null;
  const idx=s.weapons.map((w,i)=>i).filter(i=>{ const w=s.weapons[i]; return w.k!=='flak'&&weaponReady(w); }); if(!idx.length) return null;
  for(const st of computeReach(s).states){ if(st.q===s.q&&st.r===s.r) continue; const v=stateView(s,st); const n=idx.filter(i=>inReach(v,s.weapons[i],t)).length; if(!n) continue;
    const hx=(st.path||[]).filter(p=>!p.rot).length, sc=n*100-st.cost*3-(st.t||0)+(hx>=2?4:0); if(!best||sc>best.sc) best={st,n,sc,of:idx.length}; }
  return best; }
async function attackMoveF(s,u){ if(!(s&&s.side==='player'&&canUseF(s))) return false; const am=attackPlanF(s,u); if(!(am&&guardF(s))) return false;
  await actF(()=>moveUnit(s,am.st,{onLate:async()=>{ const live=liveFrom(s); for(const i of s.weapons.map((w,i)=>i).filter(i=>canFire(s,s.weapons[i],u))){ if(u.dead||s.dead||B.over||!live()) break; await fireWeapon(s,i,u); } }})); return true; }
// scenarios with attack_move: a ship with no gun bearing first attack-moves on the nearest enemy ship (coverage for the API's attack_move)
async function attackFirstF(u){ if(B.over||u.dead||u.isSq) return; if(u.weapons.some(w=>weaponReady(w)&&alive('enemy').some(t=>canFire(u,w,t)))) return;
  const es=alive('enemy').filter(x=>!x.isSq); if(!es.length) return; let t=es[0]; for(const x of es) if(hdist(u,x)<hdist(u,t)) t=x; await attackMoveF(u,t); }

// ---- the full bot: sim3d.js botUnit (Command, abilities, rams, boarding, brace, objective pull), through the game's command path.
// One addition for coverage: a ship with nothing to shoot turns in place once. Each step stops when the activation has ended.
function botObjF(v){ const o=B.obj; if(!o) return 0; const col=h=>h.q+Math.floor(h.r/2);
  if(o.type==='hold') return hdist(v,o.hex)*1.6;
  if(o.type==='break') return Math.max(0,o.exitC-col(v))*6;
  if(o.type==='defend') return Math.max(0,hdist(v,o.hex)-3)*1.2;
  if(o.type==='intercept'){ const tr=alive('enemy').filter(x=>x.transport); return tr.length?Math.min(...tr.map(t=>hdist(v,t)))*2.5:0; }
  if(o.type==='hunt'){ const f=alive('enemy').find(x=>x.flagship); return f?hdist(v,f)*2.5:0; }
  return 0; }
async function pBotFull(u){
  const r0=B.round, gone=()=>B.over||u.dead||u.activated||B.side!=='player'||B.round!==r0; // stops when the activation ends or the round changes (as api.ai_activate)
  if(gone()) return;
  if(canStance(u)) aiStance(u); // the bot picks wing stances like the enemy does (ACT.stance: no action wrapper)
  if(canCommand('player')&&!B.busy){ const c=commandFor('player'); const pl=alive('player').filter(x=>!x.isSq), en=alive('enemy').filter(x=>!x.isSq);
    if(c&&pl.length&&en.length){ const near=en.filter(e=>pl.some(p=>hdist(p,e)<=8)).length, hpR=pl.reduce((a,p)=>a+p.hp,0)/pl.reduce((a,p)=>a+p.maxHp,0), hurt=pl.some(p=>p.hp<p.maxHp*.5);
      const id=c.id, off=['barrage','hunt','scramble','surge'].includes(id);
      if((off&&(near>=2||B.round>=4))||(id==='restore'&&hpR<.6)||(id==='iron'&&(hurt||near>=2))||B.round>=6) await actF(()=>useCommand('player')); } }
  if(gone()) return;
  if(u.ab&&canAbility(u)&&canUseF(u)){ let arg;
    if(u.ab==='launch'){ const hs=launchHexes(u); arg=hs.length?{hex:hs[0],kind:u.fac==='voidsworn'?(rnd()<.5?'fighter':'bomber'):wingKind(u)}:null; }
    else if(u.ab==='nova'){ const t=novaTargets(u).find(h=>alive('enemy').some(e=>hdist(e,h)<=1)&&!alive('player').some(p=>hdist(p,h)<=1)); arg=t?{hex:t}:null; }
    if(arg!==null&&guardF(u)) await actF(()=>useAbility(u,arg)); }
  if(gone()) return;
  if(!u.isSq&&ramInfo(u)&&guardF(u)) await actF(()=>tacticRam(u));
  if(gone()) return;
  const foes=alive('enemy'); if(!foes.length) return;
  const {states}=computeReach(u); let best=null,bs=-1e9;
  for(const s of states){ const v=stateView(u,s); const off=evalOffense(v,u.weapons.filter(weaponReady),foes); const th=evalThreat(v,foes); const nd=Math.min(...foes.map(f=>hdist(v,f))); const sc=off-th*.3-(off>0?0:nd*3)-botObjF(v)-torpThreat(u,v)*.9-syncPull(u,v)*1.5; if(sc>bs){bs=sc;best=s;} }
  if(best&&best.path.length&&guardF(u)) await actF(()=>moveUnit(u,best));
  if(gone()) return;
  if(!u.weapons.some(w=>weaponReady(w)&&alive('enemy').some(t=>canFire(u,w,t)))&&canRotate(u)&&guardF(u)) await actF(()=>rotateUnit(u,1));
  if(gone()) return;
  if(!u.isSq&&boardTargets(u).length&&guardF(u)){ let b=false; await actF(async()=>{ b=await tacticBoard(u); }); if(b){ if(!gone()&&B.alt) await endActivationF(true,u); return; } }
  for(let i=0;i<u.weapons.length;i++){ if(gone()) return; let bt=null,bv=0; for(const t of alive('enemy')){ if(canFire(u,u.weapons[i],t)){ const e=expectedVs(u,u.weapons[i],t); const v=e.hull+e.shield*.3+(e.hull>=t.hp?20:0); if(v>bv){bv=v;bt=t;} } } if(bt&&guardF(u)) await actF(()=>fireWeapon(u,i,bt)); }
  if(gone()) return;
  if(!u.isSq&&!u.weapons.some(w=>w.fired)&&u.hp<u.maxHp*.5&&canOrder(u,'brace')&&evalThreat(u,alive('enemy'))>10&&guardF(u)) await actF(()=>giveOrder(u,'brace'));
  if(!gone()&&!u.isSq&&canFade(u)&&guardF(u)) await actF(()=>fadeMove(u)); // the Ithar fade after firing
  if(!gone()&&B.alt) await endActivationF(true,u);
}

// ---- canonical state ----
// B.prog is the UI's busy-watchdog step counter: no rule reads it, and its increments interleave with JS microtasks around fire-on-the-move, so it stays out of the hash
const SKIP_U={t:1,ship:1}, SKIP_B={units:1,cfg:1,prog:1}; // the battle log is in the hash
function canon(v,top){
  if(v===null||v===undefined) return 'null';
  if(typeof v==='boolean') return v?'true':'false';
  if(typeof v==='number'){ if(Number.isInteger(v)&&Math.abs(v)<9007199254740992) return String(v===0?0:v); const b=Buffer.alloc(8); b.writeDoubleBE(v); return '"d:'+b.toString('hex')+'"'; }
  if(typeof v==='string') return JSON.stringify(v);
  if(typeof v==='function') return 'null';
  if(Array.isArray(v)) return '['+v.map(x=>canon(x)).join(',')+']';
  if(!top&&v.id&&v.side&&v.hp!==undefined) return JSON.stringify('@'+v.id);
  const ks=Object.keys(v).filter(k=>v[k]!==null&&v[k]!==undefined&&typeof v[k]!=='function'&&!(top==='u'&&SKIP_U[k])&&!(top==='b'&&SKIP_B[k])).sort();
  return '{'+ks.map(k=>JSON.stringify(k)+':'+canon(v[k])).join(',')+'}';
}
function snap(turn,actor){ const t0=process.hrtime.bigint(); const units=B.units.map(u=>canon(u,'u')).join(','), gl={cut:CUT?[...CUT].sort():null,solid:SOLID?[...SOLID].sort():null,uid:UID}, s='{"b":'+canon(B,'b')+',"g":'+canon(gl,'g')+',"units":['+units+']}'; // g: rules state kept outside B (the board cut-outs, the set-piece hexes that block sight, the id counter)
  const r={turn,round:B.round,actor:actor||'',rng:RNG_S>>>0,hash:require('crypto').createHash('sha256').update(s).digest('hex'),state:s}; SNAPMS+=Number(process.hrtime.bigint()-t0)/1e6; return r; }

// ---- scenarios (scenarios.json, read by both sides); a record after every action, activation and round ----
async function runScenario(S){
  UID=1; rndSeed(S.seed); AI_LEVEL=S.ai||'veteran';
  RUN={admiral:S.admiral,fac:S.fac_player||'voidsworn',credits:0,cpCap:40,sector:S.sector,relics:(S.relics||[]).slice(),inventory:[],fleet:[],boons:(S.boons||[]).map(b=>Object.assign({},b)),patrons:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]};
  if(S.aspect) RUN.aspect=S.aspect; if(S.heat) RUN.heat=S.heat.slice(); if(S.class_track) RUN.classTrack=Object.assign({},S.class_track);
  for(const t of S.fleet) RUN.fleet.push(newShip(t,!!S.vet)); RUN.flagUid=RUN.fleet[0].uid;
  const rec=[]; let turn=0; TM={acts:[],rounds:{}}; SNAPMS=0;
  HOOK=(kind,u)=>{ if(B) rec.push(snap(turn++,kind+(u?' '+u.id:''))); };
  const cfg={kind:S.kind,fac:S.fac,col:S.col==null?3:S.col,seed:S.seed,obj:S.obj,shape:S.shape,map:S.map,dep:S.dep,enemies:S.enemies?S.enemies.map(tpl=>({tpl})):undefined};
  if(S.arch) cfg.arch=S.arch; if(S.mod) cfg.mod=S.mod; if(S.nemesis) cfg.nemesis=JSON.parse(JSON.stringify(S.nemesis)); if(S.verb) cfg.verb=S.verb;
  startBattle(cfg);
  if(S.campaign){ B.campaign=true; B.event=rollBattleEvent(cfg,S.event_war?(cfg.kind!=='boss'?(rnd()<.6?'reinf_enemy':'reinf_ally'):null):(S.event_force||null)); } // campaign3d.js battleScreen (event_war: the sector at war)
  hook('start',null);
  B.alt=S.alt!==false; for(const x of B.units) x.activated=false; if(B.alt){ const d=startSideTurn('enemy'); if(d) await d; } // ui3d.js prepBattle
  let g=0;
  const bot0=S.bot==='full'?pBotFull:pBotF, bot=S.attack_move?async u=>{ await attackFirstF(u); if(!B.over&&!u.dead&&!u.activated&&B.side==='player') await bot0(u); }:bot0;
  if(B.alt) while(!B.over&&B.round<=S.rounds&&g++<2000){ threatSnap(); const u=pendingP()[0]; if(u) await bot(u); else await endActivationF(true,null); }
  else while(!B.over&&B.round<=S.rounds&&g++<200){ for(const u of alive('player').filter(x=>!x.isSq)){ if(B.over) break; await bot(u); } if(!B.over) await endTurnF(); }
  hook('end '+(B.over||'none'),null); HOOK=null; rec.timing=TM; return rec; }
// ui3d.js computeThreat at the pinned commit (the threat overlay), for checking api.threat_map
function computeThreatF(only){ const map=new Map(), hexes=boardHexes(), losC=new Map();
  for(const e of only?[only]:alive('enemy')){
    const ws=e.weapons.filter(w=>w.off<=1&&w.cdLeft<=1); if(!ws.length) continue;
    const seen=new Set(), states=[{q:e.q,r:e.r,f:e.facing,cost:0,path:[]}].concat(e.isSq?[]:computeReach(e).states).filter(s=>{ const k=s.q+','+s.r+','+s.f; if(seen.has(k)) return false; seen.add(k); return true; });
    const per=new Map(), maxR=Math.max(...ws.map(w=>w.r)), mul=e.dmg||1;
    for(const s of states){ const v=stateView(e,s), fk=s.q+','+s.r+'|'+maxR; let lc=losC.get(fk); if(!lc){ lc={near:[],los:new Map()}; for(const h of hexes){ const d=hdist(v,h); if(d<=maxR) lc.near.push({h,d,k:hkey(h.q,h.r)}); } losC.set(fk,lc); }
      for(const n of lc.near){ const h=n.h, d=n.d; let val=0; for(const w of ws){ if(d>w.r||!inArc(v,h,w.arc)) continue; val+=w.shots*w.dmg*mul; } if(!val) continue;
        let l=lc.los.get(n.k); if(l===undefined){ l=los(v,h); lc.los.set(n.k,l); } if(l&&val>(per.get(n.k)||0)) per.set(n.k,val); } }
    for(const [k,val] of per) map.set(k,(map.get(k)||0)+val);
  }
  return map; }
var THREAT=null; // threat check: the overlay at the start of each round up to round 3 (canonical: "q,r" -> exact double)
function threatSnap(){ if(!THREAT||THREAT[B.round]) return; const m=computeThreatF(), o={}; for(const [k,v] of [...m].sort((x,y)=>x[0]<y[0]?-1:x[0]>y[0]?1:0)) o[k]=hex(v); THREAT[B.round]=o; }
async function threatScenario(S){ THREAT={}; await runScenario(Object.assign({},S,{rounds:3})); const t=THREAT; THREAT=null; return t; }
function hex(v){ const b=Buffer.alloc(8); b.writeDoubleBE(v); return b.toString('hex'); }
`;

console.debug = () => {}; // the game's swarm timing chatter
// the browser also defines FNAMES (ui3d.js), which core.js shipName reads: pinned as oracle/fnames.js (or taken from ui3d.js beside a VS_ORACLE checkout)
const fnamesSrc = () => { const f = path.join(ROOT, 'fnames.js'); if (fs.existsSync(f)) return fs.readFileSync(f, 'utf8'); const u = path.join(ROOT, 'ui3d.js'); if (fs.existsSync(u)) { const m = fs.readFileSync(u, 'utf8').match(/^const FNAMES=[\s\S]*?\};/m); if (m) return m[0]; } return ''; };
const files = ['data.js', 'core.js', 'battle.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8')).concat([fnamesSrc()]);
vm.runInThisContext(files.join('\n') + '\n' + HARNESS + '\nglobalThis.__G={runScenario,threatScenario,rndSeed,rnd,get S(){ return RNG_S; }};', { filename: 'rules_bundle.js' });
// COVER=1: count calls to the rules functions each scenario reaches (a coverage check for the golden scenarios; printed to stderr)
const COVER = process.env.COVER ? {} : null;
if (COVER) for (const k of Object.getOwnPropertyNames(globalThis)) { const f = globalThis[k];
  if (typeof f === 'function' && /^[a-z]/.test(k) && !['setTimeout','setInterval','clearTimeout','clearInterval','require','queueMicrotask','structuredClone','fetch','atob','btoa','hook','rnd','rndSeed','canon','snap','pick','ri','hdist','alive'].includes(k) && f.toString().length < 200000 && !/native code/.test(f.toString())) {
    try { globalThis[k] = function (...a) { COVER[k] = (COVER[k] || 0) + 1; return f.apply(this, a); }; } catch (e) {} } }
process.on('exit', () => { if (COVER) process.stderr.write('COVER ' + JSON.stringify(COVER) + '\n'); });
const SCEN = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'scenarios.json'), 'utf8'));
const hex = v => { const b = Buffer.alloc(8); b.writeDoubleBE(v); return b.toString('hex'); };

(async () => {
  const [mode, a, b, c, d] = process.argv.slice(2);
  if (mode === 'prng') {
    const seed = +a, n = +b, out = []; __G.rndSeed(seed);
    for (let i = 0; i < n; i++) { const d = __G.rnd(); const bf = Buffer.alloc(8); bf.writeDoubleBE(d); out.push((__G.S >>> 0) + ' ' + bf.toString('hex')); }
    fs.writeFileSync(c, out.join('\n') + '\n'); console.log('prng', seed, n, '->', c); return;
  }
  if (mode === 'math') { // inputs and V8's answers for the Math functions the rules use, for the Godot port to check against
    let s = 4242; const r = () => { s = (s * 1103515245 + 12345) % 2147483648; return s / 2147483648; }; const out = [];
    for (let i = 0; i < 40000; i++) { const x = r() * 60 - 30, y = r() * 80 - 40, z = r() * 80 - 40, e = r() * 40 - 20, q = (r() * 200 - 100) / (1 + Math.floor(r() * 7));
      out.push('sin ' + hex(x) + ' ' + hex(0) + ' ' + hex(Math.sin(x)), 'cos ' + hex(x) + ' ' + hex(0) + ' ' + hex(Math.cos(x)), 'atan2 ' + hex(y) + ' ' + hex(z) + ' ' + hex(Math.atan2(y, z)),
        'exp ' + hex(e) + ' ' + hex(0) + ' ' + hex(Math.exp(e)), 'hypot ' + hex(y) + ' ' + hex(z) + ' ' + hex(Math.hypot(y, z)), 'round ' + hex(q) + ' ' + hex(0) + ' ' + hex(Math.round(q))); const px = r() * 40, py = r() * 6 - 3; out.push('pow ' + hex(px) + ' ' + hex(py) + ' ' + hex(Math.pow(px, py))); }
    for (const cp of [1, 2, 3, 4, 5, 6, 8, 10, 12]) out.push('pow ' + hex(cp) + ' ' + hex(1.6) + ' ' + hex(Math.pow(cp, 1.6)));
    for (let q = -30; q <= 30; q++) for (let rr = -30; rr <= 30; rr++) { const x = Math.sqrt(3) * (q + rr / 2), y = 1.5 * rr; out.push('atan2 ' + hex(y) + ' ' + hex(x) + ' ' + hex(Math.atan2(y, x))); }
    fs.writeFileSync(a, out.join('\n') + '\n'); console.log('math', out.length, 'values ->', a); return;
  }
  if (mode === 'threat') { // threat <scenario> <out>: ui3d.js computeThreat (copied below) after the battle setup and the first enemy step, for api.threat_map
    const S = Object.assign({}, SCEN[a]); const out = await __G.threatScenario(S); fs.writeFileSync(b, JSON.stringify(out)); console.log('threat', a, Object.keys(out).length, 'hexes ->', b); return;
  }
  if (mode === 'batch') { // every battle in a scenario file (the sweep), one golden file each: batch <file.json> <outdir>
    const L = JSON.parse(fs.readFileSync(a, 'utf8')); let k = 0;
    for (const name of Object.keys(L)) { const rec = await __G.runScenario(Object.assign({}, L[name])); fs.writeFileSync(path.join(b, name + '.jsonl'), rec.map(r => JSON.stringify(r)).join('\n') + '\n'); k++; }
    console.log('batch', k, 'battles ->', b); return;
  }
  if (mode === 'scenario') {
    const SC = d ? JSON.parse(fs.readFileSync(d, 'utf8')) : SCEN; // optional scenario file (default scenarios.json)
    if (!SC[a]) throw new Error('unknown scenario ' + a);
    const S = Object.assign({}, SC[a]); if (c && +c >= 0) S.seed = +c; // optional seed override, for sweeps
    const rec = await __G.runScenario(S); fs.writeFileSync(b, rec.map(r => JSON.stringify(r)).join('\n') + '\n');
    fs.writeFileSync(b + '.timing.json', JSON.stringify(rec.timing));
    const last = rec[rec.length - 1]; console.log('scenario', a, rec.length, 'records', last.actor, '->', b); return;
  }
  console.log('usage: node golden.js scenario <name> <out.jsonl> [seed|-1] [file.json] | batch <file.json> <outdir> | prng <seed> <count> <out.txt> | math <out.txt>'); process.exit(2);
})().catch(e => { console.error(e); process.exit(1); });
