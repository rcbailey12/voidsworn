// ======================= BATTLE LOGIC =======================
const BW=30, BH=22; // v47: a bigger canvas; each battle's arena (strip, square or round) is cut out of it
const CX=(BW-26)>>1; // shifts the old fixed columns (built for a 26-wide board) onto the middle of the canvas
let ARENA={kind:'strip',mT:3,mB:3,mL:1,mR:1};
let B=null;
const BLOCKING={rock:1,hulk:1,planet:1,station:1};
// one table for what every terrain type is and does: tints, tooltips and the legend all read from it
const TERRAIN_INFO={
  rock:{n:'Asteroids',col:'#ff6b5a',fx:'Blocks movement and line of fire.'},
  hulk:{n:'Wreck',col:'#ff6b5a',fx:'A burning hulk. Blocks movement and line of fire.'},
  station:{n:'Station',col:'#9a948a',fx:'Blocks movement and line of fire.'},
  planet:{n:'Planet',col:'#9a948a',fx:'Blocks movement and line of fire.'},
  neb:{n:'Nebula',col:'#b07cff',fx:'Ships inside are 15 points harder to hit.'},
  debris:{n:'Debris',col:'#d4bf86',fx:'Ships inside are 10 points harder to hit.'},
  storm:{n:'Ion storm',col:'#ffe866',fx:'Ships inside lose 10 shield on every facing each turn and aim 10 points worse.'}};
function terrainPresent(){ const s=new Set(Object.values(B.terrain||{})); return Object.keys(TERRAIN_INFO).filter(k=>s.has(k)); }
// battle variety: board shapes and encounter types
const SHAPES={open:'Open void',corridor:'Corridor',lanes:'Split lanes',ring:'Ring',dense:'Dense field',compact:'Close quarters',deadstar:'Dead star',rift:'Rift',shoals:'Shoals',hourglass:'Hourglass',archipelago:'Archipelago',colossus:'Colossus'};
const ENC_ROUNDS=6;
function process_env(k){ try{ return typeof process!=='undefined'&&process.env?process.env[k]:undefined; }catch(e){ return undefined; } }
// mid-battle events: at most one per fight, always announced a round ahead
const BEVENTS={
  reinf_enemy:{n:'Enemy reinforcements',warn:'Long-range scan: enemy reinforcements will drop out of warp at the start of round {r}, on their side of the field.',go:'Enemy reinforcements drop out of warp.'},
  reinf_ally:{n:'Friendly reinforcements',warn:'Fleet command: a friendly ship will join you at the start of round {r}, on your side of the field.',go:'A friendly ship drops out of warp to help. It returns to its own patrol after the battle.'},
  flare:{n:'Solar flare',warn:'The star is flaring. At the start of round {r} every ship on both sides loses its shields for that round.',go:'Solar flare! Every shield on the field is down this round.'}};
function rollBattleEvent(cfg,force){ if(!cfg||cfg.kind==='boss') return null; if(!force&&rnd()>.45) return null; return {k:force&&BEVENTS[force]?force:pick(Object.keys(BEVENTS)),warnR:2,r:ri(3,4)}; }
function edgeHex(side){ const bb=boardBounds(), mr=Math.floor((bb.r0+bb.r1)/2), occ=occMap(), c=side==='player'?bb.c0+1:bb.c1-1; let best=null,bd=1e9;
  for(const h of boardHexes()){ const hc=h.q+Math.floor(h.r/2); if(Math.abs(hc-c)>1||blocks(terr(h.q,h.r))||occ.has(hkey(h.q,h.r))) continue; const d=Math.abs(h.r-mr)+Math.abs(hc-c)*.5; if(d<bd){bd=d;best=h;} } return best; }
function cheapHull(fac){ const F=FACTIONS[fac]||FACTIONS.voidsworn; return F.roster.filter(id=>HULLS[id]&&!HULLS[id].boss&&HULLS[id].ab!=='launch').sort((a,b)=>(HULLS[a].cp||1)-(HULLS[b].cp||1)||HULLS[a].hp-HULLS[b].hp)[0]||F.roster[0]; }
function eventTick(){ const e=B.event; if(!e||e.done||B.over) return; const E=BEVENTS[e.k];
  if(B.round>=e.warnR&&!e.warned){ e.warned=true; const m=E.warn.replace('{r}',e.r); log(m,'x'); try{ if(typeof toast==='function') toast(m); }catch(x){} }
  if(B.round<e.r) return; e.done=true;
  if(e.k==='reinf_enemy'||e.k==='reinf_ally'){ const side=e.k==='reinf_enemy'?'enemy':'player', h=edgeHex(side); if(!h){ log('The reinforcements could not find a clear lane and turn back.','x'); return; }
    const fac=side==='enemy'?B.cfg.fac:((typeof RUN!=='undefined'&&RUN&&RUN.fac)||'voidsworn'), s=B.sector||1, u=makeUnit(side,cheapHull(fac),{scale:side==='enemy'?1+.12*(s-1):1,dmg:side==='enemy'?1+.08*(s-1):1,fac});
    u.q=h.q; u.r=h.r; u.facing=side==='player'?0:3; u.reinf=true; if(side==='player') u.name='Garrison '+u.name; B.units.push(u); if(B.cp0) B.cp0[side]+=(u.t.cp||1); }
  log(E.go,e.k==='reinf_ally'?'p':'e'); try{ if(typeof toast==='function') toast(E.go); }catch(x){} }
// v47: every sector is one region of space, and the fleet travels through it column by column (outer edge first, the boss at its heart),
// so back-to-back fights share a setting while still changing scenery and engagement
const REGIONS={frontier:{n:'Asteroid frontier',route:['belt','belt','graveyard','station']},nebula:{n:'Ion nebula',route:['storm','storm','belt','storm']},
  world:{n:'Contested world',route:['belt','station','planet','planet']},boneyard:{n:'Old battlefield',route:['graveyard','belt','graveyard','station']},
  deep:{n:'Deep void',route:['graveyard','storm','storm','planet']}};
const FAC_REGION={hegemony:['world','frontier'],corsair:['frontier','boneyard'],chorus:['nebula','world'],ithar:['nebula','deep'],deathless:['boneyard','deep'],voidsworn:['world','boneyard']};
function pickRegion(fac){ const used=(typeof RUN!=='undefined'&&RUN&&RUN.regionsUsed)||[], pool=(FAC_REGION[fac]||Object.keys(REGIONS)).filter(k=>!used.includes(k)); const r=pick(pool.length?pool:(FAC_REGION[fac]||['frontier'])); if(typeof RUN!=='undefined'&&RUN) RUN.regionsUsed=used.concat(r); return r; }
function regionMap(reg,c,COLS){ const R=REGIONS[reg]; if(!R) return null; return R.route[Math.min(R.route.length-1,Math.floor(c/(COLS||7)*R.route.length))]; }
// v47 biomes: what the rocks are made of and which world hangs over the field, fixed for a whole sector so it reads as one place
const ROCK_KINDS={stone:{n:'stony asteroids',col:[1,1,1],spec:.08},ice:{n:'ice asteroids',col:[.78,.92,1.18],spec:.55,em:[.02,.05,.08]},iron:{n:'iron-nickel asteroids',col:[.62,.58,.56],spec:.7},
  carbon:{n:'carbon-black asteroids',col:[.36,.34,.33],spec:.04},crystal:{n:'crystal shards',col:[.82,1,.95],spec:.45,em:[0,.1,.08]}};
const REGION_BIOME={frontier:{rock:['stone','iron'],planet:[4,5,0],station:['rig','rig','ring']},nebula:{rock:['ice','crystal'],planet:[2,6,7],station:['ring','spire']},world:{rock:['stone','ice'],planet:[3,4,1],station:['ring','ring','rig']},boneyard:{rock:['carbon','iron'],planet:[5,0,6],station:['spire','spire','rig']},deep:{rock:['carbon','ice'],planet:[6,7,2],station:['spire','ring']}};
function rollBiome(region){ const R=REGION_BIOME[region]||{rock:Object.keys(ROCK_KINDS),planet:[0,1,2,3,4,5,6,7],station:['ring','rig','spire']}; return {rock:pick(R.rock),planet:pick(R.planet),station:pick(R.station)}; }
// fights fit their place: a station defence happens at a station; a dead star only appears out in the dark (storm and graveyard fields)
const DEEP_MAPS=['storm','graveyard'];
function fitEncounter(n){ if(!n||!n.enc) return; if(n.enc==='defend') n.map='station';
  if(n.shape==='deadstar'&&n.map&&!DEEP_MAPS.includes(n.map)){ const sh=ENCOUNTERS[n.enc].shapes.filter(x=>x!=='deadstar'); n.shape=pick(sh.length?sh:['open']); } }
// which arenas suit each objective: line battles on the strip, a relay fought over from every side on round fields, decapitations at an angle
const ENC_ARENA={rout:[['strip',.3],['square',.35],['round',.35]],hold:[['round',.6],['square',.4]],flagship:[['square',.45],['round',.35],['strip',.2]]};
const FAC_MAP={hegemony:['station'],corsair:['belt','graveyard'],chorus:['storm','planet'],ithar:['storm'],deathless:['graveyard'],voidsworn:['planet','station']};
const ENCOUNTERS={
  rout:{n:'Engagement',d:'Break their fleet. It flees once it has lost about two thirds of its strength.',shapes:['open','lanes','ring','dense','deadstar','rift','shoals','hourglass','archipelago','archipelago','colossus']},
  ambush:{n:'Ambush',d:'Two enemy groups close in from both sides. Break their fleet.',shapes:['open','ring','dense','deadstar','shoals','archipelago','colossus']},
  defend:{n:'Hold the station',d:'Keep enemy ships off the friendly station until round 6 ends. Every enemy ship within 2 hexes of it at the start of a round knocks out 1 integrity. Its batteries fire on enemies that come close.',shapes:['open','lanes','dense','corridor','archipelago']},
  hunt:{n:'Hunt',d:'Their flagship is running and jumps out at the end of round 6. Destroy it before then.',shapes:['open','corridor','lanes','ring','dense','deadstar','rift','shoals','hourglass','archipelago','colossus']},
  intercept:{n:'Intercept',d:'Enemy transports are crossing to the far side (red hexes). Destroy them before they get through.',shapes:['open','ring','dense','deadstar','shoals','archipelago']},
  break:{n:'Breakthrough',d:'Get ships off the far edge: a ship that ends its move on a green hex jumps clear. Their fleet blocks the way ahead and more close in from behind.',shapes:['open','lanes','corridor','dense','rift','shoals','archipelago','colossus']},
  hold:{n:'Relay',d:'Have a ship next to the relay, with no enemy there, at the start of 3 rounds.',shapes:['open','corridor','dense','rift','shoals','hourglass','archipelago','colossus']},
  flagship:{n:'Decapitation',d:'Destroy their flagship and the rest of their fleet scatters.',shapes:['open','corridor','lanes','ring','dense','deadstar','rift','shoals','hourglass','archipelago','colossus']}};
const ENC_POOL=['rout','ambush','defend','hunt','intercept','break','hold','flagship']; const ENC_SPECIAL=['defend','hunt','intercept','break','ambush','hold','flagship']; // v41: Relay and Decapitation can roll again
// v41: sector flagships no longer always fight a plain Engagement: sometimes they spring an ambush, sometimes the fight is decided by their death alone
function bossEncounter(){ const enc=pick(['rout','rout','ambush','flagship']); const sh=['ring','open','hourglass'].filter(s=>ENCOUNTERS[enc].shapes.includes(s)); return {enc,shape:pick(sh.length?sh:['open'])}; }
function rollEncounter(kind,col){ if(kind==='boss') return bossEncounter(); const enc=col===0?'rout':pick(ENC_POOL); return {enc,shape:pick(ENCOUNTERS[enc].shapes)}; }
function terrainConnected(T){
  const ok=h=>onBoard(h.q,h.r)&&!BLOCKING[T[hkey(h.q,h.r)]], all=boardHexes(), col=h=>h.q+Math.floor(h.r/2), bb=boardBounds();
  const reach=(from,goal)=>{ const seen=new Set(from.map(h=>hkey(h.q,h.r))), q=from.slice(); while(q.length){ const h=q.pop(); if(goal(h)) return true; for(const d of DIRS){ const n={q:h.q+d[0],r:h.r+d[1]}, k=hkey(n.q,n.r); if(!seen.has(k)&&ok(n)){ seen.add(k); q.push(n); } } } return false; };
  const lr=reach(all.filter(h=>col(h)===bb.c0+2&&ok(h)),h=>col(h)===bb.c1-2);
  const band=all.filter(h=>col(h)>=10+CX&&col(h)<=16+CX&&ok(h)), r0=Math.min(...band.map(h=>h.r)), r1=Math.max(...band.map(h=>h.r));
  const tb=band.length>0&&reach(band.filter(h=>h.r<=r0+1),h=>h.r>=r1-1&&col(h)>=8+CX&&col(h)<=18+CX);
  return lr&&tb; }
function blocks(t){ return !!BLOCKING[t]; }
const HEX_S=10, HEX_W=HEX_S*Math.sqrt(3); // hex size in world units (scene3d's HS/HW), kept here so headless sims can measure
function hexXZ(h){ return {x:HEX_W*(h.q+h.r/2), z:-1.5*HEX_S*h.r}; }
function planetEdge(R){ return R*1.5*HEX_S+HEX_S*.5; } // world radius of the near planet's rim at ship height
const CREW_MULT={voidsworn:1.2,hegemony:1,corsair:1.25,chorus:1.1,ithar:.8,deathless:1};
const BOARD_MULT={voidsworn:1.2,hegemony:1,corsair:1.45,chorus:1.35,ithar:.85,deathless:1.1};
const RAM_FAC={voidsworn:1,corsair:1,chorus:1};
function offToAx(c,r){ return {q:c-Math.floor(r/2), r}; }
let CUT=null; // hexes cut away by the board shape (corridor, close quarters)
let SOLID=null; // cut hexes filled by a set piece (giant asteroid, wreck, moon): they block line of sight as well as movement
function onBoard(q,r){ if(r<0||r>=BH) return false; const c=q+Math.floor(r/2); return c>=0&&c<BW&&!(CUT&&CUT.has(q+','+r)); }
function boardHexes(){ const o=[]; for(let r=0;r<BH;r++) for(let c=0;c<BW;c++){ const h=offToAx(c,r); if(onBoard(h.q,h.r)) o.push(h); } return o; }
function boardBounds(){ let c0=99,c1=-1,r0=99,r1=-1; for(const h of boardHexes()){ const c=h.q+Math.floor(h.r/2); c0=Math.min(c0,c); c1=Math.max(c1,c); r0=Math.min(r0,h.r); r1=Math.max(r1,h.r); } return {c0,c1,r0,r1}; }
const alive = side => B.units.filter(u=>!u.dead && (!side || u.side===side));
const caps = side => alive(side).filter(u=>!u.isSq);
function unitAt(q,r){ return B.units.find(u=>!u.dead && u.q===q && u.r===r) || null; }
function occMap(){ const m=new Map(); for(const u of B.units) if(!u.dead) m.set(hkey(u.q,u.r),u); return m; }
const terr = (q,r) => B.terrain[hkey(q,r)];

function makeUnit(side, tpl, opts={}){
  const t=HULLS[tpl]; let s;
  if(opts.ship) s=derive(opts.ship);
  else {
    const sc=opts.scale||1;
    s={maxHp:Math.round(t.hp*sc*(opts.elite?1.1:1)), shMax:Math.round(t.sh*sc), regen:Math.round(t.rg*sc), armor:t.ar, speed:t.sp, turns:t.tn, ev:t.ev,
      aim:(opts.elite?6:0), crit:opts.elite?5:0, dmg:opts.dmg||1, fx:opts.fx||{}, hangar:t.hangar||0,
      hullRegen:Math.round((t.regen||0)*sc), weapons:nameWeapons(t.fac,t.w.map(([id,arc])=>mkWeapon(id,arc,opts.fx||{})))};
  }
  const u={id:newId(), side, tpl, t, name:opts.ship?opts.ship.name:(opts.name||t.n), cls:t.cls,
    fac: t.fac || opts.fac || 'voidsworn', size:t.size, q:0, r:0, facing: side==='player'?0:3,
    hp:opts.ship?Math.min(opts.ship.hp,s.maxHp):s.maxHp, maxHp:s.maxHp, sh:[s.shMax,s.shMax,s.shMax,s.shMax], shMax:s.shMax, regen:s.regen,
    armor:s.armor, speed:s.speed, turns:s.turns, ev:s.ev, aim:s.aim, crit:s.crit, dmg:s.dmg, fx:s.fx, hangar:s.hangar, hullRegen:s.hullRegen,
    weapons:s.weapons.map(w=>Object.assign(w,{fired:false,cdLeft:0,off:0})),
    ab:t.ab||null, abCd:0, isSq:!!t.sq, sqKind:t.sq||null, boss:!!t.boss, reanimate:!!t.reanimate, reanimated:false,
    ship:opts.ship||null, parent:opts.parent||null, sqPct:opts.sqPct||0,
    mp:0, turnsLeft:0, order:null, braced:false, lockOn:false, focus:false, fullAhead:false, noTurn:false, evBuff:0,
    pflag:!!(opts.ship&&typeof RUN!=='undefined'&&RUN&&RUN.flagUid&&opts.ship.uid===RUN.flagUid), intercepts:0, dealt:0, kills:0, dead:false, st:{fire:0,shieldOff:0,engine:0}, usedLastStand:false, elite:!!opts.elite};
  if(u.isSq && opts.sqHp){ u.maxHp=Math.round(u.maxHp*(1+opts.sqHp)); u.hp=u.maxHp; }
  if(opts.ship && u.hp<=0) u.hp=1;
  if(!u.isSq){ const f=clamp(u.hp/u.maxHp,0,1); u.sec={prow:{max:Math.round(u.maxHp*.3)},mid:{max:Math.round(u.maxHp*.45)},eng:{max:Math.round(u.maxHp*.25)}}; for(const k in u.sec) u.sec[k].hp=Math.round(u.sec[k].max*f);
    u.crewMax=Math.round((12+u.size*40)*(CREW_MULT[u.fac]||1)*(u.boss?1.8:1)); u.crew=u.crewMax; u.speed+=1; }
  return u;
}

// what the enemy sees of your fleet: hull size weighted by damage, plus wings, Marks, refits, captain ranks, relics and boons
function fleetPower(){ if(typeof RUN==='undefined'||!RUN||!RUN.fleet) return 99; let p=0; for(const sh of RUN.fleet){ if(sh.hp<=0) continue; const d=derive(sh), hp=Math.min(1,sh.hp/(d.maxHp||1)), cp=HULLS[sh.tpl].cp||1;
    p+=cp*(.4+.6*hp)*(1+.12*((sh.mk||1)-1)+.03*(sh.mods||[]).length+.04*((sh.cap&&sh.cap.rank)||0))+(d.hangar||0)*.45*(.5+.5*hp); }
  const boons=(RUN.boons||[]).reduce((a,b)=>a+((RARITY[b.r||0]||RARITY[0]).m),0); return p*(1+.035*boons+.025*((RUN.relics||[]).length)); }
function playerStrength(){ return fleetPower(); }
// sector flagship hull/shield scale and damage, by sector (sims can override with BOSS_SCALE / BOSS_DMG)
const BOSS_FAC={corsair:1.45,voidsworn:1.40,hegemony:.95,chorus:1.10,deathless:1,ithar:.80}; // per-flagship tuning from the boss matrix (v40, retuned v45 at n=12)
let BOSS_SCALE=[0,.5,.55,.7], BOSS_DMG=[0,.85,.88,.95];
try{ if(process_env('BOSS_SCALE')) BOSS_SCALE=JSON.parse(process_env('BOSS_SCALE')); if(process_env('BOSS_DMG')) BOSS_DMG=JSON.parse(process_env('BOSS_DMG')); }catch(e){}
function effArch(arch,fac){ if(arch==='carrier'){ const F=FACTIONS[fac]; if(!F||!F.roster.some(id=>HULLS[id]&&HULLS[id].ab==='launch')) return 'heavy'; } return arch||null; }
function genEnemyFleet(fac,s,col,kind,arch,mod){ arch=effArch(arch,fac);
  // each map column has a fixed difficulty, so a fleet that grows can outgrow it (the point of buying that cruiser)
  const F=FACTIONS[fac]; let budget=[0,4.2,9.5,14][s]+col*(s===1?0.9:s===2?1:1.1); if(kind==='elite') budget*=1.05;
  const list=[];
  if(kind==='boss'){ list.push({tpl:F.boss}); budget*=s===1?.28:.33; }
  // a soft floor only: a battered fleet meets up to 25% less, but a strong fleet never meets more
  if(typeof RUN!=='undefined'&&RUN&&RUN.fleet&&!(typeof NO_CAP!=='undefined'&&NO_CAP)){ const target=fleetPower()*(kind==='elite'?1:kind==='boss'?.5:.85)+.3;
    if(target<budget) budget=Math.max(target,budget*.75); }
  if(heatOn('h_hunted')) budget*=1.15;
  if(mod==='bounty') budget*=1.1;
  let roster=F.roster.map(id=>({id,cp:HULLS[id].cp,car:HULLS[id].ab==='launch'}));
  // archetypes reshape the same budget: a swarm of the lightest hulls, a heavy line, or a carrier with its escort
  if(arch==='swarm'){ const mn=Math.min(...roster.map(x=>x.cp)); const light=roster.filter(x=>x.cp<=mn+1&&!x.car); if(light.length) roster=light; }
  if(arch==='heavy'){ const big=roster.filter(x=>x.cp>=2&&(!x.car||!roster.some(y=>y.cp>=3&&!y.car))); if(big.length&&budget>=Math.min(...big.map(x=>x.cp))){ const top=big.filter(x=>x.cp<=budget+.3).sort((a,b)=>b.cp-a.cp)[0]; if(top){ list.push({tpl:top.id}); budget-=top.cp; } roster=big.concat(roster.filter(x=>x.cp<2&&!x.car).slice(0,1)); } }
  if(arch==='carrier'&&kind!=='boss'){ const cr=roster.filter(x=>x.car&&x.cp<=budget+.3).sort((a,b)=>b.cp-a.cp)[0]; if(cr){ list.push({tpl:cr.id}); budget-=cr.cp; roster=roster.filter(x=>!x.car); } }
  let g=0;
  while(budget>=1 && list.length<8 && g++<60){
    const opts=roster.filter(x=>x.cp<=budget+.3); if(!opts.length) break;
    const wts=opts.map(x=> arch==='heavy'?Math.pow(x.cp,1.6):x.cp===1?1.1:Math.min(2,budget/(x.cp*2))+.35);
    let r=rnd()*wts.reduce((a,b)=>a+b,0), ch=opts[0];
    for(let i=0;i<opts.length;i++){ r-=wts[i]; if(r<=0){ch=opts[i];break;} }
    list.push({tpl:ch.id}); budget-=ch.cp;
  }
  return list;
}
let TERRAIN_META={};
function genTerrain(map,shape,opt){
  opt=opt||{}; CUT=null; const VOID={};
  { const cut=new Set(), inner=new Set(), ph=[0,1,2,3,4,5].map(()=>rnd()*6.28), nz=(x,i)=>.5+.5*(Math.sin(x*.55+ph[i])*.62+Math.sin(x*1.37+ph[i+1])*.38);
    // every board gets ragged edges, so no battlefield is a clean rectangle (kept shallow where deployments or objectives need the edge)
    const A=ARENA, round=A.kind==='round', amb=opt.enc==='ambush'||opt.enc==='intercept', eT=round?0:amb?1:2, eS=round||opt.enc==='break'?0:1, deep=shape==='archipelago'&&!round?1:0;
    // v47 arenas: the strip is the classic wide field; the square and the round arena give room to come in from any side
    for(let r=0;r<BH;r++) for(let c=0;c<BW;c++){ const h=offToAx(c,r); let out=r<A.mT||r>=BH-A.mB||c<A.mL||c>=BW-A.mR;
      if(round){ const p=hexXZ(h), cc=hexXZ(offToAx((BW-1)/2,(BH-1)/2)), a=Math.atan2(p.z-cc.z,p.x-cc.x), rad=A.R*HEX_W*(1+.05*Math.sin(a*3+ph[0])+.04*Math.sin(a*7+ph[1])); out=out||Math.hypot((p.x-cc.x)*.94,p.z-cc.z)>rad; }
      if(out) cut.add(hkey(h.q,h.r)); }
    const mid=Math.floor(BW/2), midR=Math.floor(BH/2);
    for(let c=0;c<BW;c++){ let top=Math.min(eT+deep,Math.round(nz(c,0)*(eT+deep)*1.25)), bot=Math.min(eT+deep,Math.round(nz(c,2)*(eT+deep)*1.25));
      if(shape==='hourglass'){ const w=Math.round(4.2*Math.exp(-Math.pow((c-mid)/4.4,2))); top=Math.max(top,w); bot=Math.max(bot,w); }
      for(let r=0;r<BH;r++) if(r<top+A.mT||r>=BH-bot-A.mB) cut.add(hkey(offToAx(c,r).q,offToAx(c,r).r)); }
    for(let r=0;r<BH;r++){ const L=Math.min(eS,Math.round(nz(r,1)*eS*1.3)), R=Math.min(eS,Math.round(nz(r,3)*eS*1.3)); for(let c=0;c<BW;c++) if(c<L+A.mL||c>=BW-R-A.mR) cut.add(hkey(offToAx(c,r).q,offToAx(c,r).r)); }
    if(shape==='corridor'||shape==='compact') for(let r=0;r<BH;r++) for(let c=0;c<BW;c++){ const h=offToAx(c,r); if((shape==='corridor'&&(r<3+A.mT||r>BH-4-A.mB))||(shape==='compact'&&(c<4+CX||c>BW-5-CX||r<2+A.mT||r>BH-3-A.mB))) cut.add(hkey(h.q,h.r)); }
    // a dead star: the middle of the board is a hole in space, with a ragged rim
    if(shape==='deadstar'){ const c0=offToAx(mid+ri(-1,1),midR+ri(-1,1)); VOID.deadstar={q:c0.q,r:c0.r};
      for(let r=0;r<BH;r++) for(let c=0;c<BW;c++){ const h=offToAx(c,r), d=hdist(h,c0); if(d<=2||(d===3&&nz(c*3+r,4)>.62)){ cut.add(hkey(h.q,h.r)); inner.add(hkey(h.q,h.r)); } } }
    // a rift: a jagged chasm splits the field, crossed by two or three bridges
    if(shape==='rift'){ const n=rnd()<.5?2:3, rows=[]; const ok=r=>rows.every(x=>Math.abs(x-r)>=4); for(let k=0;k<40&&rows.length<n;k++){ const r=ri(2,BH-3); if(ok(r)) rows.push(r); }
      const cells=[]; for(let r=0;r<BH;r++){ if(rows.some(x=>Math.abs(x-r)<=1)) continue; const cx=mid-1+Math.round(Math.sin(r*.62+ph[5])*1.6); for(const c of [cx,cx+1]){ const h=offToAx(c,r); cut.add(hkey(h.q,h.r)); cells.push([h.q,h.r]); } }
      VOID.rift=rows; VOID.riftCells=cells; }
    // shoals: a few holes torn out of the middle of the field
    if(shape==='shoals'){ const cs=[]; for(let k=0;k<80&&cs.length<3;k++){ const h=offToAx(ri(9,BW-10),ri(3,BH-4)); if(cs.every(p=>hdist(p,h)>=5)) cs.push(h); }
      for(const c0 of cs){ const R=rnd()<.5?1:2; for(let r=0;r<BH;r++) for(let c=0;c<BW;c++){ const h=offToAx(c,r), d=hdist(h,c0); if(d<=R||(d===R+1&&nz(c*5+r*3,4)>.7)){ cut.add(hkey(h.q,h.r)); inner.add(hkey(h.q,h.r)); } } } }
    // colossus: one huge object sits on the battlefield, splitting it into flanks
    if(shape==='colossus'){ const c0=offToAx(ri(11,BW-12),ri(5,BH-6)); for(let r=0;r<BH;r++) for(let c=0;c<BW;c++){ const h=offToAx(c,r), d=hdist(h,c0); if(d<=2||(d===3&&nz(c*7+r*2,4)>.55)){ cut.add(hkey(h.q,h.r)); inner.add(hkey(h.q,h.r)); } } }
    if(cut.size) CUT=cut;
    // every enclosed hole gets a set piece; the open rift and the board's ragged rim stay empty space
    SOLID=null; if(cut.size){ const seen=new Set(), holes=[], rift=new Set((VOID.riftCells||[]).map(x=>x[0]+','+x[1]));
      for(const k0 of inner){ if(seen.has(k0)) continue; const comp=[], st=[k0]; seen.add(k0);
        while(st.length){ const k=st.pop(); comp.push(k); const [q,r]=k.split(',').map(Number);
          for(const d of DIRS){ const nk=(q+d[0])+','+(r+d[1]); if(inner.has(nk)&&!seen.has(nk)){ seen.add(nk); st.push(nk); } } }
        if(comp.every(k=>rift.has(k))) continue; holes.push(comp); }
      if(holes.length){ SOLID=new Set(); VOID.holes=holes.map(comp=>{ comp.forEach(k=>SOLID.add(k)); const ds=VOID.deadstar&&comp.includes(VOID.deadstar.q+','+VOID.deadstar.r);
          return {cells:comp.map(k=>k.split(',').map(Number)),kind:ds?'deadstar':pick(opt.pieces||['asteroid','asteroid','station','moon','hulk','comet'])}; }); } } }
  const T={}, kinds=['belt','station','planet','storm','graveyard']; const m=kinds.includes(map)?map:pick(kinds); TERRAIN_META={map:m};
  const put=(h,t)=>{ if(onBoard(h.q,h.r)&&!T[hkey(h.q,h.r)]) T[hkey(h.q,h.r)]=t; };
  const blob=(type,n,c0,c1,r0=1,r1=BH-2)=>{ let cur=offToAx(ri(c0,c1),ri(r0,r1)); for(let k=0;k<n;k++){ put(cur,type); const d=pick(DIRS); cur={q:cur.q+d[0],r:cur.r+d[1]}; } };
  const all=boardHexes(), col=h=>h.q+Math.floor(h.r/2), mid=offToAx(Math.floor(BW/2),Math.floor(BH/2));
  const xy=h=>({x:col(h)+(h.r%2?.5:0), y:h.r*.866});
  if(m==='belt'){ const up=rnd()<.5, A={x:BW*.28,y:(up?1:BH-2)*.866}, Bp={x:BW*.72,y:(up?BH-2:1)*.866};
    const dx=Bp.x-A.x, dy=Bp.y-A.y, L2=dx*dx+dy*dy; const gaps=[.22,.55,.85].map(t=>({x:A.x+dx*t,y:A.y+dy*t}));
    for(const h of all){ const p=xy(h); let t=((p.x-A.x)*dx+(p.y-A.y)*dy)/L2; if(t<-.15||t>1.15) continue; const px=A.x+dx*t, py=A.y+dy*t, d=Math.hypot(p.x-px,p.y-py);
      if(gaps.some(g=>Math.hypot(p.x-g.x,p.y-g.y)<1.6)) continue; if(d<1.1&&rnd()<.72) put(h,'rock'); else if(d<2.4&&rnd()<.16) put(h,'rock'); else if(d<3&&rnd()<.12) put(h,'debris'); }
    for(let i=0;i<2;i++) blob('neb',ri(5,9),5,BW-6); }
  if(m==='station'){ const want=opt.stationAt||{q:mid.q+ri(-1,1),r:mid.r+ri(-1,1)};
    /* the station needs solid ground: its centre and ring on the board, and clear of any hole (a dead star, a shoal, a colossus) */
    const okSite=h=>onBoard(h.q,h.r)&&DIRS.every(d=>onBoard(h.q+d[0],h.r+d[1]))&&!(VOID.holes||[]).some(o=>o.cells.some(([q,r])=>hdist(h,{q,r})<=3));
    const c=okSite(want)?want:(all.filter(okSite).sort((a,b)=>hdist(a,want)-hdist(b,want))[0]||all.filter(h=>onBoard(h.q,h.r)&&DIRS.every(d=>onBoard(h.q+d[0],h.r+d[1]))).sort((a,b)=>hdist(a,want)-hdist(b,want))[0]||want); TERRAIN_META.station=c;
    for(const h of all){ const d=hdist(h,c); if(d<=1) T[hkey(h.q,h.r)]='station'; else if(d<=3&&rnd()<.42) put(h,'debris'); }
    for(let i=0;i<3;i++) blob('rock',ri(2,4),5,BW-6); blob('neb',ri(5,8),5,BW-6); }
  if(m==='planet'){ const top=rnd()<.5, c=offToAx(Math.floor(BW/2)+ri(-3,3),top?-5:BH+4), R=8, edge=planetEdge(R), cw=hexXZ(c); TERRAIN_META.planet={q:c.q,r:c.r,R,top};
    /* block by the planet's real outline (a circle), so no ship or asteroid ever sits under its rim */
    const dw=h=>{ const p=hexXZ(h); return Math.hypot(p.x-cw.x,p.z-cw.z); };
    for(const h of all){ const d=dw(h); if(d<=edge+HEX_S*.45) T[hkey(h.q,h.r)]='planet'; else if(d<=edge+HEX_S*3&&rnd()<.22) put(h,'debris'); }
    for(let i=0;i<3;i++) blob('rock',ri(2,4),5,BW-6,top?6:1,top?BH-2:BH-7); blob('neb',ri(4,7),5,BW-6); TERRAIN_META.planetKeep={cw,edge}; }
  if(m==='storm'){ for(let i=0;i<4;i++) blob('storm',ri(8,14),5,BW-6); for(let i=0;i<2;i++) blob('neb',ri(5,8),5,BW-6); for(let i=0;i<2;i++) blob('rock',ri(2,4),6,BW-7); }
  if(m==='graveyard'){ const spots=[]; for(let k=0;k<60&&spots.length<7;k++){ const h=offToAx(ri(6,BW-7),ri(1,BH-2)); if(spots.every(p=>hdist(p,h)>=3)) spots.push(h); }
    for(const h of spots){ T[hkey(h.q,h.r)]='hulk'; for(const d of DIRS) if(rnd()<.55) put({q:h.q+d[0],r:h.r+d[1]},'debris'); }
    TERRAIN_META.wrecks=spots; for(let i=0;i<2;i++) blob('rock',ri(2,4),6,BW-7); blob('neb',ri(4,7),5,BW-6); }
  // the sector's condition adds its own terrain to every battlefield in it (never in the deployment columns)
  { const sc=(opt&&opt.cond)||null; if(sc&&sc.terr){ const n=sc.terr==='storm'?3:sc.terr==='neb'?3:4; for(let i=0;i<n;i++) blob(sc.terr,ri(sc.terr==='debris'?4:6,sc.terr==='debris'?7:11),8,BW-9); } }
  // board shape features on top of the sector terrain
  const force=(h,t)=>{ const k=hkey(h.q,h.r); if(onBoard(h.q,h.r)&&!BLOCKING[T[k]]) T[k]=t; }, midR=Math.floor(BH/2);
  if(shape==='lanes'){ const g1=ri(8,10)+CX, g2=ri(14,16)+CX; for(let c=7;c<=BW-8;c++){ if((c>=g1&&c<=g1+1)||(c>=g2&&c<=g2+1)) continue; force(offToAx(c,midR),'rock'); if(rnd()<.45&&c!==g1-1&&c!==g2-1&&c!==g1+2&&c!==g2+2) force(offToAx(c,midR-1),'rock'); } }
  if(shape==='ring'){ for(const h of all){ if(!onBoard(h.q,h.r)) continue; const d=hdist(h,mid); if(d<=1||(d===2&&rnd()<.55)) force(h,'rock'); else if(d>=3&&d<=4&&rnd()<.16) put(h,'debris'); } }
  if(shape==='dense'){ for(let i=0;i<4;i++) blob('rock',ri(3,5),6,BW-7); for(let i=0;i<3;i++) blob('debris',ri(4,7),5,BW-6); blob('neb',ri(4,7),5,BW-6); }
  // archipelago: tight rock islands with open channels between them
  if(shape==='archipelago'){ const cs=[]; for(let k=0;k<120&&cs.length<6;k++){ const h=offToAx(ri(8,BW-9),ri(2,BH-3)); if(cs.every(p=>hdist(p,h)>=4)) cs.push(h); }
    for(const c0 of cs){ force(c0,'rock'); for(const d of DIRS) if(rnd()<.55) force({q:c0.q+d[0],r:c0.r+d[1]},'rock'); for(const d of DIRS) if(rnd()<.3) put({q:c0.q+2*d[0],r:c0.r+2*d[1]},'debris'); } }
  if(shape==='deadstar'&&VOID.deadstar){ for(const h of all){ const d=hdist(h,VOID.deadstar); if(d>=3&&d<=4&&rnd()<.22) put(h,'debris'); } }
  if(shape==='rift'){ for(const h of all){ if(!onBoard(h.q,h.r)) continue; const edge=DIRS.some(d=>!onBoard(h.q+d[0],h.r+d[1])&&Math.abs(col(h)-Math.floor(BW/2))<=4); if(edge&&rnd()<.2) put(h,'debris'); } }
  // nothing solid hugs the planet's rim: asteroids next to it would look like they sit on top of it
  if(TERRAIN_META.planetKeep){ const {cw,edge}=TERRAIN_META.planetKeep; for(const k of Object.keys(T)){ if(T[k]!=='rock') continue; const [q,r]=k.split(',').map(Number), p=hexXZ({q,r}); if(Math.hypot(p.x-cw.x,p.z-cw.z)<edge+HEX_S*1.8) delete T[k]; } delete TERRAIN_META.planetKeep; }
  Object.assign(TERRAIN_META,VOID);
  TERRAIN_META.shape=shape||'open';
  return T;
}
function deploy(units, side, zoneFn){
  const mode=B.deployMode||'line', midR=Math.floor(BH/2), caps=units.filter(u=>!u.isSq).sort((a,b)=>b.size-a.size);
  let zone, facing=null;
  const A=ARENA, L0=A.mL, R0=BW-A.mR, T0=A.mT, T1=BH-A.mB; // the strip's own edges (the canvas is bigger)
  if(mode==='flank'){ if(side==='player'){ zone=h=>h.c>=L0+3&&h.c<=L0+9&&h.r>=T1-7; facing=5; } else { zone=h=>h.c>=R0-10&&h.c<=R0-4&&h.r<=T0+6; facing=2; } }
  else if(mode==='ambush'){ if(side==='player'){ zone=h=>h.c>=L0+5+CX&&h.c<=L0+9+CX&&Math.abs(h.r-midR)<=3; facing=0; } else zone=h=>h.c>=R0-14-CX&&h.c<=R0-6&&(h.r<=T0+2||h.r>=T1-3); }
  else { if(side==='player'){ zone=h=>h.c>=L0+4&&h.c<=L0+6&&Math.abs(h.r-midR)<=5; facing=0; } else { zone=h=>h.c>=R0-7&&h.c<=R0-5&&Math.abs(h.r-midR)<=5; facing=3; } }
  if(zoneFn) zone=zoneFn;
  const occ=occMap(), free=h=>!blocks(terr(h.q,h.r))&&!occ.has(hkey(h.q,h.r));
  let cand=boardHexes().map(h=>Object.assign(h,{c:h.q+Math.floor(h.r/2)})).filter(h=>zone(h)&&free(h));
  if(cand.length<caps.length+1){ const half=side==='player'?h=>h.c<BW/2-1:h=>h.c>=BW/2+1; cand=boardHexes().map(h=>Object.assign(h,{c:h.q+Math.floor(h.r/2)})).filter(h=>half(h)&&free(h)); } // a board shape left the usual zone too small
  const cq=cand.reduce((a,h)=>a+h.q,0)/cand.length, cr=cand.reduce((a,h)=>a+h.r,0)/cand.length, centre={q:Math.round(cq),r:Math.round(cr)};
  const target=offToAx(Math.floor(BW/2),midR), placed=[];
  for(const u of caps){ let best=null,bs=-1e9;
    for(const h of cand){ if(placed.some(p=>p.q===h.q&&p.r===h.r)) continue; const dmin=placed.length?Math.min(...placed.map(p=>hdist(p,h))):3; const sc=Math.min(dmin,2)*100-hdist(h,centre)*4+rnd(); if(sc>bs){bs=sc;best=h;} }
    if(!best) best=cand[0]; placed.push(best); u.q=best.q; u.r=best.r;
    if(facing!=null) u.facing=facing; else { const x=Math.sqrt(3)*((target.q-u.q)+(target.r-u.r)/2), y=1.5*(target.r-u.r); u.facing=((Math.round(Math.atan2(y,x)*180/Math.PI/60))%6+6)%6; } }
}
const ARENAS={strip:{mT:3,mB:3,mL:1,mR:1},square:{mT:0,mB:0,mL:4,mR:4},round:{mT:0,mB:0,mL:0,mR:0,R:11}};
const AXIS_SHAPES=['corridor','lanes','hourglass','rift','compact'];
// v47: deployment zones placed by angle around the arena's centre, so the front can run any direction
function approachDeploy(){ const ap=B.approach, hs=boardHexes(); if(!hs.length) return; let cx=0,cz=0; for(const h of hs){ const p=hexXZ(h); cx+=p.x; cz+=p.z; } cx/=hs.length; cz/=hs.length;
  let ext=0; for(const h of hs){ const p=hexXZ(h); ext=Math.max(ext,Math.hypot(p.x-cx,p.z-cz)); }
  const dirAt=a=>({x:Math.cos(a),z:Math.sin(a)}), th=ap.th||0, R=ext*(ap.k==='diagonal'?.74:.68);
  const pt=(a,k)=>{ const d=dirAt(a); return {x:cx+d.x*R*(k||1),z:cz+d.z*R*(k||1)}; };
  const occ=()=>occMap(), zoneAt=(P,n)=>{ for(let rad=2.4;rad<9;rad+=.6){ const o=occ(), lim=rad*HEX_W, z=h=>{ const p=hexXZ(h); return Math.hypot(p.x-P.x,p.z-P.z)<=lim; }; if(hs.filter(h=>z(h)&&!blocks(terr(h.q,h.r))&&!o.has(hkey(h.q,h.r))).length>=n+2) return z; } return null; };
  const P=B.units.filter(u=>u.side==='player'), E=B.units.filter(u=>u.side==='enemy'&&!u.transport), nP=P.filter(u=>!u.isSq).length, Ec=E.filter(u=>!u.isSq).sort((a,b)=>b.size-a.size);
  const pP=pt(th+Math.PI); deploy(P,'player',zoneAt(pP,nP)||undefined);
  if(ap.k==='pincer'&&Ec.length>=3){ const g1=Ec.filter((u,i)=>i%2===0), g2=Ec.filter((u,i)=>i%2===1); deploy(g1,'enemy',zoneAt(pt(th+.95,.95),g1.length)||undefined); deploy(g2,'enemy',zoneAt(pt(th-.95,.95),g2.length)||undefined); }
  else if(ap.k==='cross'){ const a=th+Math.PI/2*(rnd()<.5?1:-1); deploy(E,'enemy',zoneAt(pt(a,.95),Ec.length)||undefined); }
  else deploy(E,'enemy',zoneAt(pt(th),Ec.length)||undefined);
  // everyone faces the middle of the fight, not just the board centre
  const cen=(side)=>{ const l=B.units.filter(u=>u.side===side&&!u.isSq); return {q:l.reduce((a,u)=>a+u.q,0)/Math.max(1,l.length),r:l.reduce((a,u)=>a+u.r,0)/Math.max(1,l.length)}; };
  for(const side of ['player','enemy']){ const t=cen(side==='player'?'enemy':'player'); for(const u of B.units.filter(x=>x.side===side&&!x.isSq)){ const x=Math.sqrt(3)*((t.q-u.q)+(t.r-u.r)/2), y=1.5*(t.r-u.r); u.facing=((Math.round(Math.atan2(y,x)*180/Math.PI/60))%6+6)%6; } } }
// v47 gravity well (dead star maps): ships near it get a slingshot (+1 movement); end a turn close and it drags you in; on the rim, tidal stress tears at the hull
const WELL_RIM=3, WELL_PULL=5, WELL_ASSIST=6, WELL_DMG=7;
function wellTick(u){ const W=B&&B.well; if(!W||u.isSq||u.dead) return; const d=hdist(u,W); u.gravAssist=false;
  if(d<=WELL_ASSIST){ u.mp+=1; u.gravAssist=true; }
  if(d<=WELL_RIM){ u.hp-=WELL_DMG; if(typeof fxText==='function') fxText(u,'Tidal stress \u2212'+WELL_DMG,'#c79bff'); if(u.hp<=0){ u.hp=0; log(`${u.name} is torn apart by the dead star's gravity.`, u.side==='player'?'e':'p'); Promise.resolve(killUnit(u,null)).catch(e=>console.error(e)); return 'dead'; } }
  else if(d<=WELL_PULL){ const occ=occMap(); let best=null; for(const dd of DIRS){ const n={q:u.q+dd[0],r:u.r+dd[1]}; if(hdist(n,W)!==d-1||!onBoard(n.q,n.r)||blocks(terr(n.q,n.r))||occ.has(hkey(n.q,n.r))) continue; best=n; break; }
    if(best){ const from={q:u.q,r:u.r}; u.q=best.q; u.r=best.r; if(typeof fxGravPull==='function') fxGravPull(u,from); if(typeof fxText==='function') fxText(u,'Dragged by gravity','#c79bff'); } } }
function aiWellScore(u,v){ const W=B&&B.well; if(!W||u.isSq) return 0; const d=hdist(v,W); return d<=WELL_RIM?-45:d<=WELL_PULL?-6:0; }
function B0small(cfg){ if(typeof process!=='undefined'&&process.env&&process.env.NOCOMPACT) return false; return cfg.kind!=='boss'&&!!(RUN&&RUN.fleet)&&RUN.fleet.filter(x=>x.hp>0).length<=2; }
// no fleet starts boxed in: clear rocks and wrecks around each ship and along a lane toward the enemy
function clearSpawns(){ if(process_env('NOCLEAR')==='1') return; const T=B.terrain; let n=0; const clr=(q,r)=>{ const k=hkey(q,r), t=T[k]; if(t==='rock'||t==='hulk'){ delete T[k]; n++; } };
  const near=(h,R)=>{ for(let dq=-R;dq<=R;dq++) for(let dr=Math.max(-R,-dq-R);dr<=Math.min(R,-dq+R);dr++) clr(h.q+dq,h.r+dr); };
  for(const side of ['player','enemy']){ const mine=B.units.filter(u=>u.side===side&&!u.isSq&&!u.transport), foes=B.units.filter(u=>u.side!==side&&!u.isSq); if(!mine.length||!foes.length) continue;
    const cq=foes.reduce((a,u)=>a+u.q,0)/foes.length, cr=foes.reduce((a,u)=>a+u.r,0)/foes.length, tgt={q:Math.round(cq),r:Math.round(cr)};
    for(const u of mine){ near(u,side==='player'?2:1); const line=hexLine(u,tgt), L=Math.min(line.length-1,side==='player'?6:4); for(let i=1;i<=L;i++) near(line[i],i<=3&&side==='player'?1:0); } }
  if(B.map&&B.map.wrecks) B.map.wrecks=B.map.wrecks.filter(h=>T[hkey(h.q,h.r)]==='hulk'); B.spawnCleared=n; }
function startBattle(cfg){
  const seed=cfg.seed!=null?(cfg.seed>>>0):Math.floor(rnd()*4294967296); rndSeed(seed);
  const enc=ENCOUNTERS[cfg.obj]?cfg.obj:'rout', midR=Math.floor(BH/2);
  let shape=SHAPES[cfg.shape]?cfg.shape:'open', map=enc==='defend'?'station':cfg.map;
  if(shape==='open'&&B0small(cfg)&&['rout','hunt','ambush'].includes(enc)) shape='compact'; // small fleets fight in close quarters
  if(!['belt','station','planet','storm','graveyard'].includes(map)&&FAC_MAP[cfg.fac]&&rnd()<.55) map=pick(FAC_MAP[cfg.fac]); // each faction has home ground
  if((shape==='lanes'||shape==='ring')&&map==='belt') map=pick(['station','planet','storm','graveyard']);
  // v47 arenas and approaches: only the strip has a fixed left-to-right axis; squares and round fields bring the fleets in at an angle, crossing or in a pincer
  const axisFree=['rout','hold','flagship'].includes(enc)&&cfg.kind!=='boss'&&shape!=='compact'&&!(cfg.dep==='ambush');
  const wpick=l=>{ let x=rnd()*l.reduce((a,e)=>a+e[1],0); for(const [k,w] of l){ x-=w; if(x<=0) return k; } return l[0][0]; };
  const ak=ARENAS[cfg.arena]?cfg.arena:(axisFree&&ENC_ARENA[enc]?wpick(ENC_ARENA[enc]):'strip'); ARENA=Object.assign({kind:ak},ARENAS[ak]);
  if(shape==='deadstar'&&['belt','station','planet'].includes(map)&&!cfg.keepShape){ const sh=(ENCOUNTERS[enc]||ENCOUNTERS.rout).shapes.filter(x=>x!=='deadstar'); shape=pick(sh.length?sh:['open']); }
  if(ak!=='strip'&&AXIS_SHAPES.includes(shape)) shape=pick(['open','dense','deadstar','shoals','archipelago','colossus','ring']);
  let approach=null; if(ak==='square') approach={k:rnd()<.6?'diagonal':'cross'}; else if(ak==='round') approach={k:rnd()<.4?'headon':rnd()<.5?'cross':'pincer'};
  if(approach){ approach.th=ak==='square'?(approach.k==='diagonal'?(rnd()<.5?1:-1)*(Math.PI/4+(rnd()-.5)*.35):(rnd()<.5?0:Math.PI/2)*(rnd()<.5?1:-1)):rnd()*Math.PI*2; if(cfg.approach) approach.k=cfg.approach; }
  const topt={cond:cfg.kind==='boss'?null:sectorCond(),stationAt:enc==='defend'?offToAx(9+CX,midR):null,enc,pieces:{belt:['asteroid','asteroid','comet','station'],graveyard:['hulk','hulk','station','asteroid'],planet:['moon','moon','asteroid','station'],station:['station','station','hulk','asteroid'],storm:['comet','asteroid','asteroid','moon']}[map]||null};
  let T=null; for(let k=0;k<6;k++){ T=genTerrain(map,shape,topt); if(terrainConnected(T)) break; T=null; }
  if(!T){ shape='open'; T=genTerrain(map,'open',topt); }
  if(cfg.kind==='boss') for(const k of Object.keys(T)) if(T[k]==='rock'&&rnd()<.45) delete T[k]; // flagship duels need firing lanes, not a maze
  B={seed, units:[], terrain:T, map:TERRAIN_META, shape, enc, arena:ARENA.kind, biome:cfg.biome||(RUN&&RUN.map&&RUN.map.biome)||rollBiome(null), approach, well:shape==='deadstar'&&TERRAIN_META.deadstar?{q:TERRAIN_META.deadstar.q,r:TERRAIN_META.deadstar.r}:null, deployMode:enc==='ambush'?'ambush':['defend','hunt','intercept','break'].includes(enc)?'line':(cfg.dep||'line'), resolve:{player:1,enemy:1}, round:1, side:'player', sel:null, armed:null, mode:null, hover:null, reach:null,
     busy:false, log:[], fx:[], cfg, over:false, reviveUsed:false, inspect:null, showArcs:true, sector:RUN.sector}; { const sc=sectorCond(); B.cond=sc&&RUN&&RUN.map?RUN.map.cond:null; B.condRegen=(sc&&sc.regen)||1; }
  const s=RUN.sector;
  for(const ship of RUN.fleet){ if(ship.hp<=0) continue; B.units.push(makeUnit('player', ship.tpl, {ship})); }
  const eList = cfg.enemies || genEnemyFleet(cfg.fac, s, cfg.col, cfg.kind, cfg.arch, cfg.mod);
  const sc=1+.12*(s-1), dm=1+.08*(s-1);
  const bossFit=Math.max(.55,Math.min(1,playerStrength()/([0,6,9,12][s]||12))); // a battered fleet faces a weakened flagship
  const eliteIdx=cfg.kind==='elite'?new Set(eList.map((e,i)=>[i,HULLS[e.tpl].cp||1]).sort((x,y)=>y[1]-x[1]).slice(0,Math.ceil(eList.length/2)).map(x=>x[0])):null; // elite fights: the bigger half of their fleet are elites
  eList.forEach((e,ei)=>B.units.push(makeUnit('enemy', e.tpl, {scale:sc*(HULLS[e.tpl].boss?BOSS_SCALE[s]*bossFit*(BOSS_FAC[cfg.fac]||1)*(heatOn('h_flag')?1.2:1):1), dmg:dm*(HULLS[e.tpl].boss?BOSS_DMG[s]:1), elite:!!(eliteIdx&&eliteIdx.has(ei))||cfg.kind==='boss'&&!HULLS[e.tpl].boss&&rnd()<.3||heatOn('h_elite')&&ei===(HULLS[eList[0].tpl].boss&&eList.length>1?1:0)||cfg.mod==='veteran'&&ei===eList.map((x,i)=>[i,HULLS[x.tpl].cp||1]).sort((x,y)=>y[1]-x[1])[0][0], fac:cfg.fac})));
  if(heatOn('h_undying')) for(const u of B.units) if(u.side==='enemy'&&!u.isSq&&!u.t.boss) u.reanimate=true;
  // enemies adapt to carrier-heavy fleets: escorts bolt on point defense
  { const nCar0=RUN.fleet.filter(sh=>sh.hp>0&&HULLS[sh.tpl]&&HULLS[sh.tpl].hangar).length, carDoc=(ADMIRALS[RUN.admiral]&&ADMIRALS[RUN.admiral].cmd&&ADMIRALS[RUN.admiral].cmd.id==='scramble')||RUN.aspect==='hive';
    const nCar=nCar0+(carDoc&&nCar0>=1?1:0); /* a carrier admiral or a hive flagship counts as a second carrier: one hull with doctrine still draws a response */
    if(nCar>=2&&(!cfg.enemies||process_env('ADAPT')==='1')&&process_env('NOADAPT')!=='1'){ const pd=cfg.fac==='chorus'?'spores':'flak', cand=B.units.filter(u=>u.side==='enemy'&&!u.t.boss&&!u.isSq&&!u.weapons.some(w=>w.k==='flak')).sort((x,y)=>(y.t.cp||1)-(x.t.cp||1));
      const n=Math.min(cand.length,nCar>=3?cand.length:Math.ceil(cand.length/2)); for(const u of cand.slice(0,n)){ u.weapons.push(mkWeapon(pd,'T',u.fx||{})); u.pdRefit=true; }
      if(n){ B.adapt=n; } if(FACTIONS[cfg.fac]&&FACTIONS[cfg.fac].sq) B.adaptWings=nCar>=3?2:1; } }
  if(enc==='intercept'){ const nT=eList.length>=3?3:2, ros=FACTIONS[cfg.fac].roster.filter(id=>HULLS[id]&&!HULLS[id].boss&&HULLS[id].ab!=='launch').sort((a,b)=>(HULLS[a].cp||1)-(HULLS[b].cp||1)||HULLS[a].hp-HULLS[b].hp);
    for(let i=0;i<nT;i++){ const u=makeUnit('enemy',ros[0]||FACTIONS[cfg.fac].roster[0],{scale:sc*1.3,dmg:dm,fac:cfg.fac}); u.transport=true; u.weapons=[]; u.ab=null; u.speed=Math.min(u.speed,3); u.maxHp=u.hp=Math.round(u.maxHp*1.5); u.name=`Transport ${['Aurum','Bastion','Cinder'][i]}`; B.units.push(u); } }
  if(enc==='break'){ const bb0=boardBounds(), mr=Math.floor((bb0.r0+bb0.r1)/2); deploy(B.units.filter(u=>u.side==='player'),'player',h=>h.c>=8+CX&&h.c<=10+CX&&Math.abs(h.r-mr)<=4);
    const es=B.units.filter(u=>u.side==='enemy'&&!u.isSq).sort((a,b)=>b.size-a.size), back=es.filter((u,i)=>i%3===2);
    deploy(es.filter(u=>!back.includes(u)),'enemy',h=>h.c>=16+CX&&h.c<=20+CX&&Math.abs(h.r-mr)<=6); if(back.length) deploy(back,'enemy',h=>h.c>=bb0.c0&&h.c<=bb0.c0+3&&Math.abs(h.r-mr)<=5); }
  else if(enc==='hunt'){ const bb0=boardBounds(), mr=Math.floor((bb0.r0+bb0.r1)/2), es=B.units.filter(u=>u.side==='enemy'&&!u.isSq&&!u.transport).sort((a,c)=>(c.t.cp||1)-(a.t.cp||1)||c.maxHp-a.maxHp);
    deploy(B.units.filter(u=>u.side==='player'),'player',h=>h.c>=5+CX&&h.c<=8+CX&&Math.abs(h.r-mr)<=5); deploy(es.slice(0,1),'enemy',h=>h.c>=12+CX&&h.c<=14+CX&&Math.abs(h.r-mr)<=3); if(es.length>1) deploy(es.slice(1),'enemy'); } // caught in the open, short of its escorts
  else if(B.approach) approachDeploy();
  else { deploy(B.units.filter(u=>u.side==='player'),'player');
  if(cfg.kind==='boss'&&B.deployMode==='line'){ deploy(B.units.filter(u=>u.side==='enemy'&&u.t.boss),'enemy',h=>h.c>=BW-ARENA.mR-10&&h.c<=BW-ARENA.mR-8&&Math.abs(h.r-midR)<=5); deploy(B.units.filter(u=>u.side==='enemy'&&!u.transport&&!u.t.boss),'enemy'); } // the flagship meets you mid-board; its escorts start further back
  else deploy(B.units.filter(u=>u.side==='enemy'&&!u.transport),'enemy'); }
  if(enc==='intercept'){ const bb=boardBounds(); deploy(B.units.filter(u=>u.transport),'enemy',h=>h.r<=bb.r0+1&&h.c>=13+CX&&h.c<=18+CX); }
  clearSpawns();
  if(process_env('NOPRELAUNCH')!=='1') deployWings();
  B.cp0={player:sideCP('player'),enemy:sideCP('enemy')};
  B.usage={fire:{},aim:0,ab:{},ord:{},cmd:0,moves:0,cant:{}}; // what the player actually uses, for telemetry
  setupObjective(cfg.obj);
  if(B.adapt||B.adaptWings) log(`Scouts report your carriers. The enemy ${B.adapt?`bolted extra point defense onto ${B.adapt>1?B.adapt+' ships':'one ship'}`:''}${B.adapt&&B.adaptWings?' and ':''}${B.adaptWings?`launched ${B.adaptWings>1?'two fighter wings':'a fighter wing'} to hunt your craft`:''}.`,'ember');
  startSideTurn('player');
  for(const u of alive('enemy')) u.intercepts=u.weapons.some(w=>w.k==='flak')?2:0;
  const F=FACTIONS[cfg.fac];
  log(`Contact: ${F.n}. ${eList.length} ship${eList.length>1?'s':''} on the auspex.`, 's');
  if(B.well) log('A dead star warps this field. Ships that start a turn near it get +1 movement from the slingshot, but it drags close ships inward and tears at any hull on its rim.','ember');
  if(cfg.kind==='elite') log('Elite captains command this fleet.', 'e');
  if(cfg.kind==='boss') log(`${HULLS[F.boss].n} is here. Everything else is escort.`, 'e');
}

function gainResolve(side,n){ if(!B.resolve) B.resolve={player:0,enemy:0}; B.resolve[side]=Math.min(5,(B.resolve[side]||0)+n); }
function escortsBreak(){ if(!B.cfg||B.cfg.kind!=='boss'||B.escortsFled) return; const boss=B.units.find(u=>u.boss&&u.side==='enemy'&&!u.dead); if(!boss||boss.hp>boss.maxHp*.5) return;
  const esc=alive('enemy').filter(u=>u!==boss&&!u.isSq); B.escortsFled=true;
  for(const e of esc){ e.dead=true; e.fled=true; fxWithdraw(e); } boss.regen=0; boss.hullRegen=0; boss.reanimate=false; boss.sh=boss.sh.map(v=>Math.round(v*.5)); boss.burning=true;
  log(`${boss.name} is burning. ${esc.length?'Its escorts break off and flee. ':''}Its shields falter and it can no longer repair itself.`,'s'); }
function startSideTurn(side){
  if(side==='player'&&B.round>1){ eventTick(); objectiveTick(); }
  if(side==='enemy'){ B.aiFocus=null; try{ bossCmdTick(); }catch(e){} }
  escortsBreak();
  gainResolve(side,1); let burned=false;
  for(const u of B.units){
    if(u.dead||u.side!==side) continue;
    u.braced=false; u.pivotUsed=false; u.lockOn=false; u.focus=false; u.fullAhead=false; u.noTurn=false; u.evBuff=0; u.order=null; u.ramBoost=0;
    u.mp=Math.max(1,u.speed-u.st.engine); u.turnsLeft=u.turns;
    for(const w of u.weapons){ w.fired=false; if(w.cdLeft>0) w.cdLeft--; if(w.off>0) w.off--; }
    if(u.abCd>0) u.abCd--;
    if(u.st.shieldOff>0) u.st.shieldOff--; else if(u.shMax>0){ const rg=u.regen*(((typeof B!=='undefined'&&B&&B.condRegen)||1)); for(let i=0;i<4;i++) u.sh[i]=Math.min(u.shMax,u.sh[i]+rg); }
    if(u.hullRegen && u.hp<u.maxHp && !u.pyre) u.hp=Math.min(u.maxHp,u.hp+u.hullRegen);
    if(u.st.acid>0&&!u.isSq){ u.st.acid--; u.hp-=4; fxText(u,'Acid \u22124','#c8e04a',-12); if(u.hp<=0){ u.hp=0; burned=true; log(`${u.name} dissolves.`, u.side==='player'?'e':'p'); Promise.resolve(killUnit(u,null)).catch(e=>console.error(e)); } }
    if(u.st.fire>0){ const fd=u.st.fireDmg||6; u.st.fire--; u.hp-=fd; fxText(u,'Fire \u2212'+fd,'#f08a4b'); if(u.hp<=0){ u.hp=0; burned=true; log(`${u.name} burns out.`, u.side==='player'?'e':'p'); Promise.resolve(killUnit(u,null)).catch(e=>console.error(e)); } if(!u.st.fire) u.st.fireDmg=0; }
    u.hexMoved=0; if(u.fx&&u.fx.stormRegen&&u.shMax>0&&!(u.st.shieldOff>0)){ for(let i=0;i<4;i++) u.sh[i]=Math.min(u.shMax,u.sh[i]+Math.round(u.shMax*u.fx.stormRegen)); }
    u.intercepts = u.weapons.some(w=>w.k==='flak')?2:0;
    u.boarded=false; u.rammed=false; u.emerg=false; u.repel=false;
    if(terr(u.q,u.r)==='storm'&&!u.isSq&&u.shMax>0){ for(let i=0;i<4;i++) u.sh[i]=Math.max(0,u.sh[i]-10); fxText(u,'Ion storm','#9fb8ff',-24); }
    if(u.crewMax&&u.crew<=0){ u.mp=0; u.turnsLeft=0; for(const w of u.weapons) w.fired=true; }
    if(B.well&&wellTick(u)==='dead') burned=true;
  }
  if(B.event&&B.event.k==='flare'&&B.round===B.event.r&&B.event.done) for(const u of B.units){ if(!u.dead&&u.side===side&&u.shMax>0) u.sh=[0,0,0,0]; }
  if(burned) checkEnd(); // a ship that burned out can decide the battle at the turn boundary
}

// ---------- movement ----------
function passable(u,q,r,occ){ if(!onBoard(q,r)) return false; if(blocks(terr(q,r))) return false;
  const o=occ.get(hkey(q,r)); if(o && o.side!==u.side && !u.isSq) return false; return true; }
// v50 thrusters: besides burning forward, a hull can slip into either forward-diagonal hex or back off one hex while
// holding its heading, and can climb over or dive under a rock, wreck or enemy ship it cannot stop on.
// Each faction bends one of these rules (MOVE_RULES in data.js).
const MOVE_BASE={slip:2,rev:2,over:1,evadeAt:3,evade:5,still:10,rake:.1};
function moveRules(u){ return Object.assign({},MOVE_BASE,(u&&!u.isSq&&MOVE_RULES[u.fac])||{}); }
function canEnd(u,q,r,occ){ if(!onBoard(q,r)||blocks(terr(q,r))) return false; const o=occ.get(hkey(q,r)); return !o||o===u; }
function computeReach(u){
  const map=new Map(), states=[];
  const occ=occMap(), R=moveRules(u);
  const sk=s=>s.q+','+s.r+','+s.f+','+s.t;
  const start={q:u.q,r:u.r,f:u.facing,t:0,cost:0,path:[]};
  const seen=new Map([[sk(start),0]]); const queue=[start]; let qi=0;
  const pivotFree=R.pivot&&!u.pivotUsed;
  while(qi<queue.length){
    const s=queue[qi++]; if(seen.get(sk(s))<s.cost) continue; states.push(s);
    if(s.cost>=u.mp) continue;
    const nexts=[];
    if(u.isSq){ for(let f=0;f<6;f++){ const d=DIRS[f]; const nq=s.q+d[0], nr=s.r+d[1];
      if(passable(u,nq,nr,occ)) nexts.push({q:nq,r:nr,f,t:s.t,cost:s.cost+1,path:[...s.path,{q:nq,r:nr,f}]}); } }
    else {
      const opts=[[s.f,1,null],[(s.f+1)%6,R.slip,'slip'],[(s.f+5)%6,R.slip,'slip'],[(s.f+3)%6,R.rev,'rev']];
      for(const [df,c0,kind] of opts){ const d=DIRS[df], nq=s.q+d[0], nr=s.r+d[1]; if(!onBoard(nq,nr)) continue;
        // a heavy hull with too little movement can still spend all of it on one thruster hop
        let c=kind&&s.cost===0?Math.min(c0,u.mp):c0; let over=0; const tt=terr(nq,nr);
        if(blocks(tt)){ if(tt!=='rock'&&tt!=='hulk') continue; over=1; }
        const o=occ.get(hkey(nq,nr)); if(o&&o.side!==u.side) over=over||-1; // climb over terrain, dive under ships
        if(over) c+=R.over;
        if(s.cost+c>u.mp) continue;
        const st={q:nq,r:nr,f:s.f}; if(kind) st[kind]=1; if(kind==='slip') st.side=df===(s.f+1)%6?1:-1; if(over) st.over=over;
        nexts.push({q:nq,r:nr,f:s.f,t:s.t,cost:s.cost+c,path:[...s.path,st],slips:(s.slips||0)+(kind==='slip'?1:0),revs:(s.revs||0)+(kind==='rev'?1:0),overs:(s.overs||0)+(over?1:0)}); }
    }
    if(!u.isSq && !u.noTurn && s.t<u.turnsLeft){
      const tc=pivotFree&&s.t===0?0:1; if(s.cost+tc<=u.mp||tc===0)
      for(const dd of [1,-1]){ const f=(s.f+dd+6)%6; nexts.push({q:s.q,r:s.r,f,t:s.t+1,cost:s.cost+tc,path:[...s.path,{q:s.q,r:s.r,f,rot:true}],slips:s.slips,revs:s.revs,overs:s.overs}); }
    }
    for(const n of nexts){ const k=sk(n); if(seen.has(k)&&seen.get(k)<=n.cost) continue; seen.set(k,n.cost); queue.push(n); }
  }
  const ok=states.filter(s=>seen.get(sk(s))===s.cost&&canEnd(u,s.q,s.r,occ));
  for(const s of ok){ if(s.q===u.q&&s.r===u.r) continue; const k=hkey(s.q,s.r);
    const c=map.get(k); if(!c || s.cost<c.cost || (s.cost===c.cost&&s.t<c.t)) map.set(k,s); }
  return {map, states:ok};
}
// v51 fire on the move: opts.onLate runs about two-thirds of the way through the burn, after the rules have already put the ship
// on its destination hex, so guns open up while the hull is still travelling (the maths is identical to firing after the move)
async function moveUnit(u, state, opts){
  if(!inThisBattle(u)) return; const live=liveFrom(null);
  const path=state.path; let committed=false;
  const commit=()=>{ if(committed) return; committed=true; for(const st of path) if(!st.rot){ u.q=st.q; u.r=st.r; } u.facing=path.at(-1).f;
    u.mp=Math.max(0,u.mp-state.cost); u.turnsLeft-=state.t; if(state.t>0&&moveRules(u).pivot) u.pivotUsed=true; u.moved=true; u.hexMoved=(u.hexMoved||0)+path.filter(p=>!p.rot).length; if(B.usage&&u.side==='player'&&!u.isSq) B.usage.moves++; };
  let lateP=null; const onLate=opts&&opts.onLate?()=>{ if(!live()) return; commit(); try{ lateP=Promise.resolve(opts.onLate()).catch(e=>console.error(e)); }catch(e){ console.error(e); } }:null;
  if(typeof animPath==='function'){ await animPath(u,path,onLate?{onLate}:undefined); if(B) B.prog=(B.prog||0)+1; if(lateP) await lateP; if(!live()) return; if(committed){ objAfterMove(u); return; } } // one continuous burn
  else for(const st of path){
    if(st.rot){ await animRotate(u, st.f); }
    else { await animMove(u, st.q, st.r, st.f); }
    if(B) B.prog=(B.prog||0)+1; // progress for the busy watchdog
    if(!live()) return;
  }
  commit();
  objAfterMove(u);
}
function freePivot(u){ return !!(moveRules(u).pivot&&!u.pivotUsed); }
function canRotate(u){ return !u.dead && !u.isSq && !u.noTurn && u.turnsLeft>0 && (u.mp>0||freePivot(u)) && !u.braced; }
async function rotateUnit(u,dir){ if(!canRotate(u)) return; if(freePivot(u)) u.pivotUsed=true; else u.mp--; u.turnsLeft--; u.moved=true; await animRotate(u,(u.facing+dir+6)%6); }

// ---------- combat math ----------
function sightBlocked(q,r){ return blocks(terr(q,r))||!!(SOLID&&SOLID.has(q+','+r)); }
function los(a,b){ const line=hexLine(a,b); for(let i=1;i<line.length-1;i++){ if(sightBlocked(line[i].q,line[i].r)) return false; } return true; }
function weaponReady(w){ return !w.fired && w.cdLeft===0 && w.off===0; }
function inReach(u,w,t){ const d=hdist(u,t); if(d<1||d>w.r) return false; if(!inArc(u,t,w.arc)) return false; return los(u,t); }
function canFire(u,w,t){ if(u.dead||t.dead||u.side===t.side||u.braced||w.k==='flak') return false; if(!weaponReady(w)) return false; return inReach(u,w,t); }
// v50: a hull that sat still last turn is an easy solution; one that burned hard is not
function motionHit(t){ if(!t||t.isSq||t.hexMoved==null||t.braced) return 0; const R=moveRules(t); if(t.hexMoved===0) return R.still; if(t.hexMoved>=R.evadeAt) return -R.evade; return 0; }
function rakeBonus(u,w){ if(!u||u.isSq||!(w.arc==='P'||w.arc==='S')||(u.hexMoved||0)<2) return 0; return moveRules(u).rake; }
function hitChance(u,w,t){
  const d=hdist(u,t), over=Math.max(0,d-w.opt-(u.fx.longAim||0));
  let c=w.acc+u.aim+(u.lockOn?15:0)-(u.fullAhead?15:0)-over*w.fall-Math.min(45,t.ev+(t.evBuff||0))*(w.evMult||1); // evasion caps at 45
  if(t.isSq && w.k!=='flak' && w.k!=='sq') c-=15;
  if(terr(t.q,t.r)==='neb') c-=15;
  if(terr(t.q,t.r)==='debris') c-=10;
  if(terr(u.q,u.r)==='storm') c-=10;
  if(u.crewMax){ if(u.crew<u.crewMax*.5) c-=10; if(u.crew<u.crewMax*.25) c-=10; }
  if(t.fx&&t.fx.burnEv&&(t.hexMoved||0)>=3) c-=t.fx.burnEv;
  c+=motionHit(t);
  if(u.side==='player'&&!u.isSq&&!(u.sureUsed>0)&&runFx().firstSure) return 95; // the rangefinder relic: every ship's first attack of the battle
  return clamp(Math.round(c),5,95);
}
// a boon firing in battle: a patron-coloured callout with the boon's name, counted for the after-battle recap
function boonFx(u,id,txt,dy){ try{ if(B){ B.boonStats=B.boonStats||{}; B.boonStats[id]=(B.boonStats[id]||0)+1; } const b=BOONS[id], P=b&&(b.p?PATRONS[b.p]:PATRONS[b.duo[0]]); fxText(u,(b?b.n+': ':'')+txt,P?P.col:'#f0b35a',dy==null?-30:dy); }catch(e){} }
function ownerFx(u){ if(!u) return {}; if(u.isSq){ const p=B&&B.units.find(x=>x.id===u.parent); return (p&&p.fx)||{}; } return u.fx||{}; }
// hull damage taken is cut when a ship holds the line next to an ally (Unbroken Line) or sits beside a Bulwark flagship
function guardMul(t){ if(!B||t.isSq) return 1; let m=1; const near=B.units.filter(x=>!x.dead&&x!==t&&x.side===t.side&&!x.isSq&&hdist(x,t)===1); if(!near.length) return 1;
  if(t.fx&&t.fx.lineGuard) m*=1-Math.min(.5,t.fx.lineGuard); const aura=Math.max(0,...near.map(x=>(x.fx&&x.fx.guardAura)||0)); if(aura) m*=1-aura; return m; }
function ionOf(att,w){ const f=ownerFx(att); return (w.ion||1)+(f.ionPlus||0)+(w.k==='lance'?(f.ionLance||0):0); }
function dmgMult(u,w,t,rear){
  let m=u.dmg;
  if(w.arc==='P'||w.arc==='S') m+=u.fx.broadPct||0;
  if(w.k==='lance') m+=u.fx.lancePct||0;
  if(w.k==='torp') m+=u.fx.torpPct||0;
  if(u.isSq) m+=u.sqPct||0;
  if(rear) m+=u.fx.rearPct||0;
  if(t.hp<t.maxHp/2) m+=u.fx.huntPct||0;
  if(u.focus) m+=.3;
  if(u.fx.stillPct&&!u.hexMoved&&(w.arc==='P'||w.arc==='S'||w.k==='battery')) m+=u.fx.stillPct;
  if(u.fx.momPct) m+=Math.min(4,u.hexMoved||0)*u.fx.momPct;
  if(u.fx.prowPct&&w.arc==='F') m+=u.fx.prowPct;
  m+=rakeBonus(u,w);
  let base=w.dmg*m;
  base*= t.isSq ? (w.vsSq||1) : (w.vsCap||1);
  return base;
}
// Expected value used for previews and AI
function expectedVs(u,w,t){
  const quad=shieldQuad(t,u), rear=quad===2;
  const hit=hitChance(u,w,t)/100, per=dmgMult(u,w,t,rear);
  const raw=per*w.shots*hit;
  const pierce=w.pierce||0, ion=ionOf(u,w);
  const shieldable=raw*(1-pierce);
  const absorbed=Math.min(shieldable,(t.sh[quad]||0)/ion);
  let hull=(raw-absorbed)*(1-(rear?t.armor*.5:t.armor));
  if(t.braced) hull*=Math.max(.15,1-.4-(t.fx.bracePlus||0));
  hull*=cmdTaken(t)*guardMul(t);
  return {hit, raw, hull, shield:absorbed*ion, quad, rear};
}
function applyHit(att,w,t,dmg,quad){
  const rear=quad===2, pierce=w.pierce||0, ion=ionOf(att,w), of=ownerFx(att);
  let shieldable=dmg*(1-pierce), through=dmg-shieldable;
  const s=t.sh[quad]||0; const absorbed=Math.min(shieldable,s/ion);
  t.sh[quad]=Math.max(0,s-absorbed*ion); shieldable-=absorbed;
  const arm=Math.max(0,t.armor-(t.shredded||0))*(1-(w.armorPierce||0)); let hull=(through+shieldable)*(1-(rear?arm*.5:arm)); // v48: spines strip armor, gauss ignores half of it
  if(t.braced) hull*=Math.max(.15,1-.4-(t.fx.bracePlus||0));
  hull*=cmdTaken(t)*guardMul(t);
  let crit=false;
  if(hull>0.5 && rnd()*100 < (w.crit||0)+att.crit+(att.lockOn?10:0)+(rear?15:0)+((att.hexMoved||0)>=3?(of.momCrit||0):0)){ hull*=1.5+(of.critMul||0); crit=true; }
  hull=Math.round(hull);
  if(hull>0&&!t.isSq&&!t.dead){ const ch=(of.igniteCh||0)+((w.arc==='P'||w.arc==='S')?(of.broadIgnite||0):0)+(att.isSq?(of.sqIgnite||0):0);
    if(ch>0&&rnd()<ch){ const fd=6+(of.fireDmg||0); if(!(t.st.fire>0)) boonFx(t,att.isSq&&of.sqIgnite?'d_burnswarm':(w.arc==='P'||w.arc==='S')&&of.broadIgnite&&!of.igniteCh?'d_inferno':'e_kindle','ignited',-28); t.st.fire=Math.max(t.st.fire||0,2+(of.fireLong||0)); t.st.fireDmg=Math.max(t.st.fireDmg||6,fd); } }
  if(hull>0&&!t.isSq&&!t.dead){ if(w.ignite){ t.st.fire=Math.max(t.st.fire||0,2); t.st.fireDmg=Math.max(t.st.fireDmg||6,6); } // v48 traits
    if(w.shred) t.shredded=Math.min(.15,(t.shredded||0)+w.shred);
    if(w.acid){ t.st.acid=2; } }
  if(of.pyre&&!t.isSq&&t.hp<t.maxHp/2) t.pyre=true;
  t.hp-=hull; att.dealt+=hull;
  damageSection(t, t._calledSec||SEC_OF_QUAD[quad], hull, att);
  return {shield:Math.round(absorbed*ion), hull, crit};
}
const SEC_OF_QUAD=['prow','mid','eng','mid'], SEC_NAME={prow:'prow',mid:'midships',eng:'engines'};
// v41: Restore mends destroyed sections too, giving back what the break took
function repairSection(t,sec,frac){ const s=t.sec&&t.sec[sec]; if(!s) return false;
  if(!s.broken){ if(s.hp>0) s.hp=Math.min(s.max,s.hp+Math.round(s.max*frac)); return false; }
  s.broken=false; s.hp=Math.max(1,Math.round(s.max*frac));
  if(sec==='prow') t.weapons.forEach(w=>{ if(w.arc==='F'&&w.off>=99) w.off=0; });
  if(sec==='mid'){ t.weapons.forEach(w=>{ if((w.arc==='P'||w.arc==='S')&&w.off>=99) w.off=0; }); if(t.shMax>0&&t.st.shieldOff>=99) t.st.shieldOff=0; }
  if(sec==='eng'){ t.st.engine=0; if(t.secSave){ t.turns=t.secSave.turns; t.ev=t.secSave.ev; t.secSave=null; } }
  return true; }
function damageSection(t,sec,dmg,by){
  if(!t.sec||!t.sec[sec]||dmg<=0) return; const s=t.sec[sec];
  if(t.crewMax) t.crew=Math.max(0,t.crew-Math.round(dmg/t.maxHp*t.crewMax*.35));
  if(s.hp<=0) return; s.hp=Math.max(0,s.hp-dmg); if(s.hp>0||s.broken) return; s.broken=true; if(typeof fxSectionDown==='function') fxSectionDown(t,sec);
  if(sec==='prow') t.weapons.forEach(w=>{ if(w.arc==='F') w.off=999; });
  if(sec==='mid'){ t.weapons.forEach(w=>{ if(w.arc==='P'||w.arc==='S') w.off=999; }); if(t.shMax>0){ t.st.shieldOff=999; t.sh=[0,0,0,0]; } }
  if(sec==='eng'){ t.secSave={turns:t.turns,ev:t.ev}; t.st.engine=Math.max(0,t.speed-1); t.turns=Math.min(t.turns,1); t.ev=0; }
  fxText(t,SEC_NAME[sec][0].toUpperCase()+SEC_NAME[sec].slice(1)+' destroyed','#f0b35a',-36);
  log(`${t.name}: ${SEC_NAME[sec]} destroyed. ${sec==='prow'?'Forward weapons silenced.':sec==='mid'?'Broadsides and shield generator gone.':'Engines crippled.'}`, t.side==='player'?'e':'p');
  if(by&&!by.dead) gainResolve(by.side,1);
}
function systemDamage(t,forced){
  if(t.isSq||t.dead) return null;
  const map={engines:'engine',shields:'shields',weapons:'weapon',eng:'engine',mid:'shields',prow:'weapon'};
  let r=forced&&map[forced]?map[forced]:pick(['engine','shields','weapon','fire']);
  if(r==='shields'&&!(t.shMax>0)) r='fire';
  if(r==='weapon'&&!t.weapons.length) r='fire';
  if(r==='weapon'&&forced){ const live=t.weapons.filter(w=>w.off===0).sort((a,b)=>b.dmg*b.shots-a.dmg*a.shots); if(live.length){ live[0].off=2; return live[0].n+' knocked out'; } }
  if(r==='engine'){ t.st.engine=Math.min(t.speed-1,t.st.engine+1); return 'Engines hit'; }
  if(r==='shields'&&t.shMax>0){ t.st.shieldOff=2; return 'Shield generator down'; }
  if(r==='weapon'){ const w=pick(t.weapons); w.off=2; return w.n+' knocked out'; }
  t.st.fire=2; return 'Fire on deck';
}

async function fireWeapon(u,wi,t,opts={}){ if(!inThisBattle(u)) return false; const live=liveFrom(null);
  const w=u.weapons[wi];
  if(!opts.intercept && !canFire(u,w,t)) return false;
  if(!opts.intercept){ w.fired=true; if(w.cd) w.cdLeft=w.cd; if(u.side==='player'&&!u.isSq) u.sureUsed=(u.sureUsed||0)+1; }
  if(B.usage&&u.side==='player'&&!opts.intercept&&!u.isSq){ const k=(ARC_NAME&&ARC_NAME[w.arc])||String(w.arc); B.usage.fire[k]=(B.usage.fire[k]||0)+1; if(opts.called) B.usage.aim++; }
  // squadrons attacking capital ships run the flak gauntlet first
  if(u.isSq && !t.isSq && !opts.intercept){
    for(const d of alive(t.side)){
      if(d.isSq||d.intercepts<=0||d.braced) continue;
      const fi=d.weapons.findIndex(x=>x.k==='flak'&&x.off===0); if(fi<0) continue;
      if(hdist(d,u)>d.weapons[fi].r) continue;
      d.intercepts--;
      await fireWeapon(d,fi,u,{intercept:true});
      if(u.dead){ return true; }
    }
  }
  const quad=shieldQuad(t,u), shBefore=(t.sh&&t.sh[quad])||0;
  const res={shield:0,hull:0,crits:0,hits:0,misses:0,sys:null};
  const called=opts.called&&!t.isSq&&!opts.intercept?opts.called:null;
  const hc=hitChance(u,w,t);
  const shots=[];
  for(let i=0;i<w.shots;i++) shots.push(rnd()*100<hc);
  if(w.rockets&&!t.isSq){ let shot=0; for(const d of alive(t.side)){ if(d.isSq||d.intercepts<=0||d.braced) continue; const fw=d.weapons.find(x=>x.k==='flak'&&!(x.off>0)); if(!fw||hdist(d,t)>fw.r) continue; // point defense near the target picks off rockets
      for(let i=0;i<shots.length&&d.intercepts>0;i++) if(shots[i]&&rnd()<.55){ shots[i]=false; d.intercepts--; shot++; } }
    if(shot){ res.pd=shot; fxText(t,shot+' rocket'+(shot>1?'s':'')+' shot down','#bfe3ff',30); } }
  await animWeapon(u,w,t,shots);
  if(B) B.prog=(B.prog||0)+1;
  if(!live()) return false; // abandoned after a stall: the shot never lands
  if(called){ u.crit+=15; t._calledSec=called; } // v45: applied only once the shot is known to land, so a stall can never leave it behind
  for(const h of shots){
    if(t.dead) break;
    if(!h){ res.misses++; continue; }
    res.hits++;
    const d=dmgMult(u,w,t,quad===2)*(0.85+rnd()*.3);
    const r=applyHit(u,w,t,d,quad);
    res.shield+=r.shield; res.hull+=r.hull; if(r.crit){ res.crits++; const cs=ownerFx(u).critSys; if(!res.sys && (called||cs||rnd()<.4)){ res.sys=systemDamage(t,called); if(cs&&res.sys) boonFx(t,'a_crit',res.sys,-48); } }
  }
  if(called){ u.crit-=15; t._calledSec=null; }
  if(res.shield>0){ fxShield(t,quad); fxText(t,'\u2212'+res.shield+' shield','#62ccff',-18); if(t.shMax>0&&t.sh[quad]<=.5){ fxShieldBreak(t,quad); fxText(t,'Shields down','#9fe2ff',-40);
      const ar=ownerFx(u).arcShort; if(ar&&shBefore>.5&&!t.dead){ t.hp-=ar; res.hull+=ar; u.dealt+=ar; boonFx(t,'s_arc','\u2212'+ar,-56); } } }
  if(res.hull>0) fxText(t,'\u2212'+res.hull+' hull',res.crits?'#ffd27a':'#ffae42',0);
  if(res.hits===0) fxText(t,'Miss','#9a9384',0);
  if(res.crits) fxText(t,'Critical','#f0b35a',18);
  const who = u.side==='player'?'p':'e';
  const parts=[];
  if(res.pd) parts.push(`${res.pd} shot down by point defense`);
  if(res.hits===0) parts.push('all shots miss');
  else { if(res.shield) parts.push(`${res.shield} to ${QUAD_NAME[quad]} shields`); if(res.hull) parts.push(`${res.hull} hull`); if(!res.shield&&!res.hull) parts.push('no damage'); }
  if(res.crits) parts.push(res.crits>1?`${res.crits} criticals`:'critical');
  log(`${u.name} ${opts.intercept?'intercepts with':'fires'} ${w.n} at ${t.name}: ${parts.join(', ')}.${res.sys?' '+res.sys+'!':''}`, who);
  if(res.hits>0&&t.braced&&!t.dead&&!u.dead&&!opts.intercept&&t.side!==u.side){ const rp=ownerFx(t).riposte; if(rp){ u.hp-=rp; t.dealt=(t.dealt||0)+rp; boonFx(u,'i_brace','\u2212'+rp,-40); if(u.hp<=0) await killUnit(u,t); } } // Iron Discipline: braced ships strike back
  if(t.hp<=0) await killUnit(t,u);
  return true;
}
// a ram: any enemy ship dead ahead of the bow, with at least one clear hex of run-up and movement left to cover the gap
function ramInfo(u){
  if(!u||u.isSq||u.braced||u.dead||u.rammed||(u.crewMax&&u.crew<=0)) return null; const left=Math.min(u.mp,Math.max(1,u.speed-u.st.engine)); if(left<1) return null;
  const d=DIRS[u.facing]; let q=u.q,r=u.r; const path=[];
  for(let i=0;i<=left;i++){ const nq=q+d[0], nr=r+d[1]; if(!onBoard(nq,nr)||blocks(terr(nq,nr))) return null; const o=unitAt(nq,nr);
    if(o&&o.id!==u.id){ return (o.side!==u.side&&!o.isSq&&path.length>=1)?{t:o,path}:null; } path.push({q:nq,r:nr,f:u.facing}); q=nq; r=nr; }
  return null;
}
// could this ship ram from a reachable hex and facing (used to mark ram spots on the move overlay)
function ramFrom(u,st){ if(!st||st.stay) return null; const v=Object.assign({},u,{q:st.q,r:st.r,facing:st.f,mp:u.mp-st.cost}); return ramInfo(v); }
// rams hit hard but can't one-shot a healthy ship: at most 40% of the target's full hull (finishing a damaged ship is still possible),
// the target's facing shield soaks part of it, and the rammer takes more back
function ramEstimate(u,t,run){ const f=u.fx||{}, base=(14+46*u.size)*(RAM_FAC[u.fac]?1.2:1)*(run==null?1:run<=1?.75:run===2?1:1.15), quad=shieldQuad(t,u);
  const raw=base*(1+(f.ramPct||0))*(u.ramBoost||1)*(quad===0?1:1.2)*(1-t.armor*.5), soak=Math.min(raw*.5,(t.sh&&t.sh[quad])||0);
  return {dmg:Math.round(Math.min(raw-soak,t.maxHp*(.4+Math.min(.3,f.ramCap||0)))), soak:Math.round(soak), recoil:Math.round(base*(RAM_FAC[u.fac]?.35:.5)*clamp(t.size/u.size,.5,1.6)*(1-u.armor*.5)*(1-Math.min(1,f.ramGuard||0))), sec:SEC_OF_QUAD[quad]}; }
async function ramUnit(u){
  const info=ramInfo(u); if(!info) return false; const t=info.t, live=liveFrom(u);
  if(typeof animPath==='function') await animPath(u,info.path,{charge:true}); else for(const p of info.path){ await animMove(u,p.q,p.r,p.f); }
  if(!live()) return false; // abandoned after a stall: the ram never lands
  u.mp=0; u.turnsLeft=0; u.rammed=true; if(B.usage&&u.side==='player'){ B.usage.ram=(B.usage.ram||0)+1; for(const id of ['d_jugg','r_prow']) if(hasBoon(id)){ B.boonStats=B.boonStats||{}; B.boonStats[id]=(B.boonStats[id]||0)+1; } } const e=ramEstimate(u,t,info.path.length);
  await fxRam(u,t); if(!live()||t.dead) return false;
  const qd=shieldQuad(t,u); if(e.soak&&t.sh) t.sh[qd]=Math.max(0,t.sh[qd]-e.soak*1.5);
  t.hp-=e.dmg; u.dealt+=e.dmg; damageSection(t,e.sec,e.dmg,u); u.hp-=e.recoil; damageSection(u,'prow',e.recoil,t);
  fxText(t,'\u2212'+e.dmg,'#f0b35a',0); fxText(u,'\u2212'+e.recoil,'#ff7a6e',0);
  log(`${u.name} rams ${t.name} at full speed: ${e.dmg} to its ${SEC_NAME[e.sec]}, ${e.recoil} back to the ram.`, u.side==='player'?'p':'e');
  if(rnd()<.35){ const sy=systemDamage(t,e.sec); if(sy) log(`${t.name}: ${sy}.`, u.side==='player'?'p':'e'); }
  if(u.fx&&u.fx.ramSplash){ const sd=Math.round(e.dmg*u.fx.ramSplash); for(const x of B.units.filter(x=>!x.dead&&x!==t&&x.side===t.side&&hdist(x,t)===1)){ x.hp-=sd; boonFx(x,'r_shock','\u2212'+sd,-10); if(x.hp<=0) await killUnit(x,u); } }
  if(t.hp<=0) await killUnit(t,u); if(u.hp<=0) await killUnit(u,t); checkEnd(); return true;
}
function boardTargets(u){ if(!u||u.isSq||u.braced||u.boarded||u.dead||!u.crewMax||u.crew<Math.max(4,u.crewMax*.4)||u.weapons.some(w=>w.fired)) return [];
  return alive(u.side==='player'?'enemy':'player').filter(t=>!t.isSq&&hdist(u,t)===1); }
// chance that a boarding action captures the target, from the same dice as boardUnit
// one capture model everywhere: boardUnit rolls r in [0.75,1.25); capture when round(crew*mult*r*.38) >= defenders.
// The shown chance is that roll's exact probability, so the number on the button is the real odds.
function captureChance(u,t){ const s=u.crew*(BOARD_MULT[u.fac]||1)*(1+((u.fx&&u.fx.boardPct)||0))*.38; if(s<=0) return 0; const x=(t.crew-.5)/s; return Math.round(100*Math.max(0,Math.min(1,(1.25-x)/.5))); }
// why a selected ship can't shoot a target, in plain words
const _hitBase=hitChance; hitChance=function(u,w,t){ const c=_hitBase(u,w,t); return cmdActive(t.side,'surge')?Math.max(5,c-20):c; };
const _dmgMultBase=dmgMult; dmgMult=function(u,w,t,rear){ let m=_dmgMultBase(u,w,t,rear); if(u.bloodied&&!u.isSq) m*=1+.15*u.bloodied; if(cmdActive(u.side,'hunt')) m*=1+cmdPow('hunt',null,u.side); if(u.isSq&&cmdActive(u.side,'scramble')) m*=1+cmdPow('scramble',null,u.side); if(B&&B.volleyMul&&B.volleyMul.side===u.side) m*=B.volleyMul.m; return m; };
function cantFireReason(s,t){ if(s.braced) return 'This ship is braced, so it holds fire this turn.';
  const ready=s.weapons.filter(w=>weaponReady(w)); if(!ready.length) return 'Every weapon on this ship has already fired this turn.';
  const d=hdist(s,t), maxR=Math.max(...ready.map(w=>w.r)); const inR=ready.filter(w=>d<=w.r);
  if(!inR.length) return `Out of range: ${d} hexes away, your longest ready gun reaches ${maxR}.`;
  const inA=inR.filter(w=>inArc(s,t,w.arc)); if(!inA.length){ const arcs=[...new Set(inR.map(w=>(ARC_NAME&&ARC_NAME[w.arc])||w.arc))].join(' or '); return `In range, but no ready gun points at it. Turn so it sits in your ${arcs} arc.`; }
  if(!los(s,t)) return 'Line of sight is blocked by asteroids or wreckage.';
  return 'None of the ready guns can reach that target right now.'; }
function boardOdds(u,t){ const a=u.crew*(BOARD_MULT[u.fac]||1)*(1+((u.fx&&u.fx.boardPct)||0)), d=t.crew*(BOARD_MULT[t.fac]||1)*(t.repel?2.25:1.5); const p=captureChance(u,t); return {kill:Math.round(a*.38), loss:Math.round(d*.3), chance:p, capture:p>=50}; }
async function boardUnit(u,t){
  if(!boardTargets(u).includes(t)) return false;
  if(B.usage&&u.side==='player') B.usage.board=(B.usage.board||0)+1; u.boarded=true; u.repel=true; u.mp=0; u.weapons.forEach(w=>w.fired=true);
  const live=liveFrom(u); await fxBoard(u,t); if(!live()||t.dead) return false; // abandoned after a stall: the boarders never land
  const a=u.crew*(BOARD_MULT[u.fac]||1)*(1+((u.fx&&u.fx.boardPct)||0))*(.75+rnd()*.5), d=t.crew*(BOARD_MULT[t.fac]||1)*(t.repel?2.25:1.5)*(.75+rnd()*.5);
  const kill=Math.round(a*.38), loss=Math.min(u.crew-1,Math.round(d*.3)); t.crew=Math.max(0,t.crew-kill); u.crew=Math.max(1,u.crew-loss);
  const who=u.side==='player'?'p':'e';
  if(t.crew<=0&&t.side==='player'&&!t.captured){ t.crew=Math.max(2,Math.round(t.crewMax*.15)); const s1=systemDamage(t), s2=systemDamage(t); fxText(t,'Holds the bridge','#f0b35a',-30);
    log(`${u.name}'s boarders overrun ${t.name}, but the last of its crew hold the bridge.${s1?' Saboteurs: '+s1.toLowerCase():''}${s2?', '+s2.toLowerCase():''}.`, 'e'); if(B.usage) B.usage.overrun=(B.usage.overrun||0)+1; return true; } // your ships are never captured: boarders cripple, they don't steal
  if(t.crew<=0){ if(B.usage&&u.side==='player') B.usage.cap=(B.usage.cap||0)+1; const old=t.side; t.side=u.side; t.crew=Math.max(3,Math.round(t.crewMax*.4)); t.captured=true; t.activated=true; t.mp=0; t.turnsLeft=0; t.braced=false; t.weapons.forEach(w=>w.fired=true);
    gainResolve(u.side,2); fxText(t,'Captured','#f0b35a',-30); log(`Boarding parties from ${u.name} take ${t.name}. It now fights for ${u.side==='player'?'you':'the enemy'}.`, who);
    if(typeof onCapture==='function') onCapture(t,old); checkEnd(); return true; }
  fxText(t,'\u2212'+kill+' crew','#f0b35a',-18); fxText(u,'\u2212'+loss+' crew','#ff7a6e',-18);
  let extra=''; if(rnd()<.5||(u.fx&&u.fx.boardPct)){ const sy=systemDamage(t); if(sy) extra=` Saboteurs: ${sy.toLowerCase()}.`; }
  log(`${u.name} boards ${t.name}: ${kill} defenders killed, ${loss} boarders lost.${extra}`, who); return true;
}
async function tacticRam(u){ const info=ramInfo(u); if(!info||info.path.length<2) return false; /* the AI only rams with a real run-up */ const e=ramEstimate(u,info.t,info.path.length), bold=!!RAM_FAC[u.fac];
  if(e.dmg>=info.t.hp || e.dmg>=info.t.hp*(bold?.3:.45)){ await ramUnit(u); return true; } return false; }
async function tacticBoard(u){ let best=null,bv=0; for(const t of boardTargets(u)){ const o=boardOdds(u,t); const v=o.chance>=70?100+t.maxHp/10:0; if(v>bv){bv=v;best=t;} }
  if(best){ await boardUnit(u,best); return true; } return false; }
async function killUnit(t,by){
  if(t.dead) return;
  if(t.fx.lastStand && !t.usedLastStand){ t.usedLastStand=true; t.hp=1; fxText(t,'Last stand','#f0b35a',-30); log(`${t.name} refuses to die! (Last stand)`,'s'); return; }
  if(t.side==='player' && !t.isSq && runFx().revive && !B.reviveUsed){ B.reviveUsed=true; t.hp=Math.round(t.maxHp*.25); fxText(t,'Reawakens','#7dff9b',-30); log(`The phylactery hums. ${t.name} reawakens at 25% hull.`,'s'); return; }
  if(t.reanimate && !t.reanimated && !t.pyre && rnd()<(t.side==='enemy'?.2:.35)){ t.reanimated=true; t.hp=Math.round(t.maxHp*.3); fxText(t,'Reanimating','#7dff9b',-30); log(`${t.name} reassembles itself from the wreckage.`,'e'); return; }
  t.dead=true; t.hp=0;
  if(t.side==='player'&&!t.isSq&&!t.transport){ const av=runFx().avenge; if(av){ for(const x of alive('player')) if(!x.isSq&&x.hp<x.maxHp){ const h=Math.min(x.maxHp-x.hp,Math.round(x.maxHp*av)); x.hp+=h; fxText(x,'+'+h+' hull','#8ff0a0',-20); } log(`The fleet rallies around the loss of ${t.name}.`,'s'); } }
  if(by&&by.side==='player'&&!t.isSq&&runFx().bloodied){ const k=by.isSq?B.units.find(x=>x.id===by.parent):by; if(k&&!k.dead){ k.bloodied=Math.min(3,(k.bloodied||0)+1); fxText(k,'Bloodied +'+Math.round(15*k.bloodied)+'%','#ff9f3a',-36); } }
  if(!t.isSq && t.size>=.7 && !blocks(B.terrain[hkey(t.q,t.r)])){ B.terrain[hkey(t.q,t.r)]='hulk'; t.hulk=true; log(`The wreck of ${t.name} drifts in place, blocking movement and fire.`,'x'); if(typeof refreshBlockTint==='function') setTimeout(()=>refreshBlockTint(),1200); }
  if(by&&!t.isSq) gainResolve(by.side,1);
  if(by){ by.kills++; if(by.parent){ const p=B.units.find(x=>x.id===by.parent); if(p) p.kills+=0; } }
  if(by&&by.isSq){ const p=B.units.find(x=>x.id===by.parent&&!x.dead); if(p&&p.fx&&p.fx.feast){ p.spare=(p.spare||0)+1; const h=Math.round(p.maxHp*p.fx.feast); p.hp=Math.min(p.maxHp,p.hp+h); boonFx(p,'h_feast','+'+h+' hull, +1 wing',-30); } }
  const b0=B, live=liveFrom(null); await animExplode(t); if(!live()){ if(B===b0&&!B.over) try{ checkEnd(); }catch(e){} return; } // v45: epoch check like every other await, so a stalled battle never sees this explosion's aftermath
  { const cb=by&&!t.isSq&&by.side!==t.side?ownerFx(by).chainBoom:0; if(cb){ const near=B.units.filter(x=>!x.dead&&x.side===t.side&&x!==t&&hdist(x,t)<=2); if(near.length) log(`${t.name}'s reactor goes up, scorching ${near.length} nearby ship${near.length>1?'s':''}.`,by.side==='player'?'p':'e');
      for(const x of near){ if(x.dead) continue; x.hp-=cb; boonFx(x,'e_chain','\u2212'+cb,-12); if(x.hp<=0) await killUnit(x,by); } } }
  log(`${t.name} ${t.isSq?'is shot down':'is destroyed'}.`, t.side==='player'?'e':'p');
  checkEnd();
}
function sideCP(side){ return B.units.filter(u=>u.side===side&&!u.isSq&&!u.dead).reduce((a,u)=>a+(u.t.cp||1),0); }
function setupObjective(type){ const o={type:type||'rout',score:0,escore:0};
  if(o.type==='flagship'&&caps('enemy').length<3) o.type=caps('enemy').some(u=>u.t&&u.t.boss)?'rout':'hunt'; // killing the "flagship" of a one- or two-ship fleet is just a rout
  if(o.type==='defend'&&!B.map.station) o.type='hold';
  if(o.type==='hunt'){ const e=alive('enemy').filter(u=>!u.isSq).sort((a,c)=>(c.t.cp||1)-(a.t.cp||1)||c.maxHp-a.maxHp)[0]; if(e){ e.flagship=true; o.rounds=ENC_ROUNDS; } else o.type='rout'; }
  if(o.type==='defend'){ o.hex={q:B.map.station.q,r:B.map.station.r}; o.hp=o.hpMax=5; o.rounds=ENC_ROUNDS; }
  if(o.type==='intercept'){ const tr=B.units.filter(u=>u.transport); o.total=tr.length; o.need=Math.max(1,tr.length-1); o.exitR=boardBounds().r1; o.kill=0; o.esc=0; if(!tr.length) o.type='rout'; }
  if(o.type==='break'){ const n=caps('player').length; o.need=Math.max(1,Math.ceil(n/2)); o.exitC=boardBounds().c1-1; o.out=0; }
  if(o.type==='flagship'){ const e=alive('enemy').filter(u=>!u.isSq).sort((a,c)=>(c.t.cp||1)-(a.t.cp||1)||c.maxHp-a.maxHp)[0]; if(e) e.flagship=true; else o.type='rout'; }
  if(o.type==='hold'){ const c=offToAx(Math.floor(BW/2),Math.floor(BH/2)); let best=null,bd=1e9; for(const h of boardHexes()){ if(blocks(terr(h.q,h.r))||unitAt(h.q,h.r)) continue; const d=hdist(h,c); if(d<bd){bd=d;best=h;} }
    o.hex={q:best.q,r:best.r}; for(const h of boardHexes()) if(hdist(h,o.hex)<=1&&blocks(terr(h.q,h.r))) delete B.terrain[hkey(h.q,h.r)]; }
  B.obj=o; }
function survivorsP(){ return B.units.filter(u=>u.side==='player'&&!u.isSq&&(!u.dead||u.exited)).length; }
function objZone(q,r){ const o=B&&B.obj; if(!o||!onBoard(q,r)) return null; if(o.type==='break'&&q+Math.floor(r/2)>=o.exitC) return 'exit'; if(o.type==='intercept'&&r>=o.exitR) return 'texit'; if(o.type==='defend'&&hdist({q,r},o.hex)===2) return 'guard'; return null; }
function stationFire(){ const o=B.obj; if(!o||o.type!=='defend') return; const src={q:o.hex.q,r:o.hex.r,facing:0};
  const ts=caps('enemy').filter(u=>hdist(u,o.hex)<=5).sort((a,b)=>hdist(a,o.hex)-hdist(b,o.hex)).slice(0,2);
  const att={side:'player',dealt:0,kills:0,crit:0,lockOn:false,fx:{}};
  for(const t of ts){ const r=applyHit(att,{crit:0,pierce:.2},t,12,shieldQuad(t,src)); try{ fxText(t,`Station \u2212${r.hull+r.shield}`,'#7fd6ff',-30); }catch(e){}
    log(`Station batteries hit ${t.name}: ${r.shield} shield, ${r.hull} hull.`,'p'); if(t.hp<=0&&!t.dead){ t.hp=0; Promise.resolve(killUnit(t,null)).catch(e=>console.error(e)); } } }
function objAfterMove(u){ const o=B&&B.obj; if(!o||!u||u.dead||u.isSq) return;
  if(o.type==='break'&&u.side==='player'&&objZone(u.q,u.r)==='exit'){ u.exited=true; u.dead=true; u.fled=true; try{ fxWithdraw(u); }catch(e){} log(`${u.name} breaks through and jumps clear.`,'s'); checkEnd(); }
  else if(o.type==='intercept'&&u.transport&&objZone(u.q,u.r)==='texit'){ u.dead=true; u.fled=true; try{ fxWithdraw(u); }catch(e){} log(`${u.name} gets through.`,'e'); checkEnd(); } }
function aiObjScore(u,v){ const o=B.obj; if(!o||u.isSq) return 0;
  if(u.transport) return -(o.exitR-v.r)*14;
  if(o.type==='hunt'&&u.flagship){ const d=Math.min(30,...caps('player').map(p=>hdist(v,p))); return Math.min(d,9)*3; } // runs, but stops running once well clear
  if(o.type==='defend') return -Math.max(0,hdist(v,o.hex)-2)*3;
  if(o.type==='break'){ const pl=caps('player'); if(!pl.length) return 0; const lead=Math.max(...pl.map(p=>p.q+Math.floor(p.r/2))), c=v.q+Math.floor(v.r/2); return -Math.max(0,lead+1-c)*1.2; }
  return 0; }
function objectiveTick(){ const o=B.obj; if(!o||B.over) return;
  if(o.type==='defend'){ const near=caps('enemy').filter(u=>hdist(u,o.hex)<=2); if(near.length){ o.hp=Math.max(0,o.hp-near.length); log(`${near.length} enemy ship${near.length>1?'s':''} at the station. Integrity ${o.hp}/${o.hpMax}.`,'e'); }
    if(o.hp>0&&B.round<=o.rounds) stationFire(); checkEnd(); return; }
  if(o.type==='hunt'){ if(B.round>o.rounds){ const f=B.units.find(u=>u.flagship&&u.side==='enemy'&&!u.dead); if(f){ f.dead=true; f.fled=true; o.escaped=true; try{ fxWithdraw(f); }catch(e){} log(`${f.name} jumps out. Its escorts follow.`,'e'); } } checkEnd(); return; }
  if(o.type!=='hold') return; const near=s=>alive(s).some(u=>!u.isSq&&hdist(u,o.hex)<=1); const p=near('player'), e=near('enemy');
  if(p&&!e){ o.score++; log(`You hold the relay (${o.score}/3).`,'p'); } else if(e&&!p){ o.escore++; log(`The enemy holds the relay (${o.escore}/3).`,'e'); } else if(p&&e) log('The relay is contested.','x'); checkEnd(); }
// (emergency shields removed: Admiral's Command and ship abilities cover shield refills)
// one owner for "the battle ended": the first time a battle becomes over, its end screen is scheduled once,
// whichever rule (a kill, the relay score, a squadron strike at round start, a Command) caused it
function checkEnd(){ const was=!!(B&&B.over); checkEndRules(); if(B&&!was&&B.over) scheduleBattleEnd(); }
function scheduleBattleEnd(){ const b=B; if(!b||b.showcase) return; Promise.resolve().then(()=>{ if(B===b&&b.over&&!b.ending&&typeof endBattleFlow==='function'){ b.busy=false; endBattleFlow(); } }); }
function checkEndRules(){
  if(B.over) return;
  if(caps('enemy').length===0){ B.over='win'; return; }
  const o=B.obj;
  if(o&&o.type==='break'){ const out=B.units.filter(u=>u.exited).length; o.out=out; if(out>=o.need){ B.over='win'; log(`${out} ship${out>1?'s':''} broke through. The fleet jumps clear.`,'s'); return; }
    if(out>0&&caps('player').length+out<o.need){ B.over='loss'; B.withdraw=true; log('Too few ships can still get through. The survivors jump clear.','e'); return; } }
  if(caps('player').length===0){ B.over='loss'; return; }
  if(o&&o.type==='intercept'){ const tr=B.units.filter(u=>u.transport); o.kill=tr.filter(u=>u.dead&&!u.fled).length; o.esc=tr.filter(u=>u.fled).length;
    if(o.kill>=o.need){ B.over='win'; B.routed=true; log('The convoy is broken. The escorts break off.','s'); return; }
    if(o.esc>o.total-o.need){ B.over='win'; B.partial=true; log('Enough transports got through. The escorts break off.','e'); return; } }
  if(o&&o.type==='defend'){ if(o.hp<=0){ B.over='loss'; B.withdraw=true; log('The station falls. Your fleet is forced to withdraw.','e'); return; } if(B.round>o.rounds){ B.over='win'; log('The station holds. The enemy withdraws.','s'); return; } }
  if(o&&o.type==='hunt'){ const f=B.units.find(u=>u.flagship&&u.side==='enemy'); if(f&&f.dead){ if(o.escaped){ B.over='win'; B.partial=true; log('The flagship got away. Its escorts withdraw.','e'); } else { B.over='win'; B.routed=true; log('The flagship is destroyed. Its escorts scatter.','s'); } return; } }
  if(B.obj&&B.obj.type==='flagship'&&!B.units.some(u=>u.flagship&&u.side==='enemy'&&!u.dead)){ B.over='win'; B.routed=true; log('The enemy flagship is gone. The rest of their fleet scatters.','s'); return; }
  if(B.obj&&B.obj.type==='hold'){ if(B.obj.score>=3){ B.over='win'; log('The relay is yours. The enemy withdraws.','s'); return; } if(B.obj.escore>=3){ B.over='loss'; B.withdraw=true; log('The enemy secures the relay. Your fleet is forced to withdraw.','e'); return; } }
  // a broken fleet flees instead of being hunted down hex by hex
  if(!B.cp0||(o&&(o.type==='intercept'||o.type==='hunt'))) return;
  const bossDown=B.cfg&&B.cfg.kind==='boss'&&!B.units.some(u=>u.boss&&u.side==='enemy'&&!u.dead);
  if(bossDown||sideCP('enemy')<=B.cp0.enemy*.35){ B.over='win'; B.routed=true; log(bossDown?'The flagship is gone. Its escorts break and flee.':'The enemy fleet breaks and flees.','s'); }
}

// ---------- orders & abilities ----------
function canOrder(u,o){
  if(u.dead||u.order||u.braced) return false;
  if(o==='full') return !u.moved && !u.isSq;
  if(o==='lock') return true;
  if(o==='helm') return !u.isSq && !u.noTurn;
  if(o==='brace') return !u.isSq && !u.weapons.some(w=>w.fired&&w.k!=='flak'); // brace instead of firing: not after this ship has fired
  return false;
}
function giveOrder(u,o){ if(B.usage&&u.side==='player') B.usage.ord[o]=(B.usage.ord[o]||0)+1;
  if(!canOrder(u,o)) return;
  u.order=o;
  if(o==='brace'){ u.braced=true; u.mp=0; for(const w of u.weapons) w.fired=true; fxText(u,'Braced','#7fd6c8',-24); if(u.fx.bastion&&u.shMax>0){ u.sh=u.sh.map(()=>u.shMax); boonFx(u,'d_bastion','shields full',-44); } }
  if(o==='full'){ u.fullAhead=true; u.noTurn=true; u.mp+=Math.ceil(u.mp*.5); }
  if(o==='lock'){ u.lockOn=true; u.mp=0; }
  if(o==='helm'){ u.turnsLeft++; }
  log(`${u.name}: ${ORDERS[o].n}.`, u.side==='player'?'p':'e');
}
function abilityCd(u){ return Math.max(1, ABILITIES[u.ab].cd-(u.fx.cdMod||0)); }
// ---------- squadrons fight on their own: swarm weapons that persist until shot down ----------
// nothing may wait forever: if an action outlives its limit, record what was running, save, and carry on
// stall guard: time only counts while the game is on screen (a locked phone pauses, it doesn't skip ahead).
// If an action truly hangs, the battle's epoch goes up so that action can never act later.
function gameVisible(){ return typeof document==='undefined'||document.visibilityState!=='hidden'; }
function stallGuard(p,ms,tag,info){ let iv, done=false; const b0=B, gT=()=>(typeof G!=='undefined'&&G&&typeof G.time==='number')?G.time:null, g0=gT(); const lim=new Promise(res=>{ let used=0, last=Date.now(); iv=setInterval(()=>{ const now=Date.now(); if(gameVisible()) used+=now-last; last=now; if(done){ clearInterval(iv); return; } if(B!==b0){ clearInterval(iv); res('stale'); return; }
      // animations run on game time, so a slow renderer stretches them: count game time, with a 4x real-time backstop in case frames stop entirely
      const g=gT(); if(g!=null&&g0!=null?((g-g0)*1000<ms&&used<ms*4):used<ms) return; clearInterval(iv); // a guard only ever acts on its own battle
      try{ if(B) B.epoch=(B.epoch||0)+1; if(typeof tel==='function'){ tel('stall',Object.assign({tag,round:B&&B.round,side:B&&B.side,busy:B&&B.busy},info||{})); if(typeof Persist!=='undefined'){ Persist.saveLocal(); if(Persist.save) Persist.save(); } }
        if(typeof toast==='function') toast('Something got stuck, so the game skipped ahead and saved a report for Claude.'); }catch(e){} res('stall'); },250); });
  return Promise.race([Promise.resolve(p).catch(e=>{ try{ if(typeof tel==='function') tel('action_error',{tag,msg:String(e&&e.message||e).slice(0,140),at:String(e&&e.stack||'').split('\n').slice(1,3).join(' | ').slice(0,240)}); if(typeof Persist!=='undefined'){ Persist.saveLocal(); if(Persist.save) Persist.save(); } }catch(_){} }),lim]).finally(()=>{ done=true; clearInterval(iv); }); }
// an action is live only while its battle and epoch are unchanged since it started
function liveFrom(u){ const b0=B, ep=(B&&B.epoch)||0; return ()=>B===b0&&((B&&B.epoch)||0)===ep&&(!u||!u.dead); }
// ---------- Admiral's Command: one big fleet-wide move per admiral, ready when the meter is full ----------
const COMMANDS={vex:{id:'barrage',n:'Fire for effect',d:'Every ship fires a free volley at the best target its guns can reach, right now.'},
  malek:{id:'hunt',n:"Hunter's salvo",d:'Torpedoes reload at once and every ship deals +30% damage this round.'},
  ashgrove:{id:'scramble',n:'Scramble all wings',d:'Every carrier launches a wing, then all squadrons strike again at once with +50% damage this round.'},
  thale:{id:'iron',n:'Iron wall',d:'All shields refill and your ships take 40% less hull damage this round.'}};
// Command power grows each round you hold it: tier 0 in round 1, 1 in round 2, 2 (full) from round 3
const CMD_POW={barrage:[0,.25,.5],hunt:[.3,.45,.6],scramble:[.5,.75,1],iron:[.4,.5,.6],restore:[.25,.35,.45],surge:[2,3,4]};
function cmdTier(){ if(!B||B.round<1) return 0; const bonus=B.units.some(u=>u.side==='player'&&!u.dead&&u.fx&&u.fx.cmdTier)?1:0, lost=B.units.some(u=>u.side==='player'&&!u.isSq&&!u.transport&&u.dead)?1:0; return Math.max(0,Math.min(2,B.round-1+bonus+lost-(heatOn('h_cmd')?1:0))); } /* ready from round 1, full power from round 3; losing a ship charges it a level */
function cmdRec(side){ return !B?null:side==='enemy'?B.cmdE:B.cmd; } // the enemy flagship keeps its own Command record
function cmdPow(id,tier,side){ const p=CMD_POW[id]; if(!p) return 0; if(tier==null){ const c=cmdRec(side||'player'); tier=(c&&c.tier)||0; } return p[tier]; }
function cmdDesc(c,tier,fac){ if(!c) return ''; const v=cmdPow(c.id,tier), car=fac==='chorus'?'brood':'carrier', sq=fac==='chorus'?'swarm':'squadron', pct=x=>Math.round(x*100)+'%';
  switch(c.id){
    case 'barrage': return `Every ship fires a free extra volley right now at the best target in range${v?`, with +${pct(v)} damage`:''}. Its normal shots this round still happen.`;
    case 'hunt': return `Torpedoes reload at once and every ship deals +${pct(v)} damage for the rest of this round.`;
    case 'scramble': return `Every ${car} launches ${tier>=2?'two extra wings':'an extra wing'} right now, even past its limit. Then every ${sq} you have makes a bonus attack immediately, with +${pct(v)} damage.`;
    case 'iron': return fac==='chorus'||fac==='deathless'?`Your ships take ${pct(v+.1)} less hull damage for the rest of this round.`:`All shields refill and your ships take ${pct(v)} less hull damage for the rest of this round.`;
    case 'restore': return `Every ship repairs ${pct(v)} of its hull right now.`;
    case 'surge': return `Every ship gains +${v} movement and ${tier>=2?'+2 turns':'+1 turn'} this round, and enemy fire loses 20 accuracy against you.`; }
  return c.d||''; }
function cmdNext(c,tier,fac){ const t=tier+1, v=cmdPow(c.id,t), pct=x=>Math.round(x*100)+'%', car=fac==='chorus'?'brood':'carrier';
  switch(c.id){ case 'barrage': return `+${pct(v)} damage on the free volley`; case 'hunt': return `+${pct(v)} damage`; case 'scramble': return `${t>=2?'two extra wings per '+car:'an extra wing'} and +${pct(v)} damage`;
    case 'iron': return `${pct(v)} less hull damage`; case 'restore': return `${pct(v)} of hull repaired`; case 'surge': return `+${v} movement${t>=2?' and +2 turns':''}`; } return ''; }
const CMD_HOLD='Once per battle. Each round you hold it, it gets stronger (full power from round 3), and losing a ship charges it a level at once. Hold too long and the fight may be over.';
function commandFor(side){ if(side!=='player') return null; if(typeof RUN!=='undefined'&&RUN&&RUN.cmdOverride) return RUN.cmdOverride; const id=(typeof RUN!=='undefined'&&RUN&&RUN.admiral)||'vex', a=ADMIRALS[id]; return (a&&a.cmd)||COMMANDS[id]||COMMANDS.vex; }
function cmdActive(side,id){ const c=cmdRec(side); return !!(c&&c.id===id&&c.round===B.round); }
function canCommand(side){ return !!B&&!B.over&&side==='player'&&!!commandFor(side)&&B.round>=1&&!B.cmdUsed; } // ready from round 1, once per battle
function cmdTaken(t){ return cmdActive(t.side,'iron')?1-cmdPow('iron',null,t.side)-(t.shMax?0:.1):1; } // shieldless hulls get a deeper cut, since the shield refill does nothing for them
async function useCommand(side){ if(!canCommand(side)) return false; const c=commandFor(side); const tier=cmdTier(); B.cmdUsed=true; B.cmd={id:c.id,side,round:B.round,tier}; if(B.usage&&side==='player') B.usage.cmd++;
  log(`Admiral's Command${tier?` at power ${tier+1} of 3`:''}: ${c.n}. ${cmdDesc(c,tier,(typeof RUN!=='undefined'&&RUN&&RUN.fac)||'voidsworn')}`,side==='player'?'p':'e'); try{ if(typeof tel==='function') tel('command',{id:c.id,round:B.round,tier}); }catch(e){}
  return runCommand(side,c,tier); }
async function runCommand(side,c,tier){ const foe=side==='player'?'enemy':'player', bStart=B;
  for(const u of alive(side)) if(!u.isSq) fxText(u,c.n,side==='player'?'#e8c66a':'#ff8a6a',-44);
  if(c.id==='barrage'){ const b0=B, live=liveFrom(null); B.volleyMul={side,m:1+cmdPow('barrage',tier)}; try{ for(const u of alive(side).filter(x=>!x.isSq)){ if(B.over||!live()) break; const keep=u.weapons.map(w=>[w.fired,w.cdLeft]); u.weapons.forEach(w=>{ w.fired=false; w.cdLeft=0; });
      for(let i=0;i<u.weapons.length;i++){ if(B.over||!live()||u.dead) break; const w=u.weapons[i]; const ts=alive(foe).filter(t=>canFire(u,w,t)); if(!ts.length) continue; const val=t=>{ const e=expectedVs(u,w,t); return e.hull+e.shield*.3+(e.hull>=t.hp?25:0); }; ts.sort((a,b2)=>val(b2)-val(a)); await fireWeapon(u,i,ts[0]); }
      u.weapons.forEach((w,i)=>{ w.fired=keep[i][0]; w.cdLeft=keep[i][1]; }); } } finally{ if(B===b0) B.volleyMul=null; } }
  if(c.id==='hunt') for(const u of alive(side)) for(const w of u.weapons) if(w.k==='torp'){ w.cdLeft=0; w.fired=false; }
  if(c.id==='iron') for(const u of alive(side)) if(u.shMax) u.sh=u.sh.map(()=>u.shMax);
  if(c.id==='restore') for(const u of alive(side).filter(x=>!x.isSq)){ const rp=cmdPow('restore',tier); u.hp=Math.min(u.maxHp,u.hp+Math.round(u.maxHp*rp)); if(u.sec){ let fixed=0; for(const k of Object.keys(u.sec)) if(repairSection(u,k,rp)) fixed++; if(fixed) fxText(u,fixed>1?fixed+' sections restored':'Section restored','#8ff0a0',-34); } fxText(u,'+'+Math.round(u.maxHp*rp)+' hull','#8ff0a0',-20); }
  if(c.id==='surge') for(const u of alive(side).filter(x=>!x.isSq)){ u.mp=(u.mp||0)+cmdPow('surge',tier); u.turnsLeft=(u.turnsLeft||0)+(tier>=2?2:1); }
  if(c.id==='scramble'){ for(const u of alive(side).filter(x=>x.ab==='launch')){ const hs=launchHexes(u); if(!hs.length) continue; const fs=alive(foe); hs.sort((a,b2)=>Math.min(...fs.map(f=>hdist(a,f)))-Math.min(...fs.map(f=>hdist(b2,f)))); for(let k=0;k<(tier>=2?2:1)&&k<hs.length;k++){ makeWing(u,hs[k],wingKind(u)); try{ fxFlash(hs[k],'#f0b35a'); }catch(e){} } } // extra wings, even past the hangar limit, even past the hangar limit
    for(const s of alive(side).filter(x=>x.isSq)){ s.activated=false; s.mp=s.speed; s.weapons.forEach(w=>{ w.fired=false; w.cdLeft=0; }); } await swarmPhase(side); }
  if(B===bStart) checkEnd(); return true; }
// enemy flagships carry a Command of their own: announced a round ahead, fired once, at power 2
const BOSS_CMD={hegemony:{id:'barrage',n:'Imperial broadside'},corsair:{id:'surge',n:'Burn and board'},chorus:{id:'restore',n:'Hive regrowth'},ithar:{id:'iron',n:'Prism ward'},deathless:{id:'restore',n:'Rise again'},voidsworn:{id:'hunt',n:'Crusader\u2019s wrath'}};
function bossCmdText(c,fac){ return cmdDesc(c,1,fac).replace(/your ships/g,'its ships').replace(/against you/g,'against them').replace(/Every ship/g,'Every enemy ship'); }
function bossCmdTick(){ if(!B||B.over||B.cmdEUsed) return; const boss=B.units.find(u=>u.side==='enemy'&&u.t&&u.t.boss&&!u.dead); if(!boss) return; const c=BOSS_CMD[boss.fac]; if(!c) return;
  if(B.cmdENext==null){ if(B.round>=2||boss.hp<boss.maxHp*.6){ B.cmdENext=B.round+1; log(`${boss.name} is preparing ${c.n}. ${bossCmdText(c,boss.fac)} It strikes next round.`,'e'); try{ fxText(boss,'Preparing: '+c.n,'#ff8a6a',-56); }catch(e){} try{ if(typeof toast==='function'&&typeof document!=='undefined') toast(`${boss.name} is preparing ${c.n}. It strikes next round.`); if(typeof banner==='function'&&typeof document!=='undefined') setTimeout(()=>{ try{ banner(`${c.n} next round`,'#ff8a6a'); }catch(e){} },900); }catch(e){} /* v45: the boss Command gets a banner too */ } return; } }
async function bossCmdFire(){ if(!B||B.over||B.cmdEUsed||B.cmdENext==null||B.round<B.cmdENext) return; const boss=B.units.find(u=>u.side==='enemy'&&u.t&&u.t.boss&&!u.dead); if(!boss){ B.cmdEUsed=true; return; } const c=BOSS_CMD[boss.fac];
  B.cmdEUsed=true; B.cmdE={id:c.id,side:'enemy',round:B.round,tier:1}; log(`${boss.name}: ${c.n}!`,'e'); await runCommand('enemy',c,1); }
// a ship that isn't part of the current battle (a hung action from an earlier fight) may never act
function inThisBattle(u){ return !!(B&&u&&B.units.includes(u)); }
const SQ_LEASH=8; // hexes a squadron may range from a living carrier
function sqRole(s){ return s.t.sq==='fighter'?'fighter':'bomber'; }
// bombers strike ships; fighters hunt enemy craft and only strafe ships when no enemy craft are flying
function sqWants(s,t){ if(t.dead||t.side===s.side) return false; if(sqRole(s)==='bomber') return !t.isSq; return alive(t.side).some(x=>x.isSq)?t.isSq:true; }
function sqValue(t,e){ let v=e.hull+e.shield*.3; if(e.hull>=t.hp) v+=25; if(t.isSq&&sqRole(t)==='bomber') v*=1.5; return v+(1-t.hp/t.maxHp)*10; }
// a target is "in reach" only if some hex the squadron can actually fly to this round lets a weapon legally hit it (same range, arc and sight rules as manual fire)
// wing orders (player only): 'strike' a chosen enemy, or 'guard' a friendly ship and hit whatever comes near it
function sqOrder(s){ const o=s.wingOrder; if(!o) return null; const t=B.units.find(x=>x.id===o.id); if(!t||t.dead||t.side===s.side){ s.wingOrder=null; return null; } return {kind:o.kind,t}; }
function sqPlan(s){ const ord=sqOrder(s); let foes=alive(s.side==='player'?'enemy':'player').filter(t=>sqWants(s,t)||(ord&&ord.kind==='strike'&&ord.t===t)); if(!foes.length) return null;
  const carrier=B.units.find(x=>x.id===s.parent&&!x.dead), ready=s.weapons.filter(weaponReady), {states}=computeReach(s), here={q:s.q,r:s.r,f:s.facing,cost:0,stay:true};
  const guard=ord&&ord.kind==='guard'?ord.t:null;
  const lim=SQ_LEASH+(ord&&ord.kind==='strike'?2:0), leashOK=v=>guard?hdist(v,guard)<=3:(!carrier||hdist(v,carrier)<=lim); let best=null;
  for(const st of [here,...states]){ const v=stateView(s,st); if(!leashOK(v)) continue;
    for(const t of foes) for(const w of ready){ if(!inReach(v,w,t)) continue; let val=sqValue(t,expectedVs(v,w,t))-(st.cost||0)*.01;
      if(ord&&ord.kind==='strike'&&ord.t===t) val=val*3+60; if(guard&&hdist(t,guard)<=3) val=val*2+20;
      if(!best||val>best.val) best={st,t,val,attack:true}; } }
  if(best) return best;
  if(guard){ let hm=null,hd=hdist(s,guard); for(const st of states){ const d=hdist(stateView(s,st),guard); if(d<hd||(d===hd&&!hm)){hd=d;hm=st;} } return hm&&hd<hdist(s,guard)?{st:hm,t:null,attack:false}:null; }
  if(ord&&ord.kind==='strike'){ const T=ord.t, PFo=pathField([T]); let mv=null,md=fieldDist(PFo,s,hdist(s,T)); for(const st of states){ const v=stateView(s,st); if(carrier&&hdist(v,carrier)>lim) continue; const d=fieldDist(PFo,v,hdist(v,T)); if(d<md){md=d;mv=st;} } if(mv) return {st:mv,t:T,attack:false}; }
  const T=foes.reduce((a,t)=>hdist(s,t)<hdist(s,a)?t:a,foes[0]); const PFs=pathField([T]); let mv=null,md=fieldDist(PFs,s,hdist(s,T)); for(const st of states){ const v=stateView(s,st); if(!leashOK(v)) continue; const d=fieldDist(PFs,v,hdist(v,T)); if(d<md){md=d;mv=st;} }
  if(mv) return {st:mv,t:T,attack:false};
  // stranded outside the leash (the carrier moved away): fly home toward the carrier
  if(carrier){ let hm=null,hd=hdist(s,carrier); for(const st of states){ const d=hdist(stateView(s,st),carrier); if(d<hd){hd=d;hm=st;} } if(hm) return {st:hm,t:null,attack:false}; }
  return null; }
async function sqAct(s){ const live=liveFrom(s); const p=sqPlan(s); if(!p) return; if(!p.st.stay) await moveUnit(s,p.st); if(!live()||!p.attack||s.dead||p.t.dead) return;
  for(let i=0;i<s.weapons.length;i++){ if(p.t.dead||s.dead||!live()) break; if(canFire(s,s.weapons[i],p.t)) await fireWeapon(s,i,p.t); } }
async function swarmPhase(side){ const b0=B; for(const s of alive(side).filter(x=>x.isSq&&!x.activated)){ if(B!==b0||B.over) return; const t0=(typeof performance!=='undefined'?performance.now():0); await stallGuard(sqAct(s),15000,'squadron',{name:s.name,sq:s.t.sq,q:s.q,r:s.r}); s.activated=true; if(typeof console!=='undefined'&&console.debug) console.debug('[swarm] '+side+' '+s.id+' '+Math.round((typeof performance!=='undefined'?performance.now():0)-t0)+'ms'); } }
function makeWing(u,h,kind){ const fx=u.side==='player'?sumFx(fleetFxList()):{};
  const sq=makeUnit(u.side, kind, {parent:u.id, fac:u.fac, sqPct:(u.fx.sqPct||0), sqHp:fx.sqHp||0, scale:u.side==='enemy'?1+.1*(B.sector-1):1});
  sq.fac=u.fac; sq.q=h.q; sq.r=h.r; sq.facing=u.facing; sq.name=`${HULLS[kind].n} (${u.side==='player'?u.name:u.t.n.split(' ').slice(-1)[0]})`; B.units.push(sq); return sq; }
// carriers open the battle with their wings already in flight; launching only replaces losses
function deployWings(){ for(const u of B.units.filter(x=>(x.ab==='launch'||(x.fx&&x.fx.hive))&&!x.dead&&!x.isSq)){ const foes=alive(u.side==='player'?'enemy':'player'), sec=B.sector||1, bossWings=u.side==='enemy'&&u.t.boss;
  u.spare=bossWings?Math.max(0,sec-1):(u.hangar||0); /* a sector flagship's air wing grows with the sector: 1 wing in sector I, 2 in II, 3 in III */ // v41: one spare wing per hangar slot (was two): carriers keep their opening wings, but losses end sooner
  for(let i=0;i<(bossWings?Math.min(u.hangar||0,sec):(u.hangar||0));i++){ const hs=launchHexes(u); if(!hs.length) break; hs.sort((a,b)=>Math.min(99,...foes.map(f=>hdist(a,f)))-Math.min(99,...foes.map(f=>hdist(b,f))));
    makeWing(u,hs[0],wingKind(u,i)); } }
  /* fighter screen against carrier-heavy fleets, flown off the biggest escorts */
  if(B.adaptWings){ const foes=alive('player'), hosts=alive('enemy').filter(x=>!x.isSq&&!x.transport).sort((a,b)=>(b.t.boss?0:b.t.cp||1)-(a.t.boss?0:a.t.cp||1)); for(let i=0;i<B.adaptWings&&hosts.length;i++){ const h=hosts[i%hosts.length], hs=launchHexes(h); if(!hs.length) continue; hs.sort((a,b)=>Math.min(99,...foes.map(f=>hdist(a,f)))-Math.min(99,...foes.map(f=>hdist(b,f)))); makeWing(h,hs[0],'fighter'); } } }
// a carrier's wing mix: strike craft first, then escorts. Factions whose own craft are fighters still field bombers, or their wings never touch a ship
function wingKind(u,i){ const set=FACTIONS[u.fac]&&FACTIONS[u.fac].sq, own=set||'fighter'; if(own!=='fighter') return own; if(set&&u.side==='enemy') return own; /* enemy fighter fleets stay true to their faction */ const foe=u.side==='player'?'enemy':'player', air=B.units.some(x=>!x.dead&&x.side===foe&&(x.isSq||x.ab==='launch')); if(!air) return 'bomber'; /* no enemy craft to fight: every wing is a strike wing */ const have=squadronsOf(u), nb=have.filter(x=>x.t.sq!=='fighter').length, nf=have.length-nb; if(i!=null) return i%2?'fighter':'bomber'; return nb<=nf?'bomber':'fighter'; }
function squadronsOf(u){ return alive().filter(x=>x.parent===u.id); }
function canAbility(u){
  if(!u.ab||u.dead||u.abCd>0||u.braced) return false;
  if(u.ab==='surge'&&u.st&&u.st.shieldOff>=99) return false; // the shield generator section is destroyed
  if(u.ab==='launch') return squadronsOf(u).length<u.hangar && (u.spare==null||u.spare>0) && launchHexes(u).length>0;
  if(u.ab==='reload') return u.weapons.some(w=>w.k==='torp'&&(w.cdLeft>0||w.fired));
  if(u.ab==='regrow') return u.hp<u.maxHp;
  if(u.ab==='reclaim') return alive(u.side).some(x=>!x.isSq&&hdist(x,u)<=3&&x.hp<x.maxHp);
  if(u.ab==='blink') return blinkHexes(u).length>0;
  if(u.ab==='ionpulse') return alive(u.side==='player'?'enemy':'player').some(t=>!t.isSq&&hdist(t,u)<=4);
  return true;
}
// Ithar phase jump: any open, playable hex within 3, straight past whatever is in the way
function blinkHexes(u){ const occ=occMap(), out=[]; for(const h of boardHexes()){ const d=hdist(u,h); if(d<1||d>3||blocks(terr(h.q,h.r))||occ.has(hkey(h.q,h.r))) continue; out.push(h); } return out; }
// without a tapped hex (enemy ships, the sim bot): jump to the open hex that best lines up a shot, or away when badly hurt
function autoBlink(u){ const hs=blinkHexes(u), foes=alive(u.side==='player'?'enemy':'player').filter(x=>!x.isSq); if(!hs.length||!foes.length) return null; const hurt=u.hp<u.maxHp*.35; let best=null,bv=-1e9;
  for(const h of hs){ let v=-1e9; for(let f=0;f<6;f++){ const st=stateView(u,{q:h.q,r:h.r,f}); const o=evalOffense(st,u.weapons.filter(weaponReady),foes), th=evalThreat(st,foes); v=Math.max(v,hurt?-th:o-th*.3); } const near=Math.min(...foes.map(t=>hdist(h,t))); const val=v+(hurt?near*2:-near*.5); if(val>bv){bv=val;best=h;} }
  return best; }
function launchHexes(u){ const occ=occMap(); return DIRS.map(d=>({q:u.q+d[0],r:u.r+d[1]})).filter(h=>onBoard(h.q,h.r)&&!blocks(terr(h.q,h.r))&&!occ.has(hkey(h.q,h.r))); }
async function useAbility(u,arg){
  if(!inThisBattle(u)||!canAbility(u)) return false; if(B.usage&&u.side==='player') B.usage.ab[u.ab]=(B.usage.ab[u.ab]||0)+1;
  const a=u.ab;
  if(a==='evasive'){ u.evBuff=25; u.mp+=2; fxText(u,'Evasive','#9fe3ff',-24); }
  if(a==='reload'){ for(const w of u.weapons) if(w.k==='torp'){ w.cdLeft=0; w.fired=false; } fxText(u,'Tubes loaded','#f0b35a',-24); }
  if(a==='focus'){ u.focus=true; fxText(u,'Focus fire','#f0b35a',-24); }
  if(a==='phase'){ u.evBuff=25; /* v45: was 22, strictly weaker than Evasive Burn; now level (Deathless is already the strongest faction, so parity rather than a buff) */ u.mp+=2; fxText(u,'Phase shift','#7dff9b',-24); }
  if(a==='frenzy'){ u.focus=true; fxText(u,'Blood frenzy','#ff8fe0',-24); }
  if(a==='overburn'){ u.mp+=3; u.ramBoost=1.5; fxText(u,'Overburn','#ffb35c',-24); }
  if(a==='regrow'){ const h=Math.min(u.maxHp-u.hp,Math.round(u.maxHp*.25)); u.hp+=h; fxText(u,'+'+h+' hull','#8ff0a0',-24); }
  if(a==='reclaim'){ const ts=alive(u.side).filter(x=>!x.isSq&&hdist(x,u)<=3&&x.hp<x.maxHp).sort((p,q)=>p.hp/p.maxHp-q.hp/q.maxHp), t=ts[0]; if(t){ const h=Math.min(t.maxHp-t.hp,Math.round(t.maxHp*.2)); t.hp+=h; fxText(t,'+'+h+' hull','#7dff9b',-24); log(u.name+' reanimates '+(t===u?'its own hull':t.name)+' for '+h+'.',u.side==='player'?'p':'e'); } }
  if(a==='ionpulse'){ const foes=alive(u.side==='player'?'enemy':'player').filter(t=>!t.isSq&&hdist(t,u)<=4); for(const t of foes){ if(t.sh) t.sh=t.sh.map(x=>Math.floor(x*.5)); try{ fxShield(t,-1); }catch(e){} } fxText(u,'Ion pulse','#9fd4ff',-24); log(u.name+' fires an ion pulse: '+foes.length+' enemy ship'+(foes.length===1?'':'s')+' lose half their shields.',u.side==='player'?'p':'e'); }
  if(a==='blink'){ const h=arg&&arg.hex?arg.hex:autoBlink(u); if(!h) return false; const from={q:u.q,r:u.r}; u.q=h.q; u.r=h.r; u.vis=null; try{ if(typeof animBlink==='function') await animBlink(u,from); }catch(e){} fxText(u,'Phase jump','#9fe3ff',-24); objAfterMove(u); }
  if(a==='surge'){ for(let i=0;i<4;i++) u.sh[i]=u.shMax; if(u.st.shieldOff<99) u.st.shieldOff=0; fxShield(u,-1); fxText(u,'Shields surge','#7fd6c8',-24); }
  if(a==='launch'){
    const h=arg&&arg.hex ? arg.hex : pick(launchHexes(u));
    const kind = arg&&arg.kind ? arg.kind : wingKind(u);
    if(u.spare!=null) u.spare=Math.max(0,u.spare-1); const sq=makeWing(u,h,kind); sq.mp=0; sq.weapons.forEach(w=>w.fired=true); fxFlash(h,'#f0b35a');
    log(`${u.name} launches a ${HULLS[kind].n.toLowerCase()}.`, u.side==='player'?'p':'e');
  }
  if(a==='nova'){
    const c=arg.hex; u.abCd=abilityCd(u);
    log(`${u.name} fires its nova cannon.`, u.side==='player'?'p':'e');
    const live=liveFrom(u); await animNova(u,c); if(!live()) return false; // abandoned after a stall: the blast never lands
    const hitList=alive().filter(x=>hdist(x,c)<=1);
    for(const x of hitList){
      const dmg=(hdist(x,c)===0?40:20)*u.dmg*(x.isSq?1.5:1);
      const quad=shieldQuad(x,u);
      const r=applyHit(u,{pierce:.3,crit:5},x,dmg,quad);
      if(r.shield) fxText(x,'\u2212'+r.shield,'#7fd6c8',-18);
      fxText(x,'\u2212'+r.hull,'#ff7a6e',0);
      log(`Nova blast hits ${x.name} for ${r.hull} hull${r.shield?` and ${r.shield} shields`:''}.`, x.side==='player'?'e':'p');
      if(x.hp<=0) await killUnit(x,u);
    }
    return true;
  }
  u.abCd=abilityCd(u);
  if(a!=='launch') log(`${u.name}: ${ABILITIES[a].n}.`, u.side==='player'?'p':'e');
  return true;
}
function novaTargets(u){ return boardHexes().filter(h=>{ const d=hdist(u,h); return d>=3&&d<=9&&inArc(u,h,'F'); }); }

// ---------- enemy AI ----------
function stateView(u,s){ const v=Object.create(u); v.q=s.q; v.r=s.r; v.facing=s.f; if(s.path&&!u.isSq) v.hexMoved=(u.hexMoved||0)+s.path.filter(p=>!p.rot).length; return v; }
function evalOffense(a, ready, targets){
  let tot=0;
  for(const w of ready){ let best=0;
    for(const t of targets){ if(!inReach(a,w,t)) continue; const e=expectedVs(a,w,t); let v=e.hull+e.shield*.3; if(e.hull>=t.hp) v+=15+t.maxHp*.1; if(t.isSq&&!w.vsSq) v*=.5; if(v>best) best=v; }
    tot+=best; }
  return tot;
}
// how each faction fights: threat weight (caution), weight when badly hurt, and a preferred range
// range>0 keeps at least that many hexes away (kiting); range<0 wants to be within that many hexes (closing in)
const FACTION_AI={
  voidsworn:{tw:1,hurt:1,range:0,rw:0},
  hegemony:{tw:1.15,hurt:1.3,range:3,rw:1.2},   // hold a gun line at range
  corsair:{tw:.8,hurt:1.4,range:-2,rw:1.2},     // close fast, cut and run when hurt
  chorus:{tw:.6,hurt:.7,range:-1,rw:1.8},       // swarm into tendril range
  ithar:{tw:1.3,hurt:1.6,range:2,rw:1.2},       // hit and fade
  deathless:{tw:.55,hurt:.6,range:-3,rw:.8}};   // advance and never flinch
// ---------- veteran AI helpers ----------
function aiVet(){ return (typeof AI_LEVEL==='undefined'?'veteran':AI_LEVEL)==='veteran'; }
// threat now includes what enemies could reach after moving, not just where they sit
function evalThreatVet(v,foes){ let tot=0; for(const p of foes){ const d=hdist(p,v); if(d>13) continue;
    for(const w of p.weapons){ if(w.cdLeft>1||w.off>1) continue; if(d<=w.r&&inArc(p,v,w.arc)){ const e=expectedVs(p,w,v); tot+=e.hull+e.shield*.2; }
      else if(d<=w.r+Math.max(1,(p.speed||2)-1)){ const e=expectedVs(p,w,v); tot+=(e.hull+e.shield*.2)*.2; } } } return tot; }
// a position that lines up a ram for next activation
function ramSetup(v,u){ const d=DIRS[v.facing]; let q=v.q,r=v.r; for(let i=0;i<=(u.speed||2);i++){ q+=d[0]; r+=d[1]; if(!onBoard(q,r)||blocks(terr(q,r))) return 0; const o=unitAt(q,r); if(o&&o!==u){ return (o.side!==u.side&&!o.isSq&&i>=1)?ramEstimate(Object.assign(Object.create(u),{q:v.q,r:v.r,facing:v.facing}),o).dmg:0; } } return 0; }
// the fleet-wide focus target: the most valuable ship that is closest to dying
function aiFocusTarget(){ let best=null,bv=0; for(const t of alive('player')){ if(t.isSq) continue; const ehp=t.hp+t.sh.reduce((a,x)=>a+x,0)*.3; const v=((t.t.cp||1)*12+(t.flagship?20:0))/Math.max(20,ehp); if(v>bv){bv=v;best=t;} } return best; }
function evalOffenseVet(a,ready,targets,focus){ let tot=0;
  for(const w of ready){ let best=0; for(const t of targets){ if(!inReach(a,w,t)) continue; const e=expectedVs(a,w,t); let v=e.hull+e.shield*.3; if(e.hull>=t.hp) v+=15+t.maxHp*.1; if(t.isSq&&!w.vsSq) v*=.5; if(t===focus) v*=1.3; if(e.rear) v*=1.1; if(v>best) best=v; } tot+=best; }
  return tot; }
// alternating activations: veterans act with the ship that has the best opportunity, or the most danger, right now
function aiPickActivation(list){ if(!aiVet()||list.length<2) return list[0]; const foes=alive('player'); let best=list[0],bv=-1e9;
  for(const u of list){ if(u.isSq) continue; const ready=u.weapons.filter(weaponReady); let mx=0;
    for(let f=0;f<6;f++){ const o=evalOffenseVet(Object.assign(Object.create(u),{facing:f}),ready,foes,B.aiFocus); if(o>mx) mx=o; }
    let reach=0; for(const t of foes){ const d=hdist(u,t); for(const w of ready) if(d<=w.r+(u.speed||2)) reach=Math.max(reach,w.dmg*w.shots*(t===B.aiFocus?1.3:1)); }
    const val=mx+reach*.5+evalThreat(u,foes)*.25+(u.hp<u.maxHp*.3?10:0); if(val>bv){bv=val;best=u;} }
  return best; }
function evalThreat(v, foes){
  let tot=0;
  for(const p of foes){ if(hdist(p,v)>9) continue;
    for(const w of p.weapons){ if(w.cdLeft>1||w.off>1) continue; if(hdist(p,v)>w.r) continue; if(!inArc(p,v,w.arc)) continue; const e=expectedVs(p,w,v); tot+=e.hull+e.shield*.2; } }
  return tot;
}
async function aiVolley(u,live){
    // fire: veterans pick one primary target and concentrate on it
    let primary=null; if(aiVet()){ let pv=0; const focus=B.aiFocus&&!B.aiFocus.dead?B.aiFocus:null;
      for(const t of alive('player')){ let tot=0,hull=0; for(const w of u.weapons){ if(!weaponReady(w)||!canFire(u,w,t)) continue; const e=expectedVs(u,w,t); tot+=e.hull+e.shield*.3; hull+=e.hull; } if(!tot) continue;
        const val=tot*(t.isSq?.6:1.1)+(hull>=t.hp?25+t.maxHp*.15:0)+(t===focus?10:0)+(1-t.hp/t.maxHp)*15; if(val>pv){pv=val;primary=t;} }
      if(primary&&!primary.isSq) B.aiFocus=primary; }
    const wlist=u.weapons.map((w,i)=>i).sort((a,b)=>(u.weapons[b].dmg*u.weapons[b].shots)-(u.weapons[a].dmg*u.weapons[a].shots));
    let fired=false;
    for(const wi of wlist){
      if(B.over) return null;
      const w=u.weapons[wi]; if(!weaponReady(w)) continue;
      let bt=null, bv=0;
      const taunt=alive('player').find(p=>!p.isSq&&p.fx&&p.fx.taunt&&hdist(p,u)<=p.fx.taunt); /* Aspect of the Bulwark: ships in its reach must fire on it */
      if(taunt&&w.k!=='flak'&&canFire(u,w,taunt)){ bt=taunt; bv=1; }
      else if(primary&&!primary.dead&&canFire(u,w,primary)&&!(w.vsSq>1&&!primary.isSq&&alive('player').some(s=>s.isSq&&canFire(u,w,s)))){ bt=primary; bv=1; }
      else for(const t of alive('player')){ if(!canFire(u,w,t)) continue; const e=expectedVs(u,w,t); let v=e.hull+e.shield*.3; if(e.hull>=t.hp) v+=20; if(!t.isSq) v*=1.1; if(v>bv){bv=v;bt=t;} }
      const call=null; // called shots removed
      if(bt && bv>0.5){ await fireWeapon(u,wi,bt,{called:call}); fired=true; await wait(30); if(!live()) return null; }
      if(u.dead) break;
    }
    return fired;
}
async function aiTurn(){
  const order=alive('enemy').sort((a,b)=>(a.isSq?0:1)-(b.isSq?0:1) || b.speed-a.speed);
  for(const u of order){ if(B.over) return; if(u.dead) continue; await aiUnit(u); }
}
// true travel distance (in hexes, around holes, rocks and wrecks) from every hex to the nearest of the given targets
function pathField(targets){ const D=new Map(), q=[]; for(const t of targets){ const k=hkey(t.q,t.r); if(!D.has(k)){ D.set(k,0); q.push(t); } }
  for(let i=0;i<q.length;i++){ const h=q[i], d=D.get(hkey(h.q,h.r)); for(const dd of DIRS){ const n={q:h.q+dd[0],r:h.r+dd[1]}, k=hkey(n.q,n.r); if(D.has(k)||!onBoard(n.q,n.r)||blocks(terr(n.q,n.r))) continue; D.set(k,d+1); q.push(n); } }
  return D; }
function fieldDist(D,v,fallback){ const d=D.get(hkey(v.q,v.r)); return d==null?fallback+6:d; }
async function aiUnit(u){
  if(u.isSq){ if(!B.over&&!u.dead&&u.side==='enemy') await sqAct(u); return; } // squadrons follow the swarm rules
  if(u.side==='enemy'&&!B.cmdEUsed&&B.cmdENext!=null){ await bossCmdFire(); if(B.over||u.dead) return; }
  const live=liveFrom(u);
    if(B.over||u.dead||u.side!=='enemy') return; u._calledUsed=false;
    B.aiActive=u; await wait(60); if(!live()) return;
    const foes=alive('player');
    if(!foes.length) return;
    // abilities before moving
    if(u.ab==='launch' && canAbility(u)){ const hs=launchHexes(u).sort((a,b)=>Math.min(...foes.map(f=>hdist(a,f)))-Math.min(...foes.map(f=>hdist(b,f)))); await useAbility(u,{hex:hs[0]}); await wait(200); }
    const nearF=foes.filter(f=>!f.isSq).reduce((a,f)=>!a||hdist(u,f)<hdist(u,a)?f:a,null);
    /* shields: surge when the facing toward the nearest threat is under half, not when all four facings are drained */
    if(u.ab==='surge' && canAbility(u) && nearF && hdist(u,nearF)<=8 && u.sh[shieldQuad(u,nearF)]<u.shMax*.5) { await useAbility(u); await wait(200); if(!live()) return; }
    if((u.ab==='focus'||u.ab==='frenzy') && canAbility(u) && foes.some(f=>hdist(u,f)<=6)) await useAbility(u);
    if((u.ab==='evasive'||u.ab==='phase') && canAbility(u) && foes.some(f=>hdist(u,f)<=5)) await useAbility(u);
    if(u.ab==='reload' && canAbility(u) && foes.some(f=>!f.isSq&&hdist(u,f)<=6+(u.speed||2))) { await useAbility(u); if(!live()) return; }
    if(u.ab==='regrow' && canAbility(u) && u.hp<u.maxHp*.6) await useAbility(u);
    if(u.ab==='reclaim' && canAbility(u) && alive('enemy').some(x=>!x.isSq&&hdist(x,u)<=3&&x.hp<x.maxHp*.6)) await useAbility(u);
    if(u.ab==='ionpulse' && canAbility(u) && foes.filter(t=>!t.isSq&&hdist(t,u)<=4).reduce((a,t)=>a+t.sh.reduce((x,y)=>x+y,0),0)>=30) await useAbility(u);
    if(u.ab==='overburn' && canAbility(u) && nearF && hdist(u,nearF)>(u.speed||2)+1) await useAbility(u);
    if(u.ab==='blink' && canAbility(u) && nearF && (u.hp<u.maxHp*.35&&evalThreat(u,foes)>u.hp*.3 || !u.weapons.some(w=>weaponReady(w)&&foes.some(f=>hdist(u,f)<=w.r+(u.speed||2))))) { await useAbility(u); if(!live()) return; }
    if(!live()) return;
    const runner=u.transport||(B.obj&&B.obj.type==='hunt'&&u.flagship);
    if(!u.isSq&&!runner) await tacticRam(u); if(B.over||u.dead||!live()) return;
    // plan movement
    const ready=u.weapons.filter(weaponReady);
    const {states}=computeReach(u);
    const minR=Math.min(...u.weapons.map(w=>w.opt));
    let best=null, bestScore=-1e9; const PF=pathField(foes.filter(f=>!f.isSq||u.isSq));
    for(const s of states){
      const v=stateView(u,s);
      const vet=aiVet(), focus=vet?(B.aiFocus&&!B.aiFocus.dead?B.aiFocus:(B.aiFocus=aiFocusTarget())):null;
      const off=vet?evalOffenseVet(v,ready,foes,focus):evalOffense(v,ready,foes);
      const threat=vet?evalThreatVet(v,foes):evalThreat(v,foes);
      const prof=(!u.isSq&&FACTION_AI[u.fac])||FACTION_AI.voidsworn, tw=(u.isSq?.15:!vet?.3:u.flagship?.65:u.hp<u.maxHp*.3?.6*prof.hurt:.32)*prof.tw;
      let score=off-threat*tw;
      if(vet&&!u.isSq&&prof.range){ const nd2=Math.min(99,...foes.filter(f=>!f.isSq).map(f=>hdist(v,f))); if(prof.range>0) score-=Math.max(0,prof.range-nd2)*prof.rw; else score-=Math.max(0,nd2+prof.range)*prof.rw; }
      if(vet&&!u.isSq&&RAM_FAC[u.fac]) score+=ramSetup(v,u)*.35;
      if(vet&&B.obj&&B.obj.type==='flagship'&&!u.flagship&&!u.isSq){ const fl=B.units.find(x=>x.flagship&&!x.dead); if(fl) score-=Math.max(0,hdist(v,fl)-3)*2; }
      if(off<=0){ const hd=Math.min(...foes.filter(f=>!f.isSq||u.isSq).map(f=>hdist(v,f)).concat([99])), nd=Math.max(hd,fieldDist(PF,v,hd)); score-=Math.max(0,nd-minR)*4; } // travel distance, so a hole or a rock wall between us is not a shortcut
      score-=s.cost*.05;
      if(B.obj&&B.obj.type==='hold'&&!u.isSq) score-=hdist(v,B.obj.hex)*1.6;
      score+=aiObjScore(u,v); score+=aiWellScore(u,v);
      if(score>bestScore){ bestScore=score; best=s; }
    }
    let volleyP=null;
    if(best && best.path.length){ const midFire=!u.isSq&&!runner&&!(u.ab==='nova'&&canAbility(u))&&!(typeof animPath==='function'&&typeof process!=='undefined'&&process.env&&process.env.NOMIDFIRE);
      await moveUnit(u,best,midFire?{onLate:()=>{ if(boardTargets(u).length) return; volleyP=aiVolley(u,live); return volleyP; }}:undefined); if(!live()) return; }
    if(volleyP){ const fired=await volleyP; if(!live()||B.over) return; if(!fired && !u.dead && u.hp<u.maxHp*.5 && canOrder(u,'brace') && evalThreat(u,alive('player'))>10){ giveOrder(u,'brace'); } B.aiActive=null; u.activated=true; return; }
    // nova
    if(u.ab==='nova' && canAbility(u)){
      let bh=null, bv=0;
      for(const h of novaTargets(u)){ let v=0; for(const x of alive()){ const d=hdist(x,h); if(d>1) continue; const dm=d===0?40:20; v+= x.side==='player'?dm:-dm*1.5; } if(v>bv){bv=v;bh=h;} }
      if(bh && bv>=40){ await useAbility(u,{hex:bh}); await wait(80); if(!live()) return; }
    }
    if(!u.isSq && !runner && await tacticBoard(u)){ if(live()){ B.aiActive=null; u.activated=true; } return; }
    if(!live()) return;
    if(aiVet()&&!u.isSq&&!u.t.boss&&canOrder(u,'brace')){ const pf=alive('player'), myOff=evalOffense(u,u.weapons.filter(weaponReady),pf), thr=evalThreat(u,pf); if(thr>u.hp*.45&&myOff<thr*.35&&u.hp<u.maxHp*.7){ giveOrder(u,'brace'); B.aiActive=null; u.activated=true; return; } }
    const fired=await aiVolley(u,live); if(fired===null) return;
    if(!fired && !u.isSq && !u.dead && u.hp<u.maxHp*.5 && canOrder(u,'brace') && evalThreat(u,alive('player'))>10){ giveOrder(u,'brace'); }
    B.aiActive=null; u.activated=true;
}
