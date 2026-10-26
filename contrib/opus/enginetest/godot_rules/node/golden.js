// A3 rules parity, Node side (the oracle). Runs the game's own data.js, core.js and battle.js unchanged, headless the way sim3d.js does,
// and writes one state record per activation: turn index, round, who acted, the PRNG state, the whole battle state in canonical form, and a
// SHA-256 of that canonical text. The Godot port writes the same records; compare.js finds the first turn and field that differ.
//
//   node golden.js scenario <name> <out.jsonl> [seed]   one scenario from data/scenarios.json (seed overrides its own, for sweeps)
//   node golden.js prng <seed> <count> <out.txt>   the first <count> PRNG draws from <seed>, one per line, as raw 32-bit state and draw
//   node golden.js math <out.txt>                 V8's results for sin, cos, atan2, exp, hypot and round on 240,000 inputs (Godot checks its port)
//
// Canonical form (identical on both sides): objects with keys sorted, keys whose value is null or undefined left out, integers printed as
// integers, any other number printed as 'd:' + the 16 hex digits of its IEEE 754 double, references to another ship printed as '@' + its id.
// The harness changes nothing in the game files: it only gives them a fixed clock (Date.now()=0, so ship ids are x01, x02 ...) and no-op
// presentation calls, exactly like sim3d.js.
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm'), crypto = require('crypto');
// the game files: VS_ROOT when set (the PC runner), otherwise this repo
const ROOT = process.env.VS_ROOT ? path.resolve(process.env.VS_ROOT) : path.resolve(__dirname, '..', '..', '..', '..', '..');
Date.now = () => 0;
global.require = require; global.Buffer = Buffer;
global.window = {}; global.document = undefined; global.performance = { now: () => 0 };

const HARNESS = String.raw`
function log(m){ if(B&&B.log) B.log.push({m}); } function fxText(){} function fxShield(){} function fxFlash(){}
async function animPath(u,path,opt){ if(opt&&opt.onLate) await opt.onLate(); }
async function animMove(u,q,r,f){ u.q=q; u.r=r; u.facing=f; } async function animRotate(u,f){ u.facing=f; }
async function animWeapon(){} async function animExplode(){} async function animNova(){} async function fxRam(){} async function fxBoard(){}
function onCapture(){} function fxShieldBreak(){} function fxWithdraw(){}
SPEED=0;

// ---- the bot both scenarios use for your side: sim3d.js botUnit without commands, abilities or tactics (kept small on purpose) ----
async function pBot(u){
  if(B.over||u.dead) return;
  const foes=alive('enemy'); if(!foes.length) return;
  const {states}=computeReach(u); let best=null,bs=-1e9;
  for(const s of states){ const v=stateView(u,s); const off=evalOffense(v,u.weapons.filter(weaponReady),foes); const th=evalThreat(v,foes); const nd=Math.min(...foes.map(f=>hdist(v,f))); const sc=off-th*.3-(off>0?0:nd*3); if(sc>bs){bs=sc;best=s;} }
  if(best&&best.path.length) await moveUnit(u,best);
  for(let i=0;i<u.weapons.length;i++){ let bt=null,bv=0; for(const t of alive('enemy')){ if(canFire(u,u.weapons[i],t)){ const e=expectedVs(u,u.weapons[i],t); const v=e.hull+e.shield*.3+(e.hull>=t.hp?20:0); if(v>bv){bv=v;bt=t;} } } if(bt) await fireWeapon(u,i,bt); if(B.over) return; }
}

// ---- canonical state ----
const SKIP_U={t:1,ship:1}, SKIP_B={units:1,log:1,cfg:1};
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
function snap(turn,actor){ const units=B.units.map(u=>canon(u,'u')).join(','), s='{"b":'+canon(B,'b')+',"units":['+units+']}';
  return {turn,round:B.round,actor:actor||'',rng:RNG_S>>>0,hash:require('crypto').createHash('sha256').update(s).digest('hex'),state:s}; }

// ---- scenarios (data/scenarios.json, read by both sides) ----
async function runScenario(S){
  UID=1; rndSeed(S.seed);
  RUN={admiral:S.admiral,fac:'voidsworn',credits:0,cpCap:40,sector:S.sector,relics:[],inventory:[],fleet:[],boons:[],patrons:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]};
  for(const t of S.fleet) RUN.fleet.push(newShip(t,false)); RUN.flagUid=RUN.fleet[0].uid;
  startBattle({kind:S.kind,fac:S.fac,col:3,seed:S.seed,obj:S.obj,shape:S.shape,map:S.map,dep:S.dep,enemies:S.enemies.map(tpl=>({tpl}))});
  const rec=[snap(0,'start')]; let turn=0;
  B.alt=true; for(const x of B.units) x.activated=false; { const d=startSideTurn('enemy'); if(d) await d; } rec.push(snap(++turn,'round 1'));
  for(let r=0;!B.over&&r<S.rounds;r++){ let g=0;
    while(!B.over&&g++<40){ const pp=alive('player').filter(x=>!x.isSq&&!x.activated), pe=alive('enemy').filter(x=>!x.isSq&&!x.activated); if(!pp.length&&!pe.length) break;
      if(pp.length){ await pBot(pp[0]); pp[0].activated=true; rec.push(snap(++turn,pp[0].id)); }
      const batch=alive('player').some(x=>!x.isSq&&!x.activated)?(pe.length?[aiPickActivation(pe)]:[]):pe;
      for(const u of batch){ if(B.over) break; await aiUnit(u); u.activated=true; rec.push(snap(++turn,u.id)); } }
    if(B.over) break; B.round++; for(const x of B.units) x.activated=false;
    // the game's round start (ui3d.js nextRound): both sides tick, then the deaths those ticks caused are awaited
    const d1=startSideTurn('player'), d2=B.over?null:startSideTurn('enemy'); if(d1) await d1; if(d2) await d2;
    rec.push(snap(++turn,'round '+B.round)); }
  rec.push(snap(++turn,'end '+(B.over||'none'))); return rec; }
`;

const files = ['data.js', 'core.js', 'battle.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8'));
vm.runInThisContext(files.join('\n') + '\n' + HARNESS + '\nglobalThis.__G={runScenario,rndSeed,rnd,get S(){ return RNG_S; }};', { filename: 'rules_bundle.js' });
const SCEN = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'data', 'scenarios.json'), 'utf8'));
const hex = v => { const b = Buffer.alloc(8); b.writeDoubleBE(v); return b.toString('hex'); };

(async () => {
  const [mode, a, b, c] = process.argv.slice(2);
  if (mode === 'prng') {
    const seed = +a, n = +b, out = []; __G.rndSeed(seed);
    for (let i = 0; i < n; i++) { const d = __G.rnd(); const bf = Buffer.alloc(8); bf.writeDoubleBE(d); out.push((__G.S >>> 0) + ' ' + bf.toString('hex')); }
    fs.writeFileSync(c, out.join('\n') + '\n'); console.log('prng', seed, n, '->', c); return;
  }
  if (mode === 'math') { // inputs and V8's answers for the Math functions the rules use, for the Godot port to check against
    let s = 4242; const r = () => { s = (s * 1103515245 + 12345) % 2147483648; return s / 2147483648; }; const out = [];
    for (let i = 0; i < 40000; i++) { const x = r() * 60 - 30, y = r() * 80 - 40, z = r() * 80 - 40, e = r() * 40 - 20, q = (r() * 200 - 100) / (1 + Math.floor(r() * 7));
      out.push('sin ' + hex(x) + ' ' + hex(0) + ' ' + hex(Math.sin(x)), 'cos ' + hex(x) + ' ' + hex(0) + ' ' + hex(Math.cos(x)), 'atan2 ' + hex(y) + ' ' + hex(z) + ' ' + hex(Math.atan2(y, z)),
        'exp ' + hex(e) + ' ' + hex(0) + ' ' + hex(Math.exp(e)), 'hypot ' + hex(y) + ' ' + hex(z) + ' ' + hex(Math.hypot(y, z)), 'round ' + hex(q) + ' ' + hex(0) + ' ' + hex(Math.round(q))); }
    for (let q = -30; q <= 30; q++) for (let rr = -30; rr <= 30; rr++) { const x = Math.sqrt(3) * (q + rr / 2), y = 1.5 * rr; out.push('atan2 ' + hex(y) + ' ' + hex(x) + ' ' + hex(Math.atan2(y, x))); }
    fs.writeFileSync(a, out.join('\n') + '\n'); console.log('math', out.length, 'values ->', a); return;
  }
  if (mode === 'scenario') {
    if (!SCEN[a]) throw new Error('unknown scenario ' + a);
    const S = Object.assign({}, SCEN[a]); if (c) S.seed = +c; // optional seed override, for sweeps
    const rec = await __G.runScenario(S); fs.writeFileSync(b, rec.map(r => JSON.stringify(r)).join('\n') + '\n');
    const last = rec[rec.length - 1]; console.log('scenario', a, rec.length, 'records', last.actor, '->', b); return;
  }
  console.log('usage: node golden.js scenario <name> <out.jsonl> | prng <seed> <count> <out.txt> | math <out.txt>'); process.exit(2);
})().catch(e => { console.error(e); process.exit(1); });
