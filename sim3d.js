global.window={}; global.document=undefined; global.performance={now:()=>Date.now()};
const fs=require('fs');
eval(['data.js','core.js','battle.js'].map(f=>fs.readFileSync(f,'utf8')).join('\n')+`
function log(m){ if(B&&B.log) B.log.push({m}); } function fxText(){} function fxShield(){} function fxFlash(){}
var CLOCK={old:0,neu:0,real:0,rounds:0}, ESC=1;
// B2 timing model 'real': the game's own presentation durations (fx3d.js animPath, wfx3d.js animWeapon, fx3d.js animExplode, ui3d.js turn waits),
// scaled by the speed the game runs that phase at (PACE in core.js: player 1, enemy activations PACE.enemy, the enemy tail PACE.tail, wings PACE.swarm).
// PACE_OLD=1 puts the pre-B2 pace back, for a like-for-like baseline. 'old' and 'neu' are the earlier models, kept for comparison.
var SIMSPD=1, SHIPS={p:0,e:0}, CAT={}, TEMPO={pa:0,ea:0,fire:0,rounds:0,firstLoss:0,firstN:0}; function addR(k,t,u){ CLOCK.real+=t; const key=k+(u?(u.side==='player'?':p':':e')+(u.isSq?'sq':''):''); CAT[key]=(CAT[key]||0)+t; } const MOVE_PER={voidsworn:1.25,hegemony:.75,corsair:.85,chorus:1.1,ithar:1,deathless:.6}, CLS_L={Frigate:6.5,Destroyer:9.5,Cruiser:14.5,Carrier:16.5,Battleship:21,Dreadnought:27,'Super-dreadnought':31,Transport:11,'Battle-barge':26};
if(process.env.PACE_OLD==='1') Object.assign(PACE,{move:1,rot:.75,enemy:.65,tail:.65,swarm:1,banner:520,aiGap:60,aiEnd:120,volley:1,bigMin:1});
async function animPath(u,path,opt){ const hex=path.filter(p=>!p.rot).length, rot=path.length-hex; for(const st of path){ if(st.rot) CLOCK.neu+=ESC*u.size>.8?.26:.19; else CLOCK.neu+=ESC*u.isSq?.07:u.size>.8?.19:.15; } CLOCK.old+=hex*(u.isSq?.11:u.size>.8?.3:.22)+rot*(u.size>.8?.42:.28);
  const S=hex+rot*(u.isSq?.3:PACE.rot), per=(u.isSq?110:u.size>.8?430:u.size>.6?350:280)*(u.isSq?1:(MOVE_PER[u.fac]||1)); addR('move',Math.min((per*S+(u.isSq?60:260))*(opt&&opt.charge?.72:1)*(u.isSq?1:PACE.move),u.isSq?900:3600)/1000*SIMSPD,u);
  if(opt&&opt.onLate) await opt.onLate(); }
function realLen(u){ return (u.t&&CLS_L[u.t.cls])||(6+(u.size||.6)*14); }
async function animMove(u,q,r,f){ u.q=q; u.r=r; u.facing=f; CLOCK.old+=u.isSq?.11:u.size>.8?.3:.22; CLOCK.neu+=ESC*u.isSq?.07:u.size>.8?.19:.15; } async function animRotate(u,f){ u.facing=f; CLOCK.old+=u.size>.8?.42:.28; CLOCK.neu+=ESC*u.size>.8?.26:.19; }
async function animWeapon(u,w,t,shots){ const n=shots.length, vk=!u.isSq&&u.weapons.some(x=>x!==w&&x.fired)?PACE.volley:1; addR('fire',vk*(w.k==='lance'?.32+.32+n*.25+.15:w.k==='torp'?.32+.32+n*.12+.84:n*.07+.49+(w.arc==='T'&&!u.isSq?.16:0))*SIMSPD,u); if(w.k==='lance'){ CLOCK.old+=.48+n*.34+.22; CLOCK.neu+=ESC*.32+n*.25+.15; } else if(w.k==='torp'){ CLOCK.old+=.48+n*.17+1.07; CLOCK.neu+=ESC*.32+n*.12+.84; } else { CLOCK.old+=(u.isSq?0:.48)+n*.095+.59; CLOCK.neu+=ESC*n*.07+.49; } } async function animExplode(u){ const dk=u.side==='enemy'&&!u.isSq&&!(u.t&&u.t.boss)?enemyPaceK():1, sp=SIMSPD*dk; addR('explode',u.isSq?.25*sp:(.7+.014*realLen(u))*Math.max(.4,sp)+.35*sp,u); CLOCK.old+=u.isSq?.25:1.2; CLOCK.neu+=ESC*u.isSq?.25:.68; } async function animNova(){} async function fxRam(){ STATS.rams++; } async function fxBoard(){ STATS.boards++; } function onCapture(){ STATS.caps++; } function fxShieldBreak(){} function fxWithdraw(){}
SPEED=0; if(process.env.SEED) rndSeed(+process.env.SEED);
var AI_LEVEL=process.env.AI||'veteran'; var NO_CAP=process.env.CAP==='0';
function botObj(v){ const o=B.obj; if(!o) return 0; const col=h=>h.q+Math.floor(h.r/2);
  if(o.type==='hold') return hdist(v,o.hex)*1.6;
  if(o.type==='break') return Math.max(0,o.exitC-col(v))*6;
  if(o.type==='defend') return Math.max(0,hdist(v,o.hex)-3)*1.2;
  if(o.type==='intercept'){ const tr=alive('enemy').filter(x=>x.transport); return tr.length?Math.min(...tr.map(t=>hdist(v,t)))*2.5:0; }
  if(o.type==='hunt'){ const f=alive('enemy').find(x=>x.flagship); return f?hdist(v,f)*2.5:0; }
  return 0; }
async function botTurn(){ await swarmPhase('player');
  for(const u of alive('player').filter(x=>!x.isSq)){
    if(B.over||u.dead) continue;
    if(u.ab && canAbility(u)){ if(u.ab==='launch') await useAbility(u,{hex:launchHexes(u)[0],kind:rnd()<.5?'fighter':'bomber'});
      else if(u.ab==='nova'){ const t=novaTargets(u).find(h=>alive('enemy').some(e=>hdist(e,h)<=1)&&!alive('player').some(p=>hdist(p,h)<=1)); if(t) await useAbility(u,{hex:t}); }
      else await useAbility(u); }
    const foes=alive('enemy'); if(!foes.length) break;
    const {states}=computeReach(u); let best=null,bs=-1e9;
    const PFb=pathField(foes.filter(f=>!f.isSq)); for(const s of states){ const v=stateView(u,s); const off=evalOffense(v,u.weapons.filter(weaponReady),foes); const th=evalThreat(v,foes); const hd=Math.min(...foes.map(f=>hdist(v,f))), nd=Math.max(hd,fieldDist(PFb,v,hd)); const sc=off-th*.3-(off>0?0:nd*3)-botObj(v); if(sc>bs){bs=sc;best=s;} }
    if(best&&best.path.length) await moveUnit(u,best);
    for(let i=0;i<u.weapons.length;i++){ let bt=null,bv=0; for(const t of alive('enemy')){ if(canFire(u,u.weapons[i],t)){ const e=expectedVs(u,u.weapons[i],t); const v=e.hull+e.shield*.3+(e.hull>=t.hp?20:0); if(v>bv){bv=v;bt=t;} } } if(bt) await fireWeapon(u,i,bt); if(B.over) return; }
  }
}
async function sim(S,sector){
  RUN={admiral:'vex',credits:0,cpCap:40,sector,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]};
  for(const t of S.player) RUN.fleet.push(newShip(t,true));
  RUN.boons=(S.boons||process.env.BOONS||'').split(',').filter(Boolean).map(x=>({id:x.split(':')[0],r:+(x.split(':')[1]||0)})); RUN.aspect=S.aspect||process.env.ASPECT||null; RUN.flagUid=RUN.fleet[0].uid;
  startBattle({kind:S.kind,fac:S.fac||'hegemony',col:3,enemies:S.enemy.map(tpl=>({tpl}))});
  let r=0;
  if(process.env.ALT==='1'){ B.alt=true; for(const x of B.units) x.activated=false; startSideTurn('enemy'); // alternating activations, as the game plays by default
    while(!B.over&&r<30){ await swarmPhase('player'); await swarmPhase('enemy'); let g=0;
      while(!B.over&&g++<40){ const pp=alive('player').filter(x=>!x.isSq&&!x.activated), pe=alive('enemy').filter(x=>!x.isSq&&!x.activated); if(!pp.length&&!pe.length) break;
        if(pp.length){ await botUnit(pp[0]); pp[0].activated=true; } const batch=alive('player').some(x=>!x.isSq&&!x.activated)?(pe.length?[aiPickActivation(pe)]:[]):pe; for(const u of batch){ if(B.over) break; await aiUnit(u); u.activated=true; } }
      if(B.over) break; B.round++; for(const x of B.units) x.activated=false; startSideTurn('player'); startSideTurn('enemy'); r++; } }
  else while(!B.over && r<30){ await botTurn(); if(B.over) break; B.side='enemy'; startSideTurn('enemy'); await aiTurn(); if(B.over) break; B.round++; B.side='player'; startSideTurn('player'); r++; }
  if(process.env.SQDBG){ const g=global.SQD=global.SQD||{}; for(const u of B.units){ const k=u.side+':'+(u.isSq?'sq:'+u.t.sq:u.tpl); g[k]=g[k]||{dealt:0,n:0,died:0}; g[k].dealt+=u.dealt||0; g[k].n++; if(u.dead) g[k].died++; } }
  const pl=B.units.filter(u=>u.side==='player'&&!u.isSq);
  if(process.env.NANDBG){ for(const u of pl) if(!isFinite(u.hp)||!isFinite(u.maxHp)) console.log('NaN unit',u.tpl,u.name,u.hp,u.maxHp,u.captured?'captured':'',u.reinf?'reinf':''); }
  return {res:B.over||'timeout', rounds:B.round, hpLeft:pl.reduce((a,u)=>a+Math.max(0,u.hp),0)/pl.reduce((a,u)=>a+u.maxHp,0), lost:pl.filter(u=>u.dead).length};
}

// hand-built fleets: fixed composition per faction, so tuning moves smoothly instead of jumping when a points budget tips over
const FLEET_LISTS={
  voidsworn:{sk:['cathedral','penitent','reliquary','harrow','warden','warden'],fl:['ascendant','cathedral','penitent','harrow','warden']},
  hegemony:{sk:['h_dominion','h_vanguard','h_interdictor','h_picket','h_picket','h_picket','h_picket'],fl:['h_boss','h_vanguard','h_interdictor','h_picket','h_picket']},
  corsair:{sk:['c_hulk','c_marauder','c_marauder','c_reaver','c_reaver','c_raider','c_raider','c_raider','c_raider','c_raider','c_raider'],fl:['c_boss','c_marauder','c_reaver','c_raider','c_raider','c_raider']},
  chorus:{sk:['b_brood','b_razor','b_razor','b_spitter','b_spitter','b_drone','b_drone','b_drone','b_drone'],fl:['b_boss','b_razor','b_spitter','b_drone','b_drone']},
  ithar:{sk:['i_carrier','i_song','i_song','i_blade','i_blade','i_wisp','i_wisp','i_wisp'],fl:['i_boss','i_song','i_blade','i_wisp','i_wisp']},
  deathless:{sk:['d_harvester','d_harvester','d_jackal','d_jackal','d_scythe','d_scythe','d_scythe','d_scythe'],fl:['d_boss','d_harvester','d_jackal','d_scythe']},
};
function genFleet(fac,mode){ const L=FLEET_LISTS[fac]||FLEET_LISTS.hegemony; return (mode==='fl'?L.fl:L.sk).slice(); }
// the bot uses the player's whole toolkit: Admiral's Command and Brace, not just guns, rams and boarding
async function botCommand(){ if(process.env.BOTCMD==='0'||!canCommand('player')) return; const c=commandFor('player'); if(!c) return;
  const pl=alive('player').filter(x=>!x.isSq), en=alive('enemy').filter(x=>!x.isSq); if(!pl.length||!en.length) return;
  const near=en.filter(e=>pl.some(p=>hdist(p,e)<=8)).length, hpR=pl.reduce((a,p)=>a+p.hp,0)/pl.reduce((a,p)=>a+p.maxHp,0), hurt=pl.some(p=>p.hp<p.maxHp*.5);
  const id=c.id, off=['barrage','hunt','scramble','surge'].includes(id);
  if((off&&(near>=2||B.round>=4))||(id==='restore'&&hpR<.6)||(id==='iron'&&(hurt||near>=2))||B.round>=6) await useCommand('player'); }
async function botUnit(u){
  if(B.over||u.dead) return;
  await botCommand(); if(B.over||u.dead) return;
  if(u.ab && canAbility(u)){ if(u.ab==='launch'){ const hs=launchHexes(u); if(hs.length) await useAbility(u,{hex:hs[0],kind:u.fac==='voidsworn'?(rnd()<.5?'fighter':'bomber'):wingKind(u)}); }
    else if(u.ab==='nova'){ const t=novaTargets(u).find(h=>alive('enemy').some(e=>hdist(e,h)<=1)&&!alive('player').some(p=>hdist(p,h)<=1)); if(t) await useAbility(u,{hex:t}); }
    else await useAbility(u); }
  if(!u.isSq) await tacticRam(u); if(B.over||u.dead) return;
  const foes=alive('enemy'); if(!foes.length) return;
  const {states}=computeReach(u); let best=null,bs=-1e9;
  for(const s of states){ const v=stateView(u,s); const off=evalOffense(v,u.weapons.filter(weaponReady),foes); const th=evalThreat(v,foes); const nd=Math.min(...foes.map(f=>hdist(v,f))); const sc=off-th*.3-(off>0?0:nd*3)-botObj(v); if(sc>bs){bs=sc;best=s;} }
  if(best&&best.path.length) await moveUnit(u,best);
  if(!u.isSq && await tacticBoard(u)){ u.activated=true; return; }
  for(let i=0;i<u.weapons.length;i++){ let bt=null,bv=0; for(const t of alive('enemy')){ if(canFire(u,u.weapons[i],t)){ const e=expectedVs(u,u.weapons[i],t); const v=e.hull+e.shield*.3+(e.hull>=t.hp?20:0); if(v>bv){bv=v;bt=t;} } } if(bt) await fireWeapon(u,i,bt); if(B.over) return; }
  if(process.env.BOTBRACE!=='0'&&!u.isSq&&!u.dead&&!B.over&&!u.weapons.some(w=>w.fired)&&u.hp<u.maxHp*.5&&canOrder(u,'brace')&&evalThreat(u,alive('enemy'))>10) giveOrder(u,'brace');
  u.activated=true;
}
async function match(pf,ef,mode,alt){
  RUN={admiral:'vex',credits:0,cpCap:40,sector:mode==='fl'?3:1,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]};
  for(const t of genFleet(pf,mode)) RUN.fleet.push(newShip(t,true));
  startBattle({kind:mode==='fl'?'boss':'battle',fac:ef,col:3,enemies:genFleet(ef,mode).map(tpl=>({tpl})),dep:pick(['line','flank','ambush'])});
  STATS.rounds+=0; let r=0;
  if(!alt){ while(!B.over&&r<30){ await botTurn(); if(B.over) break; B.side='enemy'; startSideTurn('enemy'); await aiTurn(); if(B.over) break; B.round++; B.side='player'; startSideTurn('player'); r++; } }
  else { B.alt=true; for(const x of B.units) x.activated=false; startSideTurn('enemy');
    while(!B.over&&r<30){
      await swarmPhase('player'); await swarmPhase('enemy');
      let guard=0;
      while(!B.over&&guard++<40){ const pp=alive('player').filter(x=>!x.isSq&&!x.activated), pe=alive('enemy').filter(x=>!x.isSq&&!x.activated); if(!pp.length&&!pe.length) break;
        if(pp.length){ await botUnit(pp[0]); pp[0].activated=true; if(B.over) break; }
        const pp2=alive('player').filter(x=>!x.isSq&&!x.activated);
        const sqs=alive('enemy').filter(x=>x.isSq&&!x.activated); const batch=pp2.length?(pe.length?[aiPickActivation(pe)]:[]):pe;
        for(const u of [...sqs,...batch]){ if(B.over) break; await aiUnit(u); u.activated=true; } }
      if(B.over) break; B.round++; for(const x of B.units) x.activated=false; startSideTurn('player'); startSideTurn('enemy'); r++; } }
  STATS.n++; STATS.rounds+=B.round; STATS.timeout+=B.over?0:1; STATS.secs+=B.units.reduce((a,x)=>a+(x.sec?Object.values(x.sec).filter(z=>z.broken).length:0),0);
  return B.over==='win';
}
var STATS={n:0,rounds:0,timeout:0,rams:0,boards:0,caps:0,secs:0};
global.match=match;
var OBJS_SEEN={};
async function campaignSim(n){ const FLEET={1:['penitent','harrow','warden','warden'],2:['cathedral','penitent','harrow','warden','warden'],3:['ascendant','cathedral','penitent','reliquary','harrow']};
  for(const [sec,kind,col] of (process.env.ONLY_BOSS?[[1,'boss',6],[3,'boss',6],[1,'elite',4]]:[1,2,3].flatMap(sc=>[['battle',1],['battle',4],['elite',4],['boss',6]].map(k=>[sc,...k])))){ let w=0,rounds=0,hull=0,lost=0,to=0; CLOCK.old=0; CLOCK.neu=0; CLOCK.real=0; CLOCK.rounds=0; CLOCK.maxR=0; SHIPS.p=0; SHIPS.e=0; for(const k in CAT) delete CAT[k]; for(const k in TEMPO) TEMPO[k]=0;
    for(let i=0;i<n;i++){ RUN={admiral:'vex',credits:0,cpCap:40,sector:sec,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]};
      for(const t of FLEET[sec]) RUN.fleet.push(newShip(t,true)); const fac=pick(SECTOR_POOL[sec-1]);
      const obj=kind==='boss'?'rout':pick(['rout','rout','flagship','hold']); OBJS_SEEN[obj]=(OBJS_SEEN[obj]||{n:0,w:0}); OBJS_SEEN[obj].n++;
      startBattle({kind,fac,col,obj,dep:kind==='boss'?'line':pick(['line','line','flank','ambush'])}); TEMPO._lost=0; SHIPS.p+=B.units.filter(x=>x.side==='player'&&!x.isSq).length; SHIPS.e+=B.units.filter(x=>x.side==='enemy'&&!x.isSq).length; let r=0; B.alt=true; for(const x of B.units) x.activated=false; startSideTurn('enemy');
      while(!B.over&&r<30){ const r0=CLOCK.real; TEMPO.rounds++; if(!TEMPO._lost&&B.units.some(x=>x.side==='player'&&x.ship&&x.dead)){ TEMPO._lost=1; TEMPO.firstLoss+=B.round; TEMPO.firstN++; } SIMSPD=PACE.swarm*enemyPaceK(); await swarmPhase('player'); await swarmPhase('enemy'); SIMSPD=1; let g=0; CLOCK.rounds++;
        while(!B.over&&g++<40){ const pp=alive('player').filter(x=>!x.isSq&&!x.activated), pe=alive('enemy').filter(x=>!x.isSq&&!x.activated); if(!pp.length&&!pe.length) break;
          if(pp.length){ SIMSPD=1; TEMPO.pa++; await botUnit(pp[0]); pp[0].activated=true; if(B.over) break; } const pp2=alive('player').filter(x=>!x.isSq&&!x.activated); const sqs=alive('enemy').filter(x=>x.isSq&&!x.activated); const batch=pp2.length?(pe.length?[aiPickActivation(pe)]:[]):pe;
          SIMSPD=(pp2.length?PACE.enemy:PACE.tail)*enemyPaceK(); for(const u of [...sqs,...batch]){ if(B.over) break; if(!u.isSq) TEMPO.ea++; ESC=.65; await aiUnit(u); if(!u.isSq&&u.weapons.some(w=>w.fired)) TEMPO.fire++; ESC=1; CLOCK.old+=.16+.12; CLOCK.neu+=.06*.65+.06; addR('aigap',PACE.aiGap/1000*SIMSPD); u.activated=true; } if(sqs.length||batch.length) addR('aiend',PACE.aiEnd/1000*SIMSPD); SIMSPD=1; CLOCK.old+=.25; CLOCK.neu+=.12; }
        CLOCK.old+=1.02; CLOCK.neu+=.66; addR('banner',(PACE.banner+140)/1000); CLOCK.maxR=Math.max(CLOCK.maxR,CLOCK.real-r0); if(B.over) break; B.round++; for(const x of B.units) x.activated=false; startSideTurn('player'); startSideTurn('enemy'); r++; }
      const pl=B.units.filter(u=>u.side==='player'&&u.ship); if(B.over==='win'){ w++; (OBJS_SEEN[B.obj.type]=OBJS_SEEN[B.obj.type]||{n:0,w:0}).w++; } if(!B.over) to++; rounds+=B.round; hull+=pl.reduce((a,u)=>a+Math.max(0,u.dead?0:u.hp),0)/pl.reduce((a,u)=>a+u.maxHp,0); lost+=B.units.filter(u=>u.ship&&(u.dead||u.side!=='player')).length; }
    console.log(\`sector \${sec} \${kind.padEnd(6)} win \${Math.round(w/n*100)}%  rounds \${(rounds/n).toFixed(1)}  hull left \${Math.round(hull/n*100)}%  ships lost \${(lost/n).toFixed(1)}  timeouts \${to}  wait old \${Math.round(CLOCK.old/n)}s new \${Math.round(CLOCK.neu/n)}s  real \${Math.round(CLOCK.real/n)}s  per round \${(CLOCK.real/Math.max(1,CLOCK.rounds)).toFixed(1)}s  max round \${(CLOCK.maxR||0).toFixed(1)}s  ships \${(SHIPS.p/n).toFixed(1)}+\${(SHIPS.e/n).toFixed(1)}\`); console.log('   tempo: enemy activations per player activation '+(TEMPO.ea/Math.max(1,TEMPO.pa)).toFixed(2)+', enemy ships firing per round '+(TEMPO.fire/Math.max(1,TEMPO.rounds)).toFixed(1)+', first player ship lost in round '+(TEMPO.firstN?(TEMPO.firstLoss/TEMPO.firstN).toFixed(1):'none')); if(process.env.CATS) console.log('   per round: '+Object.entries(CAT).sort((a,b)=>b[1]-a[1]).map(([k,v])=>k+' '+(v/Math.max(1,CLOCK.rounds)).toFixed(2)).join(', ')); } }
// B2: ships on board per sector and node, like the Oct 24 measurement (plan section 10): campaignSim's reference fleets, N battles per cell, non-squadron units per side
function shipCount(n){ const FLEET={1:['penitent','harrow','warden','warden'],2:['cathedral','penitent','harrow','warden','warden'],3:['ascendant','cathedral','penitent','reliquary','harrow']};
  for(const sec of [1,2,3]){ const row=[]; for(const [kind,cols] of [['battle',[1,2,3,4,5]],['elite',[3,4,5]],['boss',[6]]]){ let p=0,e=0,mx=0,c=0;
      for(const col of cols) for(let i=0;i<n;i++){ RUN={admiral:'vex',credits:0,cpCap:40,sector:sec,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]}; for(const t of FLEET[sec]) RUN.fleet.push(newShip(t,true));
        startBattle({kind,fac:pick(SECTOR_POOL[sec-1]),col,obj:'rout'}); const pp=B.units.filter(u=>u.side==='player'&&!u.isSq).length, ee=B.units.filter(u=>u.side==='enemy'&&!u.isSq).length; p+=pp; e+=ee; mx=Math.max(mx,pp+ee); c++; }
      row.push(kind+' '+(p/c).toFixed(1)+'+'+(e/c).toFixed(1)+'='+((p+e)/c).toFixed(1)+' (max '+mx+')'); }
    console.log('sector '+sec+' ships on board: '+row.join(' | ')); } }
var FZ_ENC=process.env.ENC||null, FZ_OUT={};
async function fuzz(n){ const F=['voidsworn','hegemony','corsair','chorus','ithar','deathless']; let ex=0, bad=[], rounds=0;
  for(let i=0;i<n;i++){ try{ const pf=pick(F), ef=pick(F), mode=rnd()<.3?'fl':'sk';
      RUN={admiral:'vex',credits:0,cpCap:40,sector:mode==='fl'?3:1,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]};
      for(const t of genFleet(pf,mode)) RUN.fleet.push(newShip(t,true));
      startBattle({kind:mode==='fl'?'boss':'battle',fac:ef,col:3,enemies:genFleet(ef,mode).map(tpl=>({tpl})),map:pick(['belt','station','planet','storm','graveyard']),dep:pick(['line','flank','ambush']),obj:FZ_ENC||pick(Object.keys(ENCOUNTERS)),shape:process.env.FZ_SHAPE||pick(Object.keys(SHAPES))}); B.event=rollBattleEvent(B.cfg,process.env.EVT||(rnd()<.5?'any':null)); FZ_OUT[B.obj.type]=FZ_OUT[B.obj.type]||{n:0,win:0,partial:0,withdraw:0,timeout:0,rounds:0};
      const check=tag=>{ const seen=new Set(); for(const u of alive()){ const k=u.q+','+u.r; if(seen.has(k)) bad.push(tag+' overlap '+u.tpl); seen.add(k); if(blocks(terr(u.q,u.r))) bad.push(tag+' on '+terr(u.q,u.r)+' '+u.tpl); if(!isFinite(u.hp)||(u.crewMax&&!isFinite(u.crew))) bad.push(tag+' NaN '+u.tpl); if(!onBoard(u.q,u.r)) bad.push(tag+' offboard '+u.tpl); } if(B.resolve.player<0||B.resolve.enemy<0||B.resolve.player>5||B.resolve.enemy>5) bad.push(tag+' resolve '+JSON.stringify(B.resolve)); };
      check('deploy'); let r=0; B.alt=true; for(const x of B.units) x.activated=false; startSideTurn('enemy');
      while(!B.over&&r<30){ await swarmPhase('player'); await swarmPhase('enemy'); let g=0;
        while(!B.over&&g++<40){ const pp=alive('player').filter(x=>!x.isSq&&!x.activated), pe=alive('enemy').filter(x=>!x.isSq&&!x.activated); if(!pp.length&&!pe.length) break;
          if(pp.length){ await botUnit(pp[0]); pp[0].activated=true; } const sqs=alive('enemy').filter(x=>x.isSq&&!x.activated); const batch=alive('player').some(x=>!x.isSq&&!x.activated)?(pe.length?[aiPickActivation(pe)]:[]):pe; for(const u of [...sqs,...batch]){ if(B.over) break; await aiUnit(u); u.activated=true; } }
        check('r'+r); if(B.over) break; B.round++; for(const x of B.units) x.activated=false; startSideTurn('player'); startSideTurn('enemy'); r++; }
      { const z=FZ_OUT[B.obj.type]; z.n++; z.rounds+=B.round; if(!B.over) z.timeout++; else if(B.partial) z.partial++; else if(B.over==='win') z.win++; else if(B.withdraw) z.withdraw++; }
      rounds+=B.round; }catch(e){ ex++; if(ex<4) console.log('EXCEPTION',e.message,(e.stack||'').split('\\n').slice(1,3).join(' | ')); } }
  if(process.env.ENCS) for(const [k,z] of Object.entries(FZ_OUT)) console.log(\`  \${k.padEnd(10)} n \${z.n}  win \${z.win}  partial \${z.partial}  withdraw \${z.withdraw}  loss \${z.n-z.win-z.partial-z.withdraw-z.timeout}  timeout \${z.timeout}  rounds \${(z.rounds/z.n).toFixed(1)}\`);
  const u=[...new Set(bad)]; console.log(\`fuzz \${n} battles: exceptions \${ex}, invariant breaks \${bad.length} (\${u.length} distinct), avg rounds \${(rounds/n).toFixed(1)}\`); u.slice(0,12).forEach(x=>console.log('  ',x)); }
function evCheck(){ const out=[];
  for(const k of ['reinf_enemy','reinf_ally','flare']){ RUN={admiral:'vex',fac:'voidsworn',credits:0,cpCap:40,sector:2,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]};
    for(const t of ['penitent','harrow','warden']) RUN.fleet.push(newShip(t,false));
    startBattle({kind:'battle',fac:'hegemony',col:2,dep:'line',obj:'rout',shape:'open'}); B.event=rollBattleEvent(B.cfg,k); B.event.r=3;
    const n0={p:B.units.filter(u=>u.side==='player').length,e:B.units.filter(u=>u.side==='enemy').length}; let warned=false, shieldsAt3=null;
    for(let r=2;r<=3;r++){ B.round=r; startSideTurn('player'); startSideTurn('enemy'); if(r===2) warned=!!B.event.warned; if(r===3) shieldsAt3=B.units.filter(u=>!u.dead&&u.shMax>0).every(u=>u.sh.every(x=>x===0)); }
    const n1={p:B.units.filter(u=>u.side==='player').length,e:B.units.filter(u=>u.side==='enemy').length}; const nu=B.units.find(u=>u.reinf);
    const ok=warned&&(k==='flare'?shieldsAt3:(k==='reinf_enemy'?n1.e===n0.e+1:n1.p===n0.p+1)&&nu&&onBoard(nu.q,nu.r)&&!blocks(terr(nu.q,nu.r))&&B.units.filter(u=>!u.dead&&u.q===nu.q&&u.r===nu.r).length===1);
    out.push((ok?'PASS ':'FAIL ')+k+' warned '+warned+' units '+JSON.stringify(n0)+' -> '+JSON.stringify(n1)+(nu?' new '+nu.name+' at '+nu.q+','+nu.r:'')+(k==='flare'?' all shields 0 in round 3: '+shieldsAt3:'')); }
  out.forEach(x=>console.log(x)); }
global.evCheck=evCheck;
async function bossCheck(n){ let odd=0; const outs={}; let rsum=0;
  for(let i=0;i<n;i++){ RUN={admiral:'aelith',fac:'ithar',credits:0,cpCap:40,sector:+(process.env.BS||1),relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]};
    for(const t of (process.env.BFL||'i_carrier,warden').split(',')) RUN.fleet.push(newShip(t,false));
    startBattle({kind:'boss',fac:process.env.BF||'voidsworn',col:6,dep:'line',obj:'rout',shape:process.env.BSHAPE||'open',map:process.env.BMAP||'planet'}); let r=0; B.alt=true; for(const x of B.units) x.activated=false; startSideTurn('enemy');
    while(!B.over&&r<30){ await swarmPhase('player'); await swarmPhase('enemy'); let g=0;
      while(!B.over&&g++<40){ const pp=alive('player').filter(x=>!x.isSq&&!x.activated), pe=alive('enemy').filter(x=>!x.isSq&&!x.activated); if(!pp.length&&!pe.length) break;
        if(pp.length){ await botUnit(pp[0]); pp[0].activated=true; } const batch=alive('player').some(x=>!x.isSq&&!x.activated)?(pe.length?[aiPickActivation(pe)]:[]):pe; for(const u of batch){ if(B.over) break; await aiUnit(u); u.activated=true; } }
      if(process.env.BDBG){ const bo=B.units.find(u=>u.boss); global.__bd=global.__bd||{}; const k=B.round; global.__bd[k]=global.__bd[k]||{n:0,hp:0,esc:0,pl:0}; const d=global.__bd[k]; d.n++; d.hp+=bo?Math.max(0,bo.hp)/bo.maxHp:0; d.esc+=B.units.filter(u=>u.side==='enemy'&&!u.boss&&!u.isSq&&!u.dead).length; d.pl+=alive('player').filter(u=>!u.isSq).length; }
      if(B.over) break; B.round++; for(const x of B.units) x.activated=false; startSideTurn('player'); startSideTurn('enemy'); r++; }
    if(process.env.BDBG){ global.__dd=global.__dd||{}; for(const u of B.units){ const k=u.side+':'+(u.isSq?'squadrons':u.t.boss?'BOSS':'ships'); global.__dd[k]=(global.__dd[k]||0)+(u.dealt||0); } global.__ddn=(global.__ddn||0)+1; }
    if(process.env.BDBG){ global.__cap=(global.__cap||0)+B.log.filter(l=>/now fights for the enemy/.test(l.m||'')).length; global.__boardE=(global.__boardE||0)+B.log.filter(l=>/ boards /.test(l.m||'')&&B.units.some(u=>u.side==='enemy'&&(l.m||'').startsWith(u.name))).length; }
    rsum+=B.round; if(process.env.RAMS) global.__rams=(global.__rams||0)+B.log.filter(l=>/ rams /.test(l.m||'')).length;
    const boss=B.units.find(u=>u.boss); const kills=B.units.filter(u=>u.side==='enemy'&&u.dead&&!u.fled&&!u.isSq).length;
    const key=B.over+(B.over==='win'&&boss&&!boss.dead?' BOSS ALIVE':''); outs[key]=(outs[key]||0)+1;
    if(B.over==='win'&&boss&&!boss.dead&&odd++<2){ console.log('--- odd win round',B.round,'boss hp',boss.hp+'/'+boss.maxHp,'escorts',B.units.filter(u=>u.side==='enemy'&&!u.boss&&!u.isSq).map(u=>u.tpl+(u.dead?(u.fled?':fled':':dead'):'')).join(','),'cp0',JSON.stringify(B.cp0),'sideCP',sideCP('enemy')); console.log(B.log.slice(-14).map(l=>'   '+l.m).join(' || ')); } }
  if(global.__bd) for(const [k,d] of Object.entries(global.__bd)) console.log('  r'+k,'n',d.n,'boss hp',(d.hp/d.n*100).toFixed(0)+'%','escorts',(d.esc/d.n).toFixed(1),'player ships',(d.pl/d.n).toFixed(1));
  if(global.__cap!=null) console.log('enemy captures per battle',(global.__cap/n).toFixed(2));
  if(global.__dd) console.log('damage dealt per battle', JSON.stringify(Object.fromEntries(Object.entries(global.__dd).map(([k,v])=>[k,Math.round(v/global.__ddn)]))));
  console.log('boss outcomes',JSON.stringify(outs),'rounds',(rsum/n).toFixed(1),global.__rams!=null?'rams/battle '+(global.__rams/n).toFixed(2):''); }
global.bossCheck=bossCheck;
async function ramCheck(n){ const outs={}; let shown=0;
  for(let i=0;i<n;i++){ RUN={admiral:'aelith',fac:'ithar',credits:0,cpCap:40,sector:1,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]};
    for(const t of ['i_carrier','warden']) RUN.fleet.push(newShip(t,false));
    startBattle({kind:'boss',fac:'voidsworn',col:6,dep:'line',obj:'rout',shape:'open',map:'planet'}); B.round=2;
    const boss=B.units.find(u=>u.boss), w=B.units.find(u=>u.tpl==='warden'); const occ=occMap();
    // put the boss two hexes behind the warden, facing it, so it can ram
    let ok=false; for(let f=0;f<6&&!ok;f++){ const d=DIRS[f]; const q=w.q-d[0]*2, r=w.r-d[1]*2; if(!onBoard(q,r)||blocks(terr(q,r))) continue; const mid={q:w.q-d[0],r:w.r-d[1]}; if(unitAt(mid.q,mid.r)||blocks(terr(mid.q,mid.r))) continue; if(unitAt(q,r)&&unitAt(q,r)!==boss) continue; boss.q=q; boss.r=r; boss.facing=f; boss.mp=boss.speed; ok=!!ramInfo(boss); }
    if(!ok){ outs.noRam=(outs.noRam||0)+1; continue; }
    const e=ramEstimate(boss,w); const hp0=boss.hp; await ramUnit(boss); escortsBreak(); checkEnd();
    const key=(B.over||'ongoing')+(boss.dead?' bossDead':'')+(w.dead?' wardenDead':''); outs[key]=(outs[key]||0)+1;
    if(B.over==='win'&&shown++<3) console.log('WIN after ram: boss hp',hp0,'->',boss.hp,'/',boss.maxHp,'recoil est',e.recoil,'dmg est',e.dmg,'| enemies',B.units.filter(u=>u.side==='enemy'&&!u.isSq).map(u=>u.tpl+':'+(u.dead?(u.fled?'fled':'dead'):u.hp)).join(','),'| cp0',JSON.stringify(B.cp0),'cp',sideCP('enemy'),'| log:',B.log.slice(-6).map(l=>l.m).join(' || ')); }
  console.log('ram outcomes',JSON.stringify(outs)); }
global.ramCheck=ramCheck;
function spawnCheck(n){ const out={boxed:0,ships:0,lane:0,cleared:0,mp:0}; for(let i=0;i<n;i++){ RUN={admiral:'reyes',fac:'hegemony',credits:0,cpCap:40,sector:2,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]};
    for(const t of ['h_vanguard','h_dominion','h_picket','h_interdictor']) RUN.fleet.push(newShip(t,false));
    const e=rollEncounter(i%7===0?'boss':'battle',2); startBattle({kind:i%7===0?'boss':'battle',fac:pick(['corsair','chorus','deathless','voidsworn','ithar']),col:3,obj:e.enc,shape:e.shape,map:'random'}); out.cleared+=B.spawnCleared||0;
    const foes=alive('enemy').filter(u=>!u.isSq), tgt={q:Math.round(foes.reduce((a,u)=>a+u.q,0)/foes.length),r:Math.round(foes.reduce((a,u)=>a+u.r,0)/foes.length)};
    for(const u of alive('player').filter(x=>!x.isSq)){ out.ships++; const line=hexLine(u,tgt).slice(1,6); const bl=line.filter(h=>blocks(terr(h.q,h.r))).length; for(const h of line){ const tt=terr(h.q,h.r); if(blocks(tt)) out[tt]=(out[tt]||0)+1; } out.lane+=bl; if(bl) out.boxed++;
      const d0=hdist(u,tgt); u.mp=u.speed; u.turnsLeft=u.turns; const {states}=computeReach(u); const best=Math.min(d0,...states.map(s=>hdist(s,tgt))); out.mp+=(d0-best)/Math.max(1,u.speed); } }
  console.log(\`spawncheck \${n} battles, \${out.ships} ships: lane blocked within 5 hexes \${(out.boxed/out.ships*100).toFixed(0)}% (blocked hexes/ship \${(out.lane/out.ships).toFixed(2)}), first-move progress \${(out.mp/out.ships*100).toFixed(0)}% of speed, rocks cleared/battle \${(out.cleared/n).toFixed(1)} by type \${JSON.stringify({rock:out.rock,hulk:out.hulk,planet:out.planet,station:out.station})}\`); }
async function boonSim(n){ const S0=JSON.parse(process.env.FLEET||'{"tag":"base","player":["penitent","harrow","harrow","warden"],"enemy":["h_vanguard","h_interdictor","h_interdictor","h_picket","h_picket"]}');
  const sets=[['base','']].concat(Object.keys(PATRONS).map(p=>[p,Object.keys(BOONS).filter(id=>BOONS[id].p===p).slice(0,+(process.env.NB||3)).map(id=>id+':'+(process.env.BR||0)).join(',')])).concat(Object.keys(ASPECTS).map(a=>['asp:'+a,'',a]));
  for(const [tag,b,asp] of sets){ let w=0,hp=0,rd=0; for(let i=0;i<n;i++){ const r=await sim(Object.assign({},S0,{boons:b,aspect:asp||null}),+(process.env.SEC||2)); if(r.res==='win') w++; hp+=r.hpLeft; rd+=r.rounds; }
    console.log('boonsim', tag.padEnd(14), 'win', Math.round(w/n*100)+'%', 'hull left', Math.round(hp/n*100)+'%', 'rounds', (rd/n).toFixed(1), b); } }
// v41: each rule fix from the October 17 audits, checked directly
async function ruleCheck(){ const out=[]; const ok=(n,c,note)=>out.push((c?'PASS ':'FAIL ')+n+(note?': '+note:''));
  const setup=(fleet,fac,enemies)=>{ RUN={fac:fac||'voidsworn',admiral:'vex',fleet:[],relics:[],inventory:[],sector:2,cpCap:60,credits:0,stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[],patrons:Object.keys(PATRONS).slice(0,4),boons:[],aspect:null};
    for(const t of (fleet||['penitent','harrow','warden'])) RUN.fleet.push(newShip(t,false)); RUN.flagUid=RUN.fleet[0].uid;
    startBattle({kind:'battle',fac:'hegemony',col:3,dep:'line',obj:'rout',enemies:(enemies||['h_interdictor','h_picket','h_picket']).map(tpl=>({tpl}))}); for(const x of B.units) x.activated=false; return {P:alive('player').filter(u=>!u.isSq),E:alive('enemy').filter(u=>!u.isSq)}; };
  { const {E}=setup(); const t=E[1]; t.reanimate=false; t.hp=5; t.st.fire=2; t.st.fireDmg=10; startSideTurn('enemy'); await new Promise(r=>setTimeout(r,0)); ok('fire can destroy a ship',t.dead,'hp '+t.hp+' dead '+t.dead); }
  { const {P}=setup(); const u=P[0]; damageSection(u,'prow',9999,null); const off=u.weapons.filter(w=>w.arc==='F').every(w=>w.off>=99); damageSection(u,'eng',9999,null); const sp=u.st.engine; await runCommand('player',{id:'restore',n:'Restore'},0);
    ok('restore repairs destroyed sections',off&&!u.sec.prow.broken&&u.sec.prow.hp>0&&u.weapons.filter(w=>w.arc==='F').every(w=>w.off<99)&&!u.sec.eng.broken&&u.st.engine===0,'prow '+u.sec.prow.hp+'/'+u.sec.prow.max+', engine penalty '+sp+' -> '+u.st.engine); }
  { const {P}=setup(['cathedral','warden']); const u=P[0]; u.abCd=0; const before=canAbility(u); damageSection(u,'mid',9999,null); ok('shield surge cannot restart a destroyed generator',before&&!canAbility(u),'before '+before+', after '+canAbility(u)); }
  { setup(['b_razor','b_spitter'],'chorus'); const c=boonUseful('i_still',fleetKit()); setup(['d_harvester','d_scythe'],'deathless'); const d=boonUseful('i_still',fleetKit()); setup(['penitent']); const v=boonUseful('i_still',fleetKit()); ok('Anchored Volley only offered to fleets it helps',!c&&!d&&v,'chorus '+c+', deathless '+d+', voidsworn '+v); }
  { const {P,E}=setup(); RUN.relics=['cogitator']; const u=P[0], w=u.weapons[0]; const has=!!runFx().firstSure; const a=hitChance(u,w,E[0]); u.sureUsed=1; const b=hitChance(u,w,E[0]); ok('rangefinder covers only the first attack',!has||(a===95&&b!==95),'relic '+has+': '+a+' then '+b); }
  { const {P}=setup(['i_wisp','i_blade'],'ithar'); const u=P[0]; let called=0; const keep=objAfterMove; objAfterMove=function(x){ if(x===u) called++; return keep(x); }; u.ab='blink'; u.abCd=0; const h=(typeof blinkHexes==='function'?blinkHexes(u):[])[0]; if(h) await useAbility(u,{hex:h}); objAfterMove=keep; ok('phase jump runs the objective exit check',!h||called>0,h?'called '+called:'no blink hex'); }
  { const {P,E}=setup(['reliquary','warden']); const c=P[0]; const t=E[0]; const sq=makeWing(c,{q:c.q,r:c.r},'bomber'); sq.wingOrder={kind:'strike',id:t.id}; const before=!!sqOrder(sq); t.side='player'; ok('a wing drops its strike order on a captured ship',before&&!sqOrder(sq)); }
  { META.mastery=Object.assign({},META.mastery,{matriarch:6,aelith:6,reyes:6}); newRun('matriarch','chorus',{alt:true}); const car=RUN.fleet.find(s=>HULLS[s.tpl].ab==='launch'); const m=!!(car&&car.mods.includes('hangar')); newRun('reyes','hegemony',{alt:true}); const r=RUN.fleet.some(s=>HULLS[s.tpl].ab==='launch'); ok('alternate fleets keep their carrier',m&&r,'matriarch hangar '+m+', reyes carrier '+r); }
  { const {P,E}=setup(['penitent','harrow','warden']); for(const u of P){ u.q=E[0].q-3; u.r=E[0].r; } let calls=0, after=0, bumped=false; const keep=fireWeapon; fireWeapon=async function(u,i,t,o){ calls++; if(bumped) after++; const r=await keep(u,i,t,o); if(!bumped){ bumped=true; B.epoch=(B.epoch||0)+1; } return r; };
    await runCommand('player',{id:'barrage',n:'Barrage'},2); fireWeapon=keep; ok('a skipped Command volley stops firing',bumped&&after===0,'shots before skip '+(calls-after)+', after '+after); }
  { const {P,E}=setup(['penitent']); const u=P[0], t=E[0]; t.hp=t.maxHp; u.q=t.q-1; u.r=t.r; const keep=animExplode; let release; animExplode=()=>new Promise(r=>{ release=r; }); t.hp=1; const p=killUnit(t,u); const b1=B; setup(['harrow']); const hp0=alive('enemy').map(x=>x.hp).join(), lg=B.log.length; release(); await p; animExplode=keep; ok('an old explosion never touches the next battle',B!==b1&&alive('enemy').map(x=>x.hp).join()===hp0&&B.log.length===lg,'log lines added '+(B.log.length-lg)); }
  // v50 thrusters and pass-overs
  { const {P,E}=setup(); const u=P[0]; for(const x of [...P.slice(1),...E]){ x.q=0; x.r=0; x.dead=true; } B.terrain={}; u.q=10; u.r=8; u.facing=0; u.mp=2; u.turnsLeft=1; u.st.engine=0;
    const fwd=DIRS[0], ahead={q:u.q+fwd[0],r:u.r+fwd[1]}; B.terrain[hkey(ahead.q,ahead.r)]='rock';
    let R=computeReach(u); const back={q:u.q+DIRS[3][0],r:u.r+DIRS[3][1]}, sl={q:u.q+DIRS[1][0],r:u.r+DIRS[1][1]};
    const bs=R.map.get(hkey(back.q,back.r)), ss=R.map.get(hkey(sl.q,sl.r));
    ok('a boxed-in hull can back off or sideslip holding its heading',!!bs&&bs.f===0&&bs.cost===2&&!!ss&&ss.f===0&&ss.cost===2,'reverse '+(bs&&bs.cost)+' slip '+(ss&&ss.cost));
    ok('a rock cannot be stopped on',!R.map.has(hkey(ahead.q,ahead.r)));
    u.mp=3; R=computeReach(u); const past={q:ahead.q+fwd[0],r:ahead.r+fwd[1]}, ps=R.map.get(hkey(past.q,past.r));
    ok('a hull can climb over a rock for +1 movement',!!ps&&ps.cost===3&&ps.path.some(p=>p.over===1),'cost '+(ps&&ps.cost));
    u.mp=1; R=computeReach(u); ok('a 1-movement hull can still spend it all on one thruster hop',!!R.map.get(hkey(back.q,back.r)));
    u.fac='deathless'; u.mp=2; R=computeReach(u); const pd=R.map.get(hkey(past.q,past.r)); ok('Deathless phase through rocks at no extra cost',!!pd&&pd.cost===2,'cost '+(pd&&pd.cost));
    u.fac='chorus'; u.mp=1; u.pivotUsed=false; R=computeReach(u); const tw=R.states.find(s=>s.q===u.q&&s.r===u.r&&s.f===1&&s.cost===0); ok('Chorus first turn is free',!!tw);
    u.fac='voidsworn'; const e=E[0]; e.dead=false; e.q=14; e.r=8; e.facing=3; u.q=10; u.r=8; u.facing=0; delete B.terrain[hkey(ahead.q,ahead.r)]; const w=e.weapons[0];
    u.hexMoved=1; const c1=hitChance(e,w,u); u.hexMoved=0; const c0=hitChance(e,w,u); u.hexMoved=3; const c3=hitChance(e,w,u);
    ok('a hull that held still is easier to hit, one that burned hard is harder',c0>c1&&c3<c1,c0+' / '+c1+' / '+c3);
    const bw=u.weapons.find(x=>x.arc==='P'||x.arc==='S'); if(bw){ u.hexMoved=0; const m0=dmgMult(u,bw,e,false); u.hexMoved=2; const m2=dmgMult(u,bw,e,false); ok('raking pass: broadsides hit harder after moving 2+ hexes',m2>m0,m0.toFixed(2)+' -> '+m2.toFixed(2)); } }
  // ---- v53 correctness checks (one per bug class fixed) ----
  const at=(u,q,r,f)=>{ u.q=q; u.r=r; if(f!=null) u.facing=f; }, clearT=()=>{ for(const k of Object.keys(B.terrain)) delete B.terrain[k]; };
  // seed replay: the same seed and the same scripted moves give the same opening rounds (and a different seed does not)
  { const fp=async seed=>{ RUN={fac:'voidsworn',admiral:'vex',fleet:[],relics:[],inventory:[],sector:2,cpCap:60,credits:0,stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[],patrons:Object.keys(PATRONS).slice(0,4),boons:[],aspect:null}; rndSeed(99);
      for(const t of ['penitent','harrow','warden']) RUN.fleet.push(newShip(t,false)); RUN.flagUid=RUN.fleet[0].uid;
      startBattle({kind:'battle',fac:'hegemony',col:3,obj:'rout',seed}); const s0=B.seed; for(let r=0;r<3&&!B.over;r++){ await botTurn(); if(B.over) break; B.side='enemy'; await startSideTurn('enemy'); await aiTurn(); if(B.over) break; B.round++; B.side='player'; await startSideTurn('player'); }
      return JSON.stringify([s0,B.shape,Object.keys(B.terrain).sort().join(';'),B.units.map(u=>[u.tpl,u.q,u.r,u.facing,Math.round(u.hp*10),u.dead?1:0,u.weapons.map(w=>w.fired?1:0).join('')]),B.log.map(x=>x.m)]); };
    const a=await fp(12345), b=await fp(12345), c=await fp(54321); ok('seed replay: same seed and moves give the same opening rounds',a===b&&a!==c,'fingerprint '+a.length+' chars'+(a===b?'':' (replay diverged)')+(a===c?' (different seed matched too)':'')); }
  // animPath is presentation only: moves, turns and rams commit their own position after the live check
  { globalThis.animPath=async function(){}; try{ const {P,E}=setup(['penitent'],null,['h_interdictor']); const u=P[0], t=E[0]; clearT();
      const st=[...computeReach(u).map.values()].find(s=>s.path.some(p=>!p.rot)); if(st) await moveUnit(u,st); const moved=!st||(u.q===st.q&&u.r===st.r&&u.facing===st.f);
      u.turnsLeft=1; u.mp=Math.max(1,u.mp); const f0=u.facing; await rotateUnit(u,1); const rot=u.facing===(f0+1)%6;
      at(u,8,6,0); at(t,11,6,3); u.mp=u.speed; u.rammed=false; u.braced=false; const info=ramInfo(u); let rammed=false; if(info){ const end=info.path[info.path.length-1]; await ramUnit(u); rammed=u.q===end.q&&u.r===end.r; }
      ok('moves, turns and rams commit their own position (animPath is presentation only)',moved&&rot&&rammed,'move '+moved+', turn '+rot+', ram '+(info?rammed:'no lane')); } finally{ delete globalThis.animPath; } }
  // a turn abandoned mid-animation (stall) does not commit; a blink to a hex that is no longer free is refused
  { const {P,E}=setup(['i_wisp','i_blade'],'ithar'); const u=P[0]; const keepR=animRotate; animRotate=async function(){ B.epoch=(B.epoch||0)+1; }; u.turnsLeft=1; u.mp=Math.max(1,u.mp); const f0=u.facing; await rotateUnit(u,1); animRotate=keepR;
    u.ab='blink'; u.abCd=0; const q0=u.q, r0=u.r, okB=await useAbility(u,{hex:{q:E[0].q,r:E[0].r}}); ok('a stalled turn does not commit, a blink onto a ship is refused',u.facing===f0&&okB===false&&u.q===q0&&u.r===r0,'facing '+f0+' -> '+u.facing+', blink '+okB); }
  // a shot abandoned after a stall leaves the gun ready and the target untouched
  { const {P,E}=setup(['penitent'],null,['h_interdictor']); const u=P[0], t=E[0]; clearT(); at(t,10,6,3); let wi=-1; for(let f=0;f<6&&wi<0;f++){ at(u,7,6,f); wi=u.weapons.findIndex(w=>canFire(u,w,t)); }
    if(wi<0) ok('an abandoned shot does not spend the gun',false,'no firing solution'); else { const keepW=animWeapon; animWeapon=async function(){ B.epoch=(B.epoch||0)+1; }; const hp=t.hp, r=await fireWeapon(u,wi,t); animWeapon=keepW; ok('an abandoned shot does not spend the gun',r===false&&weaponReady(u.weapons[wi])&&t.hp===hp,'ready '+weaponReady(u.weapons[wi])+', hp '+hp+' -> '+t.hp); } }
  // tick deaths: startSideTurn hands back a promise; the death is logged once and has finished when it resolves; the dead star has its own kill cause
  { const {E}=setup(); const t=E[1]; t.reanimate=false; t.hp=3; t.st.acid=1; t.st.fire=1; t.st.fireDmg=6; const n0=B.log.length; const p=startSideTurn('enemy'); const was=!!p&&typeof p.then==='function'; await p; const L=B.log.slice(n0).map(x=>x.m);
    ok('tick deaths are awaited, logged once, and finish before the turn goes on',was&&t.dead&&L.filter(m=>m.indexOf(t.name+' is destroyed')>=0).length===1&&!L.some(m=>m.indexOf(t.name+' burns out')>=0),'promise '+was+', lines '+L.filter(m=>m.indexOf(t.name)>=0).length); }
  { const {E}=setup(); const t=E[0]; t.reanimate=false; t.hp=5; B.well={q:t.q+1,r:t.r}; await startSideTurn('enemy'); const bad=[]; for(const id in W){ const c=killCauseOf(W[id],{id:'x'}); if(!KILL_CAUSES[c]) bad.push(id+':'+c); } for(const c of ['melt','dark','big','tidal','blast']) if(!KILL_CAUSES[c]) bad.push(c);
    ok('a dead star kill has its own cause, and every cause is in KILL_CAUSES',t.dead&&t.killCause==='tidal'&&!bad.length,'cause '+t.killCause+(bad.length?', missing '+bad.join(','):'')); }
  // a squadron whose orders stall is skipped with a log line
  { setup(['reliquary','warden']); const keepS=stallGuard; stallGuard=async function(){ return 'stall'; }; const n0=B.log.length; await swarmPhase('player'); stallGuard=keepS; const L=B.log.slice(n0).map(x=>x.m); const sq=alive('player').filter(u=>u.isSq);
    ok('stalled squadron orders are logged as lost',!sq.length||(L.some(m=>m.indexOf('orders lost in interference')>=0)&&sq.every(u=>u.activated)),sq.length+' wings, '+L.length+' lines'); }
  // saves: one defaults list, malformed saves rejected, renamed ids skipped
  { const r=migrateRun({fac:'chorus',fleet:[{tpl:'penitent',hp:10,cap:{name:'x'}}],map:{cols:[]}}), miss=Object.keys(runDefaults()).filter(k=>r[k]===undefined);
    const rej=!saneSave({meta:{},run:{fleet:{},map:{cols:[]}}})&&!saneSave({meta:[],run:null})&&!saneSave({meta:{stats:'x'}})&&saneSave({meta:defaultMeta(),run:{none:true}})&&saneSave({meta:defaultMeta(),run:r});
    const R0=RUN; RUN=null; let threw=null; const cw=console.warn; console.warn=()=>{}; try{ derive({tpl:'penitent',mods:['no_such_mod'],cap:{perks:['no_such_perk']}}); }catch(e){ threw=e.message; } console.warn=cw; RUN=R0;
    ok('saves: one defaults list, malformed saves rejected, renamed ids skipped',!miss.length&&rej&&!threw&&Array.isArray(r.fleet[0].mods)&&Array.isArray(r.fleet[0].cap.perks),'missing ['+miss.join(',')+'], rejects '+rej+(threw?', threw '+threw:'')); }
  // ---- v53-D enemy AI checks ----
  // per-gun re-pick: the heavy guns are not poured into a 2-hull wreck that the light gun can finish; shield strippers fire first into shields
  { const {P,E}=setup(['penitent','harrow'],null,['h_dominion']); const u=E[0], A=P[0], Bq=P[1]; clearT(); at(u,10,6,3); at(A,8,6,0); at(Bq,8,7,0); for(const w of u.weapons) if(w.k!=='flak') w.arc='T';
    A.hp=2; A.sh=[0,0,0,0]; A.reanimate=false; B.aiFocus=null; const shots=[]; const keepF=fireWeapon; fireWeapon=async function(x,wi,t){ shots.push([x.weapons[wi],t]); x.weapons[wi].fired=true; return true; };
    try{ await aiVolley(u,()=>true); } finally{ fireWeapon=keepF; } const heavy=u.weapons.filter(w=>w.k!=='flak').sort((a,b)=>b.dmg*b.shots-a.dmg*a.shots)[0], hs=shots.find(x=>x[0]===heavy);
    ok('volley re-pick: heavy guns skip a 2-hull target a lighter gun can kill',shots.length>=2&&hs&&hs[1]===Bq&&shots.some(x=>x[1]===A),shots.map(x=>x[0].n+'>'+(x[1]===A?'wreck':'healthy')).join(', '));
    for(const w of u.weapons) w.fired=false; const ord=aiGunOrder(u,u.weapons.filter(w=>w.k!=='flak'),Bq); ok('shield strippers fire first into a shielded target',ord[0].ion>1,ord.map(w=>w.n).join(' > ')); }
  // threat: guns that already fired this round are spent in alternating play (but not in Classic, where they reload before the next enemy turn)
  { const {P,E}=setup(['penitent'],null,['h_interdictor']); const p=P[0], v=E[0]; clearT(); at(p,8,6,0); at(v,11,6,3); B.alt=true; const t0=evalThreat(v,[p]), tv0=evalThreatVet(v,[p]);
    for(const w of p.weapons) w.fired=true; const t1=evalThreat(v,[p]), tv1=evalThreatVet(v,[p]); B.alt=false; const t2=evalThreat(v,[p]);
    ok('threat ignores guns that already fired this round (alternating)',t0>0&&tv0>0&&t1===0&&tv1===0&&t2===t0,'alt '+t0.toFixed(1)+' -> '+t1.toFixed(1)+', vet '+tv0.toFixed(1)+' -> '+tv1.toFixed(1)+', classic '+t2.toFixed(1)); }
  // sticky focus: equal candidates never steal it, a dead target releases it, brace lowers a target's worth, standard AI keeps no focus
  { const {P,E}=setup(['harrow','harrow','harrow'],null,['h_vanguard','h_interdictor']); const [a,b,c]=P; clearT(); at(a,9,8,0); at(b,9,6,0); at(c,9,10,0); at(E[0],12,7,3); at(E[1],12,9,3); for(const x of P) x.pflag=false; B.aiFocus=b; const k1=aiRefreshFocus()===b; B.aiFocus=c; const k2=aiRefreshFocus()===c;
    c.dead=true; const k3=aiRefreshFocus()!==c&&!!B.aiFocus; c.dead=false; B.aiFocus=c; const h0=a.hp; a.hp=Math.round(a.hp*.4); const k5=aiRefreshFocus()===a; a.hp=h0; const sh=aiShooters(), v0=aiFocusVal(a,sh); a.braced=true; const v1=aiFocusVal(a,sh); a.braced=false;
    const lv=AI_LEVEL; AI_LEVEL='standard'; const k4=aiRefreshFocus()===null; AI_LEVEL=lv;
    ok('fleet focus is sticky, switches only for a clearly better target, brace-aware, veteran only',k1&&k2&&k3&&k5&&v1<v0&&k4,'values '+[a,b,c].map(x=>aiFocusVal(x,sh).toFixed(2)).join('/')+', keep '+k1+'/'+k2+', release '+k3+', clearly better '+k5+', brace '+v0.toFixed(2)+' -> '+v1.toFixed(2)+', standard '+k4); }
  // relay: only the two nearest enemy ships are pulled onto it; urgency rises with the round clock
  { const {E}=setup(['penitent'],null,['h_picket','h_picket','h_picket']); clearT(); const hex={q:10,r:8}; B.obj={type:'hold',hex,score:0,escore:0}; at(E[0],12,8,3); at(E[1],13,8,3); at(E[2],18,8,3);
    const gain=(u,dq)=>aiObjScore(u,stateView(u,{q:u.q-dq,r:u.r,f:3}))-aiObjScore(u,stateView(u,{q:u.q,r:u.r,f:3})); const g0=gain(E[0],1), g2=gain(E[2],1);
    B.round=1; const u1=aiObjUrgency({type:'defend',rounds:6,hp:5}); B.round=5; const u5=aiObjUrgency({type:'defend',rounds:6,hp:2});
    ok('relay pulls the two nearest ships; objective urgency rises with the clock',g0>=1.6&&g2<=.5&&u5>u1,'near +'+g0.toFixed(2)+', far +'+g2.toFixed(2)+', urgency '+u1.toFixed(2)+' -> '+u5.toFixed(2)); }
  console.log(out.join('\\n')); console.log(out.some(x=>x.startsWith('FAIL'))?'RULECHECK FAILED':'RULECHECK PASSED'); if(out.some(x=>x.startsWith('FAIL'))) process.exitCode=1; }
async function boonCheck(){ const out=[]; const ok=(n,c,note)=>out.push((c?'PASS ':'FAIL ')+n+(note?': '+note:''));
  const setup=(boons,aspect,fleet,fac)=>{ RUN={fac:'voidsworn',admiral:'vex',fleet:[],relics:[],inventory:[],sector:2,cpCap:60,credits:0,stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[],patrons:Object.keys(PATRONS).slice(0,4),boons:boons.map(id=>({id,r:0})),aspect:aspect||null};
    for(const t of (fleet||['penitent','harrow','warden'])) RUN.fleet.push(newShip(t,false)); RUN.flagUid=RUN.fleet[0].uid;
    startBattle({kind:'battle',fac:fac||'hegemony',col:3,dep:'line',obj:'rout',enemies:[{tpl:'h_interdictor'},{tpl:'h_picket'},{tpl:'h_picket'}]}); for(const x of B.units) x.activated=false; return {P:alive('player').filter(u=>!u.isSq),E:alive('enemy').filter(u=>!u.isSq)}; };
  const place=(u,q,r,f)=>{ u.q=q; u.r=r; if(f!=null) u.facing=f; };
  // ion lash
  { let {P,E}=setup([]); const a=P[0], t=E[0]; place(a,5,5,0); place(t,8,5,3); const w=a.weapons.find(x=>inReach(a,x,t))||a.weapons[0]; const s0=expectedVs(a,w,t).shield;
    ({P,E}=setup(['s_ion'])); const a2=P[0], t2=E[0]; place(a2,5,5,0); place(t2,8,5,3); const w2=a2.weapons.find(x=>x.id===w.id&&x.arc===w.arc); const s1=expectedVs(a2,w2,t2).shield; ok('Ion Lash strips more shield',s1>s0*1.2,s0.toFixed(1)+' -> '+s1.toFixed(1)); }
  // unbroken line
  { const {P,E}=setup(['i_line']); const t=P[0], b=P[1], e=E[0]; place(t,5,5,0); place(b,9,9); place(e,8,5,3); const w=e.weapons[0]; t.sh=[0,0,0,0]; const h0=expectedVs(e,w,t).hull; place(b,5,6); const h1=expectedVs(e,w,t).hull; ok('Unbroken Line cuts hull damage beside an ally',h1<h0*.95,h0.toFixed(1)+' -> '+h1.toFixed(1)); }
  // anchored volley + momentum
  { let {P,E}=setup(['i_still']); const a=P[0], t=E[0], w=a.weapons.find(x=>x.arc==='P'||x.arc==='S'||x.k==='battery')||a.weapons[0]; a.hexMoved=0; const m0=dmgMult(a,w,t,false); a.hexMoved=2; const m1=dmgMult(a,w,t,false); ok('Anchored Volley rewards holding still',m0>m1,m0.toFixed(2)+' still vs '+m1.toFixed(2)+' moved');
    ({P,E}=setup(['r_mom'])); const b=P[0]; b.hexMoved=0; const n0=dmgMult(b,b.weapons[0],E[0],false); b.hexMoved=4; const n1=dmgMult(b,b.weapons[0],E[0],false); ok('Momentum rewards moving',n1>n0,n0.toFixed(2)+' -> '+n1.toFixed(2)); }
  // evasive burn
  { const {P,E}=setup(['r_jink']); const t=P[0], e=E[0]; place(t,5,5,0); place(e,8,5,3); t.hexMoved=0; const c0=hitChance(e,e.weapons[0],t); t.hexMoved=3; const c1=hitChance(e,e.weapons[0],t); ok('Evasive Burn after 3+ hexes',c1<c0,c0+' -> '+c1); }
  // battering prow + aspect of the ram
  { let {P,E}=setup([]); const r0=ramEstimate(P[0],E[0]); ({P,E}=setup(['r_prow'])); const r1=ramEstimate(P[0],E[0]); ({P,E}=setup([],'ram')); const r2=ramEstimate(P[0],E[0]); ok('Battering Prow and Aspect of the Ram',r1.dmg>r0.dmg&&r1.recoil<r0.recoil&&r2.recoil===0,'dmg '+r0.dmg+'/'+r1.dmg+'/'+r2.dmg+' recoil '+r0.recoil+'/'+r1.recoil+'/'+r2.recoil); }
  // chain reaction
  { const {P,E}=setup(['e_chain']); place(E[0],10,5); place(E[1],10,6); place(E[2],14,2); const h0=E[1].hp; E[0].hp=0; await killUnit(E[0],P[0]); ok('Chain Reaction scorches neighbours',E[1].hp<h0&&E[2].hp===E[2].maxHp,h0+' -> '+E[1].hp); }
  // kindling (forced)
  { const {P,E}=setup(['e_kindle']); P[0].fx.igniteCh=1; const t=E[0]; t.sh=[0,0,0,0]; applyHit(P[0],P[0].weapons[0],t,30,0); ok('Kindling sets fires',t.st.fire>0&&t.st.fireDmg>6,'fire '+t.st.fire+' for '+t.st.fireDmg); const hp=t.hp; startSideTurn('enemy'); ok('Fires burn for the boosted amount',hp-t.hp===t.st.fireDmg||hp-t.hp>=10,(hp-t.hp)+' burned'); }
  // arc discharge
  { const {P,E}=setup(['s_arc']); const a=P[0], t=E[0]; if(B&&B.terrain) for(const k of Object.keys(B.terrain)) delete B.terrain[k]; place(t,7,5,3); let wi=-1; for(let f=0;f<6&&wi<0;f++){ place(a,5,5,f); wi=a.weapons.findIndex(x=>inReach(a,x,t)); } if(wi<0){ ok('Arc Discharge on a broken facing',false,'no weapon in reach in any facing'); } else { const q=shieldQuad(t,a); t.sh[q]=1; const hp=t.hp; a.aim=300; for(let k=0;k<6&&t.sh[q]>.5;k++){ a.weapons[wi].fired=false; a.weapons[wi].cdLeft=0; await fireWeapon(a,wi,t); } ok('Arc Discharge on a broken facing',wi>=0&&hp-t.hp>=12,'hull lost '+(hp-t.hp)); } }
  // bastion duo
  { const {P}=setup(['d_bastion']); const u=P[0]; u.sh=[0,0,0,0]; giveOrder(u,'brace'); ok('Bastion refills shields on brace',u.sh.every(x=>x===u.shMax)&&u.shMax>0,u.sh.join('/')); }
  // storm mantle
  { const {P}=setup(['s_regen']); const u=P[0]; u.sh=[0,u.shMax,u.shMax,u.shMax]; u.regen=0; startSideTurn('player'); ok('Storm Mantle tops up the weakest facing',u.sh[0]>0,'facing 0 -> '+u.sh[0]); }
  // hive aspect + feast
  { const {P,E}=setup(['h_feast'],'hive'); const wings=alive('player').filter(u=>u.isSq&&u.parent===P[0].id); ok('Aspect of the Hive launches a wing from a non-carrier flagship',wings.length>=1,wings.length+' wing(s)');
    if(wings.length){ const sp=P[0].spare||0; P[0].hp=P[0].maxHp-50; const h=P[0].hp; E[0].hp=0; await killUnit(E[0],wings[0]); ok('Feast on the Fallen refunds a wing and repairs',(P[0].spare||0)===sp+1&&P[0].hp>h,'spare '+sp+' -> '+P[0].spare+', hull +'+(P[0].hp-h)); } }
  // admiral aspect
  { setup([],'admiral'); B.round=1; ok('Aspect of the Admiral raises Command power',cmdTier()===1,'tier '+cmdTier()+' in round 1'); }
  // boarding frenzy
  { let {P,E}=setup([],null,['c_marauder','c_reaver'],'hegemony'); const c0=captureChance(P[0],E[0]); ({P,E}=setup(['h_board'],null,['c_marauder','c_reaver'],'hegemony')); const c1=captureChance(P[0],E[0]); ok('Boarding Frenzy raises capture odds',c1>=c0,c0+'% -> '+c1+'%'); }
  // offers
  { setup([]); RUN.boons=[{id:'i_broad',r:0},{id:'r_burn',r:0}]; let duo=0; for(let i=0;i<60;i++){ const o=rollBoonOffer('iron',0); if(o.some(x=>BOONS[x.id].duo)) duo++; if(o.length!==3||new Set(o.map(x=>x.id)).size!==3||o.some(x=>x.id==='i_broad')) { ok('offers are 3 distinct unowned boons',false,JSON.stringify(o)); break; } } ok('duo boons get offered once both patrons are held',duo>5,duo+'/60 offers'); }
  console.log(out.join('\\n')); if(out.some(x=>x.startsWith('FAIL'))) process.exitCode=1; }
function budgetCheck(){ const cases=[['early s1',1,['h_vanguard','h_picket','h_picket'],0,1,1],['mid s2',2,['h_vanguard','h_dominion'],2,2,2],['Ryan s3',3,['h_vanguard','h_dominion','h_dominion'],4,2,3],['s3 + 6 boons',3,['h_vanguard','h_dominion','h_dominion'],4,2,3,6]];
  for(const [tag,s,fl,mods,mk,rank,nb] of cases){ RUN={fac:'hegemony',admiral:'reyes',fleet:[],relics:['banner','salvage'],inventory:[],sector:s,cpCap:60,credits:0,stats:{},fallen:[],boons:[]};
    for(const t of fl){ const sh=newShip(t,false); sh.mk=mk; sh.cap.rank=rank; sh.mods=Object.keys(MODULES).slice(0,mods); sh.hp=derive(sh).maxHp; RUN.fleet.push(sh); }
    for(let i=0;i<(nb||0);i++) RUN.boons.push({id:Object.keys(BOONS)[i],r:1});
    const raw=RUN.fleet.reduce((a,sh)=>a+(HULLS[sh.tpl].cp||1),0), pw=fleetPower();
    const rows=[0,3,6].map(col=>{ const nominal=[0,3.5,8,12.5][s]+col*(s===1?0.8:s===2?0.9:1), old=Math.min(nominal,raw*.75+.3); let cp=0,n=0; for(let i=0;i<40;i++){ const L=genEnemyFleet('voidsworn',s,col,'battle'); cp+=L.reduce((a,e)=>a+(HULLS[e.tpl].cp||1),0); n+=L.length; } return 'col'+col+' old '+old.toFixed(1)+' new~'+(cp/40).toFixed(1)+' ('+(n/40).toFixed(1)+' ships)'; });
    console.log('budget', tag.padEnd(14), 'hull cp', raw, 'power', pw.toFixed(1), '|', rows.join(' | ')); } }
function shapeCheck(n){ const rows=[]; for(const [enc,E] of Object.entries(ENCOUNTERS)) for(const sh of E.shapes){ let fb=0,bad=0,hexes=0,cut=0,objFail=0;
    for(let i=0;i<n;i++){ RUN={fac:'voidsworn',admiral:'vex',fleet:[],relics:[],inventory:[],sector:2,cpCap:60,credits:0,stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[],boons:[],patrons:['iron','storm','star','rook']};
      for(const t of ['penitent','harrow','harrow','warden','reliquary']) RUN.fleet.push(newShip(t,false));
      try{ startBattle({kind:'battle',fac:pick(['hegemony','corsair','chorus','deathless','ithar']),col:3,obj:enc,shape:sh,map:'random'}); }catch(e){ bad++; console.log('ERR',enc,sh,e.message); continue; }
      if(B.shape!==sh) fb++; hexes+=boardHexes().length; cut+=CUT?CUT.size:0; if(B.obj.type!==enc) objFail++;
      const occ=new Set(); for(const u of B.units){ if(u.dead) continue; const k=hkey(u.q,u.r); if(!onBoard(u.q,u.r)||blocks(terr(u.q,u.r))||(!u.isSq&&occ.has(k))) { bad++; break; } if(!u.isSq) occ.add(k); } }
    rows.push(enc.padEnd(10)+sh.padEnd(12)+' fallback '+fb+'/'+n+' badDeploy '+bad+' objChanged '+objFail+' hexes '+Math.round(hexes/n)+' cut '+Math.round(cut/n)); }
  console.log(rows.join('\\n')); }
async function bossMatrix(n){ const S=+(process.env.BS||1), res={}, byBoss={}, byCar={car:[0,0],gun:[0,0]};
  for(const [adm,A] of Object.entries(ADMIRALS)){ const fac=A.fac||'voidsworn'; let w=0,t=0,rd=0;
    for(const bf of RUN_FACTIONS.filter(f=>f!==fac)){ for(let i=0;i<n;i++){
      RUN={admiral:adm,fac,credits:0,cpCap:40,sector:S,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[],boons:(process.env.BOONS||'').split(',').filter(Boolean).map(x=>({id:x,r:0})),patrons:[]};
      for(const tp of A.start) RUN.fleet.push(newShip(equivHull(tp,fac),false)); RUN.flagUid=RUN.fleet[0].uid;
      { const G2=+(process.env.GROW||0), ros=FACTIONS[fac].roster.filter(id=>!HULLS[id].unique&&(HULLS[id].cp||1)<=(S>=3?4:3)); let g=0; while(G2&&fleetCP()<G2&&g++<20){ const pk=pick(ros); if(fleetCP()+(HULLS[pk].cp||1)>G2+1) continue; RUN.fleet.push(newShip(pk,false)); } if(process.env.MK) RUN.fleet.forEach(sh=>{ sh.mk=+process.env.MK; sh.hp=derive(sh).maxHp; }); }
      startBattle({kind:'boss',fac:bf,col:6,dep:'line',obj:'rout',shape:pick(['ring','open','hourglass']),map:'random'}); let r=0; B.alt=true; for(const x of B.units) x.activated=false; startSideTurn('enemy');
      while(!B.over&&r<30){ await swarmPhase('player'); await swarmPhase('enemy'); let g=0;
        while(!B.over&&g++<40){ const pp=alive('player').filter(x=>!x.isSq&&!x.activated), pe=alive('enemy').filter(x=>!x.isSq&&!x.activated); if(!pp.length&&!pe.length) break;
          if(pp.length){ await botUnit(pp[0]); pp[0].activated=true; } const batch=alive('player').some(x=>!x.isSq&&!x.activated)?(pe.length?[aiPickActivation(pe)]:[]):pe; for(const u of batch){ if(B.over) break; await aiUnit(u); u.activated=true; } }
        if(B.over) break; B.round++; for(const x of B.units) x.activated=false; startSideTurn('player'); startSideTurn('enemy'); r++; }
      const win=B.over==='win'?1:0; w+=win; t++; rd+=B.round; byBoss[bf]=byBoss[bf]||[0,0]; byBoss[bf][0]+=win; byBoss[bf][1]++; const car=A.start.some(tp=>HULLS[equivHull(tp,fac)].hangar)?'car':'gun'; byCar[car][0]+=win; byCar[car][1]++; } }
    res[adm]=Math.round(w/t*100)+'% r'+(rd/t).toFixed(1)+(A.start.some(tp=>HULLS[equivHull(tp,fac)].hangar)?' (carrier)':''); }
  console.log('bossmatrix s'+S, JSON.stringify(res)); console.log('by boss', JSON.stringify(Object.fromEntries(Object.entries(byBoss).map(([k,v])=>[k,Math.round(v[0]/v[1]*100)+'%'])))); console.log('carrier fleets', Math.round(byCar.car[0]/byCar.car[1]*100)+'%', 'gun fleets', Math.round(byCar.gun[0]/byCar.gun[1]*100)+'%'); }
async function archMatrix(n){ const S=2, out={}, cnt={};
  for(const arch of ['none','swarm','heavy','carrier']){ let w=0,t=0,rd=0,ships=0;
    for(const [adm,A] of Object.entries(ADMIRALS)){ const fac=A.fac||'voidsworn';
      for(const bf of RUN_FACTIONS.filter(f=>f!==fac)){ for(let i=0;i<n;i++){
        RUN={admiral:adm,fac,credits:0,cpCap:40,sector:S,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[],boons:[],patrons:[]};
        for(const tp of A.start) RUN.fleet.push(newShip(equivHull(tp,fac),false)); RUN.flagUid=RUN.fleet[0].uid;
        { const ros=FACTIONS[fac].roster.filter(id=>!HULLS[id].unique&&(HULLS[id].cp||1)<=3); let g=0; while(fleetCP()<10&&g++<20){ const pk=pick(ros); if(fleetCP()+(HULLS[pk].cp||1)>11) continue; RUN.fleet.push(newShip(pk,false)); } }
        startBattle({kind:'battle',fac:bf,col:3,dep:'line',obj:'rout',shape:'open',map:'random',arch:arch==='none'?null:arch}); ships+=B.units.filter(x=>x.side==='enemy'&&!x.isSq).length; let r=0; B.alt=true; for(const x of B.units) x.activated=false; startSideTurn('enemy');
        while(!B.over&&r<30){ await swarmPhase('player'); await swarmPhase('enemy'); let g=0;
          while(!B.over&&g++<40){ const pp=alive('player').filter(x=>!x.isSq&&!x.activated), pe=alive('enemy').filter(x=>!x.isSq&&!x.activated); if(!pp.length&&!pe.length) break;
            if(pp.length){ await botUnit(pp[0]); pp[0].activated=true; } const batch=alive('player').some(x=>!x.isSq&&!x.activated)?(pe.length?[aiPickActivation(pe)]:[]):pe; for(const u of batch){ if(B.over) break; await aiUnit(u); u.activated=true; } }
          if(B.over) break; B.round++; for(const x of B.units) x.activated=false; startSideTurn('player'); startSideTurn('enemy'); r++; }
        w+=B.over==='win'?1:0; t++; rd+=B.round; } } }
    out[arch]=Math.round(w/t*100)+'% r'+(rd/t).toFixed(1)+' ships '+(ships/t).toFixed(1); }
  console.log('archmatrix s2 col3', JSON.stringify(out)); }
async function fMatrix(n){ const F=RUN_FACTIONS, T=+(process.env.CPT||8), out={}, hull={}, weap={}, ab={}, st={rounds:0,n:0,timeout:0,rams:{player:0,enemy:0},boards:{player:0,enemy:0},overrun:0,caps:0};
  const _fw=fireWeapon; fireWeapon=async function(u,wi,t,opts){ const w=u.weapons[wi]; const h0=t.hp, s0=(t.sh||[]).reduce((a,b)=>a+b,0); const r=await _fw(u,wi,t,opts); if(w&&r!==false){ const k=(u.isSq?'sq:':'')+w.id+(opts&&opts.intercept?'(intercept)':''); const d=Math.max(0,h0-Math.max(0,t.hp))+Math.max(0,s0-(t.sh||[]).reduce((a,b)=>a+b,0)); weap[k]=weap[k]||{dmg:0,shots:0}; weap[k].dmg+=d; weap[k].shots++; } return r; };
  const _ua=useAbility; useAbility=async function(u,o){ const k=u.side+':'+u.ab; ab[k]=(ab[k]||0)+1; return _ua(u,o); };
  const rf=fac=>{ const ros=FACTIONS[fac].roster.filter(id=>!HULLS[id].unique); const L=[]; let cp=0,g=0; while(cp<T&&g++<40){ const id=pick(ros), c=HULLS[id].cp||1; if(cp+c>T+1) continue; L.push(id); cp+=c; } return L; };
  for(const pf of F){ out[pf]={}; for(const ef of F){ let w=0;
    for(let i=0;i<n;i++){ const adms=Object.keys(ADMIRALS).filter(a=>(ADMIRALS[a].fac||'voidsworn')===pf);
      RUN={admiral:process.env.NOADM?'none':pick(adms),fac:pf,credits:0,cpCap:60,sector:2,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[],boons:[],patrons:[]};
      const pl=rf(pf), en=rf(ef); for(const t of pl) RUN.fleet.push(newShip(t,false)); RUN.flagUid=RUN.fleet[0].uid;
      startBattle({kind:'battle',fac:ef,col:3,enemies:en.map(tpl=>({tpl})),dep:'line',obj:'rout',shape:pick(Object.keys(SHAPES)),map:'random'}); let r=0; B.alt=true; for(const x of B.units) x.activated=false; startSideTurn('enemy');
      while(!B.over&&r<30){ await swarmPhase('player'); await swarmPhase('enemy'); let g=0;
        while(!B.over&&g++<40){ const pp=alive('player').filter(x=>!x.isSq&&!x.activated), pe=alive('enemy').filter(x=>!x.isSq&&!x.activated); if(!pp.length&&!pe.length) break;
          if(pp.length){ await botUnit(pp[0]); pp[0].activated=true; } const batch=alive('player').some(x=>!x.isSq&&!x.activated)?(pe.length?[aiPickActivation(pe)]:[]):pe; for(const u of batch){ if(B.over) break; await aiUnit(u); u.activated=true; } }
        if(B.over) break; B.round++; for(const x of B.units) x.activated=false; startSideTurn('player'); startSideTurn('enemy'); r++; }
      if(B.over==='win') w++; if(!B.over) st.timeout++; st.rounds+=B.round; st.n++;
      for(const l of B.log){ const m=l.m||''; if(/ rams /.test(m)) st.rams[B.units.some(u=>u.side==='player'&&m.startsWith(u.name))?'player':'enemy']++; if(/ boards /.test(m)) st.boards[B.units.some(u=>u.side==='player'&&m.startsWith(u.name))?'player':'enemy']++; if(/hold the bridge/.test(m)) st.overrun++; if(/fights for you/.test(m)) st.caps++; }
      for(const u of B.units){ if(u.isSq) continue; const k=u.tpl, h=hull[k]=hull[k]||{n:0,dealt:0,died:0,cp:HULLS[k].cp||1}; h.n++; h.dealt+=u.dealt||0; if(u.dead) h.died++; }
      for(const u of B.units.filter(x=>x.parent)){ const p=B.units.find(x=>x.id===u.parent); if(p&&!p.isSq){ const h=hull[p.tpl]; if(h) h.dealt+=u.dealt||0; } } }
    out[pf][ef]=Math.round(w/n*100); } }
  console.log('FM '+JSON.stringify({out,st,hull,weap,ab})); }
async function boonSingle(n){ const S0={tag:'b',player:['penitent','harrow','harrow','warden'],enemy:['h_vanguard','h_interdictor','h_interdictor','h_picket','h_picket']}; const res=[];
  const run=async (b,asp)=>{ let w=0,hp=0; for(let i=0;i<n;i++){ const r=await sim(Object.assign({},S0,{boons:b,aspect:asp||null}),2); if(r.res==='win') w++; hp+=r.hpLeft; } return [Math.round(w/n*100),Math.round(hp/n*100)]; };
  const base=await run(''); res.push('BASE '+base.join('/'));
  for(const id of Object.keys(BOONS)){ const r=await run(id+':0'); res.push(id+' '+r[0]+'/'+r[1]+' '+(BOON_NEED[id]||'')); }
  for(const a of Object.keys(ASPECTS)){ const r=await run('',a); res.push('asp:'+a+' '+r[0]+'/'+r[1]); }
  console.log('BS '+JSON.stringify(res)); }
async function rsFight(cfg){ startBattle(cfg); let r=0; B.alt=true; for(const x of B.units) x.activated=false; startSideTurn('enemy');
  const pcp=RUN.fleet.reduce((a,s)=>a+(HULLS[s.tpl].cp||1),0), ecp=B.units.filter(u=>u.side==='enemy'&&!u.isSq).reduce((a,u)=>a+(u.t.cp||1),0), n0=RUN.fleet.length;
  while(!B.over&&r<30){ await swarmPhase('player'); await swarmPhase('enemy'); let g=0;
    while(!B.over&&g++<40){ const pp=alive('player').filter(x=>!x.isSq&&!x.activated), pe=alive('enemy').filter(x=>!x.isSq&&!x.activated); if(!pp.length&&!pe.length) break;
      if(pp.length){ await botUnit(pp[0]); pp[0].activated=true; } const batch=alive('player').some(x=>!x.isSq&&!x.activated)?(pe.length?[aiPickActivation(pe)]:[]):pe;
      for(const u of batch){ if(B.over) break; await aiUnit(u); u.activated=true; } }
    if(B.over) break; B.round++; for(const x of B.units) x.activated=false; startSideTurn('player'); startSideTurn('enemy'); r++; }
  for(const u of B.units){ if(!u.ship) continue; if((u.dead&&!u.exited)||u.side!=='player') RUN.fleet=RUN.fleet.filter(x=>x!==u.ship); else u.ship.hp=Math.max(1,Math.round(u.hp)); }
  return {win:B.over==='win', lost:Math.max(0,n0-RUN.fleet.length), pcp, ecp, rounds:B.round}; }
async function runSim(n){ const agg={}, reach={1:0,2:0,3:0,won:0}; const add=(k,f)=>{ const a=agg[k]||(agg[k]={n:0,w:0,lost:0,ratio:0,rounds:0}); a.n++; a.w+=f.win?1:0; a.lost+=f.lost; a.ratio+=f.ecp/Math.max(1,f.pcp); a.rounds+=f.rounds; };
  const facs=(process.env.FACS||'voidsworn,hegemony,corsair,chorus,ithar,deathless').split(',');
  for(let i=0;i<n;i++){ const fac=facs[i%facs.length], adms=Object.keys(ADMIRALS).filter(a=>(ADMIRALS[a].fac||'voidsworn')===fac), adm=process.env.ADM||adms[(i/facs.length|0)%adms.length];
    RUN={fac,foes:shuffle(RUN_FACTIONS.filter(f=>f!==fac)),admiral:adm,credits:345,cpCap:14,sector:1,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0,lost:0},fallen:[],boons:[],patrons:shuffle(Object.keys(PATRONS)).slice(0,4),aspect:pick(Object.keys(ASPECTS)),flagUid:null};
    for(const t of ADMIRALS[adm].start) RUN.fleet.push(newShip(equivHull(t,fac),true)); RUN.cpCap=Math.max(RUN.cpCap,fleetCP()+3); RUN.flagUid=RUN.fleet[0].uid;
    let alive1=true;
    for(let s=1;s<=3&&alive1;s++){ RUN.sector=s; reach[s]++; const map=genSector(s); RUN.map=map;
      for(const col of map.cols){ if(!RUN.fleet.length){ alive1=false; break; } const nd=pick(col);
        if(RUN.fleet.length<=1&&(RUN.reinf||0)<s){ RUN.reinf=s; RUN.fleet.push(newShip('warden')); }
        if(nd.type==='battle'||nd.type==='elite'||nd.type==='boss'){ const kind=nd.type, fac2=kind==='battle'?nodeFaction(nd):map.fac; const ro=kind==='boss'?{enc:'rout',shape:pick(['ring','open','hourglass'])}:{enc:nd.enc||'rout',shape:nd.shape||'open'};
          const f=await rsFight({kind,fac:fac2,col:nd.col,node:null,obj:ro.enc,shape:ro.shape,map:'random',dep:kind==='boss'?'line':undefined}); add('s'+s+' '+kind,f);
          if(!f.win||!RUN.fleet.length){ alive1=false; break; }
          RUN.credits+=Math.round((25+12*s+3*nd.col)*(kind==='boss'?3:kind==='elite'?1.6:1));
          const rw=nd.rw||rollNodeReward(kind); if(rw.k==='boon'){ const off=rollBoonOffer(rw.p,rw.min); if(off.length){ const b=pick(off); RUN.boons.push(b); } } else if(rw.k==='cred') RUN.credits+=35+10*s; else if(rw.k==='repair') RUN.fleet.forEach(sh=>{ const d=derive(sh); sh.hp=Math.min(d.maxHp,sh.hp+Math.round(d.maxHp*.25)); });
          if(kind!=='battle'){ const rl=randomRelic(); if(rl) RUN.relics.push(rl); } if(kind==='boss'){ RUN.cpCap+=3; RUN.fleet.forEach(sh=>{ const d=derive(sh); sh.hp=Math.min(d.maxHp,sh.hp+Math.round(d.maxHp*.4)); }); if(s===3) reach.won++; } }
        else if(nd.type==='shipyard'){ for(const sh of RUN.fleet){ const d=derive(sh), miss=d.maxHp-sh.hp, c=Math.ceil(miss/2); if(RUN.credits>=c){ RUN.credits-=c; sh.hp=d.maxHp; } }
          const ros=FACTIONS[fac].roster.filter(h=>!HULLS[h].unique&&HULLS[h].cost&&fleetCP()+HULLS[h].cp<=RUN.cpCap&&HULLS[h].cost<=RUN.credits);
          if(ros.length){ const h=ros.sort((a,b)=>HULLS[b].cp-HULLS[a].cp)[0]; RUN.credits-=HULLS[h].cost; RUN.fleet.push(newShip(h)); }
          else { const sh=pick(RUN.fleet); const mc=typeof mkCost==='function'?mkCost(sh):150; if(sh&&sh.mk<3&&RUN.credits>=mc){ RUN.credits-=mc; sh.mk++; } } }
        else if(nd.type==='drydock'){ RUN.fleet.forEach(sh=>{ const d=derive(sh); sh.hp+=Math.ceil((d.maxHp-sh.hp)*.6); }); }
        else if(nd.type==='field'){ RUN.fleet.forEach(sh=>{ const d=derive(sh); sh.hp=Math.min(d.maxHp,sh.hp+Math.round(d.maxHp*.2)); }); }
      } } }
  const out={}; for(const [k,a] of Object.entries(agg).sort()) out[k]=a.n+' battles, won '+Math.round(a.w/a.n*100)+'%, lost/fight '+(a.lost/a.n).toFixed(2)+', e/p cp '+(a.ratio/a.n).toFixed(2)+', rounds '+(a.rounds/a.n).toFixed(1);
  console.log('RUNSIM '+JSON.stringify(out,null,1)); console.log('reach', JSON.stringify(reach)); }
async function bossCmdCheck(n){ const out={}; for(const bf of ['hegemony','corsair','chorus','ithar','deathless','voidsworn']){ let ann=0,fired=0,wins=0;
  for(let i=0;i<n;i++){ RUN={admiral:'vex',fac:'voidsworn',credits:0,cpCap:40,sector:2,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[],boons:[],patrons:[]};
    for(const t of ['cathedral','penitent','harrow','warden','warden']) RUN.fleet.push(newShip(t,false));
    const f=await rsFight({kind:'boss',fac:bf,col:6,obj:'rout',shape:'open',map:'random',dep:'line'}); wins+=f.win?1:0;
    ann+=B.log.filter(l=>/is preparing/.test(l.m)).length; fired+=B.cmdEUsed&&B.cmdE?1:0; }
  out[bf]='announced '+ann+' fired '+fired+' wins '+wins+'/'+n; } console.log('BOSSCMD '+JSON.stringify(out)); }
async function scenSim(n){ const SC={
  'A as played (2 Harvesters)':{fleet:['d_harvester','d_harvester'],mk:[1,2]},
  'B +2 Scythes':{fleet:['d_harvester','d_harvester','d_scythe','d_scythe'],mk:[1,2,1,1]},
  'C +Jackal +Scythe':{fleet:['d_harvester','d_harvester','d_jackal','d_scythe'],mk:[1,2,1,1]},
  'D both Harvesters Mk2':{fleet:['d_harvester','d_harvester'],mk:[2,2]},
  'E +4 Scythes':{fleet:['d_harvester','d_harvester','d_scythe','d_scythe','d_scythe','d_scythe'],mk:[1,2,1,1,1,1]},
  'F Jackal x2 + Scythe x2 + Harvester':{fleet:['d_harvester','d_jackal','d_jackal','d_scythe','d_scythe'],mk:[2,1,1,1,1]}};
  const hpf=+(process.env.HPF||.75), facs=(process.env.EF||'corsair').split(','), out={};
  for(const [name,S] of Object.entries(SC)){ let w=0,t=0,lost=0,rd=0,ecp=0;
    for(const ef of facs) for(let i=0;i<n;i++){ RUN={fac:'deathless',admiral:'sekhmar',credits:0,cpCap:17,sector:2,relics:['martyr','banner'],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0,lost:0},fallen:[],boons:[{id:'s_cap',r:0},{id:'d_bastion',r:0},{id:'s_ev',r:1}],patrons:['storm','rook','iron','ember'],aspect:'lancer',flagUid:null};
      S.fleet.forEach((tp,j)=>{ const s=newShip(tp,true); s.mk=S.mk[j]||1; RUN.fleet.push(s); }); RUN.flagUid=RUN.fleet[0].uid; RUN.fleet.forEach(s=>{ s.hp=Math.round(derive(s).maxHp*hpf); });
      const f=await rsFight({kind:'battle',fac:ef,col:0,obj:'rout',shape:process.env.SHAPE||'rift',map:'belt',dep:'flank'}); w+=f.win?1:0; t++; lost+=f.lost; rd+=f.rounds; ecp+=f.ecp; }
    out[name]='win '+Math.round(w/t*100)+'%, ships lost '+(lost/t).toFixed(1)+', rounds '+(rd/t).toFixed(1)+', enemy cp '+(ecp/t).toFixed(1); }
  console.log('SCEN '+JSON.stringify(out,null,1)); }
function progCheck(){ const out=[]; const ok=(n,c,d)=>out.push((c?'PASS ':'FAIL ')+n+(d?': '+d:''));
  META.mastery={sekhmar:60,vex:0}; META.favour={storm:13}; 
  for(const adm of Object.keys(ADMIRALS)){ const fac=ADMIRALS[adm].fac||'voidsworn', base=ADMIRALS[adm].start.map(t=>equivHull(t,fac)), p=altFleetPlan(adm,fac), a=p.fleet, cp=l=>l.reduce((s,t)=>s+(HULLS[t].cp||1),0), car=l=>l.filter(t=>HULLS[t].ab==='launch').length;
    ok('alt fleet '+adm, a.length>0&&a.every(t=>HULLS[t]&&HULLS[t].fac===fac)&&cp(a)===cp(base)&&car(a)>=car(base)&&(a.slice().sort().join()!==base.slice().sort().join()||!!p.mod), base.join('+')+' -> '+a.join('+')+(p.mod?' +'+p.mod:'')); }
  for(const adm of Object.keys(ADMIRALS)){ const c=altCommand(adm); if(!c||c.id===ADMIRALS[adm].cmd.id) ok('alt command '+adm,false,String(c&&c.id)); }
  ok('every admiral has a distinct second Command',!out.some(x=>x.startsWith('FAIL alt command')));
  newRun('sekhmar','deathless',{alt:true,cmdAlt:true,heat:['h_hunted','h_cmd']}); RUN.patrons=['storm','rook','iron','ember'];
  ok('mastery level 4 from 60 xp',RUN.mastery===4,'level '+RUN.mastery);
  ok('alternate fleet used',RUN.altFleet,RUN.fleet.map(s=>s.tpl).join('+'));
  ok('second Command in force',commandFor('player').id!==ADMIRALS.sekhmar.cmd.id,commandFor('player').id);
  const f=flagshipOf(); ok('flag captain: flagship Mk II, Captain rank',f.mk>=2&&f.cap.rank>=2,'mk '+f.mk+' rank '+f.cap.rank);
  ok('heat stored',heatLevel(RUN.heat)===3,heatLevel(RUN.heat));
  META.favour={storm:13}; newRun('vex','voidsworn',{}); if(!RUN.patrons.includes('storm')){ RUN.patrons[0]='storm'; RUN.boons=[]; } 
  newRun('vex','voidsworn',{}); let gifts=0; for(let i=0;i<20;i++){ newRun('vex','voidsworn',{}); if(RUN.patrons.includes('storm')&&RUN.giftBoon&&BOONS[RUN.giftBoon].p==='storm') gifts++; else if(RUN.patrons.includes('storm')) ok('devoted gift missing',false); }
  ok('Devoted patron gives a starting boon when watching',gifts>0,gifts+'/20 runs');
  let r=0; for(let i=0;i<400;i++) r+=rollRarity(0,1,'storm')>0?1:0; let r0=0; for(let i=0;i<400;i++) r0+=rollRarity(0,1,'rook')>0?1:0; ok('Favoured patron rolls more rare boons',r>r0+20,r0+' -> '+r+' of 400');
  RUN.sector=2; const m=genSector(2); ok('sector 2 opens with a shipyard',m.cols[0].length===1&&m.cols[0][0].type==='shipyard');
  RUN.heat=['h_cmd']; B={round:1,units:[]}; ok('Slow orders delays the Command',cmdTier()===0); B={round:3,units:[]}; ok('Slow orders: full power at round 4 instead of 3',cmdTier()===1);
  RUN.heat=['h_coffers']; ok('Lean coffers raises prices',priceMult()>1.1,priceMult());
  console.log(out.join(' | ')); console.log(out.some(x=>x.startsWith('FAIL'))?'PROGCHECK FAILED':'PROGCHECK PASSED'); }
async function accCheck(n){ const acc={}, dmg={}; let cur=null;
  const _f=fireWeapon; fireWeapon=async function(u,wi,t,o){ const prev=cur; cur={u,w:u.weapons[wi],t}; try{ return await _f(u,wi,t,o); } finally{ cur=prev; } };
  const _h=hitChance; hitChance=function(u,w,t){ const c=_h(u,w,t); if(cur&&cur.u===u&&cur.w===w&&cur.t===t&&!u.isSq){ const k=u.fac+' '+w.k+(t.isSq?' vs craft':''); const a=acc[k]||(acc[k]={c:0,n:0,d:0}); a.c+=c; a.n++; a.d+=hdist(u,t); } return c; };
  const _a=applyHit; applyHit=function(att,w,t,d,q){ const r=_a(att,w,t,d,q); if(!t.isSq){ const k=t.fac+' hull hit by '+(att.isSq?'craft':w.k); dmg[k]=(dmg[k]||0)+r.hull; } return r; };
  const fleets={deathless:['d_harvester','d_harvester_t','d_scythe','d_scythe'],voidsworn:['penitent','harrow','harrow','warden'],hegemony:['h_vanguard','h_interdictor','h_picket','h_picket'],ithar:['i_song','i_blade','i_wisp','i_wisp'],chorus:['b_razor','b_spitter','b_drone','b_drone'],corsair:['c_marauder','c_reaver','c_raider','c_raider']};
  const res={}; for(const [pf,fl] of Object.entries(fleets)){ let w=0;
    for(let i=0;i<n;i++){ RUN={fac:pf,admiral:'vex',credits:0,cpCap:20,sector:1,relics:[],inventory:[],fleet:fl.map(t=>newShip(t,true)),stats:{battles:0,elites:0,bosses:0,kills:0,lost:0},fallen:[],boons:[],patrons:[],flagUid:null}; RUN.flagUid=RUN.fleet[0].uid;
      const ef=process.env.EF||'corsair'; if(ef===pf) continue; const f=await rsFight({kind:'elite',fac:ef,col:4,obj:'rout',shape:'open',map:'belt'}); w+=f.win?1:0; }
    res[pf]=Math.round(w/n*100)+'%'; }
  console.log('WIN vs '+(process.env.EF||'corsair')+' elite: '+JSON.stringify(res));
  console.log('HIT '+JSON.stringify(Object.fromEntries(Object.entries(acc).filter(([k,v])=>v.n>20).sort().map(([k,v])=>[k,Math.round(v.c/v.n)+'% @'+(v.d/v.n).toFixed(1)+' ('+v.n+')']))));
  const tot={}; for(const [k,v] of Object.entries(dmg)){ const f=k.split(' ')[0]; tot[f]=(tot[f]||0)+v; }
  console.log('DMG '+JSON.stringify(Object.fromEntries(Object.entries(dmg).sort().map(([k,v])=>[k,Math.round(v/tot[k.split(' ')[0]]*100)+'%'])))); }
async function scen2(n){ const SC={
  'as played: Harvester + tomb-turret Mk2':{fleet:['d_harvester','d_harvester_t'],mk:[1,2]},
  'same credits: Harvester + Jackal + 2 Scythes':{fleet:['d_harvester','d_jackal','d_scythe','d_scythe'],mk:[1,1,1,1]},
  'Harvester + tomb-turret (no Mk) + Scythe':{fleet:['d_harvester','d_harvester_t','d_scythe'],mk:[1,1,1]}};
  const out={}; for(const [name,S] of Object.entries(SC)){ for(const asp of ['lancer','bulwark','ram']){ let w=0,lost=0,rd=0,ecp=0;
    for(let i=0;i<n;i++){ RUN={fac:'deathless',admiral:'sekhmar',credits:0,cpCap:14,sector:1,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0,lost:0},fallen:[],boons:[{id:'e_kindle',r:1},{id:'a_long',r:2}],patrons:['iron','rook','star','ember'],aspect:asp,flagUid:null};
      S.fleet.forEach((tp,j)=>{ const s=newShip(tp,true); s.mk=S.mk[j]||1; RUN.fleet.push(s); }); RUN.flagUid=RUN.fleet[0].uid; RUN.fleet.forEach(s=>{ s.hp=Math.round(derive(s).maxHp*.85); });
      const f=await rsFight({kind:'elite',fac:'corsair',col:4,obj:'intercept',shape:'dense',map:'storm'}); w+=f.win?1:0; lost+=f.lost; rd+=f.rounds; ecp+=f.ecp; }
    out[name+' / '+asp]='win '+Math.round(w/n*100)+'%, lost '+(lost/n).toFixed(1)+', rounds '+(rd/n).toFixed(1)+', enemy cp '+(ecp/n).toFixed(1); } }
  console.log('SCEN2 '+JSON.stringify(out,null,1)); }
async function stallScopeCheck(){ RUN={admiral:'vex',fac:'voidsworn',credits:0,cpCap:40,sector:1,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]};
  for(const t of ['harrow','warden']) RUN.fleet.push(newShip(t,false));
  startBattle({kind:'battle',fac:'hegemony',col:1,dep:'line',obj:'rout'}); const A=B; const hung=stallGuard(new Promise(()=>{}),300,'test',{});
  startBattle({kind:'battle',fac:'hegemony',col:1,dep:'line',obj:'rout'}); const Bn=B, ep0=Bn.epoch||0;
  const r=await Promise.race([hung,new Promise(res=>setTimeout(()=>res('timeout'),2000))]);
  const own=stallGuard(new Promise(()=>{}),300,'test',{}); const r2=await Promise.race([own,new Promise(res=>setTimeout(()=>res('timeout'),2000))]);
  const ok=r==='stale'&&(Bn.epoch||0)===ep0+1&&r2==='stall';
  console.log((ok?'PASS':'FAIL')+' old battle guard resolved as '+r+' without touching the new battle; own guard '+r2+'; new battle epoch '+ep0+' -> '+(Bn.epoch||0)+' (only its own stall bumps it)'); }
global.stallScopeCheck=stallScopeCheck;
function encCount(){ const tot={}; let col1=0, n=0, adj=0; for(let i=0;i<300;i++){ RUN={foes:['hegemony','corsair','chorus','ithar','deathless']}; const m=genSector(1+i%3);
  for(const col of m.cols) for(const x of col) if(x.enc) tot[x.enc]=(tot[x.enc]||0)+1;
  const c1=m.cols[1].filter(x=>x.enc); n++; if(c1.some(x=>ENC_SPECIAL.includes(x.enc))) col1++; }
  console.log('encounters over 300 sectors',JSON.stringify(tot),'| column 2 offers a special fight in',col1+'/'+n); }
global.encCount=encCount;
global.campaignSim=campaignSim; global.fuzz=fuzz;
var CH_ENC={};
async function chainSim(n){ const nodes=[['battle',0],['battle',1],['elite',2],['battle',3],['battle',4],['boss',6]]; const died={}; let wins=0;
  for(let i=0;i<n;i++){ RUN={admiral:'vex',credits:0,cpCap:40,sector:1,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]};
    for(const t of ['penitent','harrow','warden']) RUN.fleet.push(newShip(t,false)); let dead=null;
    for(const [kind,col] of nodes){ if(RUN.fleet.length<=1&&!RUN.reinf&&!NO_CAP){ RUN.reinf=1; RUN.fleet.push(newShip('warden',false)); }
      if(col===3) for(const s of RUN.fleet){ const mx=derive(s).maxHp; s.hp=Math.min(mx,s.hp+Math.round(mx*.2)); }
      { const ro=process.env.ENC==='roll'?rollEncounter(kind,col):{enc:'rout',shape:'open'}; startBattle({kind,fac:'corsair',col,dep:'line',obj:ro.enc,shape:ro.shape}); CH_ENC[B.obj.type]=(CH_ENC[B.obj.type]||0)+1; } let r=0; B.alt=true; for(const x of B.units) x.activated=false; startSideTurn('enemy');
      while(!B.over&&r<30){ await swarmPhase('player'); await swarmPhase('enemy'); let g=0;
        while(!B.over&&g++<40){ const pp=alive('player').filter(x=>!x.isSq&&!x.activated), pe=alive('enemy').filter(x=>!x.isSq&&!x.activated); if(!pp.length&&!pe.length) break;
          if(pp.length){ await botUnit(pp[0]); pp[0].activated=true; } const sqs=alive('enemy').filter(x=>x.isSq&&!x.activated); const batch=alive('player').some(x=>!x.isSq&&!x.activated)?(pe.length?[aiPickActivation(pe)]:[]):pe;
          for(const u of [...sqs,...batch]){ if(B.over) break; await aiUnit(u); u.activated=true; } }
        if(B.over) break; B.round++; for(const x of B.units) x.activated=false; startSideTurn('player'); startSideTurn('enemy'); r++; }
      for(const u of B.units){ if(!u.ship) continue; if((u.dead&&!u.exited)||u.side!=='player') RUN.fleet=RUN.fleet.filter(x=>x!==u.ship); else u.ship.hp=Math.max(1,Math.round(u.hp)); }
      if(B.over==='win'&&process.env.ECON!=='0'){ for(const s of RUN.fleet){ const mx=derive(s).maxHp; s.hp=Math.min(mx,s.hp+Math.round(mx*.15)); }
        if(col===1&&RUN.fleet.length<3) RUN.fleet.push(newShip('harrow',false));
        if(col===4) for(const s of RUN.fleet) s.hp=derive(s).maxHp; }
      const retreat=B.over==='loss'&&B.withdraw&&RUN.fleet.length; if(retreat) CH_ENC.retreats=(CH_ENC.retreats||0)+1; if(B.partial) CH_ENC.partial=(CH_ENC.partial||0)+1;
      if((B.over!=='win'&&!retreat)||!RUN.fleet.length){ dead=kind+'@'+col+(B.obj?':'+B.obj.type:''); break; } }
    if(dead) died[dead]=(died[dead]||0)+1; else wins++; }
  console.log(\`chain \${NO_CAP?'OLD (no scaling)':'NEW (scaling+reinforcement)'}: cleared sector 1 in \${wins}/\${n} runs; deaths by node \${JSON.stringify(died)} encounters \${JSON.stringify(CH_ENC)}\`); }
global.chainSim=chainSim;
function capCheck(){ let worst=0; const rows=[]; for(const [ac,dc,fac] of [[60,10,'voidsworn'],[40,14,'corsair'],[30,12,'voidsworn'],[50,25,'chorus'],[25,5,'hegemony'],[45,18,'ithar'],[80,30,'corsair'],[20,9,'deathless']]){
    const u={crew:ac,fac}, t={crew:dc}; const shown=captureChance(u,t); let n=0; const N=10000; const m=BOARD_MULT[fac]||1;
    for(let i=0;i<N;i++){ if(Math.round(u.crew*m*(.75+rnd()*.5)*.38)>=t.crew) n++; } const real=100*n/N; worst=Math.max(worst,Math.abs(real-shown)); rows.push(ac+' vs '+dc+' ('+fac+'): shown '+shown+'%, rolled '+real.toFixed(1)+'%'); }
  console.log(rows.join(String.fromCharCode(10))); console.log('largest gap: '+worst.toFixed(1)+' points'); }
global.capCheck=capCheck;
async function staleCheck(){ RUN={fac:'voidsworn',admiral:'vex',fleet:[],relics:[],inventory:[],sector:1,cpCap:40,credits:0,stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]}; for(const t of ['penitent','reliquary','warden']) RUN.fleet.push(newShip(t,false)); startBattle({kind:'battle',fac:'hegemony',col:2,dep:'line',obj:'rout',pf:'voidsworn'}); const old=alive('player').find(u=>!u.isSq&&u.ab); const A=B;
  startBattle({kind:'battle',fac:'corsair',col:2,dep:'line',obj:'rout',pf:'voidsworn'}); const t=alive('enemy')[0], hp0=t.hp+t.sh.reduce((a,x)=>a+x,0), q0=old.q;
  const fired=await fireWeapon(old,0,t,{intercept:true}); await moveUnit(old,{path:[{q:old.q+1,r:old.r,f:old.facing}],cost:1,t:0}); const ab=await useAbility(old,{});
  const hp1=t.hp+t.sh.reduce((a,x)=>a+x,0); console.log('stale ship fired:',fired,'| new-battle target damaged:',hp1!==hp0,'| stale ship moved:',old.q!==q0,'| stale ability used:',ab,'| battles differ:',A!==B); }
global.staleCheck=staleCheck;
async function usageCheck(){ await match('voidsworn','corsair','sk',true); console.log('usage recorded:',JSON.stringify(B.usage)); }
global.usageCheck=usageCheck;
async function cmdCheck(){ const cases=[['vex','barrage'],['malek','hunt'],['aelith','scramble'],['maren','iron'],['nekhet','restore'],['grax','surge']]; const res=[];
  for(const [adm,id] of cases){ const A=ADMIRALS[adm]; RUN={fac:A.fac||'voidsworn',admiral:adm,fleet:[],relics:[],inventory:[],sector:1,cpCap:40,credits:0,stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]};
    for(const t of A.start) RUN.fleet.push(newShip(t,false));
    startBattle({kind:'battle',fac:A.fac==='hegemony'?'corsair':'hegemony',col:3,dep:'line',obj:'rout'}); for(const x of B.units) x.activated=false;
    const P=alive('player').filter(u=>!u.isSq), E=alive('enemy').filter(u=>!u.isSq); E.forEach((e,i)=>{ const p=P[i%P.length]; e.q=p.q+3; e.r=p.r+(i>=P.length?1:0); e.facing=3; }); for(const p of P) p.facing=0;
    for(const w of alive().filter(u=>u.isSq)){ const c=B.units.find(x=>x.id===w.parent); const hs=c?launchHexes(c):[]; if(hs.length){ w.q=hs[0].q; w.r=hs[0].r; } } // wings fly with their carrier
    const ehp0=E.reduce((a,u)=>a+u.hp+u.sh.reduce((x,y)=>x+y,0),0), fired0=P.map(u=>u.weapons.map(w=>w.fired).join()), sq0=alive('player').filter(u=>u.isSq).length;
    if(id==='restore') P.forEach(u=>u.hp=Math.round(u.maxHp*.5)); if(id==='iron') P.forEach(u=>u.sh=u.sh.map(()=>0));
    const hp0=P.map(u=>u.hp), mp0=P.map(u=>u.mp), w0=E[0].weapons.find(w=>w.k!=='flak')||E[0].weapons[0], hit0=hitChance(E[0],w0,P[0]);
    const pw=P[0].weapons.find(w=>w.k!=='flak')||P[0].weapons[0], dm0=dmgMult(P[0],pw,E[0],false), exp0=expectedVs(E[0],w0,P[0]).hull;
    const early=canCommand('player'); B.round=+(process.env.CMDROUND||2); const ok=await useCommand('player');
    let pass, note;
    const ehp1=E.reduce((a,u)=>a+Math.max(0,u.hp)+u.sh.reduce((x,y)=>x+y,0),0);
    if(id==='barrage'){ pass=ehp1<ehp0&&P.map(u=>u.weapons.map(w=>w.fired).join()).join('|')===fired0.join('|'); note=\`enemy hull+shields \${Math.round(ehp0)} -> \${Math.round(ehp1)}, weapons state kept\`; }
    if(id==='hunt'){ const r=dmgMult(P[0],pw,E[0],false)/dm0; const torps=alive('player').flatMap(u=>u.weapons).filter(w=>w.k==='torp'); pass=Math.abs(r-1-cmdPow('hunt'))<.01&&torps.length>0&&torps.every(w=>!w.fired&&!w.cdLeft); note=\`damage x\${r.toFixed(2)}, \${torps.length} torpedo tubes ready\`; }
    if(id==='scramble'){ const wings=B.units.filter(u=>u.isSq&&u.side==='player'); const flew=wings.filter(u=>u.activated&&u.weapons.some(w=>w.fired)); pass=wings.length>sq0&&flew.length===wings.length; note=\`wings launched \${wings.length-sq0}, flew their strike \${flew.length}/\${wings.length}, shot down by flak \${wings.filter(u=>u.dead).length}, enemy hull+shields \${Math.round(ehp0)} -> \${Math.round(ehp1)}\`; }
    if(id==='iron'){ const r=expectedVs(E[0],w0,P[0]).hull, ip=cmdPow('iron'); pass=P.every(u=>!u.shMax||u.sh.every(x=>x===u.shMax)); note=\`shields refilled; expected hull damage \${exp0.toFixed(1)} -> \${r.toFixed(1)} (shields now soak too)\`; P[0].sh=P[0].sh.map(()=>0); const r2=expectedVs(E[0],w0,P[0]).hull; B.cmd=null; const r3=expectedVs(E[0],w0,P[0]).hull; pass=pass&&Math.abs(r2/r3-(1-ip))<.02; note+=\`; with shields down x\${(r2/r3).toFixed(2)}\`; }
    if(id==='restore'){ pass=P.every((u,i)=>u.hp===Math.min(u.maxHp,hp0[i]+Math.round(u.maxHp*cmdPow('restore')))); note=\`hull \${hp0.join('/')} -> \${P.map(u=>u.hp).join('/')}\`; }
    if(id==='surge'){ const hit1=hitChance(E[0],w0,P[0]); pass=P.every((u,i)=>u.mp===mp0[i]+cmdPow('surge'))&&Math.abs((hit0-hit1)-20)<.01; note=\`movement +\${cmdPow('surge')}, enemy hit chance \${hit0.toFixed(0)} -> \${hit1.toFixed(0)}\`; }
    const again=canCommand('player'); res.push(\`\${(pass&&ok&&early&&B.cmdUsed&&!again)?'PASS':'FAIL'} \${A.cmd.n} (\${adm}, \${id}): \${note}; usable in round 1 \${early}, usable again \${again}\`); }
  console.log(res.join(String.fromCharCode(10))); }
global.cmdCheck=cmdCheck;
function nameCheck(){ RUN={fleet:[],relics:[],inventory:[],admiral:'vex'}; for(const [f,tpls] of Object.entries({voidsworn:['penitent'],hegemony:['h_vanguard','h_picket'],corsair:['c_hulk','c_raider'],chorus:['b_brood','b_drone'],ithar:['i_carrier','i_blade'],deathless:['d_harvester','d_jackal']})){ const out=tpls.map(t=>{ const s=newShip(t,false); RUN.fleet.push(s); return s.name+' ('+rankName(s.cap)+' '+s.cap.name+')'; }); const top=rankName({fac:f,rank:4}); console.log(f.padEnd(10),out.join(' | '),'| top rank:',top); } }
global.nameCheck=nameCheck;
function factionCheck(){ const cp=l=>l.reduce((a,t)=>a+HULLS[t].cp,0);
  for(const f of RUN_FACTIONS){ const starts=Object.entries(ADMIRALS).map(([id,a])=>{ const m=a.start.map(t=>equivHull(t,f)); return id+': '+m.join('+')+' ('+cp(m)+' vs '+cp(a.start)+')'; }); console.log(f.padEnd(10),'yard:',['warden','harrow','penitent','reliquary','cathedral','ascendant'].map(h=>equivHull(h,f)).join(',')); console.log('    ',starts.join(' | ')); }
  let own=0,dup=0,rival=0,battles=0,mainMismatch=0; for(let i=0;i<300;i++){ const f=RUN_FACTIONS[i%6]; const foes=shuffle(RUN_FACTIONS.filter(x=>x!==f)); if(foes.slice(0,3).includes(f)) own++; if(new Set(foes.slice(0,3)).size<3) dup++;
    RUN={fac:f,foes,sector:1,fleet:[]}; RUN.map=genSector(1); if(RUN.map.fac!==foes[0]) mainMismatch++; for(const col of RUN.map.cols) for(const n of col) if(n.type==='battle'){ battles++; if(nodeFaction(n)!==RUN.map.fac) rival++; } }
  console.log(\`300 runs: own faction faced \${own}, repeated sector factions \${dup}, sector-1 enemy not from shuffle \${mainMismatch}, rival raiders \${(100*rival/battles).toFixed(1)}% of \${battles} battles\`); }
global.factionCheck=factionCheck;
async function sqCheck(n){ const st={attacks:0,illegal:0,bomberOnCraft:0,fighterOnShipWithCraft:0,leash:0,idleWithTarget:0,launched:0,sqTurns:0,flakIntercepts:0};
  const _fw=fireWeapon; fireWeapon=async function(u,i,t,o){ if(u.isSq&&!(o&&o.intercept)){ st.attacks++; const w=u.weapons[i]; if(!canFire(u,w,t)) st.illegal++; if(sqRole(u)==='bomber'&&t.isSq) st.bomberOnCraft++; if(sqRole(u)==='fighter'&&!t.isSq&&alive(t.side).some(x=>x.isSq)) st.fighterOnShipWithCraft++; } if(o&&o.intercept) st.flakIntercepts++; return _fw(u,i,t,o); };
  const _sp=swarmPhase; swarmPhase=async function(side){ for(const s of alive(side).filter(x=>x.isSq&&!x.activated)){ st.sqTurns++; const p=sqPlan(s); if(p&&!p.attack){ /* verify nothing was truly reachable */ const ready=s.weapons.filter(weaponReady), {states}=computeReach(s), carrier=B.units.find(x=>x.id===s.parent&&!x.dead);
        for(const stt of [{q:s.q,r:s.r,f:s.facing},...states]){ const v=stateView(s,stt); if(carrier&&hdist(v,carrier)>SQ_LEASH) continue; if(alive(side==='player'?'enemy':'player').some(t=>sqWants(s,t)&&ready.some(w=>inReach(v,w,t)))){ st.idleWithTarget++; break; } } } }
    const before=new Map(alive(side).filter(x=>x.isSq).map(s=>{ const c=B.units.find(x=>x.id===s.parent&&!x.dead); return [s.id,c?hdist(s,c):0]; }));
    await _sp(side); for(const s of alive(side).filter(x=>x.isSq)){ const c=B.units.find(x=>x.id===s.parent&&!x.dead); if(!c) continue; const d=hdist(s,c); if(d>SQ_LEASH){ st.outsideLeash=(st.outsideLeash||0)+1; if(d>=(before.get(s.id)||0)) st.leash++; } } };
  const _ua=useAbility; useAbility=async function(u,o){ if(u.ab==='launch') st.launched++; return _ua(u,o); };
  const pairs=[['voidsworn','ithar'],['ithar','chorus'],['chorus','voidsworn'],['voidsworn','hegemony'],['ithar','deathless']];
  for(let i=0;i<n;i++){ const [a,b2]=pairs[i%pairs.length]; await match(a,b2,'sk',i%2===0); }
  console.log('squadron audit '+n+' battles: '+JSON.stringify(st)); }
global.sqCheck=sqCheck;`);
global.Persist={save(){},saveLocal(){},push(){}};
(async()=>{ if(process.argv[2]==='scen2'){ await scen2(+(process.argv[3]||20)); return; } if(process.argv[2]==='acccheck'){ await accCheck(+(process.argv[3]||10)); return; } if(process.argv[2]==='progcheck'){ progCheck(); return; } if(process.argv[2]==='scen'){ await scenSim(+(process.argv[3]||20)); return; } if(process.argv[2]==='bosscmd'){ await bossCmdCheck(+(process.argv[3]||3)); return; } if(process.argv[2]==='runsim'){ await runSim(+(process.argv[3]||12)); return; } if(process.argv[2]==='boonsingle'){ await boonSingle(+(process.argv[3]||40)); return; } if(process.argv[2]==='fmatrix'){ await fMatrix(+(process.argv[3]||6)); return; } if(process.argv[2]==='bossmatrix'){ await bossMatrix(+(process.argv[3]||4)); return; } if(process.argv[2]==='archmatrix'){ await archMatrix(+(process.argv[3]||2)); return; } if(process.argv[2]==='shapecheck'){ shapeCheck(+(process.argv[3]||25)); return; } if(process.argv[2]==='budgetcheck'){ budgetCheck(); return; } if(process.argv[2]==='booncheck'){ await boonCheck(); return; } if(process.argv[2]==='rulecheck'){ await ruleCheck(); return; } if(process.argv[2]==='boonsim'){ await boonSim(+(process.argv[3]||40)); return; } if(process.argv[2]==='spawncheck'){ spawnCheck(+(process.argv[3]||200)); return; } if(process.argv[2]==='capcheck'){ capCheck(); return; } if(process.argv[2]==='evcheck'){ evCheck(); return; } if(process.argv[2]==='enccount'){ encCount(); return; } if(process.argv[2]==='stallscope'){ await stallScopeCheck(); return; } if(process.argv[2]==='ramcheck'){ await ramCheck(+(process.argv[3]||30)); return; } if(process.argv[2]==='bosscheck'){ await bossCheck(+(process.argv[3]||30)); return; } if(process.argv[2]==='stalecheck'){ await staleCheck(); return; } if(process.argv[2]==='usagecheck'){ await usageCheck(); return; } if(process.argv[2]==='cmdcheck'){ await cmdCheck(); return; } if(process.argv[2]==='namecheck'){ nameCheck(); return; } if(process.argv[2]==='factioncheck'){ factionCheck(); return; }
  if(process.argv[2]==='sqcheck'){ await sqCheck(+(process.argv[3]||30)); return; } if(process.argv[2]==='mapcheck'){ let bad=0,rest=0,nofight=0; const seen={}; for(let i=0;i<300;i++){ const cols=genSector(1+i%3).cols; const last=cols[cols.length-2]; for(const n of last){ seen[n.type]=(seen[n.type]||0)+1; if(!['shipyard','drydock','field'].includes(n.type)) bad++; else rest++; } for(let c=1;c<cols.length-2;c++) if(!cols[c].some(n=>n.type==='battle'||n.type==='elite')) nofight++; } console.log(`mapcheck 300 sectors: nodes before boss ${rest} rest / ${bad} not-rest ${JSON.stringify(seen)}; columns missing a fight: ${nofight}`); return; } if(process.argv[2]==='chain'){ await chainSim(+(process.argv[3]||20)); return; } if(process.argv[2]==='shipcount'){ shipCount(+(process.argv[3]||60)); return; } if(process.argv[2]==='campaign'){ await campaignSim(+(process.argv[3]||10)); return; } if(process.argv[2]==='fuzz'){ await fuzz(+(process.argv[3]||100)); return; }
  if(process.argv[2]==='matrix'){ const F=['voidsworn','hegemony','corsair','chorus','ithar','deathless'], n=+(process.argv[3]||6), mode=process.argv[4]||'sk'; const tot={}; const RW=process.argv[5]?process.argv[5].split(','):F, CL=process.argv[6]?process.argv[6].split(','):F;
    console.log(''.padEnd(10)+CL.map(c=>c.slice(0,4).padStart(5)).join('')); for(const pf of RW){ let line=pf.padEnd(10); for(const ef of CL){ let w=0; for(let i=0;i<n;i++) if(await match(pf,ef,mode,true)) w++; line+=String(Math.round(w/n*100)).padStart(5); tot[pf]=(tot[pf]||0)+w; } console.log(line+'   avg '+Math.round(tot[pf]/(n*CL.length)*100)); }
    console.log('per battle: rounds '+(STATS.rounds/STATS.n).toFixed(1)+', timeouts '+STATS.timeout+'/'+STATS.n+', rams '+(STATS.rams/STATS.n).toFixed(1)+', boardings '+(STATS.boards/STATS.n).toFixed(1)+', captures '+(STATS.caps/STATS.n).toFixed(2)+', sections lost '+(STATS.secs/STATS.n).toFixed(1)); return; }
  const S=JSON.parse(process.argv[2]), sector=+(process.argv[3]||2), n=+(process.argv[4]||60);
  let wins=0,hp=0,lost=0,rounds=0;
  for(let i=0;i<n;i++){ const r=await sim(S,sector); if(r.res==='win') wins++; hp+=r.hpLeft; lost+=r.lost; rounds+=r.rounds; }
  if(global.SQD) for(const [k,v] of Object.entries(global.SQD)) console.log('   ',k.padEnd(22),'dealt/battle',(v.dealt/n).toFixed(0),'units/battle',(v.n/n).toFixed(1),'died',(v.died/v.n*100).toFixed(0)+'%');
  console.log(`${S.tag} s${sector}: win ${wins}/${n} (${Math.round(wins/n*100)}%), hull left ${(hp/n*100).toFixed(0)}%, lost ${(lost/n).toFixed(1)}, rounds ${(rounds/n).toFixed(1)}`);
})();
