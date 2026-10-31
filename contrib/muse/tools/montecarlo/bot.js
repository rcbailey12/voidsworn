// bot.js - the player-side battle bot, copied verbatim from the game's own
// simulator (sim3d.js: botObj, botCommand, botUnit), plus its alternating-
// activation battle loop (sim3d.js campaignSim inner loop). This is the same
// pilot wave 3 used, so results stay comparable with the filed evidence.
// Appended into the game vm context by shard.js; not a game file.
function botObj(v){ const o=B.obj; if(!o) return 0; const col=h=>h.q+Math.floor(h.r/2);
  if(o.type==='hold') return hdist(v,o.hex)*1.6;
  if(o.type==='break') return Math.max(0,o.exitC-col(v))*6;
  if(o.type==='defend') return Math.max(0,hdist(v,o.hex)-3)*1.2;
  if(o.type==='intercept'){ const tr=alive('enemy').filter(x=>x.transport); return tr.length?Math.min(...tr.map(t=>hdist(v,t)))*2.5:0; }
  if(o.type==='hunt'){ const f=alive('enemy').find(x=>x.flagship); return f?hdist(v,f)*2.5:0; }
  return 0; }
async function botCommand(){ if(!canCommand('player')) return; const c=commandFor('player'); if(!c) return;
  const pl=alive('player').filter(x=>!x.isSq), en=alive('enemy').filter(x=>!x.isSq); if(!pl.length||!en.length) return;
  const near=en.filter(e=>pl.some(p=>hdist(p,e)<=8)).length, hpR=pl.reduce((a,p)=>a+p.hp,0)/pl.reduce((a,p)=>a+p.maxHp,0), hurt=pl.some(p=>p.hp<p.maxHp*.5);
  const id=c.id, off=['barrage','hunt','scramble','surge'].includes(id);
  if((off&&(near>=2||B.round>=4))||(id==='restore'&&hpR<.6)||(id==='iron'&&(hurt||near>=2))||B.round>=6) await useCommand('player'); }
async function botUnit(u){
  if(B.over||u.dead) return; if(canStance(u)) aiStance(u);
  await botCommand(); if(B.over||u.dead) return;
  if(u.ab && canAbility(u)){ if(u.ab==='launch'){ const hs=launchHexes(u); if(hs.length) await useAbility(u,{hex:hs[0],kind:u.fac==='voidsworn'?(rnd()<.5?'fighter':'bomber'):wingKind(u)}); }
    else if(u.ab==='nova'){ const t=novaTargets(u).find(h=>alive('enemy').some(e=>hdist(e,h)<=1)&&!alive('player').some(p=>hdist(p,h)<=1)); if(t) await useAbility(u,{hex:t}); }
    else await useAbility(u); }
  if(!u.isSq) await tacticRam(u); if(B.over||u.dead) return;
  const foes=alive('enemy'); if(!foes.length) return;
  const {states}=computeReach(u); let best=null,bs=-1e9;
  for(const s of states){ const v=stateView(u,s); const off=evalOffense(v,u.weapons.filter(weaponReady),foes); const th=evalThreat(v,foes); const nd=Math.min(...foes.map(f=>hdist(v,f))); const sc=off-th*.3-(off>0?0:nd*3)-botObj(v)-torpThreat(u,v)*.9-syncPull(u,v)*1.5; if(sc>bs){bs=sc;best=s;} }
  if(best&&best.path.length) await moveUnit(u,best);
  if(!u.isSq && await tacticBoard(u)){ u.activated=true; return; }
  for(let i=0;i<u.weapons.length;i++){ let bt=null,bv=0; for(const t of alive('enemy')){ if(canFire(u,u.weapons[i],t)){ const e=expectedVs(u,u.weapons[i],t); const v=e.hull+e.shield*.3+(e.hull>=t.hp?20:0); if(v>bv){bv=v;bt=t;} } } if(bt) await fireWeapon(u,i,bt); if(B.over) return; }
  if(!u.isSq&&!u.dead&&!B.over&&!u.weapons.some(w=>w.fired)&&u.hp<u.maxHp*.5&&canOrder(u,'brace')&&evalThreat(u,alive('enemy'))>10) giveOrder(u,'brace');
  if(!u.isSq&&!u.dead&&!B.over&&canFade(u)) await fadeMove(u);
  u.activated=true;
}
// Alternating activations, the shipped default (SETUP.alt=true): sim3d's loop.
async function mcBattleLoop(){
  let r=0; B.alt=true; for(const x of B.units) x.activated=false; startSideTurn('enemy');
  while(!B.over&&r<30){
    await swarmPhase('player'); await swarmPhase('enemy');
    let g=0;
    while(!B.over&&g++<40){ const pp=alive('player').filter(x=>!x.isSq&&!x.activated), pe=alive('enemy').filter(x=>!x.isSq&&!x.activated); if(!pp.length&&!pe.length) break;
      if(pp.length){ await botUnit(pp[0]); pp[0].activated=true; if(B.over) break; }
      const pp2=alive('player').filter(x=>!x.isSq&&!x.activated); const sqs=alive('enemy').filter(x=>x.isSq&&!x.activated); const batch=pp2.length?(pe.length?[aiPickActivation(pe)]:[]):pe;
      for(const u of [...sqs,...batch]){ if(B.over) break; await aiUnit(u); u.activated=true; } }
    if(B.over) break; B.round++; for(const x of B.units) x.activated=false; await roundStart(); r++; }
  return B.over||'timeout';
}
