#!/usr/bin/env node
// Direct rule probes for the eight rescaled protocols (issue 443, R175).
// Loads the shipped data.js, core.js and battle.js and calls their real
// functions. It does not copy any rule. The stubs below are presentation only
// (the same ones sim3d.js installs).
//
// Run: node contrib/deepseek/tools/protocol_mechanics.js

global.window = {}; global.document = undefined; global.performance = { now: () => Date.now() };
const fs = require('fs');

const HEAD = `
function log(){} function fxText(){} function fxShield(){} function fxFlash(){}
async function animPath(){} async function animMove(){} async function animRotate(){}
async function animWeapon(){} async function animExplode(){} async function animNova(){}
async function animTorpLaunch(){} async function fxRam(){} async function fxBoard(){}
function onCapture(){} function fxShieldBreak(){} function fxWithdraw(){}
async function roundStart(){} SPEED=0;
function place(u,q,r,f){ u.q=q; u.r=r; if(f!=null) u.facing=f; }
function clearT(){ for(const k of Object.keys(B.terrain)) delete B.terrain[k]; }
function setup(boons, fleet, enemy){
  RUN={fac:'voidsworn',admiral:'vex',fleet:[],relics:[],inventory:[],sector:1,cpCap:60,credits:0,
    stats:{battles:0,elites:0,bosses:0,kills:0,lost:0},fallen:[],patrons:[],boons:(boons||[]).map(b=>typeof b==='string'?{id:b,r:0}:b),aspect:null};
  for(const t of (fleet||['cathedral','penitent','penitent','warden'])){ const s=newShip(t,false); RUN.fleet.push(s); }
  RUN.flagUid=RUN.fleet[0].uid;
  startBattle({kind:'battle',fac:'hegemony',col:3,dep:'line',obj:'rout',shape:'open',
    enemies:(enemy||['h_dominion']).map(tpl=>({tpl}))});
  for(const x of B.units) x.activated=false;
  return {P:alive('player').filter(u=>!u.isSq),E:alive('enemy').filter(u=>!u.isSq)};
}
function rar(id,r){ return [{id,r:r}]; }
(global.__probe=async function(){`;

const TAIL = `
})().then(()=>{}, e=>{ console.error(e&&e.stack||e); process.exit(1); });
`;

const body = `
const R=['Common','Rare','Epic'];
function row(name,vals){ console.log((name+' ').padEnd(34)+vals.map((v,i)=>R[i]+' '+v).join(' | ')); }

// Shield Wall: hull cut on a neighbour covered by a braced ship (braceMul is the game's own).
{
  const out=[];
  for(let r=0;r<3;r++){ const {P}=setup([{id:'i_wall',r}],['cathedral','penitent'],['h_dominion']); clearT();
    place(P[0],8,6,0); place(P[1],9,6,0); giveOrder(P[0],'brace'); const cov=P.find(u=>u.coverBy);
    out.push(cov? (+braceMul(cov)).toFixed(2):'no cover'); }
  row('i_wall covered hull cut', out);
}

// Slip the Net: movement kept after firing (fireWeapon sets postMp from the game's fade value).
{
  const out=[];
  for(let r=0;r<3;r++){ const {P,E}=setup([{id:'r_slip',r}],['cathedral'],['h_dominion']); clearT(); const u=P[0], t=E[0];
    let wi=-1; for(let f=0;f<6&&wi<0;f++){ place(u,8,6,f); place(t,12,6,3); wi=u.weapons.findIndex(w=>w.k!=='flak'&&canFire(u,w,t)); }
    if(wi<0){ out.push('no shot'); continue; }
    u.mp=6; u.postFire=false; u.postMp=0;
    await fireWeapon(u,wi,t);
    out.push('postMp '+u.postMp+' of 6'); }
  row('r_slip movement after firing', out);
}

// Hot Tubes: the reload the game actually builds (mkWeapon clamps to 1).
{
  const out=[];
  for(let r=0;r<3;r++){ setup([{id:'e_reload',r}],['harrow'],['h_dominion']);
    const w=derive(RUN.fleet[0]).weapons.find(x=>x.k==='torp');
    out.push('torp cd '+w.cd); }
  row('e_reload torpedo cooldown', out);
  console.log('e_reload base torpedo cooldown is 2 (data.js W), the rule is Math.max(1, cd - torpCd)');
}

// Marked for Death: aim bonus the game stores, and the hit chance it buys.
{
  const stored=[], base=[], marked=[];
  for(let r=0;r<3;r++){ const {P,E}=setup([{id:'a_mark',r}],['cathedral','penitent'],['h_dominion']); clearT(); const u=P[0], t=E[0];
    let wi=-1; for(let f=0;f<6&&wi<0;f++){ place(u,8,6,f); place(t,12,6,3); wi=u.weapons.findIndex(w=>w.k==='lance'&&canFire(u,w,t)); }
    if(wi<0){ stored.push('no shot'); continue; }
    const w=u.weapons[wi]; const aim=10*(ownerFx(u).markLance||1); stored.push('+'+aim+' aim');
    const c0=hitChance(u,w,t); B.mark=B.mark||{}; B.mark[u.side]={id:t.id,r:B.round,aim}; const c1=hitChance(u,w,t);
    base.push(c0); marked.push(c1); }
  row('a_mark stored aim', stored);
  row('a_mark hit chance unmarked', base.map(x=>x+'%'));
  row('a_mark hit chance marked', marked.map(x=>x+'%'));
}

// Carrier and squad values (derive reads the shipped boon fx).
{
  const hangar=[], repair=[];
  for(let r=0;r<3;r++){ setup([{id:'h_hatch',r}],['reliquary'],['h_dominion']); hangar.push('hangar '+derive(RUN.fleet[0]).hangar); }
  for(let r=0;r<3;r++){ const {P}=setup([{id:'h_brood',r}],['reliquary'],['h_dominion']); repair.push('repair '+Math.round((ownerFx(P[0]).broodRepair||0)*100)+'%'); }
  row('h_hatch reliquary hangar', hangar);
  row('h_brood repair on free wing', repair);
}

// Chain Lightning residual shield on the neighbours after a facing is knocked out.
{
  const res=[];
  for(let r=0;r<3;r++){ const {P}=setup([{id:'s_chain',r}],['penitent'],['h_dominion']); const c=ownerFx(P[0]).chainSh||0;
    res.push(Math.round((1-c)*100)+'% left'); }
  row('s_chain neighbour shield left', res);
}

// Spread Pattern splash fraction.
{
  const res=[];
  for(let r=0;r<3;r++){ const {P}=setup([{id:'e_spread',r}],['harrow'],['h_dominion']); res.push(Math.round((ownerFx(P[0]).spread||0)*100)+'%'); }
  row('e_spread splash of one torp', res);
}
`;

eval(['data.js', 'core.js', 'battle.js'].map((f) => fs.readFileSync(f, 'utf8')).join('\n') + HEAD + body + TAIL);
