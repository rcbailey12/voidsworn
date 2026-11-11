// ======================= BATTLE LOGIC =======================
const BW=30, BH=22; // v47: a bigger canvas; each battle's arena (strip, square or round) is cut out of it
const CX=(BW-26)>>1; // shifts the old fixed columns (built for a 26-wide board) onto the middle of the canvas
let ARENA={kind:'strip',mT:3,mB:3,mL:1,mR:1};
let B=null;
const BLOCKING={rock:1,hulk:1,planet:1,station:1};
// one table for what every terrain type is and does: tints, tooltips and the legend all read from it
const TERRAIN_INFO={
  rock:{n:'Asteroids',col:'#bda088',fx:'Blocks movement and line of fire.'},
  hulk:{n:'Wreck',col:'#bda088',fx:'A burning hulk. Blocks movement and line of fire.'},
  station:{n:'Station',col:'#9a948a',fx:'Blocks movement and line of fire.'},
  planet:{n:'Planet',col:'#9a948a',fx:'Blocks movement and line of fire.'},
  neb:{n:'Nebula',col:'#b07cff',fx:'Ships inside are 15 points harder to hit.'},
  debris:{n:'Debris',col:'#d4bf86',fx:'Ships inside are 10 points harder to hit.'},
  storm:{n:'Ion storm',col:'#ffe866',fx:'Ships inside lose 10 shield on every facing each turn and aim 10 points worse.'}};
function terrainPresent(){ const s=new Set(Object.values(B.terrain||{})); return Object.keys(TERRAIN_INFO).filter(k=>s.has(k)); }
// battle variety: board shapes and encounter types
const SHAPES={open:'Open void',corridor:'Corridor',lanes:'Split lanes',ring:'Ring',dense:'Dense field',compact:'Close quarters',deadstar:'Hollow Sun',rift:'Rift',shoals:'Rock shoals',hourglass:'Hourglass',archipelago:'Archipelago',colossus:'Giant wreck'};
const ENC_ROUNDS=6;
function process_env(k){ try{ return typeof process!=='undefined'&&process.env?process.env[k]:undefined; }catch(e){ return undefined; } }
// mid-battle events: at most one per fight, always announced a round ahead
const BEVENTS={
  reinf_enemy:{n:'Enemy reinforcements',warn:'Long-range scan: enemy reinforcements will jump in at the start of round {r}, on their side of the field.',go:'Enemy reinforcements jump in.'},
  reinf_ally:{n:'Friendly reinforcements',warn:'Fleet command: a friendly ship will join you at the start of round {r}, on your side of the field.',go:'A friendly ship jumps in to help. It returns to its own patrol after the battle.'},
  flare:{n:'Solar flare',warn:'The star is flaring. At the start of round {r} every ship on both sides loses its shields for that round.',go:'Solar flare! Every shield on the field is down this round.'}};
function rollBattleEvent(cfg,force){ if(!cfg||cfg.teachingGate===true&&cfg.teachingBattle===1||cfg.kind==='boss') return null; if(cfg.teachingGate===true&&cfg.teachingBattle===2) force='reinf_enemy'; if(!force&&rnd()>.45) return null; return {k:force&&BEVENTS[force]?force:pick(Object.keys(BEVENTS)),warnR:2,r:ri(3,4)}; }
function edgeHex(side){ const bb=boardBounds(), hs=boardHexes(), occ=occMap();
  if(B&&B.approach&&hs.length){ // round and square arenas bring the fleets in at an angle, so the edge is along that angle, not the board columns; the score is the distance along that bearing, so the pick is the free hex furthest out on the fleet's own side (Board, Nov 11: the cosine alone could pick a hex beside the centre)
    const mine=B.units.filter(u=>u.side===side&&!u.isSq&&!u.dead&&!u.treeOff);
    if(mine.length){ let cx=0,cz=0; for(const h of hs){ const p=hexXZ(h); cx+=p.x; cz+=p.z; } cx/=hs.length; cz/=hs.length;
      let mx=0,mz=0; for(const u of mine){ const p=hexXZ(u); mx+=p.x; mz+=p.z; } mx/=mine.length; mz/=mine.length;
      const ang=Math.atan2(mz-cz,mx-cx), dx=Math.cos(ang), dz=Math.sin(ang); let best=null,bd=-1e9;
      for(const h of hs){ if(blocks(terr(h.q,h.r))||occ.has(hkey(h.q,h.r))) continue; const p=hexXZ(h), ux=p.x-cx, uz=p.z-cz, dist=Math.hypot(ux,uz); if(!dist) continue;
        const score=ux*dx+uz*dz; if(score>bd){bd=score;best=h;} } if(best) return best; } }
  const mr=Math.floor((bb.r0+bb.r1)/2), c=side==='player'?bb.c0+1:bb.c1-1; let best=null,bd=1e9;
  for(const h of hs){ const hc=h.q+Math.floor(h.r/2); if(Math.abs(hc-c)>1||blocks(terr(h.q,h.r))||occ.has(hkey(h.q,h.r))) continue; const d=Math.abs(h.r-mr)+Math.abs(hc-c)*.5; if(d<bd){bd=d;best=h;} } return best; }
function cheapHull(fac){ const F=FACTIONS[fac]||FACTIONS.voidsworn; return F.roster.filter(id=>HULLS[id]&&!HULLS[id].boss&&HULLS[id].ab!=='launch').sort((a,b)=>(HULLS[a].cp||1)-(HULLS[b].cp||1)||HULLS[a].hp-HULLS[b].hp)[0]||F.roster[0]; }
function eventTick(){ const e=B.event; if(!e||e.done||B.over) return; const E=BEVENTS[e.k];
  if(B.round>=e.warnR&&!e.warned){ e.warned=true; const m=E.warn.replace('{r}',e.r); log(m,'x'); try{ if(typeof toast==='function') toast(m); }catch(x){} }
  if(B.round<e.r) return; e.done=true;
  if(e.k==='reinf_enemy'||e.k==='reinf_ally'){ const side=e.k==='reinf_enemy'?'enemy':'player', h=edgeHex(side); if(!h){ log('The reinforcements could not find a clear lane and turn back.','x'); return; }
    if(side==='enemy'&&B.nem) nemSig('reinforce'); // R42: a Hegemony Nemesis's reinforcements
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
// R1 (Nov 1, Ryan): never the dead star in sector 1; it stays a set piece for later sectors (sec defaults to the run's sector)
function fitEncounter(n,sec){ if(!n||!n.enc) return; if(n.enc==='defend') n.map='station';
  const s1=(sec!=null?sec:((typeof RUN!=='undefined'&&RUN&&RUN.sector)||1))===1;
  if(n.shape==='deadstar'&&(s1||(n.map&&!DEEP_MAPS.includes(n.map)))){ const sh=ENCOUNTERS[n.enc].shapes.filter(x=>x!=='deadstar'); n.shape=pick(sh.length?sh:['open']); } }
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
// R63 (Ryan, Oct 29): sector flagships get their own objective table. Step one (R1, Nov 1): no Decapitation, which made the hand-built escort pointless;
// the same single pick as before (rout twice as likely as ambush). Boss-only objectives beyond this wait on a design call.
const BOSS_ENC=['rout','rout','ambush'];
function bossEncounter(){ const enc=pick(BOSS_ENC); const sh=['ring','open','hourglass'].filter(s=>ENCOUNTERS[enc].shapes.includes(s)); return {enc,shape:pick(sh.length?sh:['open'])}; }
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
const alive = side => B.units.filter(u=>!u.dead && !u.treeOff && (!side || u.side===side)); // treeOff: a reserve held off the field (Thale B1b)
const caps = side => alive(side).filter(u=>!u.isSq);
function unitAt(q,r){ return B.units.find(u=>!u.dead && !u.treeOff && u.q===q && u.r===r) || null; }
function occMap(){ const m=new Map(); for(const u of B.units) if(!u.dead && !u.treeOff) m.set(hkey(u.q,u.r),u); return m; }
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
const BOSS_FAC={corsair:1.45,voidsworn:1.40,hegemony:.85,chorus:1.10,deathless:1,ithar:.80}; // per-flagship tuning from the boss matrix (v40, retuned v45 at n=12)
let BOSS_SCALE=[0,.5,.55,.7], BOSS_DMG=[0,.85,.88,.95];
try{ if(process_env('BOSS_SCALE')) BOSS_SCALE=JSON.parse(process_env('BOSS_SCALE')); if(process_env('BOSS_DMG')) BOSS_DMG=JSON.parse(process_env('BOSS_DMG')); }catch(e){}
// B2 battle-size ramp (R1): enemy fleets grow by sector toward about 10, 14 and 20 ships on board with a small elite player fleet (4 to 7, wings
// not counted). More ships come mostly from lighter hulls (light: weight on 1 to 2 cp hulls) and a bigger budget (grow); per-ship toughness eases
// a little as numbers rise (thin) so total threat follows the old difficulty curve. Your fleet's power scales the budget both ways (refP), so a
// strong fleet meets more and a battered one less (this replaces the old 'never outgrow the player' floor). ceil is a soft ceiling for
// performance, not a design cap. AI difficulty: Standard meets 10% less. Sims can override any field with RAMP='{...}'.
let RAMP={grow:[0,1.2,1.2,1.24], light:[0,4,4,5], thin:[0,.73,.67,.62], refP:[0,7,12,20], pw:.6, pwMin:.75, pwMax:1.3, ceil:[0,10,14,20], boss:[0,.3,.5,.6], escort:.78, std:.9}; // stream B Oct 27 and Nov 1 (step 9b): sectors 2 and 3 eased (grow 1.25/1.35 to 1.2/1.24, thin .68/.64 to .67/.62, boss escorts .55/.65 to .5/.6) to bring sim full-run wins from 13.5% back to about 20% with the bosses still a fight; sector 1 unchanged // tuned Oct 25 against the B0 baseline (campaign sim; sector 1 boss escorts held near the old .28 for the boss matrix)
try{ if(process_env('RAMP')) Object.assign(RAMP,JSON.parse(process_env('RAMP'))); }catch(e){ console.warn('RAMP override ignored (not valid JSON):',e.message); }
function effArch(arch,fac){ if(arch==='carrier'){ const F=FACTIONS[fac]; if(!F||!F.roster.some(id=>HULLS[id]&&HULLS[id].ab==='launch')) return 'heavy'; } return arch||null; }
function genEnemyFleet(fac,s,col,kind,arch,mod){ arch=effArch(arch,fac);
  // each map column has a fixed difficulty, so a fleet that grows can outgrow it (the point of buying that cruiser)
  const F=FACTIONS[fac]; let budget=([0,4.2,9.5,14][s]+col*(s===1?0.9:s===2?1:1.1))*RAMP.grow[s]; if(kind==='elite') budget*=1.05;
  const list=[];
  if(kind==='boss'){ list.push({tpl:F.boss}); budget*=RAMP.boss[s]; }
  // B2: your fleet's power scales the budget both ways around the sector's reference fleet (was: a battered fleet met less, a strong one never more)
  if(typeof RUN!=='undefined'&&RUN&&RUN.fleet&&!(typeof NO_CAP!=='undefined'&&NO_CAP)){ budget*=Math.max(RAMP.pwMin,Math.min(RAMP.pwMax,Math.pow(Math.max(.5,fleetPower())/RAMP.refP[s],RAMP.pw))); }
  if(typeof AI_LEVEL!=='undefined'&&AI_LEVEL==='standard') budget*=RAMP.std;
  if(heatOn('h_hunted')) budget*=1.15;
  if(mod==='bounty') budget*=1.1;
  let roster=F.roster.map(id=>({id,cp:HULLS[id].cp,car:HULLS[id].ab==='launch'}));
  // archetypes reshape the same budget: a swarm of the lightest hulls, a heavy line, or a carrier with its escort
  if(arch==='swarm'){ const mn=Math.min(...roster.map(x=>x.cp)); const light=roster.filter(x=>x.cp<=mn+1&&!x.car); if(light.length) roster=light; }
  if(arch==='heavy'){ const big=roster.filter(x=>x.cp>=2&&(!x.car||!roster.some(y=>y.cp>=3&&!y.car))); if(big.length&&budget>=Math.min(...big.map(x=>x.cp))){ const top=big.filter(x=>x.cp<=budget+.3).sort((a,b)=>b.cp-a.cp)[0]; if(top){ list.push({tpl:top.id}); budget-=top.cp; } roster=big.concat(roster.filter(x=>x.cp<2&&!x.car).slice(0,1)); } }
  if(arch==='carrier'&&kind!=='boss'){ const cr=roster.filter(x=>x.car&&x.cp<=budget+.3).sort((a,b)=>b.cp-a.cp)[0]; if(cr){ list.push({tpl:cr.id}); budget-=cr.cp; roster=roster.filter(x=>!x.car); } }
  let g=0;
  const ceil=RAMP.ceil[s]-((typeof RUN!=='undefined'&&RUN&&RUN.fleet)?Math.min(7,RUN.fleet.filter(sh=>sh.hp>0).length):4); // soft ceiling on ships on board, both sides
  while(budget>=1 && list.length<Math.max(4,ceil) && g++<80){
    const opts=roster.filter(x=>x.cp<=budget+.3); if(!opts.length) break;
    const wts=opts.map(x=> arch==='heavy'?Math.pow(x.cp,1.6):(x.cp===1?1.1:Math.min(2,budget/(x.cp*2))+.35)*(x.cp<=2&&arch!=='swarm'?RAMP.light[s]:1));
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
  // First teaching fight: one connected feature at the top edge, clear of both fleets.
  if(opt.edgeFeature){ const hs=boardHexes().filter(h=>onBoard(h.q,h.r)), r=Math.min(...hs.map(h=>h.r))+1, c=offToAx(Math.floor(BW/2),r);
    const feature=opt.enc==='defend'?'station':'rock';
    for(const h of [c,{q:c.q+1,r:c.r},{q:c.q,r:c.r+1}]) if(onBoard(h.q,h.r)) T[hkey(h.q,h.r)]=feature;
    if(feature==='station') TERRAIN_META.station=c;
    TERRAIN_META.shape='open'; return T; }
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
function wellTick(u,dq){ const W=B&&B.well; if(!W||u.isSq||u.dead) return; const d=hdist(u,W); u.gravAssist=false;
  if(d<=WELL_ASSIST){ u.mp+=1; u.gravAssist=true; }
  if(d<=WELL_RIM){ u.hp-=WELL_DMG; if(typeof fxText==='function') fxText(u,'Tidal stress \u2212'+WELL_DMG,'#c79bff'); if(u.hp<=0){ u.hp=0; log(`${u.name} is torn apart by the Hollow Sun's gravity.`, u.side==='player'?'e':'p'); u.killCause='tidal'; queueDeath(u,dq); return 'dead'; } }
  else if(d<=WELL_PULL){ const occ=occMap(); let best=null; for(const dd of DIRS){ const n={q:u.q+dd[0],r:u.r+dd[1]}; if(hdist(n,W)!==d-1||!onBoard(n.q,n.r)||blocks(terr(n.q,n.r))||occ.has(hkey(n.q,n.r))) continue; best=n; break; }
    if(best){ const from={q:u.q,r:u.r}; u.q=best.q; u.r=best.r; if(typeof fxGravPull==='function') fxGravPull(u,from); if(typeof fxText==='function') fxText(u,'Dragged by gravity','#c79bff'); } } }
function aiWellScore(u,v){ const W=B&&B.well; if(!W||u.isSq) return 0; const d=hdist(v,W); return d<=WELL_RIM?-45:d<=WELL_PULL?-6:0; }
function B0small(cfg){ if(typeof process!=='undefined'&&process.env&&process.env.NOCOMPACT) return false; return cfg.kind!=='boss'&&!!(RUN&&RUN.fleet)&&RUN.fleet.filter(x=>x.hp>0).length<=2; }
// no fleet starts boxed in: clear rocks and wrecks around each ship and along a lane toward the enemy
function clearSpawns(){ if(process_env('NOCLEAR')==='1') return; const T=B.terrain; let n=0;
  const midR=Math.floor(BH/2), mid=offToAx(Math.floor(BW/2),midR);
  // Q11 (Oct 29): clearing is shape-aware, so a shape's defining centre terrain is never deleted
  const def=(q,r)=> B.shape==='ring'?hdist({q,r},mid)<=2 : B.shape==='lanes'?(r===midR||r===midR-1) : false;
  const clr=(q,r)=>{ const k=hkey(q,r), t=T[k]; if((t==='rock'||t==='hulk')&&!def(q,r)){ delete T[k]; n++; } };
  const near=(h,R)=>{ for(let dq=-R;dq<=R;dq++) for(let dr=Math.max(-R,-dq-R);dr<=Math.min(R,-dq+R);dr++) clr(h.q+dq,h.r+dr); };
  for(const side of ['player','enemy']){ const mine=B.units.filter(u=>u.side===side&&!u.isSq&&!u.transport), foes=B.units.filter(u=>u.side!==side&&!u.isSq); if(!mine.length||!foes.length) continue;
    const cq=foes.reduce((a,u)=>a+u.q,0)/foes.length, cr=foes.reduce((a,u)=>a+u.r,0)/foes.length, tgt={q:Math.round(cq),r:Math.round(cr)};
    for(const u of mine){ near(u,side==='player'?2:1); const line=hexLine(u,tgt), L=Math.min(line.length-1,side==='player'?6:4); for(let i=1;i<=L;i++) near(line[i],i<=3&&side==='player'?1:0); } }
  if(B.map&&B.map.wrecks) B.map.wrecks=B.map.wrecks.filter(h=>T[hkey(h.q,h.r)]==='hulk'); B.spawnCleared=n; }
function startBattle(cfg){
  const seed=cfg.seed!=null?(cfg.seed>>>0):Math.floor(rnd()*4294967296); rndSeed(seed);
  const enc=ENCOUNTERS[cfg.obj]?cfg.obj:'rout', midR=Math.floor(BH/2);
  let shape=SHAPES[cfg.shape]?cfg.shape:'open', map=enc==='defend'?'station':cfg.map;
  if(shape==='open'&&!cfg.edgeFeature&&B0small(cfg)&&['rout','hunt','ambush'].includes(enc)) shape='compact'; // small fleets fight in close quarters
  if(!['belt','station','planet','storm','graveyard'].includes(map)&&FAC_MAP[cfg.fac]&&rnd()<.55) map=pick(FAC_MAP[cfg.fac]); // each faction has home ground
  if((shape==='lanes'||shape==='ring')&&map==='belt') map=pick(['station','planet','storm','graveyard']);
  // v47 arenas and approaches: only the strip has a fixed left-to-right axis; squares and round fields bring the fleets in at an angle, crossing or in a pincer
  const axisFree=['rout','hold','flagship'].includes(enc)&&cfg.kind!=='boss'&&shape!=='compact'&&!(cfg.dep==='ambush');
  const wpick=l=>{ let x=rnd()*l.reduce((a,e)=>a+e[1],0); for(const [k,w] of l){ x-=w; if(x<=0) return k; } return l[0][0]; };
  const ak=ARENAS[cfg.arena]?cfg.arena:(axisFree&&ENC_ARENA[enc]?wpick(ENC_ARENA[enc]):'strip'); ARENA=Object.assign({kind:ak},ARENAS[ak]);
  if(shape==='deadstar'&&(cfg.noStar||['belt','station','planet'].includes(map))&&!cfg.keepShape){ const sh=(ENCOUNTERS[enc]||ENCOUNTERS.rout).shapes.filter(x=>x!=='deadstar'); shape=pick(sh.length?sh:['open']); } // R1: cfg.noStar (campaign sector 1) never fields the dead star
  if(ak!=='strip'&&AXIS_SHAPES.includes(shape)) shape=pick(cfg.noStar?['open','dense','shoals','archipelago','colossus','ring']:['open','dense','deadstar','shoals','archipelago','colossus','ring']);
  let approach=null; if(ak==='square') approach={k:rnd()<.6?'diagonal':'cross'}; else if(ak==='round') approach={k:rnd()<.4?'headon':rnd()<.5?'cross':'pincer'};
  if(approach){ approach.th=ak==='square'?(approach.k==='diagonal'?(rnd()<.5?1:-1)*(Math.PI/4+(rnd()-.5)*.35):(rnd()<.5?0:Math.PI/2)*(rnd()<.5?1:-1)):rnd()*Math.PI*2; if(cfg.approach) approach.k=cfg.approach; }
  const topt={edgeFeature:!!cfg.edgeFeature,cond:cfg.kind==='boss'?null:sectorCond(),stationAt:enc==='defend'?offToAx(9+CX,midR):null,enc,pieces:{belt:['asteroid','asteroid','comet','station'],graveyard:['hulk','hulk','station','asteroid'],planet:['moon','moon','asteroid','station'],station:['station','station','hulk','asteroid'],storm:['comet','asteroid','asteroid','moon']}[map]||null};
  let T=null; for(let k=0;k<6;k++){ T=genTerrain(map,shape,topt); if(terrainConnected(T)) break; T=null; }
  if(!T){ shape='open'; T=genTerrain(map,'open',topt); }
  if(cfg.kind==='boss') for(const k of Object.keys(T)) if(T[k]==='rock'&&rnd()<.45) delete T[k]; // flagship duels need firing lanes, not a maze
  B={seed, units:[], terrain:T, map:TERRAIN_META, shape, enc, arena:ARENA.kind, biome:cfg.biome||(RUN&&RUN.map&&RUN.map.biome)||rollBiome(null), approach, well:shape==='deadstar'&&TERRAIN_META.deadstar?{q:TERRAIN_META.deadstar.q,r:TERRAIN_META.deadstar.r}:null, deployMode:enc==='ambush'?'ambush':['defend','hunt','intercept','break'].includes(enc)?'line':(cfg.dep||'line'), resolve:{player:1,enemy:1}, round:1, side:'player', sel:null, armed:null, mode:null, hover:null, reach:null,
     busy:false, log:[], fx:[], cfg, over:false, reviveUsed:false, inspect:null, showArcs:true, showThreat:false, called:null, wingSel:null, activeUnit:null, sector:RUN.sector}; { const sc=sectorCond(); B.cond=sc&&RUN&&RUN.map?RUN.map.cond:null; B.condRegen=(sc&&sc.regen)||1; }
  B.tree=treeBuild(); B.treeStats={}; B.treeChoices=cfg.treeChoices||null; B.treePending=[]; B.treeFlaw=null; B.treeLens=null; B.treeFlakSkip=null;
  B.treeReserve=[]; B.treePrey=null; B.treeNamedPrey=null; B.treeIronExtra=null; B.treeFiled=null; B.treePermFile=null;
  B.treeOneVoiceUsed=0; B.treeDrillUsed=0; B.treeStrikeRound=0; B.treeDebtRound=0; B.treeForgeRound=0;
  B.tr={r:1,enemyShots:{},volleyHits:{},logged:{},falseHulls:0,glassUsed:0,firstLight:null,volleyPick:{},carrierHit:{},wingsDebt:{},standardUsed:0,ledgerUsed:0,escortUsed:{},frameZeroUsed:0,targeted:{},targetedLast:{},iterKill:{},indexTarget:null,swarmHitBy:{},volleyShips:{},volleyHit:{},burnStays:null,firstThroatUsed:0,smileUsed:0,rearShips:{},wingStruck:{},hitRound:{},firstScarUsed:0,nothingSaved:0,scent:null,bigId:null,
    syncFirst:{player:null,enemy:null},secondVolleyUsed:0,secondVolleyAutoDone:0,rollingUsed:0,strikeSpeed:null,strikeSpeedId:null,crossHits:{},totalShips:{},hitDuringStrike:{},bellUsed:0,columnUsed:0,firstStopTarget:null,firstStopDone:0,wingFiled:null,escortScreen:0,beacon:null,
    carrierLast:{},wingTgt:{},wingTargets:{},lightTgt:{},wingCap:{},wingCapFirst:{},grandUsed:0,grandTarget:null,grandFirstDone:0,sunTarget:null,sunFirstDone:0,oneLens:null,fleetElsewhere:0};
  const s=RUN.sector;
  for(const ship of RUN.fleet){ if(ship.hp<=0) continue; B.units.push(makeUnit('player', ship.tpl, {ship})); }
  const eList = cfg.enemies || genEnemyFleet(cfg.fac, s, cfg.col, cfg.kind, cfg.arch, cfg.mod);
  const sc=1+.12*(s-1), dm=1+.08*(s-1);
  const bossFit=Math.max(.55,Math.min(1,playerStrength()/([0,6,9,12][s]||12))); // a battered fleet faces a weakened flagship
  const eliteIdx=cfg.kind==='elite'?new Set(eList.map((e,i)=>[i,HULLS[e.tpl].cp||1]).sort((x,y)=>y[1]-x[1]).slice(0,Math.ceil(eList.length/2)).map(x=>x[0])):null; // elite fights: the bigger half of their fleet are elites
  const thin=cfg.enemies?1:(RAMP.thin[s]||1)*(cfg.kind==='boss'?RAMP.escort:1); // boss fights: the escorts are leaner still, the flagship is the fight // B2: generated fleets are bigger, so each ship is a little less tough (set fleets from sims or events are not)
  eList.forEach((e,ei)=>B.units.push(makeUnit('enemy', e.tpl, {scale:sc*(HULLS[e.tpl].boss?BOSS_SCALE[s]*bossFit*(BOSS_FAC[cfg.fac]||1)*(heatOn('h_flag')?1.2:1):thin), dmg:dm*(HULLS[e.tpl].boss?BOSS_DMG[s]:thin), elite:!!(eliteIdx&&eliteIdx.has(ei))||cfg.kind==='boss'&&!HULLS[e.tpl].boss&&rnd()<.3||heatOn('h_elite')&&ei===(HULLS[eList[0].tpl].boss&&eList.length>1?1:0)||cfg.mod==='veteran'&&ei===eList.map((x,i)=>[i,HULLS[x.tpl].cp||1]).sort((x,y)=>y[1]-x[1])[0][0], fac:cfg.fac})));
  if(heatOn('h_undying')) for(const u of B.units) if(u.side==='enemy'&&!u.isSq&&!u.t.boss) u.reanimate=true;
  // enemies adapt to carrier-heavy fleets: escorts bolt on point defense
  { const nCar0=RUN.fleet.filter(sh=>sh.hp>0&&HULLS[sh.tpl]&&HULLS[sh.tpl].hangar).length, carDoc=(ADMIRALS[RUN.admiral]&&ADMIRALS[RUN.admiral].cmd&&ADMIRALS[RUN.admiral].cmd.id==='scramble')||RUN.aspect==='hive';
    const hiveFlag=RUN.aspect==='hive'&&!RUN.fleet.some(sh=>sh.uid===RUN.flagUid&&sh.hp>0&&HULLS[sh.tpl]&&HULLS[sh.tpl].hangar); // PP-2: a hive flagship flies a wing with no hangar, so it is a carrier hull too
    const carriers=nCar0+(hiveFlag?1:0), nCar=carriers+(carDoc&&carriers>=1?1:0); /* a carrier admiral or a hive flagship counts as a second carrier: one hull with doctrine still draws a response */
    if(nCar>=2&&(!cfg.enemies||process_env('ADAPT')==='1')&&process_env('NOADAPT')!=='1'){ const pd=cfg.fac==='chorus'?'spores':'flak', cand=B.units.filter(u=>u.side==='enemy'&&!u.t.boss&&!u.isSq&&!u.weapons.some(w=>w.k==='flak')).sort((x,y)=>(y.t.cp||1)-(x.t.cp||1));
      const n=Math.min(cand.length,nCar>=3?cand.length:Math.ceil(cand.length/2)); for(const u of cand.slice(0,n)){ u.weapons.push(Object.assign(nameWeapons(u.fac,[mkWeapon(pd,'T',u.fx||{})])[0],{fired:false,cdLeft:0,off:0})); u.pdRefit=true; } // B-21 (Oct 26): the refit gun gets the per-battle fields every other gun has, so it fires and intercepts wings
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
  treeBattleStart();
  if(process_env('NOPRELAUNCH')!=='1') deployWings();
  B.cp0={player:sideCP('player'),enemy:sideCP('enemy')};
  B.usage={fire:{},aim:0,ab:{},ord:{},cmd:0,moves:0,cant:{}}; // what the player actually uses, for telemetry
  setupObjective(cfg.obj);
  setupFactionRules(); // B3: Hegemony anchors, the Deathless legion count, the torpedo list
  if(cfg.nemesis) applyNemesis(cfg.nemesis); if(cfg.verb) applyVerb(cfg.verb); // B4: the Nemesis's own fleet; a faction verb readied on the map
  if(B.adapt||B.adaptWings) log(`Scouts report your carriers. The enemy ${B.adapt?`bolted extra point defense onto ${B.adapt>1?B.adapt+' ships':'one ship'}`:''}${B.adapt&&B.adaptWings?' and ':''}${B.adaptWings?`launched ${B.adaptWings>1?'two fighter wings':'a fighter wing'} to hunt your craft`:''}.`,'ember');
  startSideTurn('player');
  for(const u of alive('enemy')) u.intercepts=u.weapons.some(w=>w.k==='flak')?Math.max(0,2-(u.treeFlakDown||0)):0;
  const F=FACTIONS[cfg.fac];
  log(`Contact: ${F.n}. ${eList.length} ship${eList.length>1?'s':''} on the scanners.`, 's');
  if(B.well) log('The Hollow Sun warps this field. Ships that start a turn near it get +1 movement from the slingshot, but it drags close ships inward and tears at any hull on its rim.','ember');
  if(cfg.kind==='elite') log('Elite captains command this fleet.', 'e');
  if(cfg.kind==='boss') log(`${HULLS[F.boss].n} is here. Everything else is escort.`, 'e');
  for(const line of storyModifierLines()) log(line,'ember');
}

function storyDamageMult(u){ const m=B&&B.cfg&&B.cfg.storyMods; return !m||u.side!=='player'?1:(1+(m.dmgPct||0))*(m.power&&u.pflag?1+BEAT3_REWARDS.power:1); }
function storyModifierLines(u){
  const m=B&&B.cfg&&B.cfg.storyMods, out=[]; if(!m||u&&u.side!=='player') return out;
  if(m.power&&(!u||u.pflag)) out.push('Flagship weapon damage +25% this battle.');
  if(m.dmgPct) out.push(`Fleet damage ${m.dmgPct>0?'+':''}${Math.round(m.dmgPct*100)}% this battle.`);
  if(m.syncDown) out.push(B.round===1?'Synchronized fire off in round 1. Returns in round 2.':'Synchronized fire restored from round 2.');
  return out;
}

function gainResolve(side,n){ if(!B.resolve) B.resolve={player:0,enemy:0}; B.resolve[side]=Math.min(5,(B.resolve[side]||0)+n); }
function escortsBreak(){ if(!B.cfg||B.cfg.kind!=='boss'||B.escortsFled) return; const boss=B.units.find(u=>u.boss&&u.side==='enemy'&&!u.dead); if(!boss||boss.hp>boss.maxHp*.5) return;
  const esc=alive('enemy').filter(u=>u!==boss&&!u.isSq); B.escortsFled=true;
  for(const e of esc){ e.dead=true; e.fled=true; if(typeof fxWithdraw==='function') fxWithdraw(e); } boss.regen=0; boss.hullRegen=0; boss.reanimate=false; boss.sh=boss.sh.map(v=>Math.round(v*.5)); boss.burning=true;
  log(`${boss.name} is burning. ${esc.length?'Its escorts break off and flee. ':''}Its shields falter and it can no longer repair itself.`,'s'); }
function startSideTurn(side){
  const deaths=[]; // v53: ships killed by the turn's ticks; the caller awaits the returned promise so their deaths finish in order
  if(side==='player') treeRoundStart();
  if(side==='player'&&B.round>1){ eventTick(); objectiveTick(deaths); }
  if(side==='enemy'){ try{ aiRefreshFocus(); }catch(e){} try{ bossCmdTick(); }catch(e){} } // v53-D: the fleet focus is kept (sticky) and re-checked, not wiped, each enemy turn
  escortsBreak(); nemBreak(); if(side==='enemy'){ nemFleeCheck(); if(B.round>=2&&B.nem) nemTrip('slow'); } // B4: a proud Nemesis flagship's escorts flee; R42: a Corsair or Ithar Nemesis withdraws from a lost fight
  if(side==='enemy') for(const u of B.units) if(u.side==='enemy'&&!u.dead&&!u.isSq) aiStance(u); // B4 wing doctrines: the enemy picks its stances
  gainResolve(side,1); let burned=false;
  const risen=legionTurn(side); // B3 Deathless: ships reassembling since last round stand up now
  for(const u of B.units){
    if(u.dead||u.side!==side) continue;
    if(u.isSq) u.activated=false;
    u.braced=false; u.coverBy=null; u.postFire=false; u.postMp=0; u.pivotUsed=false; u.lockOn=false; u.focus=false; u.fullAhead=false; u.noTurn=false; u.evBuff=0; u.order=null; u.ramBoost=0;
    u.mp=Math.max(1,u.speed-u.st.engine); u.turnsLeft=u.turns;
    if(side==='player'&&u.burnCarry){ u.mp+=u.burnCarry.mp||0; u.turnsLeft+=u.burnCarry.turns||0; } // Grax capstone 1: the last burn carries over
    for(const w of u.weapons){ w.fired=false; if(w.cdLeft>0) w.cdLeft--; if(w.off>0) w.off--; }
    if(u.abCd>0) u.abCd--;
    if(u.st.shieldOff>0) u.st.shieldOff--; else if(u.shMax>0){ const rg=u.regen*(((typeof B!=='undefined'&&B&&B.condRegen)||1)); for(let i=0;i<4;i++) if(!(u.regenLock&&u.regenLock[i])) u.sh[i]=Math.min(u.shMax,u.sh[i]+rg); }
    ithChargeTurn(u); u.regenLock=null; // B3 Ithar prism charge (after the normal regen); an ion lock lasts one turn start
    if(u.hullRegen && u.hp<u.maxHp && !u.pyre){ u.hp=Math.min(u.maxHp,u.hp+u.hullRegen); treeMarkRepair(u); }
    if(u.st.acid>0&&!u.isSq){ u.st.acid--; u.hp-=4; if(typeof fxText==='function') fxText(u,'Acid \u22124','#c8e04a',-12); if(u.hp<=0){ u.hp=0; burned=true; log(`${u.name} dissolves.`, u.side==='player'?'e':'p'); u.killCause='melt'; queueDeath(u,deaths); } }
    if(u.st.fire>0&&!u.dead){ const fd=u.st.fireDmg||6; u.st.fire--; u.hp-=fd; if(typeof fxText==='function') fxText(u,'Fire \u2212'+fd,'#f08a4b'); if(u.hp<=0){ u.hp=0; burned=true; log(`${u.name} burns out.`, u.side==='player'?'e':'p'); u.killCause='dark'; queueDeath(u,deaths); } if(!u.st.fire) u.st.fireDmg=0; }
    u.hexMoved=0; if(u.fx&&u.fx.stormRegen&&u.shMax>0&&!(u.st.shieldOff>0)){ for(let i=0;i<4;i++) u.sh[i]=Math.min(u.shMax,u.sh[i]+Math.round(u.shMax*u.fx.stormRegen)); }
    u.intercepts = u.weapons.some(w=>w.k==='flak')?Math.max(0,2-(u.treeFlakDown||0)):0;
    u.boarded=false; u.rammed=false; u.emerg=false; u.repel=false;
    if(terr(u.q,u.r)==='storm'&&!u.isSq&&u.shMax>0){ for(let i=0;i<4;i++) u.sh[i]=Math.max(0,u.sh[i]-10); if(typeof fxText==='function') fxText(u,'Ion storm','#9fb8ff',-24); }
    if(u.crewMax&&u.crew<=0){ u.mp=0; u.turnsLeft=0; for(const w of u.weapons) w.fired=true; }
    if(B.well&&wellTick(u,deaths)==='dead') burned=true;
  }
  if(B.event&&B.event.k==='flare'&&B.round===B.event.r&&B.event.done) for(const u of B.units){ if(!u.dead&&u.side===side&&u.shMax>0) u.sh=[0,0,0,0]; }
  for(const u of risen) for(const w of u.weapons) w.fired=true; // a reassembled ship cannot fire the round it rises
  if(burned) checkEnd(); // a ship that burned out can decide the battle at the turn boundary
  if(side==='player'&&!B.over) replaceWings(side);
  return deaths.length?settleDeaths(deaths):null;
}
// v53: a death from a rules tick (fire, acid, the dead star, station guns) starts now, so its state changes land at once, and is awaited in order by the turn flow
function queueDeath(u,dq){ const p=Promise.resolve(killUnit(u,null)).catch(e=>console.error(e)); if(dq) dq.push(p); return p; }
async function settleDeaths(dq){ for(const p of dq) await p; }

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
  const baseMP=postFireMp(u), mb=treeMoveBonus(u); // Razormaw T2a: +1 movement, but only for a move that ends closer to the named prey
  const scar=!!(treeSkill('allScars')&&u.side==='player'&&!u.isSq&&cmdActive(u.side,'surge')); // Grax T3a: +1 movement per enemy passed adjacent
  const loose=!!(treeSkill('loosePack')&&u.side==='player'&&!u.isSq); // Hullbreakers shared B1b: +1 for a move that ends with no friendly within 2
  const fwd=!!(treeSkill('standardForward')&&u.side==='player'&&!u.isSq&&treeFlagUnit()); // Hegemony shared C1b: +1 for a path that stays no further from the flagship
  const dive=!!(treeSkill('mirrorAside')&&u.side==='player'&&!u.isSq&&cmdActive(u.side,'surge')&&!u.treeDiveUsed); // Vell T2a: one enemy hex dived free during the scatter
  const occ=occMap(), R=moveRules(u), MP=baseMP+mb+(scar?2:0)+(loose?1:0)+(fwd?1:0), noOver=!!u.postFire; // B4 step 3: after firing only the Ithar (or Slip the Net) may move, half what was left, no climbing or diving
  const sk=s=>s.q+','+s.r+','+s.f+','+s.t+(scar?('|'+((s.passed||[]).join('-'))):'');
  const passAdd=(s,nq,nr)=>{ if(!scar) return null; const out=(s.passed||[]).slice(); for(const e of alive('enemy')){ if(e.isSq) continue; if(hdist({q:nq,r:nr},e)===1&&!out.includes(e.id)) out.push(e.id); } out.sort(); return out; };
  const friendlyNear2=(q,r)=>alive('player').some(x=>x.id!==u.id&&!x.isSq&&hdist({q,r},x)<=2);
  const allowed=s=>s.cost<=baseMP+mb+(scar?Math.min(2,(s.passed||[]).length):0)+(loose&&!friendlyNear2(s.q,s.r)?1:0)+(fwd&&treePathTowardFlag(u,s)?1:0);
  const start={q:u.q,r:u.r,f:u.facing,t:0,cost:0,path:[],passed:scar?[]:null};
  const seen=new Map([[sk(start),0]]); const queue=[start]; let qi=0;
  const pivotFree=R.pivot&&!u.pivotUsed;
  while(qi<queue.length){
    const s=queue[qi++]; if(seen.get(sk(s))<s.cost) continue; if(!allowed(s)) continue; states.push(s);
    if(s.cost>=MP) continue;
    const nexts=[];
    if(u.isSq){ for(let f=0;f<6;f++){ const d=DIRS[f]; const nq=s.q+d[0], nr=s.r+d[1];
      if(passable(u,nq,nr,occ)) nexts.push({q:nq,r:nr,f,t:s.t,cost:s.cost+1,path:[...s.path,{q:nq,r:nr,f}]}); } }
    else {
      const opts=[[s.f,1,null],[(s.f+1)%6,R.slip,'slip'],[(s.f+5)%6,R.slip,'slip'],[(s.f+3)%6,R.rev,'rev']];
      for(const [df,c0,kind] of opts){ const d=DIRS[df], nq=s.q+d[0], nr=s.r+d[1]; if(!onBoard(nq,nr)) continue;
        // a heavy hull with too little movement can still spend all of it on one thruster hop
        let c=kind&&s.cost===0?Math.min(c0,MP):c0; let over=0; const tt=terr(nq,nr);
        if(blocks(tt)){ if(tt!=='rock'&&tt!=='hulk') continue; over=1; }
        const o=occ.get(hkey(nq,nr)); if(o&&o.side!==u.side) over=over||-1; // climb over terrain, dive under ships
        let dived=false;
        if(over){ if(noOver) continue; if(over<0&&dive&&!(s.dived||0)){ dived=true; } else c+=R.over; } // Vell T2a: the first enemy hex dived is free
        if(s.cost+c>MP) continue;
        const st={q:nq,r:nr,f:s.f}; if(kind) st[kind]=1; if(kind==='slip') st.side=df===(s.f+1)%6?1:-1; if(over) st.over=over; if(dived) st.dived=1;
        nexts.push({q:nq,r:nr,f:s.f,t:s.t,cost:s.cost+c,path:[...s.path,st],slips:(s.slips||0)+(kind==='slip'?1:0),revs:(s.revs||0)+(kind==='rev'?1:0),overs:(s.overs||0)+(over?1:0),dived:(s.dived||0)+(dived?1:0),passed:passAdd(s,nq,nr)}); }
    }
    if(!u.isSq && !u.noTurn && s.t<u.turnsLeft){
      const tc=pivotFree&&s.t===0?0:1; if(s.cost+tc<=MP||tc===0)
      for(const dd of [1,-1]){ const f=(s.f+dd+6)%6; nexts.push({q:s.q,r:s.r,f,t:s.t+1,cost:s.cost+tc,path:[...s.path,{q:s.q,r:s.r,f,rot:true}],slips:s.slips,revs:s.revs,overs:s.overs,passed:s.passed}); }
    }
    for(const n of nexts){ const k=sk(n); if(seen.has(k)&&seen.get(k)<=n.cost) continue; seen.set(k,n.cost); queue.push(n); }
  }
  const prey=mb>0?treePrey():null;
  const ok=states.filter(s=>seen.get(sk(s))===s.cost&&canEnd(u,s.q,s.r,occ)&&(!prey||s.cost<=baseMP||hdist({q:s.q,r:s.r},prey)<hdist(u,prey)));
  for(const s of ok){ if(s.q===u.q&&s.r===u.r) continue; const k=hkey(s.q,s.r);
    const c=map.get(k); if(!c || s.cost<c.cost || (s.cost===c.cost&&s.t<c.t)) map.set(k,s); }
  return {map, states:ok};
}
// v51 fire on the move: opts.onLate runs about two-thirds of the way through the burn, after the rules have already put the ship
// on its destination hex, so guns open up while the hull is still travelling (the maths is identical to firing after the move)
async function moveUnit(u, state, opts){
  if(!inThisBattle(u)) return; const live=liveFrom(null);
  const path=state.path; let committed=false; const fg=treeSkill('standardForward')?treeFlagUnit():null, fgD0=fg?hdist(u,fg):0;
  const commit=()=>{ if(committed) return; committed=true; for(const st of path) if(!st.rot){ u.q=st.q; u.r=st.r; } u.facing=path.at(-1).f;
    u.mp=Math.max(0,u.mp-state.cost); if(u.postFire) u.postMp=Math.max(0,(u.postMp||0)-state.cost); u.turnsLeft-=state.t; if(state.t>0&&moveRules(u).pivot) u.pivotUsed=true; u.moved=true; u.hexMoved=(u.hexMoved||0)+path.filter(p=>!p.rot).length; if(u.treeWarlord===1){ u.treeWarlord=2; u.mp+=state.cost; u.postMp=Math.max(u.postMp||0,state.cost); } if(state.passed&&state.passed.length) treeFx(u,'allScars','the scars carry'); if(path.some(p=>p.dived)){ u.treeDiveUsed=1; treeFx(u,'mirrorAside','the mirror steps aside'); } if(B.usage&&u.side==='player'&&!u.isSq) B.usage.moves++; treeAfterMove(u); if(fg) treeMoveTowardFlag(u,path,fgD0); };
  let lateP=null; const onLate=opts&&opts.onLate?()=>{ if(!live()) return; commit(); try{ lateP=Promise.resolve(opts.onLate()).catch(e=>console.error(e)); }catch(e){ console.error(e); } }:null;
  if(typeof animPath==='function'){ await animPath(u,path,onLate?{onLate}:undefined); if(B) B.prog=(B.prog||0)+1; if(lateP) await lateP; if(!live()) return; if(u.side==='enemy'&&!u.isSq) await treePatrolStrike(u); if(committed){ await treeHeldFire(u); objAfterMove(u); return; } } // one continuous burn
  else for(const st of path){
    if(st.rot){ if(typeof animRotate==='function') await animRotate(u, st.f); }
    else { if(typeof animMove==='function') await animMove(u, st.q, st.r, st.f); }
    if(B) B.prog=(B.prog||0)+1; // progress for the busy watchdog
    if(!live()) return;
  }
  commit();
  if(u.side==='enemy'&&!u.isSq) await treePatrolStrike(u);
  await treeHeldFire(u);
  objAfterMove(u);
}
// v54 doctrine (decided): ships move, then fire; the Ithar may still move after firing, up to half the movement they had left, with no climb or dive.
// The Slip the Net boon gives every ship that. u.postFire is set by the first shot of an activation (fireWeapon) and cleared at turn start.
function canFade(u){ return u.fac==='ithar'||!!(u.fx&&u.fx.fade); }
function treeFullFade(u){ return !!(treeSkill('splitThree')&&u&&u.side==='player'&&!u.isSq&&!u.dead&&cmdActive(u.side,'surge')); } // Vell T2b: full remaining movement after firing in the scatter
function postFireMp(u){ return u.postFire?Math.min(u.mp,u.postMp||0):u.mp; }
function freePivot(u){ return !!(moveRules(u).pivot&&!u.pivotUsed); }
function canRotate(u){ return !u.dead && !u.isSq && !u.noTurn && (u.turnsLeft>0||u.treeFreeTurn>0) && (u.mp>0||freePivot(u)||u.treeFreeTurn>0) && !u.braced; }
async function rotateUnit(u,dir){ if(!canRotate(u)||!inThisBattle(u)) return; const live=liveFrom(u), f=(u.facing+dir+6)%6; const free=u.treeFreeTurn>0; if(free) u.treeFreeTurn=0; else if(freePivot(u)) u.pivotUsed=true; else u.mp--; if(!free) u.turnsLeft--; u.moved=true; if(typeof animRotate==='function') await animRotate(u,f); if(!live()) return; u.facing=f; treeAfterMove(u); } // v53: facing commits after the live check, like moveUnit; a free turn (Sable T2a, shared C1b) costs nothing

// ---------- B3 faction identity (Oct 26; numbers are Claude's calls, vetoable) ----------
// One rule per faction on top of the drives (MOVE_RULES) and gates (FAC_GATES in data.js). Every rule keys off the hull's own faction (u.fac).
const SYNC_R=3, SYNC_DMG=.12, SYNC_AIM=6; // pass 2 tuning: was .15 and 8 // Hegemony: radius around the anchor, bonus on a target a synced ally already fired at this round
const FEED_KILL=.12, FEED_NEAR=.06, FEED_R=2, FEED_CAP=.12; // pass 3 tuning: .15 to .12 (pass 2: .2 to .15) // tuned Oct 26 after the first PC pass (enemy Chorus rose from 41 to 51 enemy-side wins in fmatrix) // Chorus: hull share regrown by the killer, by others within FEED_R of the kill, cap per ship per round
const LEGION_HP=.35; // Deathless: hull a reassembled ship comes back with
const FAC_RULES={
  hegemony:{n:'Synchronized fire',d:`Ships within ${SYNC_R} hexes of their flagship fire as one: a target another synced ship already fired on this round is ${SYNC_AIM} easier to hit and takes +${Math.round(SYNC_DMG*100)}% damage. Lose the flagship and sync is gone for the rest of the battle. Does not stack with Anchored Volley.`},
  ithar:{n:'Prism charge',d:'At the start of its turn, a shield facing that was not hit since its last turn recharges to full, and a facing that was hit recharges twice. Glasswright hulls cannot Brace.'},
  chorus:{n:'Feed',d:`When an enemy ship dies, the Chorus ship that killed it regrows ${Math.round(FEED_KILL*100)}% of its hull and every other Chorus ship within ${FEED_R} hexes regrows ${Math.round(FEED_NEAR*100)}%, up to ${Math.round(FEED_CAP*100)}% per ship each round.`},
  deathless:{n:'Archive restore',d:`The first Eclipse ship to fall each battle (never the flagship) reassembles at the start of the next round with ${Math.round(LEGION_HP*100)}% hull and cannot fire that round; a fleet of 6 or more gets two returns. Funeral Pyre stops it.`},
  corsair:{n:'Close in',d:'Hullbreakers field no lance weapons, and their rocket pods fire salvos that point defense can thin.'},
  voidsworn:{n:'Line of battle',d:'Broadsides hit harder after a hard burn (drive rule); carriers cost 25% more.'}};
// telemetry for the sims: per-faction counters in B.fstat (never read by rules)
function fstat(fac,k,n){ if(!B||!fac) return; const F=(B.fstat=B.fstat||{})[fac]||(B.fstat[fac]={}); F[k]=(F[k]||0)+(n==null?1:n); }
// Hegemony anchor: the player's flagship (or the biggest Hegemony hull when the flagship is not Hegemony); for the enemy a sector flagship, the
// objective flagship, or the biggest Hegemony hull. Set once at battle start; when it dies or is captured, sync is lost for that side.
function setupFactionRules(){ B.syncMark={player:{},enemy:{}}; B.syncLost={player:false,enemy:false}; B.legion={player:{max:0,used:0},enemy:{max:0,used:0}}; B.torps=[];
  for(const side of ['player','enemy']){ const heg=B.units.filter(u=>u.side===side&&!u.isSq&&!u.transport&&u.fac==='hegemony');
    if(heg.length){ const a=heg.find(u=>u.pflag)||heg.find(u=>u.boss)||heg.find(u=>u.flagship)||heg.slice().sort((x,y)=>(y.t.cp||1)-(x.t.cp||1)||y.maxHp-x.maxHp)[0]; a.anchor=true; }
    const dl=B.units.filter(u=>u.side===side&&!u.isSq&&u.fac==='deathless'&&u.t&&u.t.reanimate).length; B.legion[side].max=dl>=6?2:dl>=1?1:0; }
  { if(B.tree&&B.tree.length&&(treeSkill('wideNet')||treeSkill('livingRelay'))){ B.syncR=Object.assign({},B.syncR||{},{player:treeHegSyncR()});
      const fg=B.units.find(u=>u.side==='player'&&u.anchor&&!u.dead)||B.units.find(u=>u.side==='player'&&u.pflag&&!u.dead);
      if(treeSkill('wideNet')) treeFx(fg,'wideNet','the net reaches one hex further');
      if(treeSkill('livingRelay')) treeFx(fg,'livingRelay','the relay doubles the radius'); } } }
function syncAnchor(side){ if(!B||!B.syncMark||(B.syncLost&&B.syncLost[side])) return null; return B.units.find(u=>u.anchor&&u.side===side&&!u.dead)||null; }
function syncR(side){ return (B&&B.syncR&&B.syncR[side])||SYNC_R; } function syncDmg(side){ return (B&&B.syncDmg&&B.syncDmg[side])||SYNC_DMG; }
function inSync(u){ if(!u||u.isSq||u.fac!=='hegemony'||u.dead||u.side==='player'&&B.round===1&&B.cfg&&B.cfg.storyMods&&B.cfg.storyMods.syncDown) return false; const a=syncAnchor(u.side); return !!a&&hdist(u,a)<=syncR(u.side); }
function syncOn(u,t){ if(!inSync(u)||!t) return false; const m=B.syncMark[u.side][t.id]; return !!m&&m.r===B.round&&m.ids.some(id=>id!==u.id); }
function syncMarkShot(u,t){ if(!inSync(u)||!t) return; const M=B.syncMark[u.side]; let m=M[t.id]; if(!m||m.r!==B.round) m=M[t.id]={r:B.round,ids:[]}; if(!m.ids.includes(u.id)) m.ids.push(u.id);
  if(B.tr&&B.tr.syncFirst&&!B.tr.syncFirst[u.side]) B.tr.syncFirst[u.side]={id:t.id,r:B.round}; } // Kassar T1b: the first synced target of the round
function syncLose(t){ if(!B||!t||!t.anchor||!B.syncLost||B.syncLost[t.side]) return;
  { const it=treeSkill('ironTempo'); if(it&&t.side==='player'&&B.tr&&!B.tr.ironTempoUsed){ const cand=alive('player').filter(u=>u!==t&&!u.isSq&&!u.dead&&u.fac==='hegemony').sort((a,b)=>(b.maxHp-a.maxHp)||(a.id<b.id?-1:1))[0];
    if(cand){ B.tr.ironTempoUsed=1; t.anchor=false; cand.anchor=true; treeFx(cand,'ironTempo','the line finds a new anchor'); return; } } } // Kassar T3b
  B.syncLost[t.side]=true; t.anchor=false; if(B.units.some(u=>u.side===t.side&&!u.dead&&!u.isSq&&u.fac==='hegemony')){ log(`${t.name} is lost: the ${t.side==='player'?'fleet':'enemy line'} loses its synchronized fire.`,t.side==='player'?'e':'p'); } }
// AI and bot: how far a Hegemony ship would stray from its anchor (0 inside the radius)
function syncPull(u,v){ if(!u||u.isSq||u.fac!=='hegemony'||u.anchor) return 0; const a=syncAnchor(u.side); if(!a) return 0; return Math.max(0,hdist(v,a)-syncR(u.side)); }
// Ithar prism charge: facings hit since the ship's last turn (applyHit marks them); unmarked facings refill at turn start
function ithChargeTurn(u){ if(u.fac!=='ithar'||!(u.shMax>0)||u.isSq) return; const hit=u.shHit||[0,0,0,0];
  if(!(u.st.shieldOff>0)){ let g=0; const rg=Math.round(u.regen*((B&&B.condRegen)||1)); for(let i=0;i<4;i++){ if(u.regenLock&&u.regenLock[i]) continue; const add=!hit[i]?u.shMax-u.sh[i]:Math.min(rg,u.shMax-u.sh[i]); if(add>0){ g+=add; u.sh[i]+=add; } } if(g>0) fstat('ithar','charge',g); } u.shHit=[0,0,0,0]; } // tuned Oct 26: struck facings also regenerate a second time (Ithar fell to 50 in fmatrix)
// Chorus feed: an enemy capital ship dies; the killing side's Chorus ships nearby regrow hull, capped per round
function chorusFeed(t,by){ if(!B||!t||t.isSq) return; const side=by?by.side:(t.side==='player'?'enemy':'player'); if(side===t.side) return; const killer=by?(by.isSq?B.units.find(x=>x.id===by.parent):by):null;
  for(const u of B.units){ if(u.dead||u.side!==side||u.isSq||u.fac!=='chorus'||u.pyre||u.hp>=u.maxHp) continue; const share=u===killer?FEED_KILL:hdist(u,t)<=FEED_R?FEED_NEAR:0; if(!share) continue;
    chorusRegrow(u,Math.round(u.maxHp*share),'Feeds'); } }
// one cap for everything a Chorus hull regrows from feeding and biting (FEED_CAP of max hull per round)
function chorusRegrow(u,amt,label){ if(!u||u.dead||u.pyre||amt<=0) return 0; if(u.fedR!==B.round){ u.fedR=B.round; u.fed=0; } const room=Math.max(0,Math.round(u.maxHp*FEED_CAP)-u.fed), h=Math.min(room,u.maxHp-u.hp,amt); if(h<=0) return 0;
  u.hp+=h; u.fed+=h; fstat('chorus','feed',h); try{ if(typeof fxText==='function') fxText(u,(label||'Feeds')+' +'+h,'#d6d24a',-26); }catch(e){} return h; }
// v54 doctrine (decided): a Chorus hull that deals hull damage at 1 to 2 hexes regrows CHORUS_BITE of it, inside the same per-round cap
const CHORUS_BITE=.08; // pass 3 tuning: .12 to .08 (pass 2: .2 to .12)
function chorusBiteEst(u,t,hull){ return u&&t&&u.fac==='chorus'&&!u.isSq&&hdist(u,t)<=2?Math.round(hull*CHORUS_BITE):0; }
// Deathless endless legion: a fallen Deathless ship lies reassembling and rises at its side's next turn start
function legionCan(t){ if(!B||!B.legion||t.isSq||t.fac!=='deathless'||!t.t||!t.t.reanimate||t.reanimated||t.pyre||t.boss||t.pflag||t.flagship||t.transport) return false; const L=B.legion[t.side]; return !!L&&L.used<L.max; }
function legionRiseHex(u){ const occ=occMap(), ok=h=>onBoard(h.q,h.r)&&!blocks(terr(h.q,h.r))&&!occ.has(hkey(h.q,h.r)); if(ok(u)) return {q:u.q,r:u.r};
  let best=null,bd=9; for(const h of boardHexes()){ const d=hdist(h,u); if(d<=2&&d<bd&&ok(h)){ bd=d; best=h; } } return best; }
function legionRise(u,quiet){ const h=legionRiseHex(u); if(!h){ u.riseAt=null; if(!quiet) log(`${u.name} cannot find room to reassemble and stays dark.`,'x'); return false; }
  u.q=h.q; u.r=h.r; u.dead=false; u.riseAt=null; u.hp=Math.max(1,Math.round(u.maxHp*LEGION_HP)); u.st={fire:0,shieldOff:0,engine:0}; u.shredded=0;
  if(u.sec) for(const k of Object.keys(u.sec)){ repairSection(u,k,LEGION_HP); u.sec[k].hp=Math.max(1,Math.round(u.sec[k].max*LEGION_HP)); }
  u.risen=B.round; fstat('deathless','revive'); if(!quiet){ log(`${u.name} reassembles from its wreck with ${u.hp} hull. It cannot fire this round.`,u.side==='player'?'p':'e'); try{ if(typeof fxText==='function') fxText(u,'Reassembled','#7dff9b',-30); }catch(e){} } return true; }
function legionTurn(side){ if(!B||B.over) return []; const out=[]; for(const u of B.units) if(u.dead&&u.side===side&&u.riseAt!=null&&B.round>=u.riseAt&&!u.fled&&legionRise(u)) out.push(u); return out; }
// plain-words lines for the ship panel
function factionTraitLines(u){ if(!u||u.isSq||!B) return []; const out=storyModifierLines(u);
  if(u.fac==='hegemony'){ const a=syncAnchor(u.side); if(!(u.side==='player'&&B.round===1&&B.cfg.storyMods&&B.cfg.storyMods.syncDown)) out.push(!a?'Synchronized fire lost: the flagship is gone.':u.anchor?`Sync anchor: Hegemony ships within ${SYNC_R} hexes fire as one.`:inSync(u)?'In sync with the flagship.':`Out of sync: more than ${SYNC_R} hexes from the flagship.`); }
  if(u.fac==='ithar'&&u.shMax>0) out.push('Prism charge: facings not hit since its last turn refill to full; hit facings recharge twice.');
  if(u.fac==='chorus') out.push(`Feeds on kills nearby (up to ${Math.round(FEED_CAP*100)}% hull a round).`);
  if(u.fac==='deathless'&&u.t&&u.t.reanimate){ const L=B.legion&&B.legion[u.side]; out.push(u.risen?'Reassembled this battle.':L&&L.used<L.max&&!u.pflag&&!u.flagship&&!u.boss?'Archive restore: the first to fall reassembles next round.':'Archive restore spent.'); }
  for(const s of (B.torps||[])) if(s.tid===u.id&&s.side!==u.side) out.push('<span class="blood">Torpedoes inbound: they strike its marked hex next turn. Move 3 or more hexes from it to dodge.</span>');
  if(u.ab==='launch'||(u.fx&&u.fx.hive)){ const st=WING_STANCES[u.stance||'strike']; out.push(`Wing stance: ${st.n}. ${st.d}${u.side==='player'?(canStance(u)?' One free change this round.':' Changed this round.'):''}`); const pk=wingPerks(u); if(pk.length) out.push('Wing veterans: '+pk.map(k=>WING_PERKS[k].n+' ('+WING_PERKS[k].d.replace(/\.$/,'')+')').join(', ')+'.'); }
  if(u.nem&&B.nem){ if(u.nemFlag) out.push('<span class="blood">Your Nemesis commands from this ship.</span>'); const kn=(B.nem.revealed||[]).filter(w=>B.nem.weak.includes(w)); if(kn.length&&u.nemFlag) out.push('Known weaknesses: '+kn.map(w=>NEM_WEAK[w].n+' ('+NEM_WEAK[w].d.replace(/\.$/,'')+')').join('; ')+'.'); }
  return out; }
// ---------- B3 travelling torpedoes ----------
// A torpedo-kind weapon (not squadron bombs) launches now and strikes at the start of the firing side's next turn. Its lane runs from the launch hex
// to the target's hex at launch (the aim hex). At impact: the original target is hit if it is still within 2 hexes of the aim hex (10 harder 1 hex off,
// 25 harder 2 hexes off); otherwise an enemy hull sitting on the aim hex is hit (10 harder); otherwise the salvo runs wide. Range 6 and the cooldown stay.
// Damage multipliers are taken at launch (what the preview showed); accuracy, shields, armor and point defense at impact.
const TORP_RING=[0,5,15], TORP_STRAY=10, TORP_WARHEAD=1.2; // tuned Oct 26: torpedoes that can be dodged carry 20% heavier warheads (torpedo admirals fell out of the 50 to 90 band) // to-hit penalty by hexes the target got from the aim hex (3+ is a clean dodge), and for a stray hull on the aim hex
function torpTravels(w,u){ return !!w&&w.k==='torp'&&!(u&&u.isSq)&&process_env('TORP_INSTANT')!=='1'; }
function torpGhost(u,sure){ const g=Object.assign({},u); g.sureUsed=sure; g.ghost=true; return g; }
// expected torpedo damage aimed at u if it ends at v (AI and bot dodge with this)
function torpThreat(u,v){ if(!B||!B.torps||!B.torps.length||u.isSq) return 0; let tot=0; for(const s of B.torps){ if(s.side===u.side) continue; const d=hdist(v,s.aim);
    if(s.tid===u.id){ if(d<=2) tot+=s.w.dmg*s.w.shots*[.62,.52,.38][d]; } else if(d===0) tot+=s.w.dmg*s.w.shots*.5; } return tot; }
// ---------- B4 the Nemesis in battle ----------
// cfg.nemesis = {name,title,fac,weak:[...],adapt:[...],scars}. Every enemy hull is his (u.nem); the biggest is his flagship (u.nemFlag). His fixed
// weaknesses always apply (intel only tells you about them); adaptations and scars make him harder. Never touches your ships.
function nemWeak(k){ return !!(B&&B.nem&&B.nem.weak&&B.nem.weak.includes(k)); }
function applyNemesis(N){ B.nem=N; let es=B.units.filter(u=>u.side==='enemy'&&!u.isSq&&!u.transport); if(!es.length) return;
  const NF=(typeof NEM_FAC!=='undefined'&&NEM_FAC[N.fac])||{beh:{}}, beh=NF.beh||{}, tr=N.traits||[], ad=N.adapt||[];
  const fl=es.slice().sort((a,b)=>(b.t.cp||1)-(a.t.cp||1)||b.maxHp-a.maxHp)[0]; fl.nemFlag=true; fl.elite=true; fl.name=`${N.title} ${N.name}`; fl.dmg*=1+.1*(N.scars||0); // each scar makes him angrier: +10% damage on his flagship
  // R42 duelist (Ithar): a small elite fleet, at most four hulls, every one elite
  if(beh.strike==='duel'&&es.length>4){ const keep=new Set([fl,...es.filter(u=>u!==fl).sort((a,b)=>(b.t.cp||1)-(a.t.cp||1)).slice(0,3)]); B.units=B.units.filter(u=>u.side!=='enemy'||u.isSq||u.transport||keep.has(u)||(u.parent&&keep.has(B.units.find(x=>x.id===u.parent)))); es=es.filter(u=>keep.has(u)); }
  if(beh.strike==='duel') for(const u of es) if(!u.elite){ u.elite=true; u.aim+=6; u.crit+=5; }
  if(beh.strike==='duel'&&N.honed){ const h=Math.min(3,N.honed); for(const u of es){ u.aim+=3*h; if(u.shMax>0){ u.shMax=Math.round(u.shMax*(1+.1*h)); u.sh=u.sh.map(()=>u.shMax); } } } // R49: an Ithar who fled comes back with the same small fleet, honed (shields +10% and aim +3 per escape, up to 3)
  // R42 Corsair riches: each escape brings one more ship
  for(let i=0;i<(beh.strike==='raid'?(N.riches||0):0)+(ad.includes('riches')?1:0);i++){ /* R49: only a Corsair comes back with extra ships */ const h=edgeHex('enemy'); if(!h) break; const x=makeUnit('enemy',cheapHull(fl.fac),{scale:1+.12*((B.sector||1)-1),dmg:1+.08*((B.sector||1)-1),fac:fl.fac}); x.q=h.q; x.r=h.r; x.facing=3; B.units.push(x); es.push(x); }
  if(fl.fac==='hegemony'){ for(const u of es) u.anchor=false; fl.anchor=true; }
  if(beh.line) for(const u of es) if(u!==fl) for(const w of u.weapons) if(w.k!=='flak'&&w.k!=='sq') w.opt+=1; // R42 Hegemony artillery line: his escorts' guns lose less aim at range
  const fed=Math.min(.32,.04*(N.fed||0));
  for(const u of es){ u.nem=true;
    if(nemWeak('board')){ u.crewMax=Math.max(4,Math.round(u.crewMax*.7)); u.crew=Math.min(u.crew,u.crewMax); }
    if(nemWeak('slow')){ u.speed=Math.max(1,u.speed-1); }
    for(const a of ad){ if(a==='shields'&&u.shMax>0){ u.shMax=Math.round(u.shMax*1.2); u.sh=u.sh.map(()=>u.shMax); } if(a==='armor') u.armor=Math.min(.6,u.armor+.1); if(a==='evasion') u.ev+=8; if(a==='aim') u.aim+=8; if(a==='veil') u.ev+=6; if(a==='hunger') u.hullRegen+=3; if(a==='zeal') u.dmg+=.08; }
    // R42 strength traits
    if(tr.includes('gunnery')) u.aim+=6; if(tr.includes('armored')) u.armor=Math.min(.6,u.armor+.08); if(tr.includes('swift')) u.speed+=1; if(tr.includes('deadeye')) u.crit+=10; if(tr.includes('veil')) u.ev+=8; if(tr.includes('regrowth')) u.hullRegen+=4;
    if(tr.includes('veterans')||fed>0){ const k=1+(tr.includes('veterans')?.12:0)+fed; u.maxHp=Math.round(u.maxHp*k); u.hp=Math.round(u.hp*k); if(u.sec) for(const sk of Object.keys(u.sec)){ u.sec[sk].max=Math.round(u.sec[sk].max*k); u.sec[sk].hp=Math.round(u.sec[sk].hp*k); } }
    if(tr.includes('shielded')&&u.shMax>0){ u.shMax=Math.round(u.shMax*1.2); u.sh=u.sh.map(()=>u.shMax); } if(tr.includes('boarders')){ u.crewMax=Math.round(u.crewMax*1.3); u.crew=u.crewMax; }
    if(tr.includes('artillery')) for(const w of u.weapons) if(w.k!=='flak'&&w.k!=='sq'){ w.r+=1; w.opt+=1; } if(tr.includes('rockets')) for(const w of u.weapons) if(w.k==='torp') w.cd=Math.max(1,(w.cd||2)-1);
    if(tr.includes('brood')&&u.ab==='launch'){ u.hangar=(u.hangar||0)+1; u.spare=(u.spare||0)+1; } }
  if(tr.includes('undying')&&B.legion) B.legion.enemy.max+=1; if(ad.includes('legion')&&B.legion) B.legion.enemy.max+=1;
  if(ad.includes('formation')){ B.syncR=Object.assign({},B.syncR||{},{enemy:SYNC_R+1}); }
  if(ad.includes('pd')){ const pd=fl.fac==='chorus'?'spores':'flak'; for(const u of es.filter(x=>!x.weapons.some(w=>w.k==='flak')).slice(0,2)){ u.weapons.push(Object.assign(nameWeapons(u.fac,[mkWeapon(pd,'T',u.fx||{})])[0],{fired:false,cdLeft:0,off:0})); } }
  B.nemFlee=beh.flee||null; B.nemAi=beh.ai||null; B.nemLine=!!beh.line; B.nemNoRout=!!(beh.noFlee||beh.revive); B.nemChallenge=beh.strike==='challenge'; B.nemPersona=(typeof NEM_PERSONA!=='undefined'&&NEM_PERSONA[N.persona])||null; if(B.cp0) B.cp0.enemy=sideCP('enemy');
  const an=a=>(typeof nemAdaptName==='function'?nemAdaptName(a,N.fac):(NEM_ADAPT[a]?NEM_ADAPT[a].n:a)).toLowerCase(), L=typeof NEM_LINES!=='undefined'?NEM_LINES:null;
  log(`${fl.name} commands this fleet: your Nemesis.${ad.length?' '+(N.g==='n'?'It':N.g==='f'?'She':'He')+' has adapted: '+ad.map(an).join(', ')+'.':''}`,'e');
  if(L){ const bw=N.last_beat&&typeof NEM_BEAT_WORD!=='undefined'?(NEM_BEAT_WORD[N.last_beat]||N.last_beat):null, cnt=NEM_BEAT_COUNTER[N.last_beat];
    const line=typeof N.line==='string'?N.line:N.gloat&&L.gloat?L.gloat[N.gloat]:N.met&&bw?(ad.includes(cnt)?L.again:(L.remember||L.again)).replace('{beat}',bw):(L.meet[N.persona]||''); if(line) log(`${fl.name}: "${line}"`,'e'); } // #121: the campaign's own NEM_VOICE line (cfg.nemesis.line) when it sends one
  if(B.nemChallenge) nemSig('challenge'); if(beh.strike==='duel') nemSig('duel'); if(beh.line) nemSig('line');
  if(B.nemChallenge){ const d=nemDuelTarget(); if(d) log(`${fl.name} challenges ${d.pflag?'your flagship':d.name} to single combat and comes for it: the two ships deal 20% more damage to each other.`,'e'); } }
// R49 Voidsworn challenge: his flagship seeks your flagship, or your strongest ship once it is gone, and both deal 20% more damage to each other
function nemDuelTarget(){ if(!B||!B.nemChallenge) return null; let d=B.nemDuel!=null?B.units.find(u=>u.id===B.nemDuel&&!u.dead&&u.side==='player'):null;
  if(!d){ d=B.units.find(u=>u.pflag&&!u.dead&&u.side==='player')||B.units.filter(u=>u.side==='player'&&!u.dead&&!u.isSq&&!u.reinf).sort((a,b)=>(b.t.cp||1)-(a.t.cp||1)||b.maxHp-a.maxHp||(a.id<b.id?-1:1))[0]||null; if(d){ const first=B.nemDuel==null; B.nemDuel=d.id; if(!first){ const f=B.units.find(u=>u.nemFlag&&!u.dead); if(f) log(`${f.name} turns to ${d.name}: the duel goes on.`,'e'); } } } return d; }
// R42: a Nemesis who withdraws from a lost fight (Corsair: flagship under 35% hull; Ithar: every flagship shield down and hull under 60%). He and
// his escorts jump out; you win the field, he escapes to come back (richer, for a Corsair). Checked at each enemy turn start.
function nemFleeCheck(){ if(!B||!B.nem||!B.nemFlee||B.nemFled||B.over) return; const f=B.units.find(u=>u.nemFlag&&!u.dead&&u.side==='enemy'); if(!f) return; const R=B.nemFlee;
  const low=f.hp<=f.maxHp*(R.hull||0)&&(!R.shields||!(f.shMax>0)||f.sh.every(x=>x<=.5)); if(!low) return;
  B.nemFled=true; nemSig('flee_battle'); for(const e of alive('enemy').filter(u=>!u.isSq&&!u.transport)){ e.dead=true; e.fled=true; try{ if(typeof fxWithdraw==='function') fxWithdraw(e); }catch(x){} }
  log(`${f.name} breaks off and jumps out with what is left of his fleet. He will be back.`,'s'); checkEnd(); }
// R42 personality weights for his ships in the AI's move scoring and target choice
function nemProf(u,prof){ const P=B&&B.nemPersona, F=B&&B.nemAi; if(!u||!u.nem||((!P||!P.ai)&&!F)) return prof; const a=(P&&P.ai)||{}, o=Object.assign({},prof); if(a.tw) o.tw=prof.tw*a.tw; if(a.range!=null) o.range=a.range; if(a.flagFront&&u.nemFlag) o.tw=prof.tw*.6;
  if(F){ if(F.range!=null) o.range=Math.max(o.range||0,F.range); if(F.charge&&u.nemFlag) o.tw=o.tw*.7; } return o; } // R42 faction weights on top of his personality: Ithar keep range, a Voidsworn flagship charges
function nemTargetBonus(u,t){ const P=B&&B.nemPersona, F=B&&B.nemAi; if(!u||!u.nem||!t) return 0; const a=(P&&P.ai)||{}; let v=0; if(a.focusWeak||(F&&F.focusWeak)) v+=20*(1-t.hp/t.maxHp); if(a.focusFlag&&t.pflag) v+=25; if(F&&F.hunt&&u.nemFlag&&t===nemDuelTarget()) v+=30; return v; } // Ithar pick off the weakest; a Voidsworn flagship hunts yours
// R42 signatures: his faction behaviour firing, for the battle voice (G1: emit {t:'nem_signature', kind}) and the campaign record
function nemSig(kind){ if(!B||!B.nem) return; (B.nemSigs=B.nemSigs||[]).push({kind,r:B.round}); if(typeof nemSignature==='function') nemSignature(kind); }
// R42 weaknesses found by triggering them: logged once, known for the rest of the run (finishBattle merges B.nemFound). No random draws.
const NEM_BEAT_COUNTER={lance:'shields',torp:'pd',sq:'pd',ram:'armor',board:'armor',battery:'evasion',evasive:'aim'};
function nemTrip(k){ if(!B||!B.nem||!nemWeak(k)) return; B.nemFound=B.nemFound||[]; if(B.nemFound.includes(k)||(B.nem.revealed||[]).includes(k)) return; B.nemFound.push(k); (B.nem.revealed=B.nem.revealed||[]).push(k);
  log(`Weakness found: ${NEM_WEAK[k].n}. ${NEM_WEAK[k].d}`,'s'); }
// a proud flagship (weakness): once it falls below 60% hull, his escorts break and flee
function nemBreak(){ if(!B||!B.nem||B.nemBroken||!nemWeak('anchor')) return; const f=B.units.find(u=>u.nemFlag&&!u.dead&&u.side==='enemy'); if(!f||f.hp>f.maxHp*.6) return;
  B.nemBroken=true; nemTrip('anchor'); const esc=alive('enemy').filter(u=>u!==f&&!u.isSq&&!u.transport); for(const e of esc){ e.dead=true; e.fled=true; try{ if(typeof fxWithdraw==='function') fxWithdraw(e); }catch(x){} }
  log(`${f.name}'s flagship is burning. ${esc.length?'His escorts lose their nerve and flee.':''}`,'s'); }
// ion hits strip more shield from a Nemesis with brittle emitters
function ionVs(att,w,t){ return ionOf(att,w)*(t&&t.nem&&nemWeak('ion')&&(w.ion||w.k==='lance')?1.5:1); }
// ---------- B4 faction verbs in battle (readied on the map, RUN.verbNext, handed in as cfg.verb) ----------
function applyVerb(id){ const P=B.units.filter(u=>u.side==='player'&&!u.isSq); B.verb=id;
  if(id==='vigil') for(const u of P) u.fx=Object.assign({},u.fx,{lineGuard:(u.fx.lineGuard||0)+.15});
  if(id==='drill'){ B.syncR={player:SYNC_R+1}; B.syncDmg={player:.2}; }
  if(id==='attune') for(const u of P) if(u.shMax>0){ u.shMax=Math.round(u.shMax*1.25); u.sh=u.sh.map(()=>u.shMax); }
  if(id==='waken'&&B.legion) B.legion.player.max+=1;
  const V=Object.values(FAC_VERBS).find(v=>v.id===id); if(V) log(`${V.n}: ${V.d.replace(/^Next battle, /,'')}`,'p'); }
// ---------- B4 wing doctrines ----------
// Each carrier has a stance for its wings (u.stance, default strike), changed at most once per round for free. Explicit wing orders still win.
const WING_SCREEN_R=2, WING_HUNT_LEASH=4, WING_SCREEN_TORP=.45;
function wingStance(s){ const p=s&&s.isSq?B.units.find(x=>x.id===s.parent):s; return (p&&p.stance)||'strike'; }
function canStance(u){ return !!(B&&u&&!u.dead&&!u.isSq&&(u.ab==='launch'||(u.fx&&u.fx.hive))&&u.stanceRound!==B.round); }
function setStance(u,st){ if(!WING_STANCES[st]||!canStance(u)||u.stance===st) return false; u.stance=st; u.stanceRound=B.round; log(`${u.name}'s wings: ${WING_STANCES[st].n}.`,u.side==='player'?'p':'e'); return true; }
// the enemy (and the sim bot) pick a stance at their turn start: screen against torpedoes or many craft, hunt a crippled ship, else strike
function aiStance(u){ if(!canStance(u)) return; const foe=u.side==='player'?'enemy':'player', mineSq=alive(u.side).filter(x=>x.isSq).length, foeSq=alive(foe).filter(x=>x.isSq).length;
  const torps=(B.torps||[]).some(s=>s.side===foe), weak=alive(foe).some(x=>!x.isSq&&x.hp<x.maxHp*.5);
  const st=torps||foeSq>mineSq+1?'screen':weak?'hunt':'strike'; if(st!==(u.stance||'strike')) setStance(u,st); }
function wingPerks(p){ return (p&&p.ship&&p.ship.wingVet&&p.ship.wingVet.perks)||[]; }
// screening wings near a torpedo's target shoot down part of the salvo (at impact, after point defense)
function screenTorps(t,shots,res,mult){ const im=(mult==null?1:mult); let shot=0; for(const s of alive(t.side)){ if(!s.isSq||wingStance(s)!=='screen'||hdist(s,t)>WING_SCREEN_R) continue; const p=B.units.find(x=>x.id===s.parent), ch=(WING_SCREEN_TORP+(wingPerks(p).includes('pickets')?.2:0))*im;
    for(let i=0;i<shots.length;i++) if(shots[i]){ if(rnd()<ch){ shots[i]=false; shot++; } break; } }
  if(shot){ res.pd=(res.pd||0)+shot; try{ if(typeof fxText==='function') fxText(t,shot+' torpedo'+(shot>1?'es':'')+' shot down by wings','#bfe3ff',30); }catch(e){} } }
// ---------- combat math ----------
function sightBlocked(q,r){ return blocks(terr(q,r))||!!(SOLID&&SOLID.has(q+','+r)); }
function los(a,b){ const line=hexLine(a,b); for(let i=1;i<line.length-1;i++){ if(sightBlocked(line[i].q,line[i].r)) return false; } return true; }
function weaponReady(w){ return !w.fired && w.cdLeft===0 && w.off===0; }
function inReach(u,w,t){ const d=hdist(u,t); if(d<1||d>w.r) return false; if(treeDeepBlocks(u,t)) return false; if(!inArc(u,t,w.arc)) return false; return los(u,t); }
function canFire(u,w,t){ if(u.dead||t.dead||u.side===t.side||u.braced||w.k==='flak') return false; if(!weaponReady(w)) return false; return inReach(u,w,t); }
// v50: a hull that sat still last turn is an easy solution; one that burned hard is not
function motionHit(t){ if(!t||t.isSq||t.hexMoved==null||t.braced) return 0; const R=moveRules(t); if(t.hexMoved===0) return R.still; if(t.hexMoved>=R.evadeAt) return -R.evade; return 0; }
function rakeBonus(u,w){ if(!u||u.isSq||!(w.arc==='P'||w.arc==='S')||(u.hexMoved||0)<2) return 0; return moveRules(u).rake; }
function hitChance(u,w,t){
  const d=hdist(u,t), over=Math.max(0,d-w.opt-(u.fx.longAim||0));
  const noFall=!!(u.side==='player'&&B&&B.tr&&B.tr.sunTarget===t.id&&B.volleyMul&&B.volleyMul.side==='player'); // Saro capstone 1: no range falloff
  let c=w.acc+u.aim+(u.lockOn?15:0)-(u.fullAhead?15:0)-(noFall?0:over*w.fall)-Math.min(45,t.ev+(t.evBuff||0))*(w.evMult||1); // evasion caps at 45
  if(t.isSq && w.k!=='flak' && w.k!=='sq') c-=15;
  const noShadow=!!(treeSkill('coronaShadow')&&B&&B.volleyMul&&B.volleyMul.side===u.side); // Umbra T3a: the noon volley ignores terrain cover
  if(!noShadow){ if(terr(t.q,t.r)==='neb') c-=15;
    if(terr(t.q,t.r)==='debris') c-=10;
    if(terr(u.q,u.r)==='storm') c-=10; }
  if(u.crewMax){ if(u.crew<u.crewMax*.5) c-=10; if(u.crew<u.crewMax*.25) c-=10; }
  if(t.fx&&t.fx.burnEv&&(t.hexMoved||0)>=3) c-=t.fx.burnEv;
  c+=motionHit(t);
  if(syncOn(u,t)) c+=SYNC_AIM; // B3 Hegemony synchronized fire
  if(u.nem&&nemWeak('brawl')&&d<=2) c-=10; // B4 Nemesis weakness: long-gun doctrine
  if(t.isSq&&wingStance(t)==='hunt') c+=10; // B4 hunting wings fly exposed
  if(t.fx&&t.fx.lineEv&&B&&B.units.some(x=>!x.dead&&x!==t&&x.side===t.side&&!x.isSq&&hdist(x,t)===1)) c-=t.fx.lineEv; // Unbroken Line, Epic
  if(B&&B.mark&&B.mark[u.side]&&B.mark[u.side].r===B.round&&B.mark[u.side].id===t.id) c+=(B.mark[u.side].aim||10); // Marked for Death (RWD-2: aim scales with rarity)
  { const fl=treeSkill('flagshipLens'); if(fl&&w.k==='lance'&&u.side==='player'&&B&&B.treeLens&&B.treeLens.r===B.round&&B.treeLens.id===t.id) c+=treeAddVal(u,'aim',fl.n); } // Brin shared C1a
  { const f1=treeSkill('firstLight'); if(f1&&B&&B.tr&&B.tr.firstLight===u.id&&t.side==='player') c-=f1.n; } // Brin shared C1b
  { const ef=treeSkill('everyFrame'); if(ef&&u.side==='player'&&!u.isSq&&B&&B.volleyMul&&B.volleyMul.side===u.side&&(u.hexMoved||0)===0) c+=treeAddVal(u,'aim',ef.a); } // Umbra T3b
  { const sa=treeSkill('silentArchive'); if(sa&&u.side==='enemy'&&t.side==='player'&&!t.isSq&&cmdActive('player','hunt')&&!inArc(u,t,'F')) c-=sa.n; } // Ostrel T3b
  { const td=treeSkill('throatDeep'); if(td&&u.side==='player'&&!u.isSq){ const fg=B&&B.units.find(x=>x.pflag&&!x.dead); if(fg&&hdist(u,fg)<=2) c+=treeAddVal(u,'aim',td.n); } } // Chorus shared C1b
  { const bb=treeSkill('breathBite'); if(bb&&u.side==='enemy'&&cmdActive('player','surge')&&alive('player').filter(x=>!x.isSq&&hdist(x,u)===1).length>=2) c-=bb.n; } // Razormaw T3b
  { const pc=treeSkill('packCloses'); if(pc&&u.side==='player'&&!u.isSq&&cmdActive(u.side,'surge')&&alive('player').some(x=>x!==u&&!x.isSq&&hdist(x,u)===1)) c+=treeAddVal(u,'aim',pc.n); } // Grax T2a
  { const pg=treeSkill('patchGuns'); if(pg&&u.side==='player'&&!u.isSq&&u.treeAimGuns) c+=treeAddVal(u,'aim',u.treeAimGuns); } // Vesh T1b
  { const ps=treeSkill('preyScent'); if(ps&&u.side==='player'&&!u.isSq&&B&&B.tr&&B.tr.scent===t.id) c+=treeAddVal(u,'aim',ps.n); } // Hullbreakers shared B1a
  { const ss=treeSkill('sharedSolution'); if(ss&&u.side==='player'&&!u.isSq&&inSync(u)){ let best=u.aim; for(const x of alive('player')) if(x!==u&&!x.isSq&&inSync(x)) best=Math.max(best,x.aim); if(best>u.aim) c+=treeAddVal(u,'aim',best-u.aim); } } // Kassar T2a
  { const cd=treeSkill('coldDrill'); if(cd&&u.side==='player'&&!u.isSq&&inSync(u)&&(u.hexMoved||0)===0) c+=treeAddVal(u,'aim',cd.n); } // Kassar T2b
  { const pr=treeSkill('rehearsed'); if(pr&&u.isSq&&u.side==='player'&&u.extra&&cmdActive('player','scramble')) c+=treeAddVal(u,'aim',pr.n); } // Reyes T2b
  { const bc=treeSkill('beacon'); if(bc&&u.side==='player'&&!u.isSq&&B&&B.tr&&B.tr.beacon&&B.tr.beacon.r===B.round&&B.tr.beacon.id===t.id) c+=treeAddVal(u,'aim',bc.n); } // Hegemony shared C1a
  { const fm=treeSkill('formation'); if(fm&&u.side==='player'&&!u.isSq&&u.treeFormation) c+=treeAddVal(u,'aim',fm.n); } // Hegemony shared B1a
  { const ta=treeSkill('targetArchived'); if(ta&&u.treeAimTgt&&t.id===u.treeAimTgt) c+=treeAddVal(u,'aim',ta.n); } // Umbra T2b: a target no other ship chose
  { const ek=treeSkill('everyKnife'); if(ek&&u.side==='enemy'&&u.treeKnifeRound===B.round) c-=ek.n; } // Sable T3b
  { if(u.side==='enemy'&&u.treeAcidAim) c-=20; } // Voice T3b: acid in the scanners
  const surge=cmdActive(t.side,'surge')||!!(t.side==='player'&&t.burnCarry); // v53: the enemy's Surge Command, and Grax's carried burn
  if(w.k==='lance'&&u.fx&&u.fx.lanceSure) return surge?75:95; // One Clean Line (legendary)
  if(u.side==='player'&&!u.isSq&&!(u.sureUsed>0)&&runFx().firstSure) return surge?75:95; // the rangefinder relic: every ship's first attack of the battle
  const h=clamp(Math.round(c),5,95); return surge?Math.max(5,h-20):h;
}
// a boon firing in battle: a patron-coloured callout with the boon's name, counted for the after-battle recap
function boonFx(u,id,txt,dy){ try{ if(B){ B.boonStats=B.boonStats||{}; B.boonStats[id]=(B.boonStats[id]||0)+1; } const b=BOONS[id], P=b&&(b.p?PATRONS[b.p]:PATRONS[b.duo[0]]); if(typeof fxText==='function') fxText(u,(b?b.n+': ':'')+txt,P?P.col:'#f0b35a',dy==null?-30:dy); }catch(e){} }
function ownerFx(u){ if(!u) return {}; if(u.isSq){ const p=B&&B.units.find(x=>x.id===u.parent); return (p&&p.fx)||{}; } return u.fx||{}; }
// hull damage taken is cut when a ship holds the line next to an ally (Unbroken Line) or sits beside a Bulwark flagship
function guardMul(t){ if(!B||t.isSq) return 1; let m=1; const near=B.units.filter(x=>!x.dead&&x!==t&&x.side===t.side&&!x.isSq&&hdist(x,t)===1); if(!near.length) return 1;
  if(t.fx&&t.fx.lineGuard) m*=1-Math.min(.5,t.fx.lineGuard); const aura=Math.max(0,...near.map(x=>(x.fx&&x.fx.guardAura)||0)); if(aura) m*=1-aura; return m; }
function ionOf(att,w){ const f=ownerFx(att); return (w.ion||1)+(f.ionPlus||0)+(w.k==='lance'?(f.ionLance||0):0); }
function dmgMult(u,w,t,rear){
  let m=u.dmg;
  { const lf=treeSkill('longFocus'); if(lf&&B&&B.volleyMul&&B.volleyMul.side===u.side&&!u.isSq&&hdist(u,t)>w.r/2) m+=treeAddVal(u,'dmgPct',lf.n); } // Saro T1a: volley shots past half the weapon's range
  { const ff=treeSkill('flawForever'); if(ff&&w.k==='lance'&&B&&B.treeFlaw&&t.id===B.treeFlaw) m+=treeAddVal(u,'dmgPct',ff.n); } // Saro capstone 2
  { const ia=treeSkill('inheritedAim'); if(ia&&B&&B.volleyMul&&B.volleyMul.side===u.side&&!u.isSq&&(u.hexMoved||0)===0) m+=treeAddVal(u,'dmgPct',ia.n); } // Vex T2b
  { const np=treeSkill('namedPrey'); if(np&&B&&B.treeNamedPrey&&B.treeNamedPrey.r===B.round&&u.side==='player'&&t.id===B.treeNamedPrey.id) m+=treeAddVal(u,'dmgPct',np.n); } // Malek capstone 2
  { const nc=treeSkill('noonChoice'); if(nc&&u.side==='player'&&!u.isSq&&B&&B.treeNoon&&B.volleyMul&&B.volleyMul.side===u.side) m+=treeAddVal(u,'dmgPct',nc.n); } // Umbra T1b
  { const ef=treeSkill('everyFrame'); if(ef&&u.side==='player'&&!u.isSq&&B&&B.volleyMul&&B.volleyMul.side===u.side&&(u.hexMoved||0)===0) m+=treeAddVal(u,'dmgPct',ef.n); } // Umbra T3b
  { const fi=treeSkill('flagshipIndex'); if(fi&&u.side==='player'&&u.pflag&&B&&B.tr&&B.tr.indexTarget&&t.id===B.tr.indexTarget.id) m+=treeAddVal(u,'dmgPct',fi.n); } // Eclipse shared C1a
  { const cb=treeSkill('copiedBehind'); if(cb&&rear&&u.side==='player'&&cmdActive(u.side,'hunt')) m+=treeAddVal(u,'rearPct',cb.n); } // Ostrel T1a
  { const ua=treeSkill('unseenArchive'); if(ua&&u.side==='player'&&cmdActive(u.side,'hunt')&&B&&B.tr&&!B.tr.targetedLast[u.id]) m+=treeAddVal(u,'dmgPct',ua.n); } // Ostrel T1b
  { const uc=treeSkill('uncopiedTarget'); if(uc&&u.side==='player'&&cmdActive(u.side,'hunt')&&!t.treeHitBattle) m+=treeAddVal(u,'dmgPct',uc.n); } // Ostrel T2b
  { const la=treeSkill('ledgerArcs'); if(la&&u.side==='player'&&!u.isSq&&B&&B.volleyMul&&B.volleyMul.side===u.side&&(w.arc==='P'||w.arc==='S')) m+=treeAddVal(u,'broadPct',la.n); } // Vex T1a: the volley from a broadside arc
  { const ol=treeSkill('oneLens'); if(ol&&u.side==='player'&&!u.isSq&&B&&B.tr&&B.tr.oneLens&&u.id===B.tr.oneLens.ship&&t.id===B.tr.oneLens.tgt&&B.volleyMul&&B.volleyMul.side===u.side) m+=treeAddVal(u,'dmgPct',ol.n); } // Saro T1b
  { const lt=treeSkill('lightTogether'); if(lt&&u.side==='player'&&!u.isSq&&B&&B.volleyMul&&B.volleyMul.side===u.side){ const arr=B.tr&&B.tr.lightTgt?B.tr.lightTgt[t.id]:null; if(arr&&arr.some(id=>id!==u.id)) m+=treeAddVal(u,'dmgPct',lt.n); } } // Saro T2a
  { const dd=treeSkill('debtDue'); if(dd&&u.side==='player'&&!u.isSq&&B&&B.treeDebtDue) m+=treeAddVal(u,'dmgPct',dd.n); } // Vex T3b
  if(u.side==='player'&&!u.isSq){ let add=0;
    { const rd=treeSkill('runDown'); if(rd&&cmdActive(u.side,'surge')&&t.speed<u.speed) add+=rd.n; } // Razormaw T1a: the slowest are run down
    { const trd=treeSkill('throatRed'); if(trd&&u.treeRedFirst) add+=trd.n; } // Razormaw capstone 1: first shot after the red frenzy
    { const rB=treeSkill('runBigger'); if(rB&&cmdActive(u.side,'surge')&&u.treeBigStart!=null&&B&&B.tr&&B.tr.bigId){ const big=B.units.find(x=>x.id===B.tr.bigId&&!x.dead); if(big&&(u.hexMoved||0)>0&&hdist(u,big)<u.treeBigStart) add+=rB.n; } } // Grax T1a
    { const sm=treeSkill('smileCut'); if(sm&&u.treeSmile) add+=sm.n; } // Sable T3a
    { const pb=treeSkill('packBites'); if(pb&&u.treeDmgCarry&&u.treeDmgCarry.r===B.round) add+=pb.n; } // Vesh T3b
    { if(u.treeHuntRearNext&&u.treeHuntRearNext.r===B.round) add+=u.treeHuntRearNext.n; } // Sable capstone 1
    if(u.treeDmgNext) add+=u.treeDmgNext; // Mending T3a: the new flesh is angry
    { const sp=treeSkill('shadowPos'); if(sp&&u.treeShadowPos&&cmdActive(u.side,'hunt')) add+=sp.n; } // Ostrel T2a: the shadow is a position
    if(u.treeIterFire) add+=u.treeIterFire; // Nadir T2a: the rebuild does not wait
    { const sb=treeSkill('strikeBook'); if(sb&&cmdActive(u.side,'hunt')&&B&&B.tr&&B.tr.strikeSpeed!=null&&u.speed>=B.tr.strikeSpeed) add+=sb.n; } // Vorn T1b
    { const cf=treeSkill('crossFire'); if(cf&&cmdActive(u.side,'hunt')&&B&&B.tr&&(B.tr.crossHits[t.id]||0)>=1) add+=cf.n; } // Vorn T2a
    { const ti=treeSkill('totalInterdiction'); if(ti&&cmdActive(u.side,'hunt')&&B&&B.tr&&B.tr.totalShips[t.id]&&Object.keys(B.tr.totalShips[t.id]).length>=3) add+=ti.n; } // Vorn T3a
    { const pf=treeSkill('permanentFile'); if(pf&&B&&B.treePermFile&&B.treePermFile.r===B.round&&B.treePermFile.ids[t.id]) add+=B.treePermFile.m; } // Vorn capstone 1
    if(add) m+=treeAddVal(u,'dmgPct',add); }
  if(w.arc==='P'||w.arc==='S') m+=u.fx.broadPct||0;
  if(w.k==='lance') m+=u.fx.lancePct||0;
  if(w.k==='torp') m+=u.fx.torpPct||0;
  if(u.isSq) m+=u.sqPct||0;
  if(u.isSq&&u.treeBonus) m+=treeAddVal(u,'sqPct',u.treeBonus); // Ashgrove T1b: the chosen carrier's extra wing hits harder
  { const ot=treeSkill('oneTarget'); if(ot&&u.isSq&&u.side==='player'&&B&&B.tr&&B.tr.wingFiled&&B.tr.wingFiled.r===B.round&&B.tr.wingFiled.id===t.id) m+=treeAddVal(u,'sqPct',ot.n); } // Reyes capstone 1
  if(u.isSq&&u.side==='player'&&B&&B.tr){
    { const rt=treeSkill('reTasked'); if(rt&&u.extra&&!B.tr.wingStruck[t.id]) m+=treeAddVal(u,'sqPct',rt.n); } // Mott T2a
    { const sc=treeSkill('screaming'); if(sc&&u.extra&&B.tr.hitRound[t.id]) m+=treeAddVal(u,'sqPct',sc.n); } // Mott T3b
    { const pw=treeSkill('privateWing'); if(pw&&u.treePrivate&&u.treePrivateRound!==B.round) m+=treeAddVal(u,'sqPct',pw.n); } } // Mott capstone 2
  if(u.isSq&&u.side==='player'&&u.extra&&B&&B.tr){
    { const fp=treeSkill('flightPaths'); if(fp){ const par=B.units.find(x=>x.id===u.parent); if(par&&B.tr.carrierLast&&B.tr.carrierLast[par.id]===t.id) m+=treeAddVal(u,'sqPct',fp.n); } } // Tamsa T1a
    { const rp=treeSkill('replay'); if(rp&&B.tr.strikeAgain===B.round&&B.tr.hitRound[t.id]) m+=treeAddVal(u,'sqPct',rp.n); } // Tamsa T2a
    { const asp=treeSkill('accountSplits'); if(asp){ const arr=(B.tr.wingTargets&&B.tr.wingTargets[u.parent])||[]; if(arr.some(x=>x.sq!==u.id&&x.tid!==t.id)) m+=treeAddVal(u,'sqPct',asp.n); } } // Ashgrove T2a, Matriarch T2a: a split strike pays
    { const nt=treeSkill('nineThroats'); if(nt&&B.tr.swarmHunger&&B.tr.swarmHunger.r===B.round&&B.tr.swarmHunger.id===t.id) m+=treeAddVal(u,'sqPct',nt.n); } } // Matriarch capstone 1: every throat on one hunger
  if(rear) m+=u.fx.rearPct||0;
  { const tt=treeSkill('teethThroat'); if(tt&&rear&&u.side==='player'&&!u.isSq&&cmdActive(u.side,'surge')&&!u.treeTeethUsed) m+=treeAddVal(u,'rearPct',tt.n); } // Razormaw T1b: the first rear hit in the frenzy
  { const rr=treeSkill('rearReckoning'); if(rr&&rear&&u.side==='player'&&cmdActive(u.side,'hunt')) m+=treeAddVal(u,'rearPct',rr.n); } // Malek T2b
  { const kb=treeSkill('knifeBack'); if(kb&&rear&&u.side==='player'&&!u.isSq&&cmdActive(u.side,'hunt')) m+=treeAddVal(u,'rearPct',kb.n); } // Sable T1a
  if(rear&&t.nem&&nemWeak('flank')) m+=.25; // B4 Nemesis weakness: thin stern plating
  if(B&&B.nemChallenge&&((u.nemFlag&&t.id===B.nemDuel)||(u.id===B.nemDuel&&t.nemFlag))) m+=.2; // R42 Voidsworn Nemesis: the flagship duel
  if(u.nem&&B&&B.nem&&(B.nem.traits||[]).includes('zeal')&&hdist(u,t)===1) m+=.12; // R42 trait: zealots up close
  if(u.isSq&&!t.isSq){ if(wingStance(u)==='hunt'&&t.hp<t.maxHp/2) m+=.2; if(wingPerks(B&&B.units.find(x=>x.id===u.parent)).includes('killers')) m+=.15; } // B4 wing doctrine and perk
  if(t.hp<t.maxHp/2) m+=u.fx.huntPct||0;
  if(u.focus) m+=.3;
  { const still=u.fx.stillPct&&!u.hexMoved&&(w.arc==='P'||w.arc==='S'||w.k==='battery')?u.fx.stillPct:0, sy=syncOn(u,t)?syncDmg(u.side):0; m+=Math.max(still,sy); } // B3: synchronized fire does not stack with Anchored Volley (the larger applies)
  if(u.fx.momPct) m+=Math.min(4,u.hexMoved||0)*u.fx.momPct;
  if(u.fx.prowPct&&w.arc==='F') m+=u.fx.prowPct;
  m+=rakeBonus(u,w);
  let base=w.dmg*m;
  base*= t.isSq ? (w.vsSq||1) : (w.vsCap||1);
  // v53: bloodied, Commands and volley multipliers (were a wrapper patched on below; same order, same numbers)
  if(u.bloodied&&!u.isSq) base*=1+.15*u.bloodied; if(cmdActive(u.side,'hunt')&&!u.treeHuntNext) base*=1+cmdPow('hunt',null,u.side); if(u.treeHuntCarry) base*=1+u.treeHuntCarry; if(u.isSq&&cmdActive(u.side,'scramble')) base*=1+cmdPow('scramble',null,u.side); if(B&&B.volleyMul&&B.volleyMul.side===u.side) base*=B.volleyMul.m;
  return base*storyDamageMult(u);
}
// Expected value used for previews and AI
function expectedVs(u,w,t){
  const quad=shieldQuad(t,u), rear=treeIsRear(u,t,quad);
  const hit=hitChance(u,w,t)/100, per=dmgMult(u,w,t,rear);
  const raw=per*w.shots*hit;
  const pierce=w.k==='lance'&&ownerFx(u).lanceSure?1:(w.pierce||0), ion=ionVs(u,w,t);
  const shieldable=raw*(1-pierce);
  const absorbed=Math.min(shieldable,(t.sh[quad]||0)/ion);
  let hull=(raw-absorbed)*(1-(rear?t.armor*.5:t.armor));
  hull*=braceMul(t); // braced, or covered by a bracing Voidsworn neighbour
  hull*=cmdTaken(t)*guardMul(t);
  return {hit, raw, hull, shield:absorbed*ion, quad, rear};
}
function applyHit(att,w,t,dmg,quad){
  const of=ownerFx(att), rear=treeIsRear(att,t,quad); let pierce=w.k==='lance'&&of.lanceSure?1:(w.pierce||0); const ion=ionVs(att,w,t);
  if(B&&B.tr&&B.tr.firstStopTarget===t.id){ if(!B.tr.firstStopDone) B.tr.firstStopDone=1; else pierce=1; } // Kassar capstone 2: shields stop only the first hit
  if(B&&B.tr&&B.tr.sunTarget===t.id&&att&&att.side==='player'){ if(!B.tr.sunFirstDone) B.tr.sunFirstDone=1; else pierce=1; } // Saro capstone 1
  if(B&&B.tr&&B.tr.grandTarget===t.id&&att&&att.side==='player'){ if(!B.tr.grandFirstDone) B.tr.grandFirstDone=1; else pierce=1; } // Vex capstone 1
  if(t._treePierce){ pierce=1; t._treePierce=0; } // Saro T3a: the third and later volley hits ignore shields
  if(!t.isSq&&quad!=null) (t.shHit=t.shHit||[0,0,0,0])[quad]=1; // B3 Ithar prism charge: this facing was hit since the ship's last turn
  if(!t.isSq&&quad!=null&&w.ion&&att&&att.fac==='hegemony'&&t.shMax>0) (t.regenLock=t.regenLock||[0,0,0,0])[quad]=1; // v54 doctrine (decided): Hegemony ion stops that facing's regen for a turn
  let shieldable=dmg*(1-pierce), through=dmg-shieldable;
  const s=t.sh[quad]||0; const sh0=s; const absorbed=Math.min(shieldable,s/ion);
  t.sh[quad]=Math.max(0,s-absorbed*ion); shieldable-=absorbed;
  { const gc=treeSkill('glassCorrected'); if(gc&&t.side==='player'&&cmdActive('player','iron')&&!B.tr.glassUsed&&t.shMax>0&&sh0>0&&t.sh[quad]<=0){ t.sh[quad]=Math.round(t.shMax*gc.n); B.tr.glassUsed=1; treeFx(t,'glassCorrected','the emptied facing refills'); } } // Brin T3a
  { const ce=treeSkill('columnEndures'); if(ce&&t.side==='player'&&cmdActive('player','iron')&&!B.tr.columnUsed&&t.shMax>0&&sh0>0&&t.sh[quad]<=0){ t.sh[quad]=Math.round(t.shMax*ce.n); B.tr.columnUsed=1; treeFx(t,'columnEndures','the emptied facing refills'); } } // Maren T3a
  const seams=!!(treeSkill('acidSeams')&&B&&B.volleyMul&&B.volleyMul.side==='player'&&att&&att.side==='player'&&t.side==='enemy'&&t.hp<t.maxHp/2); // Voice T3a: acid finds the seams below half hull
  const arm=seams?0:Math.max(0,t.armor-(t.shredded||0))*(1-(w.armorPierce||0)); let hull=(through+shieldable)*(1-(rear?arm*.5:arm)); // v48: spines strip armor, gauss ignores half of it
  hull*=braceMul(t); // braced, or covered by a bracing Voidsworn neighbour
  hull*=cmdTaken(t)*guardMul(t);
  { const es=treeSkill('escorts'); if(es&&att&&att.isSq&&att.side==='enemy'&&B&&B.tr&&B.tr.escortScreen===B.round) hull*=Math.max(0,1-es.n); } // Reyes T3b: the escort screen cuts enemy wing damage
  { const bell=treeSkill('bell'); if(bell&&t.side==='player'&&cmdActive('player','iron')&&!B.tr.bellUsed){ B.tr.bellUsed=1; if(hull>0){ hull=0; treeFx(t,'bell','the bell takes the blow'); } } } // Maren T2a
  { const up=treeSkill('unpaid'); if(up&&t.side==='player'&&cmdActive('player','iron')&&t.hp<t.maxHp/2) treeFx(t,'unpaid','the wall pays more'); } // Thale T3a
  { const tr=treeSkill('twiceRestored'); if(tr&&t.side==='player'&&cmdActive('player','iron')&&t.treeRepaired) treeFx(t,'twiceRestored','the twice-restored hull holds'); } // Seveth T1b
  { const nl=treeSkill('noLayer'); if(nl&&t.side==='player'&&cmdActive('player','iron')&&!t.treeAbsorbed&&hull>0){ hull=0; t.treeAbsorbed=1; treeFx(t,'noLayer','the layered plates take the hit'); } } // Seveth T3a
  let crit=false, critAdd=0;
  { const ft=treeSkill('filedTriplicate'); if(ft&&att&&att.side==='player'&&B&&B.treeFiled&&t.id===B.treeFiled.id) critAdd+=ft.n; } // Vorn T1a
  { const fb=treeSkill('filedBefore'); if(fb&&att&&att.side==='player'&&!att.isSq&&cmdActive('player','hunt')&&(att.hexMoved||0)===0){ critAdd+=fb.n; treeFx(att,'filedBefore','the file is ahead of the move'); } } // Vorn T2b
  if(hull>0.5 && rnd()*100 < (w.crit||0)+att.crit+(att.lockOn?10:0)+(rear?15:0)+((att.hexMoved||0)>=3?(of.momCrit||0):0)+critAdd){ hull*=1.5+(of.critMul||0); crit=true; }
  if(crit&&critAdd>0&&att&&att.side==='player'){ if(treeSkill('filedBefore')) treeFx(att,'filedBefore','the file is ahead of the move'); else if(treeSkill('filedTriplicate')) treeFx(att,'filedTriplicate','the triplicate tells'); }
  hull=Math.round(hull);
  { const fa=treeSkill('filedArmor'); if(fa&&t.side==='player'&&cmdActive('player','iron')&&!t.treeRoundFired&&hull>0){ hull=Math.max(0,hull-fa.n); treeFx(t,'filedArmor','the armor was filed'); } } // Maren T3b
  { const sc=treeSkill('standardCovers'); if(sc&&t.side==='player'&&cmdActive('player','iron')&&hull>0) treeFx(t,'standardCovers','the standard covers all'); } // Maren capstone 1
  { const sb=treeSkill('sevenBreach'); if(sb&&crit&&att&&att.side==='player'){ const sec=t._calledSec||SEC_OF_QUAD[quad]; for(const w2 of t.weapons){ if((sec==='prow'&&w2.arc==='F')||(sec==='mid'&&(w2.arc==='P'||w2.arc==='S'))) w2.off=Math.max(w2.off||0,2); } treeFx(t,'sevenBreach','the breach silences the section'); } } // Vorn T3b
  { const tt=treeSkill('tenThousand'); if(tt&&t.side==='player'&&cmdActive('player','iron')){ const cap=Math.round(t.maxHp*tt.n), have=t.treeRoundDmg||0; if(have+hull>cap){ hull=Math.max(0,cap-have); treeFx(t,'tenThousand','the wall counts ten thousand'); } t.treeRoundDmg=have+hull; } } // Seveth capstone 1
  if(hull>0&&t.tempHp>0){ const ab=Math.min(t.tempHp,hull); t.tempHp-=ab; hull-=ab; if(typeof fxText==='function') fxText(t,'\u2212'+ab+' grown hull','#8ff0a0',-30); } // H10: temporary hull is taken before hull
  if(hull>0&&!t.isSq&&!t.dead){ const ch=(of.igniteCh||0)+((w.arc==='P'||w.arc==='S')?(of.broadIgnite||0):0)+(att.isSq?(of.sqIgnite||0):0);
    if(ch>0&&rnd()<ch){ const fd=6+(of.fireDmg||0); if(!(t.st.fire>0)) boonFx(t,att.isSq&&of.sqIgnite?'d_burnswarm':(w.arc==='P'||w.arc==='S')&&of.broadIgnite&&!of.igniteCh?'d_inferno':'e_kindle','ignited',-28); t.st.fire=Math.max(t.st.fire||0,2+(of.fireLong||0)); t.st.fireDmg=Math.max(t.st.fireDmg||6,fd); } }
  if(hull>0&&!t.isSq&&!t.dead){ if(w.ignite){ t.st.fire=Math.max(t.st.fire||0,2); t.st.fireDmg=Math.max(t.st.fireDmg||6,6); } // v48 traits
    if(w.shred) t.shredded=Math.min(.15,(t.shredded||0)+w.shred);
    if(w.acid){ t.st.acid=2; } }
  if(of.pyre&&!t.isSq&&t.hp<t.maxHp/2) t.pyre=true;
  t.hp-=hull; att.dealt+=hull;
  let hard=false; { const hl=treeSkill('hardLight'); if(hl&&t.side==='player'&&cmdActive('player','iron')&&!t.treeHardUsed&&t.shMax>0&&sh0>0){ hard=true; t.treeHardUsed=1; treeFx(t,'hardLight','the shield holds the section'); } } // Brin T3b: the first hit with shield left skips section damage
  if(!hard) damageSection(t, t._calledSec||SEC_OF_QUAD[quad], hull, att);
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
  if(s.treeLock){ s.hp=Math.max(1,s.hp-dmg); return; } // Mending capstone 2: a section the tide grew back cannot be destroyed again
  if(s.hp<=0) return; s.hp=Math.max(0,s.hp-dmg); if(s.hp>0||s.broken) return;
  { const nb=treeSkill('nothingBroken'); if(nb&&t.side==='player'&&!B.tr.nothingSaved){ B.tr.nothingSaved=1; s.hp=s.max; treeFx(t,'nothingBroken','the weld holds'); return; } } // Vesh capstone 2: the first section loss of the battle is undone
  s.broken=true; if(typeof fxSectionDown==='function') fxSectionDown(t,sec);
  if(sec==='prow') t.weapons.forEach(w=>{ if(w.arc==='F') w.off=999; });
  if(sec==='mid'){ t.weapons.forEach(w=>{ if(w.arc==='P'||w.arc==='S') w.off=999; }); if(t.shMax>0){ t.st.shieldOff=999; t.sh=[0,0,0,0]; } }
  if(sec==='eng'){ t.secSave={turns:t.turns,ev:t.ev}; t.st.engine=Math.max(0,t.speed-1); t.turns=Math.min(t.turns,1); t.ev=0; }
  if(typeof fxText==='function') fxText(t,SEC_NAME[sec][0].toUpperCase()+SEC_NAME[sec].slice(1)+' destroyed','#f0b35a',-36);
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
  if(r==='shields'&&t.shMax>0&&(t.st.shieldOff||0)<99){ t.st.shieldOff=Math.max(t.st.shieldOff||0,2); return 'Shield generator down'; }
  if(r==='weapon'){ const ws=t.weapons.filter(w=>(w.off||0)<99); if(ws.length){ const w=pick(ws); w.off=Math.max(w.off||0,2); return w.n+' knocked out'; } } // B1 (F17): a crit never brings back a system a destroyed section already took out
  if(r==='shields'&&(t.st.shieldOff||0)>=99){ t.st.fire=2; return 'Fire on deck'; }
  t.st.fire=2; return 'Fire on deck';
}

async function fireWeapon(u,wi,t,opts={}){ if(!inThisBattle(u)) return false; const live=liveFrom(null);
  const w=u.weapons[wi]; let svArc=false;
  if(!opts.intercept && !canFire(u,w,t)){ if(opts.forceArc&&treeArcLegal(u,w,t)){ svArc=true; } else if(opts.forceRange&&treeRangeLegal(u,w,t)){ svArc=true; } else if(treeSecondVolleyOK(u,w,t)){ svArc=true; B.tr.secondVolleyUsed=1; treeFx(u,'secondVolley','one more synced ship fires out of arc'); } else return false; }
  const keep=[w.fired,w.cdLeft,u.sureUsed,u.postFire,u.postMp], b0=B; // v53: an abandoned shot gives the gun back (see the live check below)
  if(!opts.intercept){ w.fired=true; if(w.cd) w.cdLeft=w.cd; if(u.side==='player'&&!u.isSq){ u.sureUsed=(u.sureUsed||0)+1; u.treeHasFired=1; u.treeRoundFired=1; } }
  if(B.usage&&u.side==='player'&&!opts.intercept&&!u.isSq){ const k=(ARC_NAME&&ARC_NAME[w.arc])||String(w.arc); B.usage.fire[k]=(B.usage.fire[k]||0)+1; if(opts.called) B.usage.aim++; }
  if(B.usage&&u.side==='player'&&!opts.intercept){ const K=B.usage.kind=B.usage.kind||{}, kk=u.isSq?'sq':w.k; K[kk]=(K[kk]||0)+1; if(w.ion) B.usage.ion=(B.usage.ion||0)+1; } // B4: what the Nemesis learns from
  if(!opts.intercept&&!u.isSq&&w.k!=='flak'&&!u.postFire){ u.postFire=true; u.postMp=canFade(u)?(treeFullFade(u)?u.mp:Math.floor(u.mp*((u.fx&&u.fx.fade)||.5))):0; if(treeFullFade(u)) treeFx(u,'splitThree','the light splits three ways'); } // v54: firing ends normal movement (RWD-2: Slip the Net fade fraction scales with rarity)
  if(!opts.intercept&&u.side==='player'&&!u.isSq&&(u.ab==='launch'||(u.hangar||0)>0)) B.tr.carrierLast[u.id]=t.id; // Tamsa T1a: the carrier's last-fired target
  if(!opts.intercept&&torpTravels(w,u)){ // B3: torpedoes travel and strike next turn
    const r=await launchTorp(u,w,t,opts,live,keep,b0);
    if(r&&u.side==='player'&&!u.isSq&&cmdActive('player','hunt')){
      if(treeSkill('torpFirst')){ const S=B.torps[B.torps.length-1]; if(S&&S.by===u.id){ B.torps.pop(); await torpImpact(S); treeFx(u,'torpFirst','the torpedoes run first'); } } // Malek T2a: they strike at once
      if(!opts.half&&treeSkill('salvoEnd')&&!u.treeSalvoUsed){ u.treeSalvoUsed=1; let t2=null,bv=0;
        for(const e of alive('enemy')){ if(e===t||e.isSq||e.dead) continue; let v=0; for(const w2 of u.weapons){ if(w2.k!=='torp'||w2.off) continue; if(hdist(u,e)<=w2.r&&los(u,e)&&inArc(u,e,w2.arc)) v+=w2.dmg*w2.shots; } if(v>bv){ bv=v; t2=e; } }
        if(!t2) for(const e of alive('enemy')){ if(!e.isSq&&!e.dead&&e===t){ t2=e; break; } }
        if(!t2) for(const e of alive('enemy')){ if(!e.isSq&&!e.dead){ t2=e; break; } }
        if(t2){ const wi=u.weapons.findIndex(x=>x.k==='torp'&&!x.off); if(wi>=0&&await treeExtraShot(u,wi,t2,{half:true})) treeFx(u,'salvoEnd','the salvo has no end'); } }
    }
    return r;
  }
  if(!opts.intercept&&u.side==='player'&&!u.isSq){ const sm=treeSkill('smileCut'); if(sm&&cmdActive('player','hunt')&&!B.tr.smileUsed){ B.tr.smileUsed=1; u.treeSmile=1; } } // Sable T3a: the first ship to fire in the Command round
  // squadrons attacking capital ships run the flak gauntlet first
  if(u.isSq && !t.isSq && !opts.intercept){
    for(const d of alive(t.side)){
      if(d.isSq||d.intercepts<=0||d.braced) continue;
      { const fs=treeSkill('flakSkip'); if(fs&&cmdActive(u.side,'scramble')&&B.treeFlakSkip===d.id){ treeFx(d,'flakSkip','point defence looks the wrong way'); continue; } } // Tamsa T3a
      { const fc=treeSkill('flightCast'); if(fc&&cmdActive(u.side,'scramble')&&u.isSq&&u.extra&&d===t){ treeFx(d,'flightCast','the flak cannot see the strike'); continue; } } // Tamsa capstone 1: the target's flak is ignored
      const fi=d.weapons.findIndex(x=>x.k==='flak'&&x.off===0); if(fi<0) continue;
      if(hdist(d,u)>d.weapons[fi].r) continue;
      d.intercepts--;
      await fireWeapon(d,fi,u,{intercept:true});
      if(u.dead){ return true; }
    }
  }
  if(!opts.intercept && u.side==='enemy' && t.side==='player' && !t.isSq){ const fs=treeSkill('firstScar'); if(fs&&B.tr&&!B.tr.firstScarUsed){ const fg=B.units.find(x=>x.pflag&&!x.dead); if(fg&&fg!==t&&hdist(fg,t)===1){ t=fg; B.tr.firstScarUsed=1; treeFx(fg,'firstScar','the flagship takes the first scar'); } } } // Hullbreakers shared C1a
  const quad=shieldQuad(t,u), shBefore=(t.sh&&t.sh[quad])||0;
  const res={shield:0,hull:0,crits:0,hits:0,misses:0,sys:null};
  const called=opts.called&&!t.isSq&&!opts.intercept?opts.called:null;
  const su=u.sureUsed; if(!opts.intercept) u.sureUsed=keep[2];
  let treePen=0;
  if(!opts.intercept&&u.side==='enemy'&&t.side==='player'){
    { const fe=treeSkill('fleetElsewhere'); if(fe&&!B.tr.fleetElsewhere){ B.tr.fleetElsewhere=1; for(const x of alive('player')){ if(x.isSq) continue; const add=treeAddVal(x,'speed',fe.n); x.mp=(x.mp||0)+add; x.postMp=(x.postMp||0)+add; x.treeFreeTurn=1; } treeFx(treeFlagUnit()||t,'fleetElsewhere','the fleet is elsewhere'); } } // Vell capstone 1
    { const sa=treeSkill('silentArchive'); if(sa&&!t.isSq&&cmdActive('player','hunt')&&!inArc(u,t,'F')) treeFx(t,'silentArchive','the archive hides the ship'); } // Ostrel T3b
    B.tr.targeted[t.id]=1;
    if(!B.tr.firstLight){ const f1=treeSkill('firstLight'); if(f1){ B.tr.firstLight=u.id; const fg=B.units.find(x=>x.pflag&&!x.dead)||t; treeFx(fg,'firstLight',u.name+' is recorded'); } } // Brin shared C1b
    const wi=treeSkill('twoImages'); if(wi&&cmdActive('player','surge')&&!B.tr.enemyShots[t.id]){ B.tr.enemyShots[t.id]=1; treePen+=wi.n; treeFx(t,'twoImages','the image takes the shot'); } // Vell T1a
    if(u.treeAimDebuff){ treePen+=u.treeAimDebuff; u.treeAimDebuff=0; treeFx(t,'wardGlass','the ward reflects the aim'); } // Brin capstone 1
  }
  let starAim=0;
  { const st=treeSkill('starlings'); if(st&&!opts.intercept&&u.side==='player'&&u.isSq&&u.extra){ const arr=B.tr.wingTgt[t.id]||(B.tr.wingTgt[t.id]=[]); if(arr.some(id=>id!==u.id)) starAim=treeAddVal(u,'aim',st.n); if(!arr.includes(u.id)) arr.push(u.id); } } // Tamsa T2b
  let hc=hitChance(u,w,t); if(treePen) hc=Math.max(5,hc-treePen);
  { if(starAim>0){ hc=Math.min(95,hc+starAim); treeFx(u,'starlings','the starlings form up'); } }
  { if(u.treeAimNext){ hc=Math.min(95,hc+u.treeAimNext); treeFx(u,'stillnessCounted','the stillness counts'); u.treeAimNext=0; } } // Seveth T3b
  { const eg=treeSkill('everyGun'); if(eg&&u.treeAimPlus){ hc=Math.min(95,hc+u.treeAimPlus); treeFx(u,'everyGun','a shared solution'); u.treeAimPlus=0; } } // Vex T3a: ships on one target share the solution
  { const bb=treeSkill('breathBite'); if(bb&&!opts.intercept&&u.side==='enemy'&&cmdActive('player','surge')&&alive('player').filter(x=>!x.isSq&&hdist(x,u)===1).length>=2) treeFx(t,'breathBite','the throat has no room'); } // Razormaw T3b
  { const td=treeSkill('throatDeep'); if(td&&!opts.intercept&&u.side==='player'&&!u.isSq){ const fg=B.units.find(x=>x.pflag&&!x.dead); if(fg&&hdist(u,fg)<=2) treeFx(u,'throatDeep','the deep throat guides the shot'); } } // Chorus shared C1b
  { const wg=treeSkill('wardGlass'); if(!opts.intercept&&u.side==='enemy'&&t.side==='player'&&cmdActive('player','iron')&&wg&&!u.treeWardOnce){ u.treeWardOnce=1; u.treeAimDebuff=wg.n; } }
  { if(!opts.intercept&&u.side==='enemy'&&t.side==='player'&&!t.isSq){ const ew=treeEscortWing(t); if(ew){ t=ew; treeFx(ew,'escortName','the escort takes the hit'); } } } // H16 Ashgrove T1a
  u.sureUsed=su; // B3 (B-20): the rangefinder relic reads the count from before this shot (it never applied before)
  if(!opts.intercept&&!u.isSq){ fstat(u.fac,'shots'); if(syncOn(u,t)) fstat(u.fac,'syncShots'); } // telemetry: synced share of Hegemony fire
  const shots=[];
  for(let i=0;i<w.shots;i++) shots.push(rnd()*100<hc);
  { const fh=treeSkill('falseHulls'); if(!opts.intercept&&u.side==='enemy'&&fh&&cmdActive('player','surge')&&(B.tr.falseHulls||0)<fh.n){ B.tr.falseHulls=(B.tr.falseHulls||0)+1; for(let i=0;i<shots.length;i++) shots[i]=false; treeFx(u,'falseHulls','the attack is wasted on a false image'); } } // Vell capstone 2
  rocketDefense(w,t,shots,res);
  { const sr=treeSkill('standardReroll'); if(sr&&!opts.intercept&&u.side==='player'&&!u.isSq&&!B.tr.standardUsed){ const fg=B.units.find(x=>x.pflag&&!x.dead); if(fg&&hdist(u,fg)<=2){ let mi=-1; for(let i=0;i<shots.length;i++) if(!shots[i]){ mi=i; break; } if(mi>=0){ shots[mi]=rnd()*100<hc; B.tr.standardUsed=1; treeFx(u,'standardReroll','the standard rerolls a miss'); } } } } // Vex shared C1b
  let halfShot=-1; { const fz=treeSkill('frameZero'); if(fz&&!opts.intercept&&u.side==='player'&&u.pflag&&!B.tr.frameZeroUsed){ let mi=-1; for(let i=0;i<shots.length;i++) if(!shots[i]){ mi=i; break; } if(mi>=0){ B.tr.frameZeroUsed=1; shots[mi]=rnd()*100<hc; if(shots[mi]) halfShot=mi; treeFx(u,'frameZero','the frame zero shot is recorded'); } } } // Eclipse shared C1b
  { const fol=!u.isSq&&u.weapons.some(x=>x!==w&&x.fired); if(fol) SPEED*=PACE.volley; try{ if(typeof animWeapon==='function') await animWeapon(u,w,t,shots); } finally{ if(fol) SPEED/=PACE.volley; } } // B2: follow-up weapons in a volley play quicker (presentation only)
  if(B) B.prog=(B.prog||0)+1;
  if(!live()){ if(!opts.intercept&&B===b0){ w.fired=keep[0]; w.cdLeft=keep[1]; u.sureUsed=keep[2]; u.postFire=keep[3]; u.postMp=keep[4]; } return false; } // abandoned after a stall: the shot never lands, and the gun is not spent
  if(!opts.intercept) syncMarkShot(u,t); // B3: later synced ships get the bonus on this target this round
  if(!opts.intercept&&u.side==='player'&&!u.pflag&&!u.isSq) B.tr.indexTarget={id:t.id,r:B.round}; // Eclipse shared C1a: the flagship copies an ally's target
  const preSSid=B.tr.strikeSpeedId;
  const landed=landVolley(u,w,t,{quad,shBefore,shots,called,res,intercept:!!opts.intercept,half:!!opts.half,halfShot});
  if(landed&&!opts.intercept&&u.side==='player'&&!u.isSq&&B.tr.strikeSpeedId===preSSid){ B.tr.strikeSpeed=u.speed; B.tr.strikeSpeedId=u.id; } // Vorn T1b: the last ship that fired this round (a nested extra shot stays the last)
  if(landed&&!opts.intercept&&u.side==='player'&&!u.isSq&&inSync(u)) await treeSecondVolleyAuto(u,t); // Kassar T1b: one more synced ship, out of arc
  if(landed&&!opts.intercept&&u.side==='enemy'&&t.side==='player'&&t.shMax>0&&shBefore>0&&(t.sh[quad]||0)<=0){ const wa=treeSkill('wallAnswers'); if(wa&&cmdActive('player','iron')&&!t.treeAnswerUsed){ t.treeAnswerUsed=1; await treeWallAnswer(t,u); } } // H4 Thale T3b
  if(landed&&!opts.intercept&&u.side==='player'&&u.pflag&&!B.tr.ledgerUsed){ const fl=treeSkill('flagshipLedger'); if(fl){ const other=alive('player').find(x=>x!==u&&!x.isSq&&x.treeHasFired); if(other){ let wi=-1,bv=Infinity; for(let i=0;i<other.weapons.length;i++){ const w2=other.weapons[i]; if(w2.off||w2.k==='flak') continue; const v=w2.dmg*w2.shots; if(v<bv){ bv=v; wi=i; } } if(wi>=0){ const w2=other.weapons[wi]; let best=null,bs=-Infinity; for(const t2 of alive('enemy')){ const e=expectedVs(other,w2,t2); const v=e.hull+e.shield*.3; if(v>bs){ bs=v; best=t2; } } if(best&&canFire(other,w2,best)){ B.tr.ledgerUsed=1; if(await treeExtraShot(other,wi,best,{half:true})) treeFx(u,'flagshipLedger','the flagship calls in the debt'); } } } } } // H4 Vex shared C1a
  if(!opts.intercept&&u.side==='player'&&!u.isSq) u.treeRedFirst=0; // Razormaw capstone 1: the first shot spends it
  { if(landed&&!opts.intercept&&u.side==='player'&&!u.isSq&&treeSkill('rushRail')&&cmdActive(u.side,'surge')&&!u.treeRushLogged&&alive('enemy').some(x=>!x.isSq&&hdist(u,x)===1)){ u.treeRushLogged=1; treeFx(u,'rushRail','rush the rail'); } } // Grax T2b: the rail is reachable even after firing
  return landed;
}
// point defense near the target picks off rockets (Corsair rocket trait); at fire time, or at impact for a travelling salvo
function rocketDefense(w,t,shots,res,mult){ if(!w.rockets||t.isSq) return; const im=(mult==null?1:mult); let shot=0; for(const d of alive(t.side)){ if(d.isSq||d.intercepts<=0||d.braced) continue; const fw=d.weapons.find(x=>x.k==='flak'&&!(x.off>0)); if(!fw||hdist(d,t)>fw.r) continue;
    for(let i=0;i<shots.length&&d.intercepts>0;i++) if(shots[i]&&rnd()<.55*im){ shots[i]=false; d.intercepts--; shot++; } }
  if(shot){ res.pd=shot; if(typeof fxText==='function') fxText(t,shot+' rocket'+(shot>1?'s':'')+' shot down','#bfe3ff',30); } }
// the shots of one weapon land: damage, shields, criticals, callouts, the log line and a kill (shared by direct fire and torpedo impact)
async function landVolley(u,w,t,o){ const quad=o.quad, shots=o.shots, called=o.called, res=o.res;
  if(called){ u.crit+=15; t._calledSec=called; } // v45: applied only once the shot is known to land, so a stall can never leave it behind
  let hi=0;
  for(const h of shots){
    const shotIdx=hi++;
    if(t.dead) break;
    if(!h){ res.misses++; continue; }
    res.hits++;
    { const lf=treeSkill('longFocus'); if(lf&&B.volleyMul&&B.volleyMul.side===u.side&&!u.isSq&&hdist(u,t)>w.r/2) treeFx(t,'longFocus','the long focus bites'); } // Saro T1a
    { const ia=treeSkill('inheritedAim'); if(ia&&B.volleyMul&&B.volleyMul.side===u.side&&!u.isSq&&(u.hexMoved||0)===0) treeFx(t,'inheritedAim','the inherited aim holds'); } // Vex T2b
    { const np=treeSkill('namedPrey'); if(np&&B.treeNamedPrey&&B.treeNamedPrey.r===B.round&&u.side==='player'&&t.id===B.treeNamedPrey.id) treeFx(t,'namedPrey','the named prey falls'); } // Malek capstone 2
    { const bf=treeSkill('burnFlaw'); if(bf&&B.volleyMul&&B.volleyMul.side===u.side){ const n=(B.tr.volleyHits[t.id]||0)+1; B.tr.volleyHits[t.id]=n; if(n>=3) t._treePierce=1; treeFx(t,'burnFlaw',n>=3?'the third hit passes the shields':'hits stack'); } } // Saro T3a counter
    { const nc=treeSkill('noonChoice'); if(nc&&u.side==='player'&&!u.isSq&&B.treeNoon&&B.volleyMul&&B.volleyMul.side===u.side) treeFx(u,'noonChoice','the noon is chosen'); } // Umbra T1b
    { const ef=treeSkill('everyFrame'); if(ef&&u.side==='player'&&!u.isSq&&B.volleyMul&&B.volleyMul.side===u.side&&(u.hexMoved||0)===0) treeFx(u,'everyFrame','every frame fires at noon'); } // Umbra T3b
    { const cs=treeSkill('coronaShadow'); if(cs&&u.side==='player'&&B.volleyMul&&B.volleyMul.side===u.side) treeFx(u,'coronaShadow','the noon throws no shadow'); } // Umbra T3a
    { const fi=treeSkill('flagshipIndex'); if(fi&&u.side==='player'&&u.pflag&&B.tr.indexTarget&&t.id===B.tr.indexTarget.id) treeFx(u,'flagshipIndex','the index is copied'); } // Eclipse shared C1a
    { const uc=treeSkill('uncopiedTarget'); if(uc&&u.side==='player'&&cmdActive(u.side,'hunt')&&!t.treeHitBattle) treeFx(u,'uncopiedTarget','the uncopied target is found'); } // Ostrel T2b
    { const rd=treeSkill('runDown'); if(rd&&u.side==='player'&&!u.isSq&&cmdActive(u.side,'surge')&&t.speed<u.speed) treeFx(t,'runDown','the slowest are run down'); } // Razormaw T1a
    { const as=treeSkill('acidSeams'); if(as&&B.volleyMul&&B.volleyMul.side==='player'&&u.side==='player'&&t.side==='enemy'&&t.hp<t.maxHp/2) treeFx(t,'acidSeams','the acid finds the seams'); } // Voice T3a
    { const pc=treeSkill('packCloses'); if(pc&&u.side==='player'&&!u.isSq&&cmdActive(u.side,'surge')&&alive('player').some(x=>x!==u&&!x.isSq&&hdist(x,u)===1)) treeFx(u,'packCloses','the pack closes'); } // Grax T2a
    { const pg=treeSkill('patchGuns'); if(pg&&u.side==='player'&&!u.isSq&&u.treeAimGuns) treeFx(u,'patchGuns','the patched guns find the mark'); } // Vesh T1b
    { const ps=treeSkill('preyScent'); if(ps&&u.side==='player'&&!u.isSq&&B.tr&&B.tr.scent===t.id) treeFx(u,'preyScent','the named prey is scented'); } // Hullbreakers shared B1a
    { const rB=treeSkill('runBigger'); if(rB&&u.side==='player'&&!u.isSq&&cmdActive(u.side,'surge')&&u.treeBigStart!=null&&B.tr&&B.tr.bigId){ const big=B.units.find(x=>x.id===B.tr.bigId&&!x.dead); if(big&&(u.hexMoved||0)>0&&hdist(u,big)<u.treeBigStart) treeFx(u,'runBigger','the biggest thing is closer'); } } // Grax T1a
    { const sm=treeSkill('smileCut'); if(sm&&u.side==='player'&&!u.isSq&&u.treeSmile) treeFx(u,'smileCut','the first cut smiles'); } // Sable T3a
    { const pb=treeSkill('packBites'); if(pb&&u.side==='player'&&!u.isSq&&u.treeDmgCarry&&u.treeDmgCarry.r===B.round) treeFx(u,'packBites','the pack bites on'); } // Vesh T3b
    const rq=treeIsRear(u,t,quad);
    { if(rq&&u.side==='player'&&!u.isSq&&cmdActive(u.side,'surge')&&!u.treeTeethUsed){ u.treeTeethUsed=1; treeFx(u,'teethThroat','the teeth find the throat'); } } // Razormaw T1b: the first rear hit spends the bonus
    if(rq&&quad!==2) treeFx(u,'debtHunts','side hits count as rear');
    { const kb=treeSkill('knifeBack'); if(kb&&rq&&u.side==='player'&&!u.isSq&&cmdActive(u.side,'hunt')) treeFx(u,'knifeBack','the knife finds the back'); } // Sable T1a
    { const ct=treeSkill('cutTurn'); if(ct&&rq&&u.side==='player'&&!u.isSq){ u.treeFreeTurn=1; treeFx(u,'cutTurn','cut and turn'); } } // Sable T2a
    { const ek=treeSkill('everyKnife'); if(ek&&rq&&u.side==='player'&&!u.isSq){ const arr=B.tr.rearShips[t.id]||(B.tr.rearShips[t.id]=[]); if(!arr.includes(u.id)) arr.push(u.id); if(arr.length>=3&&t.treeKnifeRound==null){ t.treeKnifeRound=B.round+1; treeFx(t,'everyKnife','three knives find one back'); } } } // Sable T3b counter
    { if(rq&&u.side==='player'&&!u.isSq&&u.treeHuntRearNext&&u.treeHuntRearNext.r===B.round){ treeFx(u,'darkKnives','the dark keeps its knives'); u.treeHuntRearNext=null; } } // Sable capstone 1: spent on the first rear shot
    { const cb=treeSkill('copiedBehind'); if(cb&&rq&&u.side==='player'&&cmdActive(u.side,'hunt')) treeFx(u,'copiedBehind','the copy strikes the rear'); } // Ostrel T1a
    { const ua=treeSkill('unseenArchive'); if(ua&&u.side==='player'&&cmdActive(u.side,'hunt')&&B.tr&&!B.tr.targetedLast[u.id]) treeFx(u,'unseenArchive','the unseen ship strikes'); } // Ostrel T1b
    let stMul=1;
    { const st2=treeSkill('secondThroat'); if(st2&&u.isSq&&u.side==='player'&&t.side==='enemy'){ const first=B.tr.swarmHitBy&&B.tr.swarmHitBy[t.id]; if(first&&first!==u.id){ stMul=1+treeAddVal(u,'sqPct',st2.n); treeFx(u,'secondThroat','the second throat bites'); } else if(!first){ B.tr.swarmHitBy=B.tr.swarmHitBy||{}; B.tr.swarmHitBy[t.id]=u.id; } } } // Matriarch T3b
    { const ti=treeSkill('totalInterdiction'); if(ti&&u.side==='player'&&!u.isSq&&cmdActive(u.side,'hunt')){ const s=B.tr.totalShips[t.id]||(B.tr.totalShips[t.id]={}); s[u.id]=1; if(Object.keys(s).length>=3) treeFx(t,'totalInterdiction','three ships have it'); } } // Vorn T3a
    { const sb=treeSkill('strikeBook'); if(sb&&u.side==='player'&&!u.isSq&&cmdActive(u.side,'hunt')&&B.tr.strikeSpeed!=null&&u.speed>=B.tr.strikeSpeed) treeFx(u,'strikeBook','the book is followed'); } // Vorn T1b
    { const cf=treeSkill('crossFire'); if(cf&&u.side==='player'&&cmdActive(u.side,'hunt')&&(B.tr.crossHits[t.id]||0)>=1) treeFx(t,'crossFire','the file is cross-referenced'); } // Vorn T2a
    { const pf=treeSkill('permanentFile'); if(pf&&u.side==='player'&&B.treePermFile&&B.treePermFile.r===B.round&&B.treePermFile.ids[t.id]) treeFx(t,'permanentFile','the permanent file pays'); } // Vorn capstone 1
    { const pr=treeSkill('rehearsed'); if(pr&&u.isSq&&u.side==='player'&&u.extra&&cmdActive('player','scramble')) treeFx(u,'rehearsed','the procedure is rehearsed'); } // Reyes T2b
    let d=(o.per?o.per(rq):dmgMult(u,w,t,rq))*(0.85+rnd()*.3)*(o.half?.5:1)*stMul;
    { const itk=treeSkill('iterationKill'); if(itk&&u.side==='player'&&cmdActive(u.side,'hunt')&&B.tr.iterKill&&B.tr.iterKill[t.id]){ d*=1+treeAddVal(u,'dmgPct',itk.n); B.tr.iterKill[t.id]=0; treeFx(u,'iterationKill','the next hit bites deeper'); } } // Ostrel T3a
    if(o.halfShot===shotIdx) d*=0.5; // Eclipse shared C1b: the recorded frame zero shot lands at half damage
    let flightSec=null;
    { const fc=treeSkill('flightCast'); if(fc&&u.isSq&&u.side==='player'&&u.extra&&cmdActive('player','scramble')&&t.side==='enemy'){ const n=(B.tr.wingCap[t.id]||0)+1; B.tr.wingCap[t.id]=n;
      if(n>1){ t._treePierce=1; d*=1+treeAddVal(u,'dmgPct',fc.n); const secs=t.sec?Object.keys(t.sec):[]; let best=null,br=2; for(const k2 of secs){ const s2=t.sec[k2]; if(s2.broken) continue; const rr=s2.hp/s2.max; if(rr<br){ br=rr; best=k2; } } if(best){ flightSec=best; t._calledSec=best; }
        treeFx(u,'flightCast','the strike passes the shields'); } } } // Tamsa capstone 1
    { const ff=treeSkill('frenzyFeeds'); if(ff&&u.side==='player'&&!u.isSq&&cmdActive(u.side,'surge')&&rq&&!u.treeFrenzyMove){ u.treeFrenzyMove=1; u.mp=(u.mp||0)+ff.n; u.postMp=Math.max(u.postMp||0,ff.n); treeFx(u,'frenzyFeeds','the frenzy feeds the throat'); } } // Razormaw T3a
    { const wd=treeSkill('wingsDebt'); if(wd&&u.isSq&&u.side==='player'&&!B.tr.wingsDebt[u.parent]&&B.tr.carrierHit[u.parent]===t.id){ d*=1+treeAddVal(u,'sqPct',wd.n); B.tr.wingsDebt[u.parent]=1; treeFx(u,'wingsDebt','the wings settle the debt'); } } // Ashgrove T3b
    const r=applyHit(u,w,t,d,quad);
    if(u.treeIterFire) u.treeIterFire=0; // Nadir T2a: the bonus belongs to the next shot only
    if(flightSec&&t._calledSec===flightSec) t._calledSec=null;
    { const fp=treeSkill('flightPaths'); if(fp&&u.isSq&&u.extra&&u.side==='player'){ const par=B.units.find(x=>x.id===u.parent); if(par&&B.tr.carrierLast&&B.tr.carrierLast[par.id]===t.id) treeFx(u,'flightPaths','the wing follows the glass'); } } // Tamsa T1a
    { const rp=treeSkill('replay'); if(rp&&u.isSq&&u.extra&&u.side==='player'&&B.tr.strikeAgain===B.round&&B.tr.hitRound[t.id]===1) treeFx(u,'replay','the replay corrects'); } // Tamsa T2a
    { const asp=treeSkill('accountSplits'); if(asp&&u.isSq&&u.extra&&u.side==='player'){ const arr=(B.tr.wingTargets&&B.tr.wingTargets[u.parent])||[]; if(arr.some(x=>x.sq!==u.id&&x.tid!==t.id)) treeFx(u,'accountSplits','the account splits'); } } // Ashgrove T2a
    { const la=treeSkill('ledgerArcs'); if(la&&u.side==='player'&&!u.isSq&&B&&B.volleyMul&&B.volleyMul.side===u.side&&(w.arc==='P'||w.arc==='S')) treeFx(u,'ledgerArcs','the broadside is on the ledger'); } // Vex T1a
    { const ol=treeSkill('oneLens'); if(ol&&u.side==='player'&&!u.isSq&&B&&B.tr&&B.tr.oneLens&&u.id===B.tr.oneLens.ship&&t.id===B.tr.oneLens.tgt&&B.volleyMul&&B.volleyMul.side===u.side) treeFx(u,'oneLens','one lens, one target'); } // Saro T1b
    { const lt=treeSkill('lightTogether'); if(lt&&u.side==='player'&&!u.isSq&&B&&B.volleyMul&&B.volleyMul.side===u.side){ const arr=B.tr&&B.tr.lightTgt?B.tr.lightTgt[t.id]:null; if(arr&&arr.some(id=>id!==u.id)) treeFx(u,'lightTogether','the light arrives together'); } } // Saro T2a
    { const rr2=treeSkill('rearReckoning'); if(rr2&&rq&&u.side==='player'&&cmdActive(u.side,'hunt')) treeFx(u,'rearReckoning','the rear arc reckons'); } // Malek T2b
    { if(treeSkill('lightTogether')&&u.side==='player'&&!u.isSq&&!o.intercept){ const arr=B.tr.lightTgt[t.id]||(B.tr.lightTgt[t.id]=[]); if(!arr.includes(u.id)) arr.push(u.id); } } // Saro T2a counter: every hit by one of your ships this round counts, not only volley hits
    { if(u.isSq&&u.side==='player'){ const arr=B.tr.wingTargets[u.parent]||(B.tr.wingTargets[u.parent]=[]); if(!arr.some(x=>x.sq===u.id&&x.tid===t.id)) arr.push({sq:u.id,tid:t.id}); if(u.extra) u.treeLastTgt=t.id; } } // Ashgrove T2a tracking, Tamsa capstone 2 target
    if(u.side==='player'){ B.tr.crossHits[t.id]=(B.tr.crossHits[t.id]||0)+1; if(cmdActive(u.side,'hunt')) B.tr.hitDuringStrike[t.id]=1; } // Vorn T2a, capstone 1
    { if(u.isSq&&u.side==='player'&&u.extra){ const rt=treeSkill('reTasked'); if(rt&&!B.tr.wingStruck[t.id]) treeFx(u,'reTasked','the wing takes a fresh target'); const sc=treeSkill('screaming'); if(sc&&B.tr.hitRound[t.id]) treeFx(u,'screaming','the wing comes back screaming'); const pw=treeSkill('privateWing'); if(pw&&u.treePrivate&&u.treePrivateRound!==B.round){ u.treePrivateRound=B.round; treeFx(u,'privateWing','the private wing strikes first'); } } } // Mott T2a, T3b, capstone 2 callouts
    { if(u.isSq&&u.side==='player'){ B.tr.wingStruck[t.id]=1; B.tr.hitRound[t.id]=1; } else if(u.side==='player') B.tr.hitRound[t.id]=1; } // Mott counters: which targets this round's hits and wings have found
    if(u.treeSmile) u.treeSmile=0; // Sable T3a: the bonus belongs to the first shot only
    { const aw=treeSkill('arcsWarm'); if(aw&&u.side==='player'&&w.id==='doom'&&B.volleyMul&&B.volleyMul.side===u.side&&!o.intercept){ const near=alive('enemy').filter(x=>x!==t).sort((a,b)=>hdist(a,t)-hdist(b,t)||(a.id<b.id?-1:1)); const adj=near[0]||null; if(adj){ const rr=applyHit(u,w,adj,d*aw.n,shieldQuad(adj,u)); res.hull+=rr.hull; if(adj.hp<=0){ adj.killCause='big'; await killUnit(adj,u); } treeFx(u,'arcsWarm','the corona splashes'); } } } // Umbra T1a
    { const bs=treeSkill('burnStays'); if(bs&&B.volleyMul&&B.volleyMul.side==='player'&&u.side==='player'&&!u.isSq&&t.side==='enemy'){ B.tr.burnStays=B.tr.burnStays||{}; B.tr.burnStays[t.id]=(B.tr.burnStays[t.id]||0)+(r.hull||0); } } // Voice T2a: the burn stays
    if(rq&&u.side==='player'&&cmdActive(u.side,'hunt')) B.tr.iterKill[t.id]=1; // Ostrel T3a: mark the next hit this round
    if(u.side==='player'&&!t.isSq) t.treeHitBattle=1;
    res.shield+=r.shield; res.hull+=r.hull; if(r.crit){ res.crits++; const cs=ownerFx(u).critSys; if(!res.sys && (called||cs||rnd()<.4)){ res.sys=systemDamage(t,called); if(cs&&res.sys) boonFx(t,'a_crit',res.sys,-48); } }
  }
  if(res.hits>0&&B.volleyMul&&B.volleyMul.side==='player'&&u.side==='player'&&!u.isSq) u.treeVolleyHit=1; // Voice capstone 1: the first spit found the hull
  if(res.hits>0&&B.volleyMul&&B.volleyMul.side==='player'&&u.side==='player'&&!u.isSq&&treeSkill('manyMouths')){ const arr=B.tr.volleyShips[t.id]||(B.tr.volleyShips[t.id]=[]); if(!arr.includes(u.id)) arr.push(u.id); } // Voice T3b counter
  if(called){ u.crit-=15; t._calledSec=null; }
  if(res.hits>0&&u.side==='player'&&!u.isSq&&!o.torp&&!o.intercept&&(u.ab==='launch'||(u.hangar||0)>0)) B.tr.carrierHit[u.id]=t.id; // Ashgrove T3b: which target the carrier's guns hit this round
  { const rw=treeSkill('rollWings'); if(rw&&u.isSq&&u.side==='player'&&cmdActive('player','scramble')&&res.hits>0&&!o.intercept&&!t.dead){ t.st.fire=Math.max(t.st.fire||0,2); t.st.fireDmg=Math.max(t.st.fireDmg||6,6); t.treeFlakDown=(t.treeFlakDown||0)+1; treeFx(u,'rollWings','the wing sets it burning'); } } // Ashgrove capstone 1
  if(res.hits&&B.nem){ if(t.nem&&u.side==='player'){ if(quad===2) nemTrip('flank'); if((w.ion||w.k==='lance')&&res.shield>0) nemTrip('ion'); if(o.torp) nemTrip('torp'); } if(u.nem&&t.side==='player'&&!u.isSq&&hdist(u,t)<=2) nemTrip('brawl'); } // R42
  if(res.shield>0){ if(typeof fxShield==='function') fxShield(t,quad); if(typeof fxText==='function') fxText(t,'−'+res.shield+' shield','#62ccff',-18); if(t.shMax>0&&t.sh[quad]<=.5){ if(typeof fxShieldBreak==='function') fxShieldBreak(t,quad); if(typeof fxText==='function') fxText(t,'Shields down','#9fe2ff',-40);
      if(ownerFx(u).chainSh&&o.shBefore>.5&&!t.dead&&t.sh){ const csh=ownerFx(u).chainSh; for(const qq of [(quad+1)%4,(quad+3)%4]) t.sh[qq]=Math.round(t.sh[qq]*(1-csh)); boonFx(t,'s_chain','chain lightning',-62); } // Chain Lightning (RWD-2: chainSh scales with rarity)
      const ar=ownerFx(u).arcShort; if(ar&&o.shBefore>.5&&!t.dead){ t.hp-=ar; res.hull+=ar; u.dealt+=ar; boonFx(t,'s_arc','−'+ar,-56); } } }
  if(res.hull>0&&typeof fxText==='function') fxText(t,'−'+res.hull+' hull',res.crits?'#ffd27a':'#ffae42',0);
  if(res.hits===0&&typeof fxText==='function') fxText(t,'Miss','#9a9384',0);
  if(res.crits){ if(typeof fxText==='function') fxText(t,'Critical','#f0b35a',18); if(typeof fxCrit==='function') fxCrit(t); }
  const who = u.side==='player'?'p':'e';
  const parts=[];
  if(res.pd) parts.push(`${res.pd} shot down by point defense`);
  if(res.hits===0) parts.push('all shots miss');
  else { if(res.shield) parts.push(`${res.shield} to ${QUAD_NAME[quad]} shields`); if(res.hull) parts.push(`${res.hull} hull`); if(!res.shield&&!res.hull) parts.push('no damage'); }
  if(res.crits) parts.push(res.crits>1?`${res.crits} criticals`:'critical');
  if(!o.torp&&!o.intercept&&res.hull>0&&t.side!==u.side){ const bite=chorusBiteEst(u,t,res.hull); if(bite) chorusRegrow(u,bite,'Bites'); } // v54 Chorus doctrine
  if(res.hits>0&&w.k==='lance'&&!o.intercept&&ownerFx(u).markLance&&B&&(!(B.mark=B.mark||{})[u.side]||B.mark[u.side].r!==B.round)&&!t.dead){ B.mark[u.side]={id:t.id,r:B.round,aim:10*(ownerFx(u).markLance||1)}; boonFx(t,'a_mark','marked',-62); } // Marked for Death
  log(o.torp?`Torpedoes from ${u.name} reach ${t.name}${o.stray?' (a stray hit in the lane)':''}: ${parts.join(', ')}.${res.sys?' '+res.sys+'!':''}`:`${u.name} ${o.intercept?'intercepts with':'fires'} ${w.n} at ${t.name}: ${parts.join(', ')}.${res.sys?' '+res.sys+'!':''}`, who);
  if(!o.torp&&res.hits>0&&t.braced&&!t.dead&&!u.dead&&!o.intercept&&t.side!==u.side){ const rp=ownerFx(t).riposte; if(rp){ u.hp-=rp; t.dealt=(t.dealt||0)+rp; boonFx(u,'i_brace','−'+rp,-40); if(u.hp<=0) await killUnit(u,t); } } // Iron Discipline: braced ships strike back
  if(t.hp<=0){ t.killCause=killCauseOf(w,t); await killUnit(t,o.by||u); }
  return true;
}
// B3 torpedo launch: the gun is spent and the salvo is placed in flight with its lane; nothing is rolled yet
async function launchTorp(u,w,t,opts,live,keep,b0){
  const S={id:(B.torpSeq=(B.torpSeq||0)+1), side:u.side, by:u.id, fac:u.fac, w:Object.assign({},w), tid:t.id, aim:{q:t.q,r:t.r}, from:{q:u.q,r:u.r}, r:B.round, called:opts.called&&!t.isSq?opts.called:null};
  fstat(u.fac,'shots'); if(syncOn(u,t)) fstat(u.fac,'syncShots');
  S.base=dmgMult(u,w,t,false)*TORP_WARHEAD; S.rearAdd=dmgMult(u,w,t,true)*TORP_WARHEAD-S.base; if(opts&&opts.half){ S.base*=.5; S.rearAdd*=.5; } S.ghost=torpGhost(u,keep[2]); // multipliers as the preview showed them at launch; Malek capstone 1 fires the second torpedo at half damage
  { const pn=treeSkill('preyName'); if(pn&&u.side==='player'&&B.treePrey&&B.treePrey.r===B.round&&B.treePrey.id===t.id){ const b=treeAddVal(u,'torpPct',pn.n); S.base*=1+b; S.rearAdd*=1+b; treeFx(u,'preyName','the named prey pays'); } } // Malek T1a
  { if(u.side==='player'&&cmdActive(u.side,'hunt')&&treeSkill('darkTorps')){ S.dark=1; treeFx(u,'darkTorps','the torpedoes come in unseen'); } } // Sable T1b
  { const ts=treeSkill('twoSalvos'); if(ts&&u.side==='player'&&u.treeTorpCarry){ S.base*=1+u.treeTorpCarry; S.rearAdd*=1+u.treeTorpCarry; u.treeTorpCarry=0; treeFx(u,'twoSalvos','the first torpedo keeps the salvo bonus'); } } // Malek T3b
  { const ow=treeSkill('oathWings'); if(ow&&u.side==='enemy'&&t.side==='player'&&cmdActive('player','scramble')&&alive('player').some(x=>!x.isSq&&(x.ab==='launch'||(x.fx&&x.fx.hive))&&hdist(x,t)<=2)){ S.oath=1; treeFx(t,'oathWings','the escort wall closes'); } } // Ashgrove capstone 2
  if(typeof animTorpLaunch==='function'){ try{ await animTorpLaunch(u,S); }catch(e){ console.warn(e); } if(!live()){ if(B===b0){ w.fired=keep[0]; w.cdLeft=keep[1]; u.sureUsed=keep[2]; u.postFire=keep[3]; u.postMp=keep[4]; } return false; } }
  syncMarkShot(u,t); B.torps.push(S); fstat(u.fac,'torpLaunch'); if(B) B.prog=(B.prog||0)+1;
  log(`${u.name} launches ${w.n} at ${t.name}. They strike its marked hex next turn.`, u.side==='player'?'p':'e'); try{ if(typeof fxText==='function') fxText(t,'Torpedo lane: impact next turn','#ff9f3a',-44); }catch(e){}
  return true; }
// B3 torpedo impact, at the start of the firing side's next turn (after that side's turn ticks)
async function torpImpact(S){ const live=liveFrom(null), w=S.w, g=S.ghost; g.q=S.from.q; g.r=S.from.r;
  const real=B.units.find(x=>x.id===S.by)||null, orig=B.units.find(x=>x.id===S.tid);
  let t=null, pen=0;
  if(orig&&!orig.dead&&orig.side!==S.side&&hdist(orig,S.aim)<=2){ t=orig; pen=(w.trait==='star'?[0,0,10]:TORP_RING)[hdist(orig,S.aim)]; } // Ithar star torpedoes are fast and track better
  else { const foes=B.units.filter(o=>!o.dead&&!o.isSq&&o.side!==S.side&&hdist(o,S.aim)<=((orig&&!orig.dead)?0:1)).sort((a,b)=>hdist(a,S.aim)-hdist(b,S.aim)||(a.id<b.id?-1:1)); if(foes.length){ t=foes[0]; pen=TORP_STRAY; } } // a stray hull on the aim hex; if the target is already gone, the nearest enemy within 1 hex
  if(!t&&g.fx&&g.fx.spread){ const near=alive(S.side==='player'?'enemy':'player').filter(x=>!x.isSq&&hdist(x,S.aim)<=1); if(near.length){ log(`${w.n} from ${g.name} burst in the lane, catching ${near.length} ship${near.length>1?'s':''}.`,S.side==='player'?'p':'e');
    for(const x of near){ if(x.dead) continue; const r=applyHit(g,w,x,S.base*g.fx.spread,shieldQuad(x,g)); boonFx(x,'e_spread','\u2212'+r.hull,-20); if(x.hp<=0){ x.killCause='big'; await killUnit(x,real||g); } } } } // Spread Pattern
  if(!t){ fstat(S.fac,orig&&!orig.dead?'torpDodge':'torpGone'); log(`${w.n} from ${g.name} run wide: ${orig&&!orig.dead?orig.name+' slipped out of the lane':'nothing left in the lane'}.`,'x'); try{ if(typeof fxFlash==='function') fxFlash(S.aim,'#ff9f3a'); }catch(e){} return; }
  const quad=shieldQuad(t,g), shBefore=(t.sh&&t.sh[quad])||0, res={shield:0,hull:0,crits:0,hits:0,misses:0,sys:null};
  const hc=clamp(hitChance(g,w,t)-pen+(t.nem&&nemWeak('torp')?15:0),5,95), shots=[]; for(let i=0;i<w.shots;i++) shots.push(rnd()*100<hc);
  const im=S.dark?0.5:1; // Sable T1b: torpedoes fired in the dark are intercepted at half the usual chance
  rocketDefense(w,t,shots,res,im); screenTorps(t,shots,res,im); // B4: screening wings beside the target thin the salvo
  { if(S.oath){ for(let i=0;i<shots.length;i++) if(shots[i]){ if(rnd()<WING_SCREEN_TORP){ shots[i]=false; res.pd=(res.pd||0)+1; } treeFx(g,'oathWings','the wall takes the salvo'); break; } } } // Ashgrove capstone 2
  try{ if(typeof animWeapon==='function') await animWeapon(g,w,t,shots); }catch(e){ console.warn(e); }
  if(!live()||t.dead) return;
  const d0=g.dealt||0, same=t===orig;
  await landVolley(g,w,t,{quad,shBefore,shots,called:same?S.called:null,res,torp:true,stray:!same,per:same?(rear=>S.base+(rear?S.rearAdd:0)):null,by:real||g});
  { if(real&&!real.dead&&!res.hits) treeSecondKnife(real); } // Sable T2b: a torpedo that misses reloads one turn sooner than normal
  if(res.hits) fstat(S.fac,'torpHit'); if(real) real.dealt=(real.dealt||0)+(g.dealt||0)-d0; }
async function resolveTorps(side){ if(!B||!B.torps||!B.torps.length) return; const b0=B, due=B.torps.filter(s=>s.side===side&&s.r<B.round); if(!due.length) return; B.torps=B.torps.filter(s=>!due.includes(s));
  for(const S of due){ if(B!==b0||B.over) return; await torpImpact(S); } if(B===b0) checkEnd(); }
// one side's turn start: ticks (and their deaths), then that side's torpedoes land. The game and the sims both use these, so the order cannot drift.
async function turnStart(side){ const d=startSideTurn(side); if(d) await d; if(side==='player'&&B&&!B.over) await treeRoundFx(); if(B&&!B.over) await resolveTorps(side); }
// alternating round start: player ticks, enemy ticks (unless the battle ended), then player torpedoes, then enemy torpedoes
async function roundStartBoth(){ const b0=B, d1=startSideTurn('player'), d2=B.over?null:startSideTurn('enemy'); if(d1) await d1; if(d2) await d2; if(B!==b0||B.over) return; await treeRoundFx(); if(B!==b0||B.over) return; await resolveTorps('player'); if(B!==b0||B.over) return; await resolveTorps('enemy'); }
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
  const maw=treeSkill('mawOpens'), mawAdd=(maw&&u.side==='player'&&cmdActive(u.side,'surge')&&!u.treeMawUsed)?treeAddVal(u,'ramPct',maw.n):0; // Grax T3b: the first ram of the burn
  const raw=base*(1+(f.ramPct||0)+mawAdd)*(u.ramBoost||1)*(quad===0?1:1.2)*(1-t.armor*.5), soak=Math.min(raw*.5,(t.sh&&t.sh[quad])||0);
  return {dmg:Math.round(Math.min(raw-soak,t.maxHp*(.4+Math.min(.3,f.ramCap||0)))), soak:Math.round(soak), recoil:Math.round(base*(RAM_FAC[u.fac]?.35:.5)*clamp(t.size/u.size,.5,1.6)*(1-u.armor*.5)*(1-Math.min(1,f.ramGuard||0))), sec:SEC_OF_QUAD[quad]}; }
async function ramUnit(u){
  const mawPre=!!(treeSkill('mawOpens')&&u.side==='player'&&cmdActive(u.side,'surge')&&!u.treeMawUsed); // Grax T3b
  const info=ramInfo(u); if(!info) return false; const t=info.t, live=liveFrom(u);
  if(typeof animPath==='function') await animPath(u,info.path,{charge:true}); else for(const p of info.path){ if(typeof animMove==='function') await animMove(u,p.q,p.r,p.f); }
  if(!live()) return false; // abandoned after a stall: the ram never lands
  for(const p of info.path){ u.q=p.q; u.r=p.r; } u.facing=info.path.at(-1).f; // v53: the ram commits its own run-up (animPath is presentation only)
  u.mp=0; u.turnsLeft=0; u.rammed=true; if(B.usage&&u.side==='player'){ B.usage.ram=(B.usage.ram||0)+1; for(const id of ['d_jugg','r_prow']) if(hasBoon(id)){ B.boonStats=B.boonStats||{}; B.boonStats[id]=(B.boonStats[id]||0)+1; } } const e=ramEstimate(u,t,info.path.length);
  if(mawPre){ u.treeMawUsed=1; treeFx(u,'mawOpens','the maw opens'); } // Grax T3b: the first ram of the burn
  if(typeof fxRam==='function') await fxRam(u,t); if(!live()||t.dead) return false;
  const qd=shieldQuad(t,u); if(e.soak&&t.sh) t.sh[qd]=Math.max(0,t.sh[qd]-e.soak*1.5);
  t.hp-=e.dmg; u.dealt+=e.dmg; damageSection(t,e.sec,e.dmg,u); u.hp-=e.recoil; damageSection(u,'prow',e.recoil,t);
  if(typeof fxText==='function') fxText(t,'\u2212'+e.dmg,'#f0b35a',0); if(typeof fxText==='function') fxText(u,'\u2212'+e.recoil,'#ff7a6e',0);
  log(`${u.name} rams ${t.name} at full speed: ${e.dmg} to its ${SEC_NAME[e.sec]}, ${e.recoil} back to the ram.`, u.side==='player'?'p':'e');
  if(rnd()<.35){ const sy=systemDamage(t,e.sec); if(sy) log(`${t.name}: ${sy}.`, u.side==='player'?'p':'e'); }
  if(u.fx&&u.fx.ramSplash){ const sd=Math.round(e.dmg*u.fx.ramSplash); for(const x of B.units.filter(x=>!x.dead&&x!==t&&x.side===t.side&&hdist(x,t)===1)){ x.hp-=sd; boonFx(x,'r_shock','\u2212'+sd,-10); if(x.hp<=0) await killUnit(x,u); } }
  if(t.hp<=0){ t.killCause='big'; await killUnit(t,u); } if(u.hp<=0){ u.killCause='big'; await killUnit(u,t); } checkEnd(); return true;
}
function boardTargets(u){ if(!u||u.isSq||u.braced||u.boarded||u.dead||!u.crewMax||u.crew<Math.max(4,u.crewMax*.4)) return [];
  if(u.weapons.some(w=>w.fired)){ const rr=treeSkill('rushRail'), wr=treeSkill('warlordRun'); const okB=(rr&&u.side==='player'&&cmdActive(u.side,'surge'))||(wr&&u.side==='player'&&u.pflag&&cmdActive(u.side,'surge')); if(!okB) return []; } // Grax T2b and capstone 2: board after firing
  return alive(u.side==='player'?'enemy':'player').filter(t=>!t.isSq&&hdist(u,t)===1); }
// Grax T1b: a ship that crossed the burn at speed boards at +25% strength (boardPct room)
function treeRailBonus(u){ if(!u||u.isSq||u.side!=='player') return 0; const r=treeSkill('railBoarding'); return (r&&cmdActive(u.side,'surge')&&(u.hexMoved||0)>=4)?treeAddVal(u,'boardPct',r.n):0; }
// chance that a boarding action captures the target, from the same dice as boardUnit
// one capture model everywhere: boardUnit rolls r in [0.75,1.25); capture when round(crew*mult*r*.38) >= defenders.
// The shown chance is that roll's exact probability, so the number on the button is the real odds.
function captureChance(u,t){ if(t&&t.boss) return 0; /* B1 (R4): sector flagships cannot be captured */ const s=u.crew*(BOARD_MULT[u.fac]||1)*(1+((u.fx&&u.fx.boardPct)||0)+treeRailBonus(u))*.38; if(s<=0) return 0; const x=(t.crew-.5)/s; return Math.round(100*Math.max(0,Math.min(1,(1.25-x)/.5))); }
// why a selected ship can't shoot a target, in plain words
function cantFireReason(s,t){ if(s.braced) return 'This ship is braced, so it holds fire this turn.';
  const ready=s.weapons.filter(w=>weaponReady(w)); if(!ready.length) return 'Every weapon on this ship has already fired this turn.';
  const d=hdist(s,t), maxR=Math.max(...ready.map(w=>w.r)); const inR=ready.filter(w=>d<=w.r);
  if(!inR.length) return `Out of range: ${d} hexes away, your longest ready gun reaches ${maxR}.`;
  const inA=inR.filter(w=>inArc(s,t,w.arc)); if(!inA.length){ const arcs=[...new Set(inR.map(w=>(ARC_NAME&&ARC_NAME[w.arc])||w.arc))].join(' or '); return `In range, but no ready gun points at it. Turn so it sits in your ${arcs} arc.`; }
  if(!los(s,t)) return 'Line of sight is blocked by asteroids or wreckage.';
  return 'None of the ready guns can reach that target right now.'; }
function boardOdds(u,t){ const a=u.crew*(BOARD_MULT[u.fac]||1)*(1+((u.fx&&u.fx.boardPct)||0)+treeRailBonus(u)), d=t.crew*(BOARD_MULT[t.fac]||1)*(t.repel?2.25:1.5); const p=captureChance(u,t); return {kill:Math.round(a*.38), loss:Math.round(d*.3), chance:p, capture:p>=50}; }
async function boardUnit(u,t){
  if(!boardTargets(u).includes(t)) return false;
  const hadFired=u.weapons.some(w=>w.fired); // Grax T2b: boarded after firing this round
  if(B.usage&&u.side==='player') B.usage.board=(B.usage.board||0)+1; u.boarded=true; u.repel=true; u.mp=0; u.weapons.forEach(w=>w.fired=true);
  const live=liveFrom(u); if(typeof fxBoard==='function') await fxBoard(u,t); if(!live()||t.dead) return false; // abandoned after a stall: the boarders never land
  if(t.nem&&u.side==='player') nemTrip('board'); // R42: his thin crews show once you board
  { const rb=treeRailBonus(u); if(rb>0) treeFx(u,'railBoarding','over the rail'); } // Grax T1b
  { if(hadFired&&treeSkill('rushRail')&&cmdActive(u.side,'surge')) treeFx(u,'rushRail','rush the rail'); } // Grax T2b
  const a=u.crew*(BOARD_MULT[u.fac]||1)*(1+((u.fx&&u.fx.boardPct)||0)+treeRailBonus(u))*(.75+rnd()*.5), d=t.crew*(BOARD_MULT[t.fac]||1)*(t.repel?2.25:1.5)*(.75+rnd()*.5);
  const kill=Math.round(a*.38), loss=Math.min(u.crew-1,Math.round(d*.3)); t.crew=Math.max(0,t.crew-kill); u.crew=Math.max(1,u.crew-loss);
  const who=u.side==='player'?'p':'e';
  if(t.crew<=0&&(t.side==='player'||t.boss)&&!t.captured){ t.crew=Math.max(2,Math.round(t.crewMax*.15)); const s1=systemDamage(t), s2=systemDamage(t); if(typeof fxText==='function') fxText(t,'Holds the bridge','#f0b35a',-30);
    log(`${u.name}'s boarders overrun ${t.name}, but the last of its crew hold the bridge.${s1?' Saboteurs: '+s1.toLowerCase():''}${s2?', '+s2.toLowerCase():''}.`, who); if(B.usage&&t.side==='player') B.usage.overrun=(B.usage.overrun||0)+1; return true; } // your ships and sector flagships (B1, R4) are never captured: boarders cripple, they don't steal
  if(t.crew<=0){ if(B.usage&&u.side==='player') B.usage.cap=(B.usage.cap||0)+1; if(t.anchor) syncLose(t); const old=t.side; t.side=u.side; t.crew=Math.max(3,Math.round(t.crewMax*.4)); t.captured=true; t.activated=true; t.mp=0; t.turnsLeft=0; t.braced=false; t.weapons.forEach(w=>w.fired=true);
    gainResolve(u.side,2); if(typeof fxText==='function') fxText(t,'Captured','#f0b35a',-30); log(`Boarding parties from ${u.name} take ${t.name}. It now fights for ${u.side==='player'?'you':'the enemy'}.`, who);
    if(typeof onCapture==='function') onCapture(t,old); checkEnd(); return true; }
  if(typeof fxText==='function') fxText(t,'\u2212'+kill+' crew','#f0b35a',-18); if(typeof fxText==='function') fxText(u,'\u2212'+loss+' crew','#ff7a6e',-18);
  let extra=''; if(rnd()<.5||(u.fx&&u.fx.boardPct)){ const sy=systemDamage(t); if(sy) extra=` Saboteurs: ${sy.toLowerCase()}.`; }
  log(`${u.name} boards ${t.name}: ${kill} defenders killed, ${loss} boarders lost.${extra}`, who); return true;
}
async function tacticRam(u){ const info=ramInfo(u); if(!info||info.path.length<2) return false; /* the AI only rams with a real run-up */ const e=ramEstimate(u,info.t,info.path.length), bold=!!RAM_FAC[u.fac];
  if(e.dmg>=info.t.hp || e.dmg>=info.t.hp*(bold?.3:.45)){ await ramUnit(u); return true; } return false; }
async function tacticBoard(u){ let best=null,bv=0; for(const t of boardTargets(u)){ const o=boardOdds(u,t); const v=o.chance>=70?100+t.maxHp/10:0; if(v>bv){bv=v;best=t;} }
  if(best){ await boardUnit(u,best); return true; } return false; }
// v52: how a ship dies depends on what killed it (presentation only; fx3d animExplode reads u.killCause)
// v53: the one list of kill causes. killCauseOf, the turn ticks (melt, dark, tidal) and rams (big) set u.killCause to one of these ids;
// fx3d animExplode keys its death presets by the same ids (an id it lacks plays the plain blast), and salvage reads the words and whether the wreck is scrap
const KILL_CAUSES={cut:{w:'cut in two by a lance'},big:{w:'blown apart',scrap:1},flay:{w:'unmade by null fire',scrap:1},melt:{w:'dissolved',scrap:1},dark:{w:'gutted and dark'},blast:{w:'destroyed'},tidal:{w:'torn apart by the Hollow Sun',scrap:1}};
function killCauseOf(w,t){ if(!w) return 'blast'; const k=w.k, tr=w.trait;
  if(tr==='gauss'||k==='gauss'||k==='doom') return 'flay';
  if(tr==='acid'||tr==='spines'||k==='bioplasma'||k==='tendril'||k==='sporeb') return 'melt';
  if(k==='lance'||k==='beam'||tr==='plasma'&&/lance/i.test(w.n||'')) return 'cut';
  if(k==='torp'||k==='htorp'||k==='startorp'||k==='bombs') return 'big';
  if((k==='battery'||k==='hbattery'||k==='turret'||k==='autocannon'||k==='scatter')&&(String(t&&t.id).split('').reduce((h,c)=>h*31+c.charCodeAt(0)|0,B?B.round||0:0)>>>0)%10<3) return 'dark'; // no rules RNG for looks
  return 'blast'; }
async function killUnit(t,by){ if(t&&by&&!t.killedBy) t.killedBy=by.isSq?((B.units.find(x=>x.id===by.parent)||by).name):by.name;
  if(t.dead) return;
  if(t.fx.lastStand && !t.usedLastStand){ t.usedLastStand=true; t.hp=1; if(typeof fxText==='function') fxText(t,'Last stand','#f0b35a',-30); log(`${t.name} refuses to die! (Last stand)`,'s'); return; }
  if(t.side==='player' && !t.isSq && runFx().revive && !B.reviveUsed){ B.reviveUsed=true; t.hp=Math.round(t.maxHp*.25); if(typeof fxText==='function') fxText(t,'Restarts','#7dff9b',-30); log(`Second ignition. ${t.name} restarts at 25% hull.`,'s'); return; }
  const legion=legionCan(t); // B3 Deathless endless legion replaces the random reanimate for Deathless hulls; other reanimating hulls (Undying foes heat) keep the old roll
  if(!legion && t.reanimate && !t.reanimated && !t.pyre && !(t.fac==='deathless'&&t.t&&t.t.reanimate) && rnd()<(t.side==='enemy'?.2:.35)){ t.reanimated=true; t.hp=Math.round(t.maxHp*.3); if(typeof fxText==='function') fxText(t,'Rebuilding','#7dff9b',-30); log(`${t.name} reassembles itself from the wreckage.`,'e'); return; }
  t.dead=true; t.hp=0;
  { const ts=treeSkill('trophyStandard'); if(ts&&by&&by.side==='player'&&by.pflag&&t.side==='enemy'){ for(const x of alive('player')) if(!x.isSq&&!x.dead) x.treeFreeTurn=1; treeFx(by,'trophyStandard','the trophy standard turns the fleet'); } } // Hullbreakers shared C1b
  if(legion){ t.reanimated=true; t.riseAt=B.round+1; B.legion[t.side].used++; log(`${t.name} falls, but its wreck is already reassembling. It rises next round.`,t.side==='player'?'p':'e'); try{ if(typeof fxText==='function') fxText(t,'Reassembling: rises next round','#7dff9b',-30); }catch(e){} }
  syncLose(t); chorusFeed(t,by); // B3: a dead anchor collapses Hegemony sync; Chorus feed on the kill
  { const rf=treeSkill('rollingFire'); if(rf&&t.side==='enemy'&&by&&by.side==='player'&&!by.isSq&&inSync(by)&&B.tr&&!B.tr.rollingUsed){ B.tr.rollingUsed=1;
    const cand=alive('player').filter(x=>x!==by&&!x.isSq&&!x.dead&&inSync(x)&&!x.weapons.some(w=>w.fired)); let bu=null,bt=null,bi=-1,bs=-1e18;
    for(const x of cand){ for(let i=0;i<x.weapons.length;i++){ const w=x.weapons[i]; if(w.k==='flak'||w.off||w.cdLeft) continue; for(const e of alive('enemy')){ if(e.isSq||e===t||e.dead) continue; if(!canFire(x,w,e)) continue; const v=expectedVs(x,w,e), sc=v.hull+v.shield*.3; if(sc>bs){ bs=sc; bu=x; bt=e; bi=i; } } } }
    if(bu&&bt&&await treeExtraShot(bu,bi,bt,{})) treeFx(bu,'rollingFire','another synced ship fires at once'); } } // Kassar T3a
  if(by&&!t.isSq&&by.side!==t.side&&ownerFx(by).broodTithe){ const cs=alive(by.side).filter(x=>!x.isSq&&(x.ab==='launch'||(x.fx&&x.fx.hive))&&launchHexes(x).length).sort((a,b)=>hdist(a,t)-hdist(b,t)); if(cs.length){ const c=cs[0], h=launchHexes(c)[0], sq=makeWing(c,h,wingKind(c)); sq.mp=0; sq.weapons.forEach(w=>w.fired=true); const rep=ownerFx(by).broodRepair||0; if(rep>0){ const heal=Math.min(c.maxHp-c.hp,Math.round(c.maxHp*rep)); if(heal>0){ c.hp+=heal; if(typeof fxText==='function') fxText(c,'+'+heal+' hull','#8ff0a0',-20); } } boonFx(c,'h_brood','free wing',-30); } } // Brood Tithe (RWD-2: broodRepair scales with rarity)
  if(t.side==='player'&&!t.isSq&&!t.transport){ const av=runFx().avenge; if(av){ for(const x of alive('player')) if(!x.isSq&&x.hp<x.maxHp){ const h=Math.min(x.maxHp-x.hp,Math.round(x.maxHp*av)); x.hp+=h; if(typeof fxText==='function') fxText(x,'+'+h+' hull','#8ff0a0',-20); } log(`The fleet rallies around the loss of ${t.name}.`,'s'); } }
  if(by&&by.side==='player'&&!t.isSq&&runFx().bloodied){ const k=by.isSq?B.units.find(x=>x.id===by.parent):by; if(k&&!k.dead){ k.bloodied=Math.min(3,(k.bloodied||0)+1); if(typeof fxText==='function') fxText(k,'Bloodied +'+Math.round(15*k.bloodied)+'%','#ff9f3a',-36); } }
  if(!t.isSq && t.size>=.7 && !legion && !blocks(B.terrain[hkey(t.q,t.r)])){ B.terrain[hkey(t.q,t.r)]='hulk'; t.hulk=true; log(`The wreck of ${t.name} drifts in place, blocking movement and fire.`,'x'); if(typeof refreshBlockTint==='function') setTimeout(()=>refreshBlockTint(),1200); }
  if(by&&!t.isSq) gainResolve(by.side,1);
  if(by){ by.kills++; if(by.parent){ const p=B.units.find(x=>x.id===by.parent); if(p) p.kills+=0; } }
  if(by&&by.isSq){ const p=B.units.find(x=>x.id===by.parent&&!x.dead); if(p&&p.fx&&p.fx.feast){ p.spare=(p.spare||0)+1; const h=Math.round(p.maxHp*p.fx.feast); p.hp=Math.min(p.maxHp,p.hp+h); boonFx(p,'h_feast','+'+h+' hull, +1 wing',-30); } }
  const b0=B, live=liveFrom(null); { const dk=t.side==='enemy'&&!t.isSq&&!(t.t&&t.t.boss)?enemyPaceK():1; SPEED*=dk; try{ if(typeof animExplode==='function') await animExplode(t); } finally{ SPEED/=dk; } } // B2: in big fights an escort's death plays quicker; flagships keep the full show
  if(!live()){ if(B===b0&&!B.over) try{ checkEnd(); }catch(e){} return; } // v45: epoch check like every other await, so a stalled battle never sees this explosion's aftermath (B-18, Oct 26: this line was swallowed by the comment above and never ran)
  { const cb=by&&!t.isSq&&by.side!==t.side?ownerFx(by).chainBoom:0; if(cb){ const near=B.units.filter(x=>!x.dead&&x.side===t.side&&x!==t&&hdist(x,t)<=2); if(near.length) log(`${t.name}'s reactor goes up, scorching ${near.length} nearby ship${near.length>1?'s':''}.`,by.side==='player'?'p':'e');
      const cf=ownerFx(by).chainFire; for(const x of near){ if(x.dead) continue; x.hp-=cb; if(cf&&!x.isSq){ x.st.fire=Math.max(x.st.fire||0,2); x.st.fireDmg=Math.max(x.st.fireDmg||6,6); } boonFx(x,'e_chain','\u2212'+cb,-12); if(x.hp<=0) await killUnit(x,by); } } }
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
function stationFire(dq){ const o=B.obj; if(!o||o.type!=='defend') return; const src={q:o.hex.q,r:o.hex.r,facing:0};
  const ts=caps('enemy').filter(u=>hdist(u,o.hex)<=5).sort((a,b)=>hdist(a,o.hex)-hdist(b,o.hex)).slice(0,2);
  const att={side:'player',dealt:0,kills:0,crit:0,lockOn:false,fx:{}};
  for(const t of ts){ const r=applyHit(att,{crit:0,pierce:.2},t,12,shieldQuad(t,src)); try{ if(typeof fxText==='function') fxText(t,`Station \u2212${r.hull+r.shield}`,'#7fd6ff',-30); }catch(e){}
    log(`Station batteries hit ${t.name}: ${r.shield} shield, ${r.hull} hull.`,'p'); if(t.hp<=0&&!t.dead){ t.hp=0; queueDeath(t,dq); } } }
function objAfterMove(u){ const o=B&&B.obj; if(!o||!u||u.dead||u.isSq) return;
  if(o.type==='break'&&u.side==='player'&&objZone(u.q,u.r)==='exit'){ u.exited=true; u.dead=true; u.fled=true; try{ if(typeof fxWithdraw==='function') fxWithdraw(u); }catch(e){} log(`${u.name} breaks through and jumps clear.`,'s'); checkEnd(); }
  else if(o.type==='intercept'&&u.transport&&objZone(u.q,u.r)==='texit'){ u.dead=true; u.fled=true; try{ if(typeof fxWithdraw==='function') fxWithdraw(u); }catch(e){} log(`${u.name} gets through.`,'e'); checkEnd(); } }
function aiObjScore(u,v){ const o=B.obj; if(!o||u.isSq) return 0;
  if(u.transport) return -(o.exitR-v.r)*14;
  if(o.type==='hunt'&&u.flagship){ const d=Math.min(30,...caps('player').map(p=>hdist(v,p))); return Math.min(d,9)*3; } // runs, but stops running once well clear
  const vet=aiVet(), urg=vet?aiObjUrgency(o):1; // v53-D: veterans feel the round clock and the station's integrity; standard keeps the flat pull
  if(o.type==='defend') return -Math.max(0,hdist(v,o.hex)-2)*3*urg;
  if(o.type==='break'){ const pl=caps('player'); if(!pl.length) return 0; const lead=Math.max(...pl.map(p=>p.q+Math.floor(p.r/2))), c=v.q+Math.floor(v.r/2); if(!vet) return -Math.max(0,lead+1-c)*1.2;
    // veterans block the exit lane in front of the leading ship, harder the further it has got
    const L=pl.find(p=>p.q+Math.floor(p.r/2)===lead), c0=o.c0!=null?o.c0:(o.c0=boardBounds().c0), prog=clamp((lead-c0)/Math.max(1,o.exitC-c0),0,1);
    return -(Math.max(0,lead+1-c)*1.2+Math.max(0,Math.abs(v.r-L.r)-2)*.5)*(1+1.5*prog); }
  if(vet&&o.type==='intercept'){ let d=99; for(const x of B.units) if(x.transport&&!x.dead) d=Math.min(d,hdist(v,x)); return d<99?-Math.max(0,d-3)*1.5:0; } // escorts screen their convoy
  if(vet&&o.type==='hold'){ // the relay pulls only the two enemy ships nearest it; the rest fight nearby. A ship already holding it uncontested is paid to stay
    const mine=caps('enemy').filter(x=>!x.transport).sort((a,b)=>hdist(a,o.hex)-hdist(b,o.hex)||(a.id<b.id?-1:1)), k=mine.indexOf(u), d=hdist(v,o.hex);
    if(k<0||k>1) return -Math.max(0,d-5)*.4;
    const held=hdist(u,o.hex)<=1&&!caps('player').some(p=>hdist(p,o.hex)<=1); return -d*1.6*urg+(held&&d<=1?4:0); }
  return 0; }
// v53-D: objective urgency (veteran): rises as the round clock runs down and when the station or the relay score is close to decided
function aiObjUrgency(o){ const done=clamp(((B.round||1)-1)/(o.rounds||ENC_ROUNDS),0,1);
  if(o.type==='defend') return 1+done*1.2+(o.hp<=2?.6:0);
  if(o.type==='hold') return 1+done*.8+(o.score>=2?.8:0)+(o.escore>=2?.4:0);
  return 1; }
function objectiveTick(dq){ const o=B.obj; if(!o||B.over) return;
  if(o.type==='defend'){ const near=caps('enemy').filter(u=>hdist(u,o.hex)<=2); if(near.length){ o.hp=Math.max(0,o.hp-near.length); log(`${near.length} enemy ship${near.length>1?'s':''} at the station. Integrity ${o.hp}/${o.hpMax}.`,'e'); }
    if(o.hp>0&&B.round<=o.rounds) stationFire(dq); checkEnd(); return; }
  if(o.type==='hunt'){ if(B.round>o.rounds){ const f=B.units.find(u=>u.flagship&&u.side==='enemy'&&!u.dead); if(f){ f.dead=true; f.fled=true; o.escaped=true; try{ if(typeof fxWithdraw==='function') fxWithdraw(f); }catch(e){} log(`${f.name} jumps out. Its escorts follow.`,'e'); } } checkEnd(); return; }
  if(o.type!=='hold') return; const near=s=>alive(s).some(u=>!u.isSq&&hdist(u,o.hex)<=1); const p=near('player'), e=near('enemy');
  if(p&&!e){ o.score++; log(`You hold the relay (${o.score}/3).`,'p'); } else if(e&&!p){ o.escore++; log(`The enemy holds the relay (${o.escore}/3).`,'e'); } else if(p&&e) log('The relay is contested.','x'); checkEnd(); }
// (emergency shields removed: Admiral's Command and ship abilities cover shield refills)
// one owner for "the battle ended": the first time a battle becomes over, its end screen is scheduled once,
// whichever rule (a kill, the relay score, a squadron strike at round start, a Command) caused it
function checkEnd(){ const was=!!(B&&B.over); checkEndRules(); if(B&&!was&&B.over){ if(B.over==='win') for(const u of B.units) if(u.dead&&u.side==='player'&&u.riseAt!=null&&!u.fled) legionRise(u,true); /* B3: your reassembling Deathless ship stands up after a win */ scheduleBattleEnd(); } }
function scheduleBattleEnd(){ const b=B; if(!b||b.showcase) return; Promise.resolve().then(()=>{ if(B===b&&b.over&&!b.ending&&typeof endBattleFlow==='function'){ b.busy=false; endBattleFlow(); } }); }
function checkEndRules(){
  if(B.over) return;
  if(caps('enemy').length===0){ B.over='win'; return; }
  const o=B.obj;
  if(o&&o.type==='break'){ const out=B.units.filter(u=>u.exited).length; o.out=out; if(out>=o.need){ B.over='win'; log(`${out} ship${out>1?'s':''} broke through. The fleet jumps clear.`,'s'); return; }
    if(out>0&&caps('player').length+out<o.need){ B.over='loss'; B.withdraw=true; log('Too few ships can still get through. The survivors jump clear.','e'); return; } }
  if(caps('player').length===0 && !B.units.some(u=>u.side==='player'&&!u.dead&&u.treeOff)){ B.over='loss'; return; } // a reserve held off the field still counts (Thale B1b)
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
  if(bossDown||(sideCP('enemy')<=B.cp0.enemy*.35&&!B.nemNoRout)){ // R42: a Voidsworn or Deathless Nemesis fights to the last hull
    B.over='win'; B.routed=true; log(bossDown?'The flagship is gone. Its escorts break and flee.':'The enemy fleet breaks and flees.','s'); }
}

// ---------- orders & abilities ----------
function canOrder(u,o){
  if(u.dead||u.order||u.braced) return false;
  if(o==='full') return !u.moved && !u.isSq;
  if(o==='lock') return true;
  if(o==='helm') return !u.isSq && !u.noTurn;
  if(o==='brace') return !u.isSq && !(FAC_GATES[u.fac]&&FAC_GATES[u.fac].noBrace) && !u.weapons.some(w=>w.fired&&w.k!=='flak'); // brace instead of firing: not after this ship has fired; B3: Ithar cannot brace
  return false;
}
function giveOrder(u,o){ if(B.usage&&u.side==='player') B.usage.ord[o]=(B.usage.ord[o]||0)+1;
  if(!canOrder(u,o)) return;
  u.order=o;
  if(o==='brace'){ fstat(u.fac,'braces'); u.braced=true; u.mp=0; for(const w of u.weapons) w.fired=true; if(typeof fxText==='function') fxText(u,'Braced','#7fd6c8',-24); braceCover(u); if(u.fx.bastion&&u.shMax>0){ u.sh=u.sh.map(()=>u.shMax); boonFx(u,'d_bastion','shields full',-44); } }
  if(o==='full'){ u.fullAhead=true; u.noTurn=true; u.mp+=Math.ceil(u.mp*.5); }
  if(o==='lock'){ u.lockOn=true; u.mp=0; }
  if(o==='helm'){ u.turnsLeft++; }
  log(`${u.name}: ${ORDERS[o].n}.`, u.side==='player'?'p':'e');
}
// v54 doctrine (decided): a Voidsworn hull that braces also covers one adjacent ally facing the same way (the most damaged); the Shield Wall boon covers every neighbour
function braceCover(u){ const wall=!!(u.fx&&u.fx.wallBrace); if(u.fac!=='voidsworn'&&!wall) return []; let near=B.units.filter(x=>!x.dead&&x!==u&&x.side===u.side&&!x.isSq&&hdist(x,u)===1&&(wall||x.facing===u.facing));
  if(!wall) near=near.sort((a,b)=>a.hp/a.maxHp-b.hp/b.maxHp).slice(0,1); for(const x of near){ x.coverBy=u.id; try{ if(typeof fxText==='function') fxText(x,'Covered','#7fd6c8',-24); }catch(e){} } return near; }
function braceMul(t){ if(t.braced) return Math.max(.15,1-.4-((t.fx&&t.fx.bracePlus)||0)); if(t.coverBy&&B){ const c=B.units.find(x=>x.id===t.coverBy); if(c&&!c.dead&&c.braced) return Math.max(.15,1-.4-((c.fx&&c.fx.bracePlus)||0)-((c.fx&&c.fx.wallPlus)||0)); } return 1; }
function abilityCd(u){ return Math.max(1, ABILITIES[u.ab].cd-(u.fx.cdMod||0)); }
// ---------- squadrons fight on their own: swarm weapons that persist until shot down ----------
// nothing may wait forever: if an action outlives its limit, record what was running, save, and carry on
// stall guard: time only counts while the game is on screen (a locked phone pauses, it doesn't skip ahead).
// If an action truly hangs, the battle's epoch goes up so that action can never act later.
function gameVisible(){ return typeof document==='undefined'||document.visibilityState!=='hidden'; }
function stallGuard(p,ms,tag,info){ let iv, done=false; const b0=B, gT=()=>(typeof G!=='undefined'&&G&&typeof G.time==='number')?G.time:null, g0=gT(); const lim=new Promise(res=>{ let used=0, last=Date.now(); iv=setInterval(()=>{ const now=Date.now(); if(gameVisible()) used+=now-last; last=now; if(done){ clearInterval(iv); return; } if(B!==b0){ clearInterval(iv); res('stale'); return; }
      // animations run on game time, so a slow renderer stretches them: count game time, with a 4x real-time backstop in case frames stop entirely
      const g=gT(); if(g!=null&&g0!=null?((g-g0)*1000<ms&&used<ms*4):used<ms) return; clearInterval(iv); // a guard only ever acts on its own battle
      try{ if(B) B.epoch=(B.epoch||0)+1; if(typeof tel==='function'){ tel('stall',Object.assign({tag,round:B&&B.round,side:B&&B.side,busy:B&&B.busy},info||{})); if(typeof Persist!=='undefined') Persist.saveLocal(); } /* v53: local only, no cloud stamp */
        if(typeof toast==='function') toast('Something got stuck, so the game skipped ahead and saved a report for Claude.'); }catch(e){} res('stall'); },250); });
  return Promise.race([Promise.resolve(p).catch(e=>{ try{ if(typeof tel==='function') tel('action_error',{tag,msg:String(e&&e.message||e).slice(0,140),at:String(e&&e.stack||'').split('\n').slice(1,3).join(' | ').slice(0,240)}); if(typeof Persist!=='undefined') Persist.saveLocal(); }catch(_){} }),lim]).finally(()=>{ done=true; clearInterval(iv); }); }
// an action is live only while its battle and epoch are unchanged since it started
function liveFrom(u){ const b0=B, ep=(B&&B.epoch)||0; return ()=>B===b0&&((B&&B.epoch)||0)===ep&&(!u||!u.dead); }
// ---------- Admiral's Command: one big fleet-wide move per admiral, ready when the meter is full ----------
const COMMANDS={vex:{id:'barrage',n:'Fire for effect',d:'Every ship fires a free volley at the best target its guns can reach, right now.'},
  malek:{id:'hunt',n:"Hunter's salvo",d:'Torpedoes reload at once and every ship deals +30% damage this round.'},
  ashgrove:{id:'scramble',n:'Scramble all wings',d:'Every launch ship sends out an extra wing if there is room, then all squadrons strike again with +50% damage this round.'},
  thale:{id:'iron',n:'Iron wall',d:'All shields refill and your ships take 40% less hull damage this round.'}};
// Command power grows each round you hold it: tier 0 in round 1, 1 in round 2, 2 (full) from round 3
const CMD_POW={barrage:[0,.25,.5],hunt:[.3,.45,.6],scramble:[.5,.75,1],iron:[.4,.5,.6],restore:[.25,.35,.45],surge:[2,3,4]};
function cmdTier(){ if(!B||B.round<1) return 0; const bonus=B.units.some(u=>u.side==='player'&&!u.dead&&u.fx&&u.fx.cmdTier)?1:0, lost=B.units.some(u=>u.side==='player'&&!u.isSq&&!u.transport&&u.dead)?1:0; return Math.max(0,Math.min(2,B.round-1+bonus+lost-(heatOn('h_cmd')?1:0))); } /* ready from round 1, full power from round 3; losing a ship charges it a level */
function cmdRec(side){ return !B?null:side==='enemy'?B.cmdE:B.cmd; } // the enemy flagship keeps its own Command record
function cmdPow(id,tier,side){ const p=CMD_POW[id]; if(!p) return 0; if(tier==null){ const c=cmdRec(side||'player'); tier=(c&&c.tier)||0; } return p[tier]; }
function cmdDesc(c,tier,fac){ if(!c) return ''; const v=cmdPow(c.id,tier), car=fac==='chorus'?'brood':'launch ship', sq=fac==='chorus'?'swarm':'squadron', pct=x=>Math.round(x*100)+'%';
  switch(c.id){
    case 'barrage': return `Every ship fires a free extra volley right now at the best target in range${v?`, with +${pct(v)} damage`:''}. Its normal shots this round still happen.`;
    case 'hunt': return fac==='hegemony'?`Every ship deals +${pct(v)} damage for the rest of this round.`:`Torpedoes reload at once and every ship deals +${pct(v)} damage for the rest of this round.`;
    case 'scramble': return `Every ${car} launches ${tier>=2?'two extra wings':'an extra wing'} right now if there are open adjacent hexes, even past its hangar limit. Then every ${sq} you have makes a bonus attack immediately, with +${pct(v)} damage.`;
    case 'iron': return fac==='chorus'||fac==='deathless'?`Your ships take ${pct(v+.1)} less hull damage for the rest of this round.`:`All shields refill and your ships take ${pct(v)} less hull damage for the rest of this round.`;
    case 'restore': return `Every ship repairs ${pct(v)} of its hull right now.`;
    case 'surge': return `Every ship gains +${v} movement and ${tier>=2?'+2 turns':'+1 turn'} this round, and enemy fire loses 20 accuracy against you.`; }
  return c.d||''; }
function cmdNext(c,tier,fac){ const t=tier+1, v=cmdPow(c.id,t), pct=x=>Math.round(x*100)+'%', car=fac==='chorus'?'brood':'launch ship';
  switch(c.id){ case 'barrage': return `+${pct(v)} damage on the free volley`; case 'hunt': return `+${pct(v)} damage`; case 'scramble': return `${t>=2?'two extra wings per '+car:'an extra wing'} and +${pct(v)} damage`;
    case 'iron': return `${pct(v)} less hull damage`; case 'restore': return `${pct(v)} of hull repaired`; case 'surge': return `+${v} movement${t>=2?' and +2 turns':''}`; } return ''; }
const CMD_HOLD='Once per battle. Each round you hold it, it gets stronger (full power from round 3), and losing a ship charges it a level at once. Hold too long and the fight may be over.';
// ---------- admiral tree effects (issue #305 job 1: H0 plumbing, H1 choice, H2 counters, H3 next round) ----------
// One place builds the player's live skills from the run snapshot; one helper per hook is called from one place.
function treeBuild(){ const L=(typeof RUN!=='undefined'&&RUN&&RUN.lineage)||null; if(!L||!LINEAGE_TREES[L.id]) return [];
  const out=[]; for(const pick of (L.picks||[])){ const p=String(pick), key=p.indexOf(L.id+':')===0?p:L.id+':'+p, fx=TREE_FX[key]; if(fx) out.push(Object.assign({key},fx)); } // #335: old saves and the campaign store short picks ("A:0:0"); TREE_FX is keyed "admiral:A:0:0"
  if(L.capstone!=null){ const key=L.id+':cap:'+L.capstone, fx=TREE_FX[key]; if(fx) out.push(Object.assign({key},fx)); } return out; }
function treeSkill(k){ return B&&B.tree?B.tree.find(s=>s.k===k):null; }
function treeHas(k){ return !!treeSkill(k); }
function treeName(key){ const p=String(key).split(':'), id=p[0], b=p[1], tree=LINEAGE_TREES[id]; if(!tree) return key;
  if(b==='cap'){ const c=Number(p[2]); return tree.capstones[c]&&tree.capstones[c].n?tree.capstones[c].n:key; }
  const t=Number(p[2]), c=Number(p[3]), br=tree.branches[b]; return br&&br.tiers[t]&&br.tiers[t][c]?br.tiers[t][c].n:key; }
// a skill firing: counted for the recap, with one callout and log line per round so a per-hit rule is not spammed
function treeFx(u,kind,txt){ const s=treeSkill(kind); if(!s||!B) return; B.treeStats=B.treeStats||{}; B.treeStats[s.key]=(B.treeStats[s.key]||0)+1;
  B.tr=B.tr||{}; B.tr.logged=B.tr.logged||{};
  if(!B.tr.logged[s.key]){ B.tr.logged[s.key]=1; const name=treeName(s.key);
    try{ if(typeof fxText==='function') fxText(u,name+': '+txt,'#e8c66a',-60); }catch(e){}
    try{ log(`Lineage: ${name}. ${txt}`, u&&u.side==='player'?'p':'e'); }catch(e){} } }
// the step 1 cap still owns the ceiling: a tree number only fills the room left under its key
function treeAddVal(u,key,v){ const cap=FX_CAPS[key]; if(cap==null) return v; return Math.max(0,Math.min(v,cap-((u&&u.fx&&u.fx[key])||0))); }
// Eclipse (issue #305 job 3): H8 hull cut, H9 repair and H11 movement helpers, one place each.
function treeFlagUnit(){ return B.units.find(x=>x.pflag&&!x.dead)||alive('player')[0]||null; }
function treeMarkRepair(u){ if(B&&B.tree&&B.tree.length&&u&&u.side==='player'&&!u.isSq){ u.treeRepaired=1; u.treeRepairedRound=B.round; } }
// Hullbreakers (issue #305 job 5): H2 a missed torpedo reloads one turn sooner than normal
function treeSecondKnife(real){ if(!real||real.dead||real.side!=='player') return false; if(!treeSkill('secondKnife')) return false;
  for(const rw of real.weapons){ if(rw.k==='torp'){ rw.cdLeft=Math.max(0,(rw.cdLeft||0)-1); treeFx(real,'secondKnife','the second knife comes free'); return true; } } return false; }
function treeInEnemyRear(u){ for(const t of alive('enemy')){ if(!t.isSq&&shieldQuad(t,u)===2) return true; } return false; }
function treeInEnemyFront(u){ for(const t of alive('enemy')){ if(!t.isSq&&inArc(t,u,'F')) return true; } return false; }
function treeRearApproach(u){ let best=null,bd=1e9; for(const t of alive('enemy')){ if(t.isSq) continue; const d=hdist(u,t); if(d<bd||(d===bd&&best&&t.id<best.id)){ bd=d; best=t; } }
  if(!best) return null; const d=DIRS[(best.facing+3)%6]; return {q:best.q+d[0],r:best.r+d[1]}; }
function treeStepToward(u,goal,steps){ let moved=0;
  for(let s=0;s<steps;s++){ let best=null,bd=hdist(u,goal); const occ=occMap();
    for(const d of DIRS){ const nq=u.q+d[0], nr=u.r+d[1]; if(!onBoard(nq,nr)||blocks(terr(nq,nr))||occ.has(hkey(nq,nr))) continue; const dd=hdist({q:nq,r:nr},goal); if(dd<bd){ bd=dd; best={q:nq,r:nr}; } }
    if(!best) break; u.q=best.q; u.r=best.r; moved++; }
  return moved; }
// H3: the Sunward Glass capstone 1 volley returns at the next round start; the turn flows call this one place after a player start
async function treeRoundFx(){ if(!B||B.over) return;
  if(B.treeStrikeRound===B.round){ const wings=alive('player').filter(x=>x.isSq&&x.treeStrikeNow); for(const sq of wings){ if(B.over||sq.dead) break; sq.treeStrikeNow=0; if(await treeWingStrikeNow(sq)) treeFx(sq,'secondWave','the held wing strikes'); } B.treeStrikeRound=0; }
  if(B.treeForgeRound===B.round&&B.treeForgeList){ const list=B.treeForgeList; B.treeForgeRound=0; B.treeForgeList=null; const s=treeSkill('forgeAhead');
    for(const e of list){ if(B.over) break; const tgt=B.units.find(x=>x.id===e.tid&&!x.dead); if(!tgt) continue; const sq=alive('player').find(x=>x.isSq&&x.extra&&x.parent===e.carrier&&!x.dead); if(!sq) continue;
      const old=sq.treeBonus; if(s) sq.treeBonus=(old||0)+treeAddVal(sq,'sqPct',s.n); if(await treeWingStrikeAt(sq,tgt)) treeFx(sq,'forgeAhead','one wing per carrier strikes again'); sq.treeBonus=old; } }
  if(B.treeDebtRound===B.round){ B.treeDebtRound=0; const b0=B; B.volleyMul={side:'player',m:1+(B.treeDebtPow||0)}; B.treeDebtDue=1;
    try{ for(const u of alive('player').filter(x=>!x.isSq)){ if(B.over) break; await treeFreeVolleyShip(u,'enemy',false); } } finally{ B.treeDebtDue=0; if(B===b0) B.volleyMul=null; }
    if(B===b0&&!B.over) treeFx(treeFlagUnit(),'debtDue','the interest comes due'); }
  if(B.treeSpatRound&&B.treeSpatRound===B.round){ B.treeSpatRound=0; const b0=B; B.volleyMul={side:'player',m:1};
    try{ for(const id of (B.treeSpatIds||[])){ const u=B.units.find(x=>x.id===id&&!x.dead&&!x.isSq); if(!u||B.over) continue; await treeFreeVolleyShip(u,'enemy',true); } } finally{ if(B===b0) B.volleyMul=null; }
    if(B===b0&&!B.over) treeFx(treeFlagUnit(),'spatRounds','the held spit spits now'); } // Voice T2b: the held half volley fires at half damage
  if(B.treeNoonRound&&B.treeNoonRound===B.round){ B.treeNoonRound=0; const b0=B; B.volleyMul={side:'player',m:1};
    try{ for(const u of alive('player').filter(x=>!x.isSq)){ if(B.over) break; await treeFreeVolleyShip(u,'enemy',true); } } finally{ if(B===b0) B.volleyMul=null; }
    if(B===b0&&!B.over) treeFx(treeFlagUnit(),'noonRepeat','the noon volley returns'); } }
// H1: the pick for a skill. A fixture or the UI may name the unit; otherwise a plain best-value default keeps the bot, the sims and the browser identical.
function treeChoice(kind){ const c=B&&B.treeChoices?B.treeChoices[kind]:null; if(c){ const u=B.units.find(x=>x.id===c&&!x.dead); if(u) return u; }
  if(kind==='carrier'||kind==='brood'){ const l=alive('player').filter(x=>!x.isSq&&x.ab==='launch'); return l.sort((a,b)=>(b.hangar||0)-(a.hangar||0)||(a.id<b.id?-1:1))[0]||null; }
  if(kind==='enemy'){ const l=alive('enemy').filter(x=>!x.isSq); return l.sort((a,b)=>b.maxHp-a.maxHp||(a.id<b.id?-1:1))[0]||null; }
  if(kind==='ship'||kind==='friend'){ const l=alive('player').filter(x=>!x.isSq); return l.sort((a,b)=>(a.hp/a.maxHp)-(b.hp/b.maxHp)||(a.id<b.id?-1:1))[0]||null; }
  if(kind==='reserve'){ const l=alive('player').filter(x=>!x.isSq&&!x.pflag); return l.sort((a,b)=>(a.hp/a.maxHp)-(b.hp/b.maxHp)||(a.id<b.id?-1:1))[0]||null; }
  if(kind==='largest'){ const l=alive('player').filter(x=>!x.isSq&&x.ab!=='launch'&&!(x.hangar>0)); return l.sort((a,b)=>b.maxHp-a.maxHp||(a.id<b.id?-1:1))[0]||null; } // Mott T1b: the largest ship that is not a carrier
  if(kind==='other'){ const l=alive('player').filter(x=>!x.isSq&&!x.pflag); return l.sort((a,b)=>(a.hp/a.maxHp)-(b.hp/b.maxHp)||(a.id<b.id?-1:1))[0]||null; } // Vesh T2a: a ship other than the flagship
  return null; }
// Razormaw T2a: the named prey this round (null when the pick is absent or the prey is gone)
function treePrey(){ const s=treeSkill('razorPrey'); if(!s||!B||!B.treeRazorPrey||B.treeRazorPrey.r!==B.round) return null; return B.units.find(x=>x.id===B.treeRazorPrey.id&&!x.dead)||null; }
function treeMoveBonus(u){ if(!u||u.isSq||u.side!=='player') return 0; const s=treeSkill('razorPrey'); return (s&&treePrey())?s.n:0; }
// Hegemony Navy (issue #305 job 6): one helper per hook, called from one place.
function treeHegSyncR(){ const wn=treeSkill('wideNet'), lr=treeSkill('livingRelay'); let r=SYNC_R+(wn?wn.n:0); if(lr) r*=2; return r; }
// shield overcharge above the maximum, capped at a quarter of the maximum (the plan's treeShOver ceiling)
function treeShieldOver(u,frac){ if(!u||u.dead||u.isSq||!(u.shMax>0)) return 0; const cap=Math.round(u.shMax*1.25), add=Math.round(u.shMax*frac); let any=0;
  for(let i=0;i<4;i++){ if((u.sh[i]||0)<u.shMax) continue; const v=Math.min(cap,(u.sh[i]||0)+add); if(v>u.sh[i]){ any+=v-u.sh[i]; u.sh[i]=v; } } return any; }
// is the ship on a straight line of three or more friendly ships (the flagship joins every line with its capstone)
const TREE_LINES=[v=>v.r,v=>v.q,v=>v.q+v.r,v=>v.q+Math.floor(v.r/2)]; // rows, cube axes and the screen column the deployment line uses
function treeInColumn(u){ if(!u||u.isSq||u.side!=='player') return false; const fleet=alive('player').filter(x=>!x.isSq&&!x.dead), fg=treeFlagUnit(), joins=!!treeSkill('flagshipStandard');
  for(const lk of TREE_LINES){ const base=lk(u); let n=1, fgOn=false;
    for(const v of fleet){ if(v===u) continue; if(lk(v)===base){ n++; if(fg&&v===fg) fgOn=true; } }
    if(joins&&fg&&fg!==u&&!fgOn) n+=1; if(n>=3) return true; } return false; }
function treeInFlagLine(u){ const fg=treeFlagUnit(); if(!u||!fg||u===fg||u.isSq||u.side!=='player') return false;
  for(const lk of TREE_LINES) if(lk(u)===lk(fg)) return true; return false; }
function treeOffenseAt(u,q,r){ const v=stateView(u,{q,r,f:u.facing}); let s=0; const foes=alive('enemy');
  for(const w of u.weapons){ if(!weaponReady(w)||w.k==='flak') continue; let b=0;
    for(const t of foes){ if(t.isSq) continue; if(!inReach(v,w,t)) continue; const e=expectedVs(v,w,t), val=e.hull+e.shield*.3; if(val>b) b=val; } s+=b; } return s; }
// Standard Rotation: after a move, the best adjacent un-swapped friend takes the better firing hex, once per ship
function treeRotSwap(u){ if(!treeSkill('rotation')||!u||u.isSq||u.side!=='player'||u.dead||!cmdActive(u.side,'iron')||u.treeRotUsed) return;
  const cands=alive('player').filter(x=>x!==u&&!x.isSq&&!x.dead&&!x.treeRotUsed&&hdist(x,u)===1); let best=null,bs=-1e18;
  for(const v of cands){ const gain=treeOffenseAt(v,u.q,u.r)-treeOffenseAt(v,v.q,v.r); if(gain>bs){ bs=gain; best=v; } }
  if(best){ const q=u.q,r=u.r; u.q=best.q; u.r=best.r; best.q=q; best.r=r; u.treeRotUsed=1; best.treeRotUsed=1; treeFx(best,'rotation','the line rotates'); } }
// Drill Revision One: once per battle, after the first enemy move, the most hurt ship finds a safer free hex within 2
function treeDrillMove(){ const who=alive('player').filter(x=>!x.isSq&&!x.dead).sort((a,b)=>(a.hp/a.maxHp)-(b.hp/b.maxHp)||(a.id<b.id?-1:1))[0]; if(!who) return;
  const occ=occMap(); let best={q:who.q,r:who.r},bs=-1e18;
  for(const h of boardHexes()){ if(hdist(h,who)>2||blocks(terr(h.q,h.r))||occ.has(hkey(h.q,h.r))) continue; let md=99; for(const e of alive('enemy')) if(!e.isSq) md=Math.min(md,hdist(h,e));
    if(md>bs||(md===bs&&(h.q<best.q||(h.q===best.q&&h.r<best.r)))){ bs=md; best=h; } }
  if(best.q!==who.q||best.r!==who.r){ who.q=best.q; who.r=best.r; treeFx(who,'drillRevision','the drill is revised'); } }
// Standard Borne Forward: a path where every hex is no further from the flagship earns +1 movement
function treePathTowardFlag(u,s){ const fg=treeFlagUnit(); if(!fg) return false; const d0=hdist(u,fg);
  for(const p of (s.path||[])){ if(p.rot) continue; if(hdist({q:p.q,r:p.r},fg)>d0) return false; } return true; }
function treeMoveTowardFlag(u,path,d0){ if(!treeSkill('standardForward')||!u||u.isSq||u.side!=='player') return false; const fg=treeFlagUnit(); if(!fg) return false;
  let steps=0; for(const p of (path||[])){ if(p.rot) continue; if(hdist({q:p.q,r:p.r},fg)>d0) return false; steps++; } if(steps>0) treeFx(u,'standardForward','the standard carries the line'); return steps>0; }
// Second Volley: the shot is legal apart from the arc, at the first synced target, once a round
function treeSecondVolleyOK(u,w,t){ if(!treeSkill('secondVolley')||!u||u.isSq||u.dead||!t||t.dead||u.side!=='player'||w.k==='flak') return false;
  if(!inSync(u)) return false; const sf=B&&B.tr&&B.tr.syncFirst?B.tr.syncFirst.player:null; if(!sf||sf.r!==B.round||sf.id!==t.id||B.tr.secondVolleyUsed) return false;
  const d=hdist(u,t); if(d<1||d>w.r||treeDeepBlocks(u,t)||!los(u,t)) return false; return !inArc(u,t,w.arc); }
function treeArcLegal(u,w,t){ if(!u||u.dead||!t||t.dead||u.side===t.side||u.braced||w.k==='flak'||!weaponReady(w)) return false;
  const d=hdist(u,t); return d>=1&&d<=w.r&&!treeDeepBlocks(u,t)&&los(u,t); }
function treeRangeLegal(u,w,t){ if(!u||u.dead||!t||t.dead||u.side===t.side||u.braced||w.k==='flak'||!weaponReady(w)) return false; return !treeDeepBlocks(u,t)&&los(u,t); }
async function treeSecondVolleyAuto(src,t){ if(!treeSkill('secondVolley')||!B||!B.tr||B.tr.secondVolleyAutoDone) return; const sf=B.tr.syncFirst?B.tr.syncFirst.player:null;
  if(!sf||sf.r!==B.round||sf.id!==t.id) return; B.tr.secondVolleyAutoDone=1;
  const cand=alive('player').filter(x=>x!==src&&!x.isSq&&!x.dead&&inSync(x)&&!x.weapons.some(w=>w.fired));
  for(const x of cand){ for(let i=0;i<x.weapons.length;i++){ const w=x.weapons[i]; if(w.k==='flak'||w.off||w.cdLeft) continue; if(canFire(x,w,t)||!treeArcLegal(x,w,t)) continue;
      if(await treeExtraShot(x,i,t,{forceArc:true})){ treeFx(x,'secondVolley','one more synced ship fires out of arc'); return; } } } }
async function treeVolleyAt(u,t){ if(!u||!t||u.dead||t.dead||B.over) return; const b0=B, keep=u.weapons.map(w=>[w.fired,w.cdLeft]), pf=[u.postFire,u.postMp];
  u.weapons.forEach(w=>{ w.fired=false; w.cdLeft=0; });
  try{ for(let i=0;i<u.weapons.length;i++){ if(B!==b0||B.over||u.dead||t.dead) break; const w=u.weapons[i]; if(w.k==='flak'||w.off) continue; if(canFire(u,w,t)) await fireWeapon(u,i,t); } }
  finally{ u.weapons.forEach((w,i)=>{ w.fired=keep[i][0]; w.cdLeft=keep[i][1]; }); u.postFire=pf[0]; u.postMp=pf[1]; } }
async function treeWingStrikeAt(sq,t){ if(!sq||sq.dead||!t||t.dead||B.over) return false; let fired=false;
  for(let i=0;i<sq.weapons.length;i++){ if(B.over||sq.dead||t.dead) break; if(canFire(sq,sq.weapons[i],t)){ await fireWeapon(sq,i,t); fired=true; } } return fired; }
async function treeWingStrikeNow(sq){ if(!sq||sq.dead||B.over) return false; let fired=false;
  for(let i=0;i<sq.weapons.length;i++){ if(B.over||sq.dead) break; let best=null,bv=0;
    for(const t of alive('enemy')){ if(!canFire(sq,sq.weapons[i],t)) continue; const e=expectedVs(sq,sq.weapons[i],t), v=e.hull+e.shield*.3+(e.hull>=t.hp?20:0); if(v>bv){ bv=v; best=t; } }
    if(best){ await fireWeapon(sq,i,best); fired=true; } } return fired; }
async function treePatrolStrike(enemy){ if(!treeSkill('standingGroup')||!enemy||enemy.dead||enemy.isSq||enemy.side!=='enemy') return;
  for(const sq of alive('player')){ if(!sq.isSq||!sq.treePatrol||sq.dead||sq.treePatrolRound===B.round) continue; const p=B.units.find(x=>x.id===sq.parent&&!x.dead); if(!p) continue;
    let range=0; for(const w of p.weapons){ if(w.k==='flak') continue; range=Math.max(range,w.r||0); } if(!range) range=6; if(hdist(p,enemy)>range) continue;
    let fired=false; for(let i=0;i<sq.weapons.length;i++){ if(B.over||sq.dead||enemy.dead) break; if(canFire(sq,sq.weapons[i],enemy)||treeRangeLegal(sq,sq.weapons[i],enemy)){ if(await treeExtraShot(sq,i,enemy,{forceArc:true,forceRange:true})) fired=true; } }
    if(fired){ sq.treePatrolRound=B.round; treeFx(sq,'standingGroup','the patrol strikes the intruder'); } } }
function treeFacingTo(u,t){ const a=angTo(u,t); return ((Math.round(a/60)%6)+6)%6; }
// H6: extra swarms may be placed up to r hexes from the brood (Matriarch T1b)
function treeLaunchHexes(u,r){ const occ=occMap(), out=[]; for(const h of boardHexes()){ const d=hdist(u,h); if(d<1||d>r||blocks(terr(h.q,h.r))||occ.has(hkey(h.q,h.r))) continue; out.push(h); } return out; }
// the facing that brings the most ready guns to bear, for the free-turn tree skills (deterministic, no random draw)
function treeBestFacing(u){ const foe=u.side==='player'?'enemy':'player', foes=alive(foe).filter(t=>!t.dead); if(!foes.length) return null;
  let best=null,bv=0; for(let f=0;f<6;f++){ if(f===u.facing) continue; const v=stateView(u,{q:u.q,r:u.r,f}); let score=0;
    for(const w of u.weapons){ if(!weaponReady(w)) continue; for(const t of foes){ if(inReach(v,w,t)){ const e=expectedVs(v,w,t); score+=e.hull+e.shield*.3; } } }
    if(score>bv){ bv=score; best=f; } } return bv>0?best:null; }
// H3: once per player round start: counters, start facings, pending next-round heals, and the flagship lens pick
function treeRoundStart(){ if(!B||!B.tree||!B.tree.length) return; B.tr=B.tr||{};
  const prevStrike=Object.assign({},B.tr.hitDuringStrike||{});
  B.treePermFile=(treeSkill('permanentFile')&&B.cmd&&B.cmd.id==='hunt'&&B.cmd.round===B.round-1)?{r:B.round,m:cmdPow('hunt',B.cmd.tier),ids:prevStrike}:null;
  B.tr.enemyShots={}; B.tr.volleyHits={}; B.tr.logged={}; B.tr.volleyPick={}; B.tr.wingsDebt={}; B.tr.standardUsed=0; B.tr.escortUsed={};
  B.tr.smileUsed=0; B.tr.rearShips={}; B.tr.wingStruck={}; B.tr.hitRound={};
  B.tr.targetedLast=B.tr.targeted||{}; B.tr.targeted={}; B.tr.iterKill={};
  B.tr.swarmHitBy={}; B.tr.volleyShips={}; B.tr.volleyHit={}; B.tr.burnStays=null;
  B.tr.syncFirst={player:null,enemy:null}; B.tr.secondVolleyUsed=0; B.tr.secondVolleyAutoDone=0; B.tr.rollingUsed=0; B.tr.strikeSpeed=null; B.tr.strikeSpeedId=null;
  B.tr.crossHits={}; B.tr.totalShips={}; B.tr.hitDuringStrike={}; B.tr.bellUsed=0; B.tr.columnUsed=0; B.tr.firstStopTarget=null; B.tr.firstStopDone=0;
  B.tr.wingFiled=null; B.tr.escortScreen=0; B.tr.beacon=null;
  B.tr.wingTgt={}; B.tr.wingTargets={}; B.tr.lightTgt={}; B.tr.wingCap={}; B.tr.wingCapFirst={};
  B.tr.swarmHunger=null;
  B.tr.sunTarget=null; B.tr.sunFirstDone=0; B.tr.grandTarget=null; B.tr.grandFirstDone=0; B.tr.oneLens=null;
  B.treeWeakShip=null; B.treeShiftUp=null; B.treeShiftDown=null; B.treeWallEarly=0;
  B.treeIronExtra=null;
  for(const u of alive('player')) if(!u.isSq){ u.treeHuntNext=0; u.treeHuntCarry=0; u.treeTorpCarry=0; u.ironCarry=0; u.treeAimNext=0; u.treeRoundDmg=0; u.treeRoundFired=0; u.treeSilentMark=0; u.treeDmgNext=0; u.treeRedFirst=0; u.treeAcidAim=0; u.tempHp=0; u.treeFrenzyMove=0; u.treeVolleyHit=0; u.treeSmile=0; u.treeAimGuns=0; u.treeFreeTurn=0; u.treeRushLogged=0; u.burnCarry=null; u.treeFormation=0; u.treeRotUsed=0; u.treeOverflowUsed=0; u.treeDiveUsed=0; u.treeLensRot=0; u.treeWardFacing=null; u.treeSalvoUsed=0; u.treeShadowPos=0; u.treeEclForm=0; u.treeTeethUsed=0; u.treeIterFire=0; u.treeAimTgt=null; u.treeHpStart=u.hp; }
  if(B.treeReserve&&B.treeReserve.length&&B.round>=2){ const keep=[]; const rk=treeSkill('broodReserve')?'broodReserve':'debtsReserve';
    for(const id of B.treeReserve){ const u=B.units.find(x=>x.id===id); if(!u||u.dead) continue; const h=edgeHex('player'); u.treeOff=0; if(h){ u.q=h.q; u.r=h.r; } u.hp=u.maxHp; u.treeReserve=0; u.activated=false;
      treeFx(u,rk,'the reserve joins the line'); }
    B.treeReserve=keep; }
  if(B.treePending&&B.treePending.length){ const keep=[];
    for(const p of B.treePending){ if(p.r>=B.round){ keep.push(p); continue; }
      if(p.k==='rechargeLit'){ const s=treeSkill('rechargeLit'); let any=false;
        for(const u of alive('player').filter(x=>!x.isSq&&x.shMax>0)){ if((u.st.shieldOff||0)>=99) continue; for(let i=0;i<4;i++) u.sh[i]=Math.min(u.shMax,u.sh[i]+u.regen); any=true; }
        if(any&&s) treeFx(B.units.find(x=>x.pflag&&!x.dead)||alive('player')[0]||null,'rechargeLit','shields recharge a second time'); }
      if(p.k==='holdCounted'){ for(const u of alive('player')) if(!u.isSq&&(u.hexMoved||0)===0) u.ironCarry=p.pow||0; treeFx(B.units.find(x=>x.pflag&&!x.dead)||alive('player')[0]||null,'holdCounted','the wall holds one more round'); }
      if(p.k==='oathStillness'){ for(const u of alive('player')) if(!u.isSq&&u.shMax>0&&(u.hexMoved||0)===0){ for(let i=0;i<4;i++) u.sh[i]=Math.min(u.shMax,u.sh[i]+Math.round(u.shMax*.5)); } treeFx(B.units.find(x=>x.pflag&&!x.dead)||alive('player')[0]||null,'oathStillness','the stillness recharges the wall'); }
      if(p.k==='ironTestament'){ B.treeIronExtra={r:B.round,pow:p.pow||0}; for(const u of alive('player')) if(!u.isSq&&u.shMax>0){ for(let i=0;i<4;i++) u.sh[i]=Math.min(u.shMax,u.sh[i]+Math.round(u.shMax*.5)); } treeFx(B.units.find(x=>x.pflag&&!x.dead)||alive('player')[0]||null,'ironTestament','the wall stands a second round'); }
      if(p.k==='salvoTwoHands'){ for(const id of (p.ids||[])){ const u=B.units.find(x=>x.id===id); if(u&&!u.dead&&!u.isSq) u.treeHuntCarry=p.pow||0; } treeFx(B.units.find(x=>x.pflag&&!x.dead)||alive('player')[0]||null,'salvoTwoHands','the held salvo pays now'); }
      if(p.k==='twoSalvos'){ for(const u of alive('player')) if(!u.isSq) u.treeTorpCarry=p.pow||0; treeFx(B.units.find(x=>x.pflag&&!x.dead)||alive('player')[0]||null,'twoSalvos','the next salvo keeps its bonus'); }
      if(p.k==='wingReserve'){ const u=B.units.find(x=>x.id===p.carrier); if(u&&!u.dead&&!u.isSq){ const hs=launchHexes(u); if(hs.length){ const sq=makeWing(u,hs[0],wingKind(u)); sq.extra=1; treeFx(u,'wingReserve','the held wing launches'); } } }
      if(p.k==='swarmScrap'){ const s=treeSkill('swarmScrap'); let any=false; for(const id of (p.ids||[])){ const u=B.units.find(x=>x.id===id); if(!u||u.dead||u.isSq) continue; const hs=launchHexes(u); if(!hs.length) continue; const fs=alive('enemy'); hs.sort((a,b2)=>Math.min(...fs.map(f=>hdist(a,f)))-Math.min(...fs.map(f=>hdist(b2,f)))); const sq=makeWing(u,hs[0],wingKind(u)); sq.extra=1; any=true; } if(any&&s) treeFx(treeFlagUnit(),'swarmScrap','the swarm launches twice'); } // Mott capstone 1: the second launch after the player turn
      if(p.k==='fleshKnit'){ const s=treeSkill('fleshKnit'); for(const id of (p.ids||[])){ const u=B.units.find(x=>x.id===id); if(u&&!u.dead&&!u.isSq){ u.treeDmgNext=treeAddVal(u,'dmgPct',s.n); treeFx(u,'fleshKnit','the new flesh is angry'); } } }
      if(p.k==='tideEnd'){ const s=treeSkill('tideEnd'); const rp=(p.pow||0)*.5; let any=false;
        for(const u of alive('player')) if(!u.isSq){ const h=Math.min(u.maxHp-u.hp,Math.round(u.maxHp*rp)); if(h>0){ u.hp+=h; any=true; } if(u.sec) for(const k of Object.keys(u.sec)) repairSection(u,k,rp); }
        if(any&&s) treeFx(B.units.find(x=>x.pflag&&!x.dead)||alive('player')[0]||null,'tideEnd','the tide comes a second time'); }
      if(p.k==='burnStays'){ const s=treeSkill('burnStays'); let any=false;
        for(const id in (p.map||{})){ const t=B.units.find(x=>x.id===id); if(!t||t.dead) continue; const d=Math.round((p.map[id]||0)*s.n); if(d<=0) continue; any=true; t.hp=Math.max(1,t.hp-d); if(typeof fxText==='function') fxText(t,'Acid \u2212'+d,'#c8e04a',-16); log(`${t.name} takes ${d} acid damage from the last volley.`,t.side==='player'?'e':'p'); }
        if(any) treeFx(B.units.find(x=>x.pflag&&!x.dead)||alive('player')[0]||null,'burnStays','the burn stays'); }
      if(p.k==='manyMouths'){ const s=treeSkill('manyMouths'); for(const id of (p.ids||[])){ const u=B.units.find(x=>x.id===id); if(u&&!u.dead&&!u.isSq){ u.treeAcidAim=1; treeFx(u,'manyMouths','acid eats at the scanners'); } } }
      if(p.k==='spatRounds'){ B.treeSpatRound=B.round; B.treeSpatIds=p.ids||[]; } // Voice T2b: the held spit fires after this round start (treeRoundFx)
      if(p.k==='growthWound'){ const s=treeSkill('growthWound'); let any=false;
        for(const e of (p.list||[])){ const u=B.units.find(x=>x.id===e.id); if(!u||u.dead||!u.sec||!u.sec[e.sec]) continue; const sec=u.sec[e.sec]; if(sec.broken) continue; repairSection(u,e.sec,e.amt); any=true; }
        if(any&&s) treeFx(B.units.find(x=>x.pflag&&!x.dead)||alive('player')[0]||null,'growthWound','the wound holds its growth'); } // Mending T2b: the section heals again
      if(p.k==='noonRepeat'){ B.treeNoonRound=B.round; } // Umbria capstone 1: the volley repeats after this round start (treeRoundFx)
      if(p.k==='debtDue'){ B.treeDebtRound=B.round; B.treeDebtPow=p.pow||0; } // Vex T3b: the delayed volley fires now
      if(p.k==='forgeAhead'){ B.treeForgeRound=B.round; B.treeForgeList=p.list||[]; } // Tamsa capstone 2: the forge strikes now
      if(p.k==='layersShift'){ const fg=treeFlagUnit(); if(fg) for(const u of caps('player')){ if(u===fg) continue; if(treeStepToward(u,fg,1)) treeFx(u,'layersShift','the layer shifts'); } }
      if(p.k==='burnCarry'){ for(const u of alive('player')) if(!u.isSq) u.burnCarry={mp:p.pow||0,turns:p.turns||0}; treeFx(treeFlagUnit(),'burnCarry','the burn carries into the new round'); }
      if(p.k==='secondWave'){ let any=false; const patrol=!!treeSkill('standingGroup'), marked={}, launchOrd=treeSkill('launchOrder'), oneTgt=treeSkill('oneTarget'), fullG2=treeSkill('fullGroup');
        const filedT=(oneTgt||fullG2)?treeChoice('enemy'):null; let firstW=0;
        for(const e of (p.ships||[])){ const u=B.units.find(x=>x.id===e.id); if(!u||u.dead||u.isSq) continue;
          for(let k=0;k<(e.count||0);k++){ const hs=launchHexes(u); if(!hs.length) break; const fs=alive('enemy'); hs.sort((a,b2)=>Math.min(...fs.map(f=>hdist(a,f)))-Math.min(...fs.map(f=>hdist(b2,f))));
            const sq=makeWing(u,hs[0],wingKind(u)); sq.extra=1; sq.treeStrikeNow=1; any=true;
            if((oneTgt||fullG2)&&filedT){ sq.wingOrder={kind:'strike',id:filedT.id}; if(oneTgt) B.tr.wingFiled={r:B.round,id:filedT.id}; }
            if(launchOrd&&!firstW){ firstW=1; sq.treeBonus=(sq.treeBonus||0)+launchOrd.n; treeFx(sq,'launchOrder','the first held wing strikes first'); }
            if(patrol&&!marked[u.id]){ sq.treePatrol=1; marked[u.id]=1; } } }
        if(any){ B.treeStrikeRound=B.round; treeFx(treeFlagUnit(),'secondWave','the held wings strike at the new round'); } } }
    B.treePending=keep; }
  { const big=alive('enemy').filter(x=>!x.isSq).sort((a,b)=>b.maxHp-a.maxHp||(a.id<b.id?-1:1))[0]||null; if(treeSkill('runBigger')){ B.tr.bigId=big?big.id:null; for(const u of alive('player')) if(!u.isSq) u.treeBigStart=big?hdist(u,big):0; } } // Grax T1a: the largest enemy at the start of the burn
  { const sc=treeSkill('stillnessCounted'); if(sc&&B.cmd&&B.cmd.id==='iron'&&B.cmd.round===B.round-1){ for(const u of caps('player')) if((u.hexMoved||0)===0){ u.treeAimNext=treeAddVal(u,'aim',sc.n); treeFx(u,'stillnessCounted','the stillness counts'); } } } // Seveth T3b
  { const os=treeSkill('outShadow'); if(os&&B.cmd&&B.cmd.id==='hunt'&&B.cmd.round===B.round-1){ const pow=cmdPow('hunt',B.cmd.tier); for(const u of caps('player')) if(treeInEnemyRear(u)||!B.tr.targetedLast[u.id]){ u.treeHuntCarry=pow; treeFx(u,'outShadow','the shadow holds a second round'); } } } // Ostrel capstone 1
  const foes=alive('enemy').filter(x=>!x.isSq);
  for(const u of alive('player')) if(!u.isSq){ u.treeStartFacing=u.facing; u.treeDeep=0; u.treeAngleUsed=0; u.treeMirrorUsed=0; u.treePreyRear=null;
    if(treeSkill('debtHunts')&&foes.length){ let near=null,nd=1e9; for(const f of foes){ const d=hdist(u,f); if(d<nd){ nd=d; near=f; } }
      if(near){ let closest=true; for(const v of alive('player')) if(v!==u&&!v.isSq&&hdist(v,near)<nd){ closest=false; break; }
        if(closest) u.treePreyRear=near.id; } } }
  { const s=treeSkill('flagshipLens'); if(s){ const t=treeChoice('enemy'); B.treeLens=t?{r:B.round,id:t.id}:null; if(t) treeFx(B.units.find(x=>x.pflag&&!x.dead)||t,'flagshipLens','the lens marks '+t.name); } }
  { const bc=treeSkill('beacon'); if(bc){ const t=treeChoice('enemy'); B.tr.beacon=t?{r:B.round,id:t.id}:null; if(t) treeFx(treeFlagUnit()||t,'beacon','the flagship stamps '+t.name); } } // Hegemony shared C1a
  { const ss=treeSkill('sharedSolution'); if(ss){ const syn=alive('player').filter(x=>!x.isSq&&!x.dead&&inSync(x)); if(syn.length>1){ const low=syn.slice().sort((a,b)=>a.aim-b.aim||(a.id<b.id?-1:1))[0]; treeFx(low,'sharedSolution','the best solution is shared'); } } } // Kassar T2a
  { const cd=treeSkill('coldDrill'); if(cd){ const u=alive('player').filter(x=>!x.isSq&&!x.dead&&inSync(x))[0]; if(u) treeFx(u,'coldDrill','the drill runs cold'); } } // Kassar T2b
  { const tr=treeSkill('throatRed'); if(tr&&B.cmd&&B.cmd.id==='surge'&&B.cmd.round===B.round-1){ for(const u of alive('player')) if(!u.isSq&&(u.treeRedNext||alive('enemy').some(x=>!x.isSq&&hdist(u,x)===1))){ u.treeRedFirst=1; treeFx(u,'throatRed','the throat turns red'); } } for(const u of alive('player')) if(!u.isSq) u.treeRedNext=0; }
  { const rh=treeSkill('refuseHoles'); if(rh){ const hurt=alive('player').filter(x=>!x.isSq&&x.hp<x.maxHp/2); if(hurt.length){ hurt.sort((a,b)=>a.hp/a.maxHp-b.hp/b.maxHp||(a.id<b.id?-1:1)); const u=hurt[0]; const want=Math.min(Math.round(u.maxHp*rh.n),Math.max(0,Math.ceil(u.maxHp/2)-u.hp)); if(want>0){ u.hp=Math.min(u.maxHp,u.hp+want); treeFx(u,'refuseHoles','the throat refuses holes'); } } } } }
// H12: move one ship to a free hex in its own deployment zone, before any ship acts
function treeDeployMove(kind,txt){ if(!B||!B.tree||!B.tree.length) return; if(!treeSkill(kind)) return;
  const who=treeChoice('ship'); if(!who) return; const bb=boardBounds(), occ=occMap(); let best=null,bd=1e9;
  for(const h of boardHexes()){ const c=h.q+Math.floor(h.r/2); if(c>bb.c0+2) continue; if(blocks(terr(h.q,h.r))||occ.has(hkey(h.q,h.r))) continue; const d=hdist(h,who); if(d>0&&d<bd){ bd=d; best=h; } }
  if(best){ who.q=best.q; who.r=best.r; treeFx(who,kind,txt); } }
// H12 plus H13: the two Glasswright fleet picks, and the Sunward sworn deployment and reserve, run at battle start
function treeBattleStart(){ if(!B||!B.tree||!B.tree.length) return;
  treeDeployMove('deployRead','redeployed from the shards');
  treeDeployMove('swornDeploy','sworn into place');
  const cc=treeSkill('castCorrected');
  if(cc){ const l=alive('player').filter(x=>!x.isSq).slice(0,2); if(l.length===2){ const a=l[0], b=l[1], q=a.q, r=a.r; a.q=b.q; a.r=b.r; b.q=q; b.r=r; treeFx(a,'castCorrected','the cast is corrected'); } }
  const isw=treeSkill('iterationSwap');
  if(isw){ const l=alive('player').filter(x=>!x.isSq).slice(0,2); if(l.length===2){ const a=l[0], b=l[1], q=a.q, r=a.r; a.q=b.q; a.r=b.r; b.q=q; b.r=r; treeFx(a,'iterationSwap','the copy is swapped'); } }
  const dr=treeSkill('debtsReserve');
  if(dr){ const who=treeChoice('reserve'); if(who){ who.treeOff=1; who.treeReserve=1; B.treeReserve=(B.treeReserve||[]).concat(who.id); treeFx(who,'debtsReserve','held in reserve'); } }
  const br=treeSkill('broodReserve');
  if(br){ const who=treeChoice('brood'); if(who){ who.treeOff=1; who.treeReserve=1; B.treeReserve=(B.treeReserve||[]).concat(who.id); treeFx(who,'broodReserve','the brood is held back'); } }
  const ps=treeSkill('preyScent');
  if(ps){ const e=treeChoice('enemy'); B.tr.scent=e?e.id:null; if(e) treeFx(treeFlagUnit()||e,'preyScent','the pack names its prey'); } } // Hullbreakers shared B1a: name the prey at battle start
// called wherever a ship's facing changes (move, rotate): Vell's free turn, recorded angles and full-distance cover
function treeAfterMove(u){ if(!B||!B.tree||!B.tree.length||!u||u.isSq) return;
  const mt=treeSkill('mirrorTurns');
  if(mt&&cmdActive(u.side,'surge')&&!u.treeMirrorUsed){ const f=treeBestFacing(u); u.treeMirrorUsed=1; if(f!=null&&f!==u.facing) u.facing=f; treeFx(u,'mirrorTurns','the mirror turns'); }
  const ar=treeSkill('anglesRecorded');
  if(ar&&cmdActive(u.side,'surge')&&!u.treeAngleUsed&&u.treeStartFacing!=null&&u.facing!==u.treeStartFacing){ u.treeAngleUsed=1; u.evBuff=Math.min(FX_CAPS.ev||50,(u.evBuff||0)+ar.n); treeFx(u,'anglesRecorded','a false angle holds'); }
  { const lr=treeSkill('lensRotates'); if(lr&&u.side==='player'&&cmdActive(u.side,'iron')&&!u.treeLensRot&&u.treeWardFacing!=null&&u.facing!==u.treeWardFacing){ u.treeLensRot=1; u.evBuff=Math.min(FX_CAPS.ev||50,(u.evBuff||0)+lr.n); treeFx(u,'lensRotates','the lens turns'); } } // Brin T2b
  const rf=treeSkill('refraction');
  if(rf&&cmdActive(u.side,'surge')&&u.mp<=0){ u.treeDeep=1; treeFx(u,'refraction','the reflection cannot be found beyond range 6'); }
  { const sa=treeSkill('silentArchive'); if(sa&&u.side==='player'&&cmdActive(u.side,'hunt')&&!u.treeSilentMark){ for(const t of alive('enemy')){ if(!t.isSq&&!inArc(t,u,'F')){ u.treeSilentMark=1; treeFx(u,'silentArchive','the archive hides the ship'); break; } } } }
  const tr=treeSkill('throatRed');
  if(tr&&cmdActive(u.side,'surge')&&alive('enemy').some(x=>!x.isSq&&hdist(u,x)===1)) u.treeRedNext=1; // Razormaw capstone 1: the red throat carries into next round
  { const lp=treeSkill('loosePack'); if(lp&&u.side==='player'&&(u.hexMoved||0)>0&&!alive('player').some(x=>x.id!==u.id&&!x.isSq&&hdist(x,u)<=2)) treeFx(u,'loosePack','the pack runs wide'); } // Hullbreakers shared B1b
  if(u.side==='player'&&!u.isSq){
    if(treeSkill('formation')&&alive('player').filter(x=>x!==u&&!x.isSq&&hdist(x,u)===1).length>=2){ u.treeFormation=1; treeFx(u,'formation','the formation is filed'); }
    { const ef=treeSkill('eclFormation'); if(ef&&!u.treeEclForm&&alive('player').filter(x=>x!==u&&!x.isSq&&hdist(x,u)===1).length>=2){ u.treeEclForm=1; u.evBuff=Math.min(FX_CAPS.ev||45,(u.evBuff||0)+ef.n); treeFx(u,'eclFormation','the formation holds'); } } // Eclipse shared B1a: two friends close by give evasion
    { const sp=treeSkill('shadowPos'); if(sp&&cmdActive(u.side,'hunt')&&!u.treeShadowPos&&treeInEnemyRear(u)){ u.treeShadowPos=1; treeFx(u,'shadowPos','the shadow is a position'); } } // Ostrel T2a: ending in a rear arc pays
    if(cmdActive(u.side,'iron')){
      const cs=treeSkill('columnStraight'); if(cs&&treeInColumn(u)){ if(treeShieldOver(u,cs.n)>0) treeFx(u,'columnStraight','the column adds shield'); }
      const fs=treeSkill('flagshipStandard'); if(fs&&treeInFlagLine(u)){ if(treeShieldOver(u,fs.n)>0) treeFx(u,'flagshipStandard','the flagship holds the line'); }
      const ov=treeSkill('overflow'); if(ov&&u.shMax>0&&u.sh.every(v=>v>=u.shMax)&&!u.treeOverflowUsed){ u.treeOverflowUsed=1; u.evBuff=Math.min(45,(u.evBuff||0)+ov.n); treeFx(u,'overflow','the surplus becomes evasion'); }
      const rot=treeSkill('rotation'); if(rot) treeRotSwap(u);
    }
  }
  if(u.side==='enemy'&&treeSkill('drillRevision')&&!B.treeDrillUsed){ B.treeDrillUsed=1; treeDrillMove(); } } // Hegemony job 6
function treeDeepBlocks(u,t){ const s=treeSkill('refraction'); return !!(s&&t&&t.treeDeep&&!u.isSq&&hdist(u,t)>s.n); }
// Malek T3a: side arc hits on the ship's hunted target count as rear arc hits this round
function treeIsRear(u,t,quad){ if(quad===2) return true; const s=treeSkill('debtHunts'); return !!(s&&u&&t&&u.side==='player'&&u.treePreyRear===t.id&&(quad===1||quad===3)); }
// H4: one weapon fired again outside the normal flow, then the gun is put back exactly as it was
async function treeExtraShot(u,wi,t,opts){ if(!B||!u||!t||u.dead||t.dead) return false; const w=u.weapons[wi]; if(!w) return false;
  const keep=[w.fired,w.cdLeft]; w.fired=false; w.cdLeft=0; let ok=false;
  try{ if(canFire(u,w,t)||(opts&&opts.forceArc&&treeArcLegal(u,w,t))||(opts&&opts.forceRange&&treeRangeLegal(u,w,t))) ok=await fireWeapon(u,wi,t,opts||{}); } finally{ w.fired=keep[0]; w.cdLeft=keep[1]; } return ok; }
async function treeSpit(u){ const s=treeSkill('throatSpits'); if(!s||!B||!u||u.dead||u.isSq||u.side!=='player') return false; // Voice T1b: a ship whose guns cannot bear spits once at the nearest enemy in range, ignoring arc
  const foes=alive('enemy').filter(t=>!t.dead&&!t.isSq); if(!foes.length) return false;
  let t=null,td=1e9; for(const f of foes){ const d=hdist(u,f); if(d<td){ td=d; t=f; } }
  let wi=-1,bv=-1; for(let i=0;i<u.weapons.length;i++){ const w=u.weapons[i]; if(w.k==='flak') continue; if(td>w.r) continue; const v=w.dmg*w.shots; if(v>bv){ bv=v; wi=i; } }
  if(wi<0) return false;
  const w=u.weapons[wi], keep=[w.fired,w.cdLeft,w.off], old=u.facing, pf=[u.postFire,u.postMp];
  const f=treeFacingTo(u,t); if(f!=null) u.facing=f; w.fired=false; w.cdLeft=0; w.off=0; let ok=false;
  try{ if(canFire(u,w,t)) ok=await fireWeapon(u,wi,t,{half:true}); } finally{ w.fired=keep[0]; w.cdLeft=keep[1]; w.off=keep[2]; u.facing=old; u.postFire=pf[0]; u.postMp=pf[1]; }
  if(ok) treeFx(u,'throatSpits','a throat spits without a bearing');
  return ok; }
async function treeWallAnswer(t,att){ if(!t||!att||t.dead||att.dead) return false; let wi=-1,bv=Infinity;
  for(let i=0;i<t.weapons.length;i++){ const w=t.weapons[i]; if(w.off||w.k==='flak') continue; const v=w.dmg*w.shots; if(v<bv){ bv=v; wi=i; } }
  if(wi<0) return false; const ok=await treeExtraShot(t,wi,att,{}); if(ok) treeFx(t,'wallAnswers','the wall answers'); return ok; }
// H4: Vex's held volley fires right after the chosen ship moves this round
async function treeFreeVolleyShip(u,foe,half){ const b0=B; const keep=u.weapons.map(w=>[w.fired,w.cdLeft]); const pf=[u.postFire,u.postMp];
  u.weapons.forEach(w=>{ w.fired=false; w.cdLeft=0; });
  try{ for(let i=0;i<u.weapons.length;i++){ if(B!==b0||B.over||u.dead) break; const w=u.weapons[i]; const ts=alive(foe).filter(t=>canFire(u,w,t)); if(!ts.length) continue;
    const val=t=>{ const e=expectedVs(u,w,t); return e.hull+e.shield*.3+(e.hull>=t.hp?25:0); }; ts.sort((a,b2)=>val(b2)-val(a)); await fireWeapon(u,i,ts[0],half?{half:true}:{}); } }
  finally{ u.weapons.forEach((w,i)=>{ w.fired=keep[i][0]; w.cdLeft=keep[i][1]; }); u.postFire=pf[0]; u.postMp=pf[1]; } }
async function treeHeldFire(u){ if(!B||!B.tree||!B.tree.length||!u||u.isSq||!u.treeHeld) return; u.treeHeld=0;
  if(B.over||u.dead||!cmdActive('player','barrage')) return; const b0=B; B.volleyMul={side:'player',m:1+cmdPow('barrage',B.cmd&&B.cmd.tier)};
  try{ await treeFreeVolleyShip(u,'enemy'); } finally{ if(B===b0) B.volleyMul=null; }
  treeFx(u,'heldAccount','the held volley fires after the move'); }
// H16: an escort wing takes the first gunfire aimed at its named friend this round
function treeEscortWing(t){ const s=treeSkill('escortName'); if(!s||!B||!B.tr||!t) return null; const used=B.tr.escortUsed||(B.tr.escortUsed={});
  for(const sq of alive('player')){ if(!sq.isSq||sq.escort!==t.id) continue; if(used[sq.id]) continue; used[sq.id]=1; return sq; }
  return null; }
function treeRecordedAngle(side){ const s=treeSkill('recordedAngle'); if(!s||side!=='player'||!cmdActive(side,'barrage')) return;
  for(const u of alive(side).filter(x=>!x.isSq)){ if(!(u.turnsLeft>=u.turns)) continue; const f=treeBestFacing(u); if(f==null||f===u.facing) continue; u.facing=f; treeFx(u,'recordedAngle','the lens turns before the volley'); } }
function commandFor(side){ if(side!=='player') return null; if(typeof RUN!=='undefined'&&RUN&&RUN.cmdOverride) return RUN.cmdOverride; const id=(typeof RUN!=='undefined'&&RUN&&RUN.admiral)||'vex', a=ADMIRALS[id]; return (a&&a.cmd)||COMMANDS[id]||COMMANDS.vex; }
function cmdActive(side,id){ const c=cmdRec(side); return !!(c&&c.id===id&&c.round===B.round); }
function canCommand(side){ return !!B&&!B.over&&side==='player'&&!!commandFor(side)&&B.round>=1&&!B.cmdUsed; } // ready from round 1, once per battle
function cmdTaken(t){ // shieldless hulls get a deeper cut, since the shield refill does nothing for them
  let cut = cmdActive(t.side,'iron') ? cmdPow('iron',null,t.side) : (((t.side==='player')&&B&&B.treeIronExtra&&B.treeIronExtra.r===B.round) ? (B.treeIronExtra.pow||0) : (t.side==='player'?(t.ironCarry||0):0));
  { const wc=t.treeWallCarry; if(wc&&wc.r===B.round&&t.side==='player') cut=Math.max(cut,wc.pow); } // Seveth capstone 2
  { const ps=treeSkill('platesShadow'); if(ps&&t.side==='player'&&cmdActive('player','iron')&&B.treePlate&&B.treePlate.r===B.round) cut = t.id===B.treePlate.id ? .75 : .25; } // Seveth T1a
  { const tr=treeSkill('twiceRestored'); if(tr&&t.side==='player'&&cmdActive('player','iron')&&t.treeRepaired) cut=Math.min(.95,cut+tr.n); } // Seveth T1b
  { const up=treeSkill('unpaid'); if(up&&cut>0&&t.side==='player'&&t.hp<t.maxHp/2) cut=Math.min(.95,cut+up.n); } // Thale T3a
  { const sc=treeSkill('standardCovers'); if(sc&&t.side==='player'&&cmdActive('player','iron')) cut=Math.min(.95,cut+sc.n); } // Maren capstone 1
  { const ws=treeSkill('weakSide'); if(ws&&t.side==='player'&&cmdActive('player','iron')&&B&&B.treeWeakShip&&B.treeWeakShip.r===B.round&&t.id===B.treeWeakShip.id) cut=Math.min(.95,cut+ws.n); } // Brin T1a
  { const sh=treeSkill('screensShift'); if(sh&&t.side==='player'&&cmdActive('player','iron')&&B){ if(B.treeShiftUp&&B.treeShiftUp.r===B.round&&t.id===B.treeShiftUp.id) cut=Math.min(.95,cut+sh.n); if(B.treeShiftDown&&B.treeShiftDown.r===B.round&&t.id===B.treeShiftDown.id) cut=Math.max(0,cut-sh.n); } } // Thale T1b
  { const we=treeSkill('wallEarly'); if(we&&t.side==='player'&&cmdActive('player','iron')&&B&&B.treeWallEarly===B.round) cut=Math.min(.95,cut+we.n); } // Thale T2a
  return cut>0?1-cut-(t.shMax?0:.1):1; }
async function useCommand(side){ if(!canCommand(side)) return false; const c=commandFor(side); const tier=cmdTier(); B.cmdUsed=true; B.cmd={id:c.id,side,round:B.round,tier}; if(B.usage&&side==='player') B.usage.cmd++;
  log(`Admiral's Command${tier?` at power ${tier+1} of 3`:''}: ${c.n}. ${cmdDesc(c,tier,(typeof RUN!=='undefined'&&RUN&&RUN.fac)||'voidsworn')}`,side==='player'?'p':'e'); try{ if(typeof tel==='function') tel('command',{id:c.id,round:B.round,tier}); }catch(e){}
  return runCommand(side,c,tier); }
async function runCommand(side,c,tier){ const foe=side==='player'?'enemy':'player', bStart=B;
  for(const u of alive(side)) if(!u.isSq&&typeof fxText==='function') fxText(u,c.n,side==='player'?'#e8c66a':'#ff8a6a',-44);
  if(c.id==='barrage'){ { const dd=treeSkill('debtDue'); if(dd&&side==='player'){ (B.treePending=B.treePending||[]).push({k:'debtDue',r:B.round,pow:cmdPow('barrage',tier)}); treeFx(treeFlagUnit(),'debtDue','the account waits a round'); if(B===bStart) checkEnd(); return true; } } // Vex T3b: the volley is delayed
    treeRecordedAngle(side); const b0=B, live=liveFrom(null); B.volleyMul={side,m:1+cmdPow('barrage',tier)};
    B.treeNoon=!!(treeSkill('noonChoice')&&side==='player'&&!alive('player').some(x=>!x.isSq&&((x.hexMoved||0)>0||x.treeRoundFired)));
    const cf=treeSkill('copyFires'), osc=treeSkill('oneSunCopied');
    const held=(side==='player'&&treeSkill('heldAccount'))?treeChoice('ship'):null; let heldOnce=0;
    const named=(side==='player'&&treeSkill('namedLedger'))?treeChoice('enemy'):null; if(named) treeFx(named,'namedLedger','the volley is aimed by name');
    const eg=(side==='player')?treeSkill('everyGun'):null;
    const acid=(side==='player')?treeSkill('acidBeforeAim'):null;
    const spits=(side==='player')?treeSkill('throatSpits'):null;
    const grows=(side==='player')?treeSkill('volleyGrows'):null;
    const mouth=(side==='player')?treeSkill('mouthDeep'):null; const mouthShip=mouth?treeChoice('ship'):null;
    const olS=(side==='player'&&treeSkill('oneLens'))?treeChoice('ship'):null; const olT=(olS&&treeSkill('oneLens'))?treeChoice('enemy'):null;
    if(olS&&olT){ B.tr.oneLens={ship:olS.id,tgt:olT.id}; treeFx(olS,'oneLens','one lens, one target'); } // Saro T1b
    const sun=(side==='player')?treeSkill('sunLens'):null; const sunT=sun?treeChoice('enemy'):null; if(sun&&sunT){ B.tr.sunTarget=sunT.id; B.tr.sunFirstDone=0; treeFx(sunT,'sunLens','the sun goes through one lens'); } // Saro capstone 1
    const grand=(side==='player'&&treeSkill('grandLedger')&&!B.tr.grandUsed)?treeSkill('grandLedger'):null; const grandT=grand?treeChoice('enemy'):null; if(grand&&grandT){ B.tr.grandUsed=1; B.tr.grandTarget=grandT.id; B.tr.grandFirstDone=0; treeFx(grandT,'grandLedger','the grand ledger opens'); } // Vex capstone 1
    const lastA=(side==='player')?treeSkill('lastAccount'):null;
    const srS=(side==='player')?treeSkill('spatRounds'):null; const spatSet={};
    if(srS){ const all=alive('player').filter(x=>!x.isSq&&!x.dead); const cc=all.filter(x=>!alive(foe).some(t=>!t.isSq&&x.weapons.some(w=>canFire(x,w,t)))); const pick=cc.slice().sort((a,b2)=>{ const da=a.weapons.reduce((n,w)=>n+(w.k==='flak'?0:w.dmg*w.shots),0), db=b2.weapons.reduce((n,w)=>n+(w.k==='flak'?0:w.dmg*w.shots),0); return db-da||(a.id<b2.id?-1:1); }).slice(0,Math.floor(all.length/2)); for(const u of pick) spatSet[u.id]=1; } // Voice T2b: only ships with nothing to fire at now hold their spit (up to half the fleet); the default never holds a ship that could fire
    const ta=(side==='player')?treeSkill('targetArchived'):null; const taPick={}, taCount={};
    if(ta){ for(const u of alive('player').filter(x=>!x.isSq&&!x.dead)){ let own=null,ov=-Infinity; for(const t of alive(foe)){ if(t.isSq) continue; for(const w of u.weapons){ if(canFire(u,w,t)){ const e=expectedVs(u,w,t); const v=e.hull+e.shield*.3; if(v>ov){ ov=v; own=t; } } } } if(own){ taPick[u.id]=own.id; taCount[own.id]=(taCount[own.id]||0)+1; } } } // Umbra T2b: every ship picks its own target before the volley
    try{ for(const u of alive(side).filter(x=>!x.isSq)){ if(B.over||!live()) break; let firedAny=false;
      if(spatSet[u.id]) continue;
      if(held&&!heldOnce&&u.id===held.id&&(u.hexMoved||0)===0){ u.treeHeld=1; heldOnce=1; treeFx(u,'heldAccount','the volley is held for the move'); continue; }
      const ll=treeSkill('longLight'); let bumped=0; if(ll&&side==='player'&&u.turnsLeft>=u.turns){ bumped=treeAddVal(u,'lanceRange',ll.n); if(bumped>0){ for(const w of u.weapons) if(w.k==='lance'){ w.r+=bumped; w.opt+=bumped; } treeFx(u,'longLight','lances reach further'); } }
      let own=null; if(eg){ let ov=-Infinity; for(const t of alive(foe)){ if(t.isSq) continue; for(const w of u.weapons){ if(canFire(u,w,t)){ const e=expectedVs(u,w,t); const v=e.hull+e.shield*.3; if(v>ov){ ov=v; own=t; } } } }
        if(own){ const n=(B.tr.volleyPick&&B.tr.volleyPick[own.id])||0; if(n>0){ u.treeAimPlus=treeAddVal(u,'aim',eg.n); treeFx(u,'everyGun','a shared solution'); } B.tr.volleyPick[own.id]=n+1; } }
      if(ta&&taPick[u.id]){ const tid=taPick[u.id]; if((taCount[tid]||0)===1){ u.treeAimTgt=tid; treeFx(u,'targetArchived','the archived target is unshared'); } } // Umbra T2b
      const keep=u.weapons.map(w=>[w.fired,w.cdLeft]), pf=[u.postFire,u.postMp]; u.weapons.forEach(w=>{ w.fired=false; w.cdLeft=0; });
      const foesBefore=alive(foe).length;
      u.treeVolleyHit=0;
      for(let i=0;i<u.weapons.length;i++){ if(B.over||!live()||u.dead) break; const w=u.weapons[i]; const ts=alive(foe).filter(t=>canFire(u,w,t)); if(!ts.length) continue; firedAny=true; const val=t=>{ const e=expectedVs(u,w,t); return e.hull+e.shield*.3+(e.hull>=t.hp?25:0); }; ts.sort((a,b2)=>val(b2)-val(a));
        let pick=ts[0]; if(olS&&u.id===olS.id&&olT&&canFire(u,w,olT)) pick=olT; else if(sunT&&canFire(u,w,sunT)) pick=sunT; else if(grandT&&canFire(u,w,grandT)) pick=grandT; else if(named&&canFire(u,w,named)) pick=named; else if(acid){ pick=ts.slice().sort((a,b2)=>hdist(u,a)-hdist(u,b2)||(a.id<b2.id?-1:1))[0]; treeFx(u,'acidBeforeAim','the nearest enemy is chosen'); } else if(eg&&own&&canFire(u,w,own)) pick=own; // Voice T1a: the nearest enemy instead of the best target
        await fireWeapon(u,i,pick); }
      u.treeAimPlus=0; if(ta) u.treeAimTgt=null;
      u.weapons.forEach((w,i)=>{ w.fired=keep[i][0]; w.cdLeft=keep[i][1]; }); if(bumped>0) for(const w of u.weapons) if(w.k==='lance'){ w.r-=bumped; w.opt-=bumped; } u.postFire=pf[0]; u.postMp=pf[1];
      if(spits&&!firedAny&&!u.dead&&!B.over) await treeSpit(u); // Voice T1b: a throat that cannot bear still spits
      if(grows&&u.treeVolleyHit&&!u.dead&&!B.over){ let bw=-1,bt2=null,bv=-1; for(let i=0;i<u.weapons.length;i++){ const w=u.weapons[i]; if(w.k==='flak'||w.off) continue; for(const t of alive(foe)){ if(!canFire(u,w,t)) continue; const e=expectedVs(u,w,t), v=e.hull+e.shield*.3; if(v>bv){ bv=v; bw=i; bt2=t; } } }
        if(bw>=0&&bt2&&await treeExtraShot(u,bw,bt2,{half:true})) treeFx(u,'volleyGrows','the first spit spits again'); } // Voice capstone 1
      if(mouth&&mouthShip&&u.id===mouthShip.id&&!u.dead&&!B.over){ let bt3=null,bv3=-1; for(const t of alive(foe)){ let v=0; for(const w of u.weapons){ if(w.k==='flak'||w.off) continue; if(canFire(u,w,t)){ const e=expectedVs(u,w,t); v+=e.hull+e.shield*.3; } } if(v>bv3){ bv3=v; bt3=t; } }
        if(bt3){ for(let rep=0;rep<2;rep++) for(let i=0;i<u.weapons.length;i++){ if(bt3.dead||B.over||u.dead) break; if(canFire(u,u.weapons[i],bt3)) await treeExtraShot(u,i,bt3,{}); } treeFx(u,'mouthDeep','the deep mouth spits every gun twice'); } } // Voice capstone 2
      if(side==='player'&&cf&&!u.dead&&!B.over&&alive(foe).length<foesBefore){ let bt=null,bv=-Infinity; for(const t2 of alive(foe)){ if(t2.isSq) continue; for(const w2 of u.weapons){ if(!canFire(u,w2,t2)) continue; const e=expectedVs(u,w2,t2); const v=e.hull+e.shield*.3; if(v>bv){ bv=v; bt=t2; } } } if(bt){ let wi=-1; for(let i=0;i<u.weapons.length;i++){ if(canFire(u,u.weapons[i],bt)){ wi=i; break; } } if(wi>=0&&await treeExtraShot(u,wi,bt,{})) treeFx(u,'copyFires','the copy fires again'); } } // Umbra T2a
      if(side==='player'&&osc&&!u.dead&&!B.over){ const low=alive(foe).filter(x=>!x.isSq).sort((a,b)=>a.hp-b.hp||(a.id<b.id?-1:1))[0]; if(low){ let any=false; for(let i=0;i<u.weapons.length;i++){ if(B.over||u.dead) break; if(canFire(u,u.weapons[i],low)){ if(await treeExtraShot(u,i,low,{half:true})) any=true; } } if(any) treeFx(u,'oneSunCopied','the sun is copied'); } }
      if(side==='player'&&lastA&&!u.dead&&!B.over&&alive(foe).length<foesBefore){ let bt=null,bv=-Infinity; for(const t2 of alive(foe)){ if(t2.isSq) continue; for(const w2 of u.weapons){ if(!canFire(u,w2,t2)) continue; const e=expectedVs(u,w2,t2); const v=e.hull+e.shield*.3; if(v>bv){ bv=v; bt=t2; } } }
        if(bt){ let wi=-1; for(let i=0;i<u.weapons.length;i++){ if(canFire(u,u.weapons[i],bt)){ wi=i; break; } } if(wi>=0&&await treeExtraShot(u,wi,bt,{})) treeFx(u,'lastAccount','the last account is paid'); } } // Vex capstone 2
    }
    if(srS){ const ids=Object.keys(spatSet); if(ids.length){ (B.treePending=B.treePending||[]).push({k:'spatRounds',r:B.round,ids}); treeFx(treeFlagUnit(),'spatRounds','half the spits are held'); } } // Voice T2b
    { const ov=treeSkill('oneVoice'); if(ov&&side==='player'&&!B.treeOneVoiceUsed){ const e=treeChoice('enemy'); if(e){ B.treeOneVoiceUsed=1; B.tr.firstStopTarget=e.id; B.tr.firstStopDone=0;
        for(const u of alive('player').filter(x=>!x.isSq&&!x.dead&&inSync(x))){ if(B.over||e.dead) break; await treeVolleyAt(u,e); }
        B.tr.firstStopTarget=null; treeFx(treeFlagUnit(),'oneVoice','every synced ship fires as one'); } } } } finally{ if(B===b0) B.volleyMul=null; }
    { const ff=treeSkill('flawForever'); if(ff&&side==='player'&&B.tr&&B.tr.volleyHits){ let best=null,bn=0; for(const k in B.tr.volleyHits){ const n=B.tr.volleyHits[k]; if(n>bn){ bn=n; best=k; } }         if(best){ B.treeFlaw=best; treeFx(B.units.find(x=>x.id===best)||B.units.find(x=>x.pflag&&!x.dead)||null,'flawForever','the flaw is marked for the battle'); } } }
    { const mm=treeSkill('manyMouths'); if(mm&&side==='player'&&B.tr&&B.tr.volleyShips){ const ids=[]; for(const k in B.tr.volleyShips){ if(B.tr.volleyShips[k].length>=4){ ids.push(k); const t=B.units.find(x=>x.id===k); if(t) treeFx(t,'manyMouths','four mouths find one throat'); } } if(ids.length) (B.treePending=B.treePending||[]).push({k:'manyMouths',r:B.round,ids}); } } // Voice T3b
    { const bs=treeSkill('burnStays'); if(bs&&side==='player'&&B.tr&&B.tr.burnStays){ let any=false; for(const k in B.tr.burnStays) if(B.tr.burnStays[k]>0) any=true; if(any){ (B.treePending=B.treePending||[]).push({k:'burnStays',r:B.round,map:Object.assign({},B.tr.burnStays)}); treeFx(B.units.find(x=>x.pflag&&!x.dead)||alive('player')[0]||null,'burnStays','the burn will stay'); } } }
    { const nr=treeSkill('noonRepeat'); if(nr&&side==='player') (B.treePending=B.treePending||[]).push({k:'noonRepeat',r:B.round}); } } // the free volley leaves movement as it was
  if(c.id==='hunt'){ { const lc=treeSkill('longCopy'); if(lc&&side==='player'){ for(const u of caps('player')){ const g=treeRearApproach(u); if(g&&treeStepToward(u,g,2)) treeFx(u,'longCopy','the long copy strikes'); } } } // Ostrel capstone 2
    for(const u of alive(side)) for(const w of u.weapons) if(w.k==='torp'){ w.cdLeft=0; w.fired=false; }
    { const pn=treeSkill('preyName'); if(pn&&side==='player'){ const e=treeChoice('enemy'); B.treePrey=e?{id:e.id,r:B.round}:null; if(e) treeFx(B.units.find(x=>x.pflag&&!x.dead)||e,'preyName','the prey is entered by name'); } }
    { const st=treeSkill('salvoTwoHands'); if(st&&side==='player'){ const pl=alive('player').filter(x=>!x.isSq).slice().sort((a,b2)=>(a.hp/a.maxHp)-(b2.hp/b2.maxHp)||(a.id<b2.id?-1:1)); const half=pl.slice(0,Math.max(1,Math.ceil(pl.length/2))); for(const u of half) u.treeHuntNext=1; (B.treePending=B.treePending||[]).push({k:'salvoTwoHands',r:B.round,pow:cmdPow('hunt',tier),ids:half.map(u=>u.id)}); treeFx(B.units.find(x=>x.pflag&&!x.dead)||half[0]||null,'salvoTwoHands','half the salvo is held for next round'); } }
    { const ts=treeSkill('twoSalvos'); if(ts&&side==='player'){ (B.treePending=B.treePending||[]).push({k:'twoSalvos',r:B.round,pow:cmdPow('hunt',tier)}); treeFx(B.units.find(x=>x.pflag&&!x.dead)||alive('player')[0]||null,'twoSalvos','the next salvo keeps its bonus'); } }
    { const np=treeSkill('namedPrey'); if(np&&side==='player'){ const e=treeChoice('enemy'); if(e){ B.treeNamedPrey={id:e.id,r:B.round}; for(const S of (B.torps||[])) if(S.side==='player'){ S.tid=e.id; S.aim={q:e.q,r:e.r}; } treeFx(e,'namedPrey','the named prey falls'); } } }
    { const dk=treeSkill('darkKnives'); if(dk&&side==='player'){ const pow=cmdPow('hunt',tier); for(const u of caps('player')) u.treeHuntRearNext={r:B.round+1,n:pow}; } } // Sable capstone 1
    { const cfd=treeSkill('cutFeeds'); if(cfd&&side==='player'){ for(const u of caps('player')){ const g=treeRearApproach(u); if(g&&treeStepToward(u,g,2)) treeFx(u,'cutFeeds','the cut feeds the pack'); } } } // Sable capstone 2
    { const ft=treeSkill('filedTriplicate'); if(ft&&side==='player'){ const e=treeChoice('enemy'); B.treeFiled=e?{id:e.id}:null; if(e) treeFx(treeFlagUnit()||e,'filedTriplicate','the target is filed in triplicate'); } } // Vorn T1a
    { const oo=treeSkill('oneOrder'); if(oo&&side==='player'){ let any=false; for(const u of caps('player')){ let bw=-1,bt=null,bv=-1;
        for(let i=0;i<u.weapons.length;i++){ const w=u.weapons[i]; if(w.k==='flak'||w.off||w.cdLeft) continue; for(const t2 of alive('enemy')){ if(t2.isSq) continue; if(!canFire(u,w,t2)) continue; const e=expectedVs(u,w,t2), v=e.hull+e.shield*.3; if(v>bv){ bv=v; bw=i; bt=t2; } } }
        if(bw>=0&&bt&&await treeExtraShot(u,bw,bt,{half:true})) any=true; }
      if(any) treeFx(treeFlagUnit(),'oneOrder','every gun answers'); } } } // Vorn capstone 2
  if(c.id==='iron'){ const rl=treeSkill('rechargeLit'); if(rl&&side==='player'&&!(B.treePending||[]).some(p=>p.k==='rechargeLit'&&p.r===B.round)) (B.treePending=B.treePending||[]).push({k:'rechargeLit',r:B.round}); for(const u of alive(side)) if(u.shMax) u.sh=u.sh.map(()=>u.shMax);
    { if(side==='player'){ for(const u of caps('player')){
        const ov=treeSkill('overflow'); if(ov&&u.shMax>0&&!u.treeOverflowUsed&&u.sh.every(v=>v>=u.shMax)){ u.treeOverflowUsed=1; u.evBuff=Math.min(45,(u.evBuff||0)+ov.n); treeFx(u,'overflow','the surplus becomes evasion'); }
        const cs=treeSkill('columnStraight'); if(cs&&treeInColumn(u)){ if(treeShieldOver(u,cs.n)>0) treeFx(u,'columnStraight','the column adds shield'); }
        const fs=treeSkill('flagshipStandard'); if(fs&&treeInFlagLine(u)){ if(treeShieldOver(u,fs.n)>0) treeFx(u,'flagshipStandard','the flagship holds the line'); }
        if(treeSkill('rotation')) treeRotSwap(u); } } } // Hegemony column, overflow and flagship line
    { const ps=treeSkill('platesShadow'); if(ps&&side==='player'){ const who=treeChoice('ship'); B.treePlate=who?{id:who.id,r:B.round}:null; if(who) treeFx(who,'platesShadow','the wall stacks on '+who.name); } }
    { const rf=treeSkill('restoredFleet'); if(rf&&side==='player'){ for(const u of caps('player')) if(u.treeRepairedRound===B.round){ u.treeWallCarry={r:B.round+1,pow:cmdPow('iron',tier)}; treeFx(u,'restoredFleet','the restored hull keeps the wall'); } } }
    { const ls=treeSkill('layersShift'); if(ls&&side==='player') (B.treePending=B.treePending||[]).push({k:'layersShift',r:B.round}); }
    { const hc=treeSkill('holdCounted'); if(hc&&side==='player') (B.treePending=B.treePending||[]).push({k:'holdCounted',r:B.round,pow:cmdPow('iron',tier)}); }
    { const os=treeSkill('oathStillness'); if(os&&side==='player') (B.treePending=B.treePending||[]).push({k:'oathStillness',r:B.round}); }
    { const it=treeSkill('ironTestament'); if(it&&side==='player') (B.treePending=B.treePending||[]).push({k:'ironTestament',r:B.round,pow:cmdPow('iron',tier)}); }
    if(side==='player'){ for(const u of caps('player')) u.treeWardFacing=u.facing; }
    { const ws=treeSkill('weakSide'); if(ws&&side==='player'){ const cand=alive('player').filter(x=>!x.isSq&&!x.dead).sort((a,b2)=>{ const sa=(a.sh||[]).reduce((n,v)=>n+v,0), sb=(b2.sh||[]).reduce((n,v)=>n+v,0); return sa-sb||(a.id<b2.id?-1:1); })[0]; if(cand){ B.treeWeakShip={id:cand.id,r:B.round}; treeFx(cand,'weakSide','the weak side takes the light'); } } } // Brin T1a
    { const pf=treeSkill('prismsFace'); if(pf&&side==='player'){ for(const u of caps('player')){ if(u.dead) continue; const foes=alive('enemy').filter(x=>!x.isSq&&!x.dead); if(!foes.length) continue; let near=null,nd=1e9; for(const f of foes){ const d=hdist(u,f); if(d<nd){ nd=d; near=f; } } const want=near?treeFacingTo(u,near):null; if(want!=null&&u.facing===want&&treeShieldOver(u,pf.n)>0) treeFx(u,'prismsFace','the prisms face the fire'); } } } // Brin T1b
    { const fl=treeSkill('facetLit'); if(fl&&side==='player'){ for(const u of caps('player')){ if(!(u.shMax>0)) continue; const room=Math.max(0,Math.round(u.maxHp*(FX_CAPS.treeTempHp||.2))-(u.tempHp||0)); const add=Math.max(0,Math.min(Math.round(u.shMax*fl.n),room)); if(add>0){ u.tempHp=(u.tempHp||0)+add; treeFx(u,'facetLit','the facets are lit'); } } } } // Brin capstone 2
    { const sh=treeSkill('screensShift'); if(sh&&side==='player'){ const up=treeChoice('ship'); const down=alive('player').filter(x=>!x.isSq&&!x.dead&&(!up||x.id!==up.id)).sort((a,b2)=>(b2.hp/b2.maxHp)-(a.hp/a.maxHp)||(a.id<b2.id?-1:1))[0]; /* the healthiest other ship gives up the 20 points */ if(up){ B.treeShiftUp={id:up.id,r:B.round}; treeFx(up,'screensShift','the screens shift'); } if(down) B.treeShiftDown={id:down.id,r:B.round}; } } // Thale T1b
    { const we=treeSkill('wallEarly'); if(we&&side==='player'&&alive('player').every(x=>x.isSq||((x.hexMoved||0)===0&&!x.treeRoundFired))){ B.treeWallEarly=B.round; treeFx(treeFlagUnit(),'wallEarly','the wall is declared early'); } } // Thale T2a
    { const wm=treeSkill('wallMoves'); if(wm&&side==='player'){ for(const u of caps('player')){ if(u.dead) continue; const add=treeAddVal(u,'speed',wm.n); u.mp=(u.mp||0)+add; u.postMp=(u.postMp||0)+add; } treeFx(treeFlagUnit(),'wallMoves','the wall moves'); } } // Thale capstone 2
  }
  if(c.id==='restore'){
    let rp=cmdPow('restore',tier); const p=(side==='player');
    const triage=p?treeSkill('copiesTriage'):null, iterFire=p?treeSkill('iterationFire'):null, growth=p?treeSkill('growthWound'):null;
    const arch=p?treeSkill('archiveFirst'):null, tideE=p?treeSkill('tideEarly'):null;
    if(p&&arch&&alive('player').every(x=>x.isSq||((x.hexMoved||0)===0&&!x.treeRoundFired))){ rp+=arch.n; treeFx(treeFlagUnit(),'archiveFirst','the archive answers first'); } // Nadir T2b
    if(p&&tideE&&alive('player').every(x=>x.isSq||x.hp>=(x.treeHpStart!=null?x.treeHpStart:x.hp))){ rp+=tideE.n; treeFx(treeFlagUnit(),'tideEarly','the tide comes early'); } // Mending T2a
    const ninth=p?treeSkill('restoreNinth'):null, beyond=p?treeSkill('restoredBeyond'):null, contribute=p?treeSkill('copiesContribute'):null;
    const tenth=p?treeSkill('tenthFrame'):null, earlier=p?treeSkill('earlierCopy'):null;
    const gh=(p&&treeSkill('growHurts'))?treeChoice('ship'):null;
    const sk=(p&&treeSkill('skinThick'))?treeChoice('ship'):null;
    const fk=p?treeSkill('fleshKnit'):null, te=p?treeSkill('tideEnd'):null, tb=p?treeSkill('tornBack'):null;
    const weld=(p&&treeSkill('weldMatters'))?treeChoice('ship'):null, pgun=p?treeSkill('patchGuns'):null;
    const front=(p&&treeSkill('scrapFront'))?treeChoice('other'):null, wfight=p?treeSkill('weldedFight'):null;
    const bolted=p?treeSkill('doubleBolted'):null, bites=p?treeSkill('packBites'):null, whole=p?treeSkill('weldedWhole'):null;
    const frontFlag=front?treeFlagUnit():null, frontShare=(front&&frontFlag&&front!==frontFlag)?Math.round(frontFlag.maxHp*rp*2):0;
    const flesh=[]; const gwList=[];
    const flag=contribute?treeFlagUnit():null;
    let chosen=(ninth||tenth||earlier||contribute)?treeChoice('ship'):null;
    if(contribute&&chosen===flag) chosen=alive('player').filter(x=>!x.isSq&&x!==flag).sort((a,b)=>(a.hp/a.maxHp)-(b.hp/b.maxHp)||(a.id<b.id?-1:1))[0]||flag;
    const flagShare=(contribute&&flag&&chosen&&chosen!==flag)?Math.round(flag.maxHp*rp):0;
    let chosenBroken=null; if(tenth&&chosen&&chosen.sec){ for(const k of Object.keys(chosen.sec)) if(chosen.sec[k].broken){ chosenBroken=k; break; } }
    let firedNinth=0,firedTenth=0,firedEarlier=0,firedContrib=0;
    for(const u of alive(side).filter(x=>!x.isSq)){
      let amt=rp; if(p&&ninth) amt=(u===chosen?rp:rp/2); if(p&&tenth&&u===chosen) amt=rp*3;
      let heal=Math.round(u.maxHp*amt);
      if(contribute&&u===flag) heal=0;
      if(contribute&&u===chosen&&u!==flag) heal+=flagShare;
      if(front&&u===frontFlag) heal=0;
      if(front&&u===front&&u!==frontFlag) heal+=frontShare;
      const hp0=u.hp;
      const secFullBefore=new Set(); if(u.sec) for(const k of Object.keys(u.sec)){ const s=u.sec[k]; if(!s.broken&&s.hp>=s.max) secFullBefore.add(k); }
      const skin=!!(p&&sk&&u===sk);
      if(skin){ const skn=treeSkill('skinThick').n; const cap=FX_CAPS.treeTempHp||.2; const add=Math.max(0,Math.min(Math.round(u.maxHp*skn),Math.round(u.maxHp*cap)-(u.tempHp||0))); u.tempHp=(u.tempHp||0)+add; if(add>0) treeFx(u,'skinThick','the regrowth is grown thick'); if(typeof fxText==='function') fxText(u,'+'+add+' grown hull','#8ff0a0',-20); }
      else { u.hp=Math.min(u.maxHp,u.hp+heal); }
      const secFixed=[];
      if(u.sec&&!skin&&!(front&&u===frontFlag)){
        const torn=new Set();
        if(tb) for(const k of Object.keys(u.sec)){ const s=u.sec[k]; if(s.broken){ repairSection(u,k,1); s.treeLock=1; torn.add(k); treeFx(u,'tornBack','the torn section grows back'); } }
        if(whole) for(const k of Object.keys(u.sec)){ const s=u.sec[k]; if(s.broken){ repairSection(u,k,1); torn.add(k); treeFx(u,'weldedWhole','the hull is welded whole'); break; } } // Vesh capstone 1
        if(weld&&u===weld){ let best=null,bv=2; for(const k of Object.keys(u.sec)){ const s=u.sec[k]; if(s.broken) continue; const rr=s.hp/s.max; if(rr<bv){ bv=rr; best=k; } } if(best){ repairSection(u,best,amt); secFixed.push(best); treeFx(u,'weldMatters','the weld goes where it matters'); } } // Vesh T1a
        else if(gh&&u===gh){ let best=null,bv=2; for(const k of Object.keys(u.sec)){ const s=u.sec[k]; if(s.broken) continue; const rr=s.hp/s.max; if(rr<bv){ bv=rr; best=k; } } if(best){ repairSection(u,best,amt); treeFx(u,'growHurts','the regrowth goes where it hurts'); } }
        else { let fixed=0; for(const k of Object.keys(u.sec)){ if(torn.has(k)) continue; const s=u.sec[k], h0=s.hp; repairSection(u,k,amt); if(s.hp>h0){ fixed++; secFixed.push(k); } }
          if(fixed&&typeof fxText==='function') fxText(u,fixed>1?fixed+' sections restored':'Section restored','#8ff0a0',-34); }
      }
      if(p&&earlier&&u===chosen){ for(const k of Object.keys(u.sec||{})) repairSection(u,k,rp); u.hp=Math.min(u.maxHp,u.hp+Math.round(u.maxHp*rp)); if(!firedEarlier){ firedEarlier=1; treeFx(u,'earlierCopy','the earlier copy returns'); } }
      if(tenth&&u===chosen&&chosenBroken&&u.sec&&u.sec[chosenBroken]){ const s=u.sec[chosenBroken]; s.broken=false; s.hp=s.max; }
      if(u.hp>hp0||secFixed.length) treeMarkRepair(u);
      if(p&&triage&&u.sec){ let toFull=false; for(const k of Object.keys(u.sec)){ const s=u.sec[k]; if(!s.broken&&s.hp>=s.max&&!secFullBefore.has(k)){ toFull=true; break; } } if(toFull&&(u.st.fire||u.st.acid)){ u.st.fire=0; u.st.acid=0; treeFx(u,'copiesTriage','the copies triage the damage'); } } // Nadir T1b
      if(p&&iterFire&&(u.hp>hp0||secFixed.length)){ u.treeIterFire=treeAddVal(u,'dmgPct',iterFire.n); treeFx(u,'iterationFire','the rebuild does not wait'); } // Nadir T2a
      if(p&&growth&&secFixed.length){ for(const k of secFixed) gwList.push({id:u.id,sec:k,amt}); } // Mending T2b: the same amount will heal again
      if(typeof fxText==='function'&&!skin) fxText(u,'+'+Math.round(u.maxHp*rp)+' hull','#8ff0a0',-20);
      if(p&&beyond&&secFixed.length){ if(!u.treeRebuilt) u.treeRebuilt={}; for(const k of secFixed){ if(u.treeRebuilt[k]) continue; u.treeRebuilt[k]=1; const s=u.sec[k], add=Math.round(s.max*beyond.n); s.max=s.max+add; s.hp=Math.min(s.max,s.hp+add); treeFx(u,'restoredBeyond','the section is rebuilt stronger'); } }
      if(p&&ninth&&u===chosen&&!firedNinth){ firedNinth=1; treeFx(u,'restoreNinth','the ninth frame is restored'); }
      if(p&&tenth&&u===chosen&&!firedTenth){ firedTenth=1; treeFx(u,'tenthFrame','the tenth frame is restored'); }
      if(p&&contribute&&u===chosen&&chosen!==flag&&!firedContrib){ firedContrib=1; treeFx(u,'copiesContribute','the flagship share is divided'); }
      if(p&&pgun&&secFixed.some(k=>k==='prow'||k==='mid')){ u.treeAimGuns=treeAddVal(u,'aim',pgun.n); treeFx(u,'patchGuns','the patched guns find the mark'); } // Vesh T1b
      if(p&&bolted&&secFixed.length){ if(!u.treeBolted) u.treeBolted={}; for(const k of secFixed){ if(u.treeBolted[k]) continue; u.treeBolted[k]=1; const s=u.sec[k], add=Math.round(s.max*bolted.n); s.max=s.max+add; s.hp=Math.min(s.max,s.hp+add); treeFx(u,'doubleBolted','the plate is double-bolted'); } } // Vesh T3a
      if(p&&bites&&hp0<u.maxHp*.5&&u.hp>=u.maxHp*.5){ u.treeDmgCarry={r:B.round+1,n:bites.n}; treeFx(u,'packBites','the pack bites on'); } // Vesh T3b
      if(p&&front&&u===front&&u!==frontFlag){ treeFx(u,'scrapFront','the scrap goes to the front'); } // Vesh T2a
      if(p&&wfight&&(u.hp>hp0||secFixed.length)){ let bw=-1,bt2=null,bv=-1; for(let i=0;i<u.weapons.length;i++){ const w=u.weapons[i]; if(w.k==='flak'||w.off) continue; for(const t2 of alive(foe)){ if(!canFire(u,w,t2)) continue; const e=expectedVs(u,w,t2), v=e.hull+e.shield*.3; if(v>bv){ bv=v; bw=i; bt2=t2; } } } if(bw>=0&&bt2&&await treeExtraShot(u,bw,bt2,{half:true})) treeFx(u,'weldedFight','the weld fires while it is hot'); } // Vesh T2b
      if(p&&fk&&u.hp>u.maxHp*.75) flesh.push(u.id);
    }
    if(p&&fk&&flesh.length){ (B.treePending=B.treePending||[]).push({k:'fleshKnit',r:B.round,ids:flesh}); treeFx(B.units.find(x=>x.pflag&&!x.dead)||alive('player')[0]||null,'fleshKnit','the new flesh is angry'); } // Mending T3a
    if(p&&growth&&gwList.length){ (B.treePending=B.treePending||[]).push({k:'growthWound',r:B.round,list:gwList}); treeFx(treeFlagUnit(),'growthWound','the wound will hold its growth'); } // Mending T2b
    if(p&&te){ (B.treePending=B.treePending||[]).push({k:'tideEnd',r:B.round,pow:rp}); treeFx(B.units.find(x=>x.pflag&&!x.dead)||alive('player')[0]||null,'tideEnd','the tide will come again'); } // Mending capstone 1
  }
  if(c.id==='surge'){ for(const u of alive(side).filter(x=>!x.isSq)){ u.mp=(u.mp||0)+cmdPow('surge',tier); u.turnsLeft=(u.turnsLeft||0)+(tier>=2?2:1); }
    if(side==='player'){
      { const rp=treeSkill('razorPrey'); if(rp){ const e=treeChoice('enemy'); B.treeRazorPrey=e?{id:e.id,r:B.round}:null; if(e) treeFx(B.units.find(x=>x.pflag&&!x.dead)||e,'razorPrey','the prey is named'); } } // Razormaw T2a
      { const pm=treeSkill('preyEveryMouth'); if(pm){ const e=treeChoice('enemy'); B.treeRazorPrey=e?{id:e.id,r:B.round}:null; for(const u of alive('player')) if(!u.isSq) u.turnsLeft=(u.turnsLeft||0)+1; treeFx(B.units.find(x=>x.pflag&&!x.dead)||alive('player')[0]||null,'preyEveryMouth','every mouth turns to the prey'); } } // Razormaw capstone 2
      { const bc=treeSkill('burnCarry'); if(bc){ (B.treePending=B.treePending||[]).push({k:'burnCarry',r:B.round,pow:cmdPow('surge',tier),turns:tier>=2?2:1}); treeFx(treeFlagUnit(),'burnCarry','the burn will carry'); } } // Grax capstone 1
      { const wr=treeSkill('warlordRun'); if(wr){ const pg=treeFlagUnit(); if(pg){ pg.treeWarlord=1; treeFx(pg,'warlordRun','the warlord runs again'); } } } } } // Grax capstone 2
  if(c.id==='scramble'){ const ct=treeSkill('castTwice')?treeChoice('carrier'):null, aloft=treeSkill('lensAloft');
    const nine=(side==='player')?treeSkill('nineThroats'):null; const nineT=nine?treeChoice('enemy'):null;
    if(nine&&nineT){ B.tr.swarmHunger={r:B.round,id:nineT.id}; treeFx(nineT,'nineThroats','nine throats choose one hunger'); } // Matriarch capstone 1
    const fw=(side==='player'&&treeSkill('firstWave'))?treeChoice('carrier'):null;
    const esc=(side==='player'&&treeSkill('escortName'))?treeChoice('friend'):null;
    const gen=(side==='player')?treeSkill('generation'):null;
    const resv=(side==='player')?treeSkill('wingReserve'):null; let resvDone=0, escDone=0;
    const brood=(side==='player'&&treeSkill('chooseBrood'))?treeChoice('brood'):null;
    const spore=(side==='player')?treeSkill('sporeTide'):null;
    const every=(side==='player')?treeSkill('everyThroat'):null;
    const patched=(side==='player')?treeSkill('patchedWing'):null, patchedPick=patched?treeChoice('carrier'):null;
    const hulk=(side==='player')?treeSkill('hulkMore'):null, hulkPick=hulk?treeChoice('largest'):null;
    const wreck=(side==='player')?treeSkill('wreckLine'):null, yard=(side==='player')?treeSkill('wholeYard'):null;
    const priv=(side==='player')?treeSkill('privateWing'):null, privPick=priv?treeChoice('carrier'):null;
    const scrap=(side==='player')?treeSkill('swarmScrap'):null;
    const cru=(side==='player'&&treeSkill('cruisersCarriers'))?treeChoice('largest'):null;
    const launchOrd=(side==='player')?treeSkill('launchOrder'):null;
    const secondW=(side==='player')?treeSkill('secondWave'):null;
    const fullG=(side==='player')?treeSkill('fullGroup'):null;
    const escortScr=(side==='player')?treeSkill('escorts'):null;
    const oneTgt=(side==='player')?treeSkill('oneTarget'):null;
    const stand=(side==='player')?treeSkill('standingGroup'):null;
    const filedT=(fullG||oneTgt)?treeChoice('enemy'):null;
    const ships=alive(side).filter(x=>x.ab==='launch');
    const allLaunch=!!(fullG&&ships.length&&ships.every(u=>treeLaunchHexes(u,2).length>0));
    const heldShips=[], patrolMarked={}; let launchFirst=0;
    if(escortScr){ B.tr.escortScreen=B.round; treeFx(treeFlagUnit(),'escorts','the wings form a screen'); }
    { const fs=treeSkill('flakSkip'); if(fs&&side==='player'){ const e=treeChoice('enemy'); B.treeFlakSkip=e?e.id:null; if(e&&e.weapons&&e.weapons.some(w=>w.k==='flak')) treeFx(e,'flakSkip','point defence cannot see the wings'); } }
    for(const u of ships){
      if(brood&&u.id!==brood.id) continue; // Matriarch T1a: the other broods release none extra
      let count=(tier>=2?2:1);
      if(brood&&u.id===brood.id){ count+=1; treeFx(u,'chooseBrood','the chosen brood swells'); }
      if(aloft&&side==='player'&&(u.hexMoved||0)===0){ count+=1; treeFx(u,'lensAloft','one more wing aloft'); }
      if(gen&&(u.hexMoved||0)===0){ count+=1; treeFx(u,'generation','one more generation aloft'); }
      if(yard&&(squadronsOf(u).length+count)>=(u.hangar||0)){ count+=1; treeFx(u,'wholeYard','the whole yard flies'); } // Mott T3a
      if(allLaunch){ count+=1; treeFx(u,'fullGroup','the full group assembles'); } // Reyes T3a
      if(secondW){ heldShips.push({id:u.id,count}); treeFx(u,'secondWave','the extra wings are held for next round'); continue; }
      for(let k=0;k<count;k++){ let hs=(spore?treeLaunchHexes(u,spore.n||2):(allLaunch?treeLaunchHexes(u,2):launchHexes(u))); if(!hs.length) break; const fs=alive(foe); hs.sort((a,b2)=>Math.min(...fs.map(f=>hdist(a,f)))-Math.min(...fs.map(f=>hdist(b2,f))));
        if(resv&&!resvDone&&k===count-1){ (B.treePending=B.treePending||[]).push({k:'wingReserve',r:B.round,carrier:u.id}); resvDone=1; treeFx(u,'wingReserve','one wing waits in reserve'); continue; }
        const sq=makeWing(u,hs[0],wingKind(u)); sq.extra=1;
        if(nine&&nineT) sq.wingOrder={kind:'strike',id:nineT.id}; // Matriarch capstone 1: every extra swarm hunts the one hunger
        if((fullG||oneTgt)&&filedT){ sq.wingOrder={kind:'strike',id:filedT.id}; treeFx(sq,fullG?'fullGroup':'oneTarget','the wings file on '+filedT.name); }
        if(oneTgt&&filedT) B.tr.wingFiled={r:B.round,id:filedT.id};
        if(stand&&!patrolMarked[u.id]){ sq.treePatrol=1; patrolMarked[u.id]=1; treeFx(sq,'standingGroup','the wing stays on patrol'); }
        if(launchOrd&&!launchFirst){ launchFirst=1; sq.treeBonus=(sq.treeBonus||0)+launchOrd.n; treeFx(sq,'launchOrder','the first wing strikes first'); }
        if(spore) treeFx(u,'sporeTide','the spores ride the tide'); // Matriarch T1b
        if(every&&(u.hexMoved||0)===0){ sq.treeBonus=every.n; treeFx(u,'everyThroat','the throat opens wide'); } // Matriarch T3a
        if(fw&&u.id===fw.id){ sq.treeBonus=treeSkill('firstWave').n; treeFx(u,'firstWave','the first wave owes the second'); }
        if(wreck&&(u.hexMoved||0)===0){ sq.treeBonus=(sq.treeBonus||0)+wreck.n; treeFx(u,'wreckLine','the wings come off the wreck line'); } // Mott T2b
        if(patchedPick&&u.id===patchedPick.id){ sq.treeBonus=(sq.treeBonus||0)+treeAddVal(sq,'sqPct',patched.n); sq.treeRemove=1; treeFx(u,'patchedWing','the patched wing flies'); } // Mott T1a
        if(privPick&&u.id===privPick.id){ sq.treePrivate=1; treeFx(u,'privateWing','the private wing flies'); } // Mott capstone 2
        if(esc&&!escDone){ sq.escort=esc.id; sq.wingOrder={kind:'guard',id:esc.id}; escDone=1; treeFx(sq,'escortName','the escort is sworn to '+esc.name); }
        if(ct&&u.id===ct.id){ sq.treeTwice=1; const e=treeChoice('enemy'); if(e) sq.treeTgt=e.id; } try{ if(typeof fxFlash==='function') fxFlash(hs[0],'#f0b35a'); }catch(e){} } }
    if(hulkPick&&side==='player'){ const hs=launchHexes(hulkPick); if(hs.length){ const fs=alive(foe); hs.sort((a,b2)=>Math.min(...fs.map(f=>hdist(a,f)))-Math.min(...fs.map(f=>hdist(b2,f)))); const sq=makeWing(hulkPick,hs[0],wingKind(hulkPick)); sq.extra=1; treeFx(hulkPick,'hulkMore','a wing comes off the spare racks'); } } // Mott T1b
    if(cru&&side==='player'){ const hs=launchHexes(cru); if(hs.length){ const fs=alive(foe); hs.sort((a,b2)=>Math.min(...fs.map(f=>hdist(a,f)))-Math.min(...fs.map(f=>hdist(b2,f)))); const sq=makeWing(cru,hs[0],wingKind(cru)); sq.extra=1;
      if((fullG||oneTgt)&&filedT){ sq.wingOrder={kind:'strike',id:filedT.id}; }
      if(stand){ sq.treePatrol=1; patrolMarked[cru.id]=1; }
      if(launchOrd&&!launchFirst){ launchFirst=1; sq.treeBonus=(sq.treeBonus||0)+launchOrd.n; }
      treeFx(cru,'cruisersCarriers','a hull without a hangar launches a wing'); } } // Reyes T1a
    if(secondW&&side==='player'&&heldShips.length){ (B.treePending=B.treePending||[]).push({k:'secondWave',r:B.round,ships:heldShips}); treeFx(treeFlagUnit(),'secondWave','the extra wings are held for next round'); }
    for(const s of alive(side).filter(x=>x.isSq)){ s.activated=false; s.mp=s.speed; s.weapons.forEach(w=>{ w.fired=false; w.cdLeft=0; }); } if(side==='player') B.tr.strikeAgain=B.round; await swarmPhase(side); if(side==='player') B.tr.strikeAgain=0;
    if(side==='player'){ for(const sq of alive('player').filter(x=>x.isSq&&x.treeRemove)){ sq.dead=true; sq.hp=0; treeFx(sq,'patchedWing','the patched wing comes apart'); } } // Mott T1a: removed after its strike
    if(side==='player'&&treeSkill('forgeAhead')){ const list=[],seen={}; for(const sq of alive('player').filter(x=>x.isSq&&x.extra&&x.treeLastTgt)){ if(seen[sq.parent]) continue; seen[sq.parent]=1; const tgt=B.units.find(x=>x.id===sq.treeLastTgt&&!x.dead); if(tgt) list.push({carrier:sq.parent,tid:sq.treeLastTgt}); }
      if(list.length){ (B.treePending=B.treePending||[]).push({k:'forgeAhead',r:B.round,list}); treeFx(treeFlagUnit(),'forgeAhead','the forge will cast ahead'); } } // Tamsa capstone 2
    if(scrap&&side==='player'){ const ids=alive(side).filter(x=>x.ab==='launch'&&!x.isSq).map(x=>x.id); if(ids.length){ (B.treePending=B.treePending||[]).push({k:'swarmScrap',r:B.round,ids}); treeFx(treeFlagUnit(),'swarmScrap','the swarm launches again after the last activation'); } } // Mott capstone 1: the second launch waits for the end of the player turn
    if(ct&&side==='player'){ for(const sq of alive(side).filter(x=>x.isSq&&x.treeTwice)){ const t=B.units.find(x=>x.id===sq.treeTgt); if(!t||t.dead||(t.hexMoved||0)!==0) continue; let fired=false; for(const w of sq.weapons) w.fired=false; for(let i=0;i<sq.weapons.length;i++){ if(t.dead||B.over) break; if(canFire(sq,sq.weapons[i],t)){ await fireWeapon(sq,i,t,{half:true}); fired=true; } } if(fired) treeFx(sq,'castTwice','the recorded strike repeats at half damage'); } } }
  if(B===bStart) checkEnd(); return true; }
// enemy flagships carry a Command of their own: announced a round ahead, fired once, at power 2
const BOSS_CMD={hegemony:{id:'barrage',n:'Registry broadside'},corsair:{id:'surge',n:'Burn and board'},chorus:{id:'restore',n:'Brood regrowth'},ithar:{id:'iron',n:'Prism ward'},deathless:{id:'restore',n:'Restore from the Archive'},voidsworn:{id:'hunt',n:'Crusader\u2019s wrath'}};
function bossCmdText(c,fac){ return cmdDesc(c,1,fac).replace(/your ships/g,'its ships').replace(/against you/g,'against them').replace(/Every ship/g,'Every enemy ship'); }
function bossCmdTick(){ if(!B||B.over||B.cmdEUsed) return; const boss=B.units.find(u=>u.side==='enemy'&&u.t&&u.t.boss&&!u.dead); if(!boss) return; const c=BOSS_CMD[boss.fac]; if(!c) return;
  if(B.cmdENext==null){ if(B.round>=2||boss.hp<boss.maxHp*.6){ B.cmdENext=B.round+1; log(`${boss.name} is preparing ${c.n}. ${bossCmdText(c,boss.fac)} It strikes next round.`,'e'); try{ if(typeof fxText==='function') fxText(boss,'Preparing: '+c.n,'#ff8a6a',-56); }catch(e){} try{ if(typeof toast==='function'&&typeof document!=='undefined') toast(`${boss.name} is preparing ${c.n}. It strikes next round.`); if(typeof banner==='function'&&typeof document!=='undefined') setTimeout(()=>{ try{ banner(`${c.n} next round`,'#ff8a6a'); }catch(e){} },900); }catch(e){} /* v45: the boss Command gets a banner too */ } return; } }
async function bossCmdFire(){ if(!B||B.over||B.cmdEUsed||B.cmdENext==null||B.round<B.cmdENext) return; const boss=B.units.find(u=>u.side==='enemy'&&u.t&&u.t.boss&&!u.dead); if(!boss){ B.cmdEUsed=true; return; } const c=BOSS_CMD[boss.fac];
  B.cmdEUsed=true; B.cmdE={id:c.id,side:'enemy',round:B.round,tier:1}; log(`${boss.name}: ${c.n}!`,'e'); await runCommand('enemy',c,1); }
// a ship that isn't part of the current battle (a hung action from an earlier fight) may never act
function inThisBattle(u){ return !!(B&&u&&B.units.includes(u)); }
const SQ_LEASH=8; // hexes a squadron may range from a living carrier
function sqRole(s){ return s.t.sq==='fighter'?'fighter':'bomber'; }
// bombers strike ships; fighters hunt enemy craft and only strafe ships when no enemy craft are flying
function sqWants(s,t){ if(t.dead||t.side===s.side) return false; if(sqRole(s)==='bomber') return !t.isSq; return alive(t.side).some(x=>x.isSq)?t.isSq:true; }
function sqValue(t,e,s){ let v=e.hull+e.shield*.3; if(e.hull>=t.hp) v+=25; if(t.isSq&&sqRole(t)==='bomber') v*=1.5; if(s&&s.side==='enemy'&&t===B.aiFocus&&aiVet()) v*=1.3; if(s&&(s.side==='player'||aiVet())&&sqObjNear(t)) v+=6; return v+(1-t.hp/t.maxHp)*10; }
// v53-D: wings lean on the fleet focus (as evalOffenseVet does) and on targets close to the station or a transport in defend and intercept
function sqObjNear(t){ const o=B&&B.obj; if(!o) return false; if(o.type==='defend'&&o.hex) return hdist(t,o.hex)<=3; if(o.type==='intercept'){ for(const x of B.units) if(x.transport&&!x.dead&&hdist(x,t)<=3) return true; } return false; }
// a target is "in reach" only if some hex the squadron can actually fly to this round lets a weapon legally hit it (same range, arc and sight rules as manual fire)
// wing orders (player only): 'strike' a chosen enemy, or 'guard' a friendly ship and hit whatever comes near it
function sqOrder(s){ const o=s.wingOrder; if(!o) return null; const t=B.units.find(x=>x.id===o.id); if(!t||t.dead||(o.kind==='strike'?t.side===s.side:t.side!==s.side)){ s.wingOrder=null; return null; } return {kind:o.kind,t}; }
function sqPlan(s){ const ord=sqOrder(s); let foes=alive(s.side==='player'?'enemy':'player').filter(t=>sqWants(s,t)||(ord&&ord.kind==='strike'&&ord.t===t)); if(!foes.length) return null;
  const carrier=B.units.find(x=>x.id===s.parent&&!x.dead), ready=s.weapons.filter(weaponReady), {states}=computeReach(s), here={q:s.q,r:s.r,f:s.facing,cost:0,stay:true};
  const stc=ord?null:wingStance(s), guard=ord&&ord.kind==='guard'?ord.t:stc==='screen'&&carrier?carrier:null; // B4: a screening wing guards its carrier (an explicit order still wins)
  const lim=SQ_LEASH+(ord&&ord.kind==='strike'?2:0)+(stc==='hunt'?WING_HUNT_LEASH:0), leashOK=v=>guard?hdist(v,guard)<=(stc==='screen'?WING_SCREEN_R+1:3):(!carrier||hdist(v,carrier)<=lim); let best=null;
  for(const st of [here,...states]){ const v=stateView(s,st); if(!leashOK(v)) continue;
    for(const t of foes) for(const w of ready){ if(!inReach(v,w,t)) continue; let val=sqValue(t,expectedVs(v,w,t),s)-(st.cost||0)*.01;
      if(ord&&ord.kind==='strike'&&ord.t===t) val=val*3+60; if(guard&&hdist(t,guard)<=3) val=val*2+20;
      if(stc==='screen'&&t.isSq) val*=2; if(stc==='hunt'&&!t.isSq&&t.hp<t.maxHp/2) val*=1.6;
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
async function swarmPhase(side){ const b0=B; for(const s of alive(side).filter(x=>x.isSq&&!x.activated)){ if(B!==b0||B.over) return; const t0=(typeof performance!=='undefined'?performance.now():0); if(await stallGuard(sqAct(s),15000,'squadron',{name:s.name,sq:s.t.sq,q:s.q,r:s.r})==='stall'&&B===b0) log(`${s.t&&s.t.n||s.name}: orders lost in interference.`,'x'); s.activated=true; if(typeof console!=='undefined'&&console.debug) console.debug('[swarm] '+side+' '+s.id+' '+Math.round((typeof performance!=='undefined'?performance.now():0)-t0)+'ms'); } }
function makeWing(u,h,kind){ const fx=u.side==='player'?sumFx(fleetFxList()):{};
  const sq=makeUnit(u.side, kind, {parent:u.id, fac:u.fac, sqPct:(u.fx.sqPct||0), sqHp:fx.sqHp||0, scale:u.side==='enemy'?1+.1*(B.sector-1):1});
  { const pk=wingPerks(u); if(pk.includes('aces')) sq.aim+=10; if(pk.includes('jinkers')) sq.ev+=8; if(pk.includes('armored')){ sq.maxHp=Math.round(sq.maxHp*1.25); sq.hp=sq.maxHp; } } // B4 wing veteran perks
  sq.fac=u.fac; sq.q=h.q; sq.r=h.r; sq.facing=u.facing; sq.name=`${HULLS[kind].n} (${u.side==='player'?u.name:u.t.n.split(' ').slice(-1)[0]})`; B.units.push(sq); return sq; }
// carriers open the battle with their wings already in flight; launching only replaces losses
function deployWings(){ for(const u of B.units.filter(x=>(x.ab==='launch'||(x.fx&&x.fx.hive))&&!x.dead&&!x.isSq&&!x.treeOff)){ const foes=alive(u.side==='player'?'enemy':'player'), sec=B.sector||1, bossWings=u.side==='enemy'&&u.t.boss;
  u.spare=bossWings?Math.max(0,sec-1):(u.fx&&u.fx.endless)?99:(u.hangar||0)+(wingPerks(u).includes('reserve')?1:0)+((u.fx&&u.fx.spareWings)||0); /* a sector flagship's air wing grows with the sector: 1 wing in sector I, 2 in II, 3 in III */ // v41: one spare wing per hangar slot (was two): carriers keep their opening wings, but losses end sooner
  for(let i=0;i<(bossWings?Math.min(u.hangar||0,sec):(u.hangar||0));i++){ const hs=launchHexes(u); if(!hs.length) break; hs.sort((a,b)=>Math.min(99,...foes.map(f=>hdist(a,f)))-Math.min(99,...foes.map(f=>hdist(b,f))));
    makeWing(u,hs[0],wingKind(u,i)); } }
  /* fighter screen against carrier-heavy fleets, flown off the biggest escorts */
  if(B.adaptWings){ const foes=alive('player'), hosts=alive('enemy').filter(x=>!x.isSq&&!x.transport).sort((a,b)=>(b.t.boss?0:b.t.cp||1)-(a.t.boss?0:a.t.cp||1)); for(let i=0;i<B.adaptWings&&hosts.length;i++){ const h=hosts[i%hosts.length], hs=launchHexes(h); if(!hs.length) continue; hs.sort((a,b)=>Math.min(99,...foes.map(f=>hdist(a,f)))-Math.min(99,...foes.map(f=>hdist(b,f)))); makeWing(h,hs[0],'fighter'); } } }
// a carrier's wing mix: strike craft first, then escorts. Factions whose own craft are fighters still field bombers, or their wings never touch a ship
function wingKind(u,i){ const set=FACTIONS[u.fac]&&FACTIONS[u.fac].sq, own=set||'fighter'; if(own!=='fighter') return own; if(set&&u.side==='enemy') return own; /* enemy fighter fleets stay true to their faction */ const foe=u.side==='player'?'enemy':'player', air=B.units.some(x=>!x.dead&&x.side===foe&&(x.isSq||x.ab==='launch')); if(!air) return 'bomber'; /* no enemy craft to fight: every wing is a strike wing */ const have=squadronsOf(u), nb=have.filter(x=>x.t.sq!=='fighter').length, nf=have.length-nb; if(i!=null) return i%2?'fighter':'bomber'; return nb<=nf?'bomber':'fighter'; }
function squadronsOf(u){ return alive().filter(x=>x.parent===u.id); }
// R88: replace one lost player wing per ready carrier each round, using the existing reserves and cooldown.
function replaceWings(side){ for(const u of alive(side).filter(x=>x.ab==='launch'&&!x.isSq)){
  if(!launchReady(u)) continue;
  const foes=alive(side==='player'?'enemy':'player'), hs=launchHexes(u);
  hs.sort((a,b)=>Math.min(99,...foes.map(f=>hdist(a,f)))-Math.min(99,...foes.map(f=>hdist(b,f))));
  launchWing(u,hs[0],wingKind(u)); u.abCd=abilityCd(u);
} }
function launchReady(u){ return u.ab==='launch'&&!u.dead&&!(u.abCd>0)&&!u.braced&&squadronsOf(u).length<u.hangar&&(u.spare==null||u.spare>0)&&launchHexes(u).length>0; }
function launchWing(u,h,kind){
  if(u.spare!=null) u.spare=Math.max(0,u.spare-1); const sq=makeWing(u,h,kind); sq.mp=0; sq.weapons.forEach(w=>w.fired=true); if(typeof fxFlash==='function') fxFlash(h,'#f0b35a');
  log(`${u.name} launches a ${HULLS[kind].n.toLowerCase()}.`,u.side==='player'?'p':'e');
}
function canAbility(u){
  if(!u.ab||u.dead||u.abCd>0||u.braced) return false;
  if(u.ab==='surge'&&u.st&&u.st.shieldOff>=99) return false; // the shield generator section is destroyed
  if(u.ab==='launch') return u.side!=='player'&&launchReady(u);
  if(u.ab==='reload') return u.weapons.some(w=>w.k==='torp'&&(w.cdLeft>0||w.fired));
  if(u.ab==='regrow') return u.hp<u.maxHp;
  if(u.ab==='reclaim') return alive(u.side).some(x=>!x.isSq&&hdist(x,u)<=3&&x.hp<x.maxHp);
  if(u.ab==='blink') return blinkHexes(u).length>0;
  if(u.ab==='ionpulse') return alive(u.side==='player'?'enemy':'player').some(t=>!t.isSq&&hdist(t,u)<=4&&t.sh.some(x=>x>0));
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
  if(a==='evasive'){ u.evBuff=25; u.mp+=2; if(typeof fxText==='function') fxText(u,'Evasive','#9fe3ff',-24); }
  if(a==='reload'){ for(const w of u.weapons) if(w.k==='torp'){ w.cdLeft=0; w.fired=false; } if(typeof fxText==='function') fxText(u,'Tubes loaded','#f0b35a',-24); }
  if(a==='focus'){ u.focus=true; if(typeof fxText==='function') fxText(u,'Focus fire','#f0b35a',-24); }
  if(a==='phase'){ u.evBuff=25; /* v45: was 22, strictly weaker than Evasive Burn; now level (Deathless is already the strongest faction, so parity rather than a buff) */ u.mp+=2; if(typeof fxText==='function') fxText(u,'Phase shift','#7dff9b',-24); }
  if(a==='frenzy'){ u.focus=true; if(typeof fxText==='function') fxText(u,'Blood frenzy','#ff8fe0',-24); }
  if(a==='overburn'){ u.mp+=3; u.ramBoost=1.5; if(typeof fxText==='function') fxText(u,'Overburn','#ffb35c',-24); }
  if(a==='regrow'){ const h=Math.min(u.maxHp-u.hp,Math.round(u.maxHp*.25)); u.hp+=h; if(typeof fxText==='function') fxText(u,'+'+h+' hull','#8ff0a0',-24); }
  if(a==='reclaim'){ const ts=alive(u.side).filter(x=>!x.isSq&&hdist(x,u)<=3&&x.hp<x.maxHp).sort((p,q)=>p.hp/p.maxHp-q.hp/q.maxHp), t=ts[0]; if(t){ const h=Math.min(t.maxHp-t.hp,Math.round(t.maxHp*.2)); t.hp+=h; if(typeof fxText==='function') fxText(t,'+'+h+' hull','#7dff9b',-24); log(u.name+' rebuilds '+(t===u?'its own hull':t.name)+' for '+h+'.',u.side==='player'?'p':'e'); } }
  if(a==='ionpulse'){ const foes=alive(u.side==='player'?'enemy':'player').filter(t=>!t.isSq&&hdist(t,u)<=4); for(const t of foes){ if(t.sh) t.sh=t.sh.map(x=>Math.floor(x*.5)); try{ if(typeof fxShield==='function') fxShield(t,-1); }catch(e){} } if(typeof fxText==='function') fxText(u,'Ion pulse','#9fd4ff',-24); log(u.name+' fires an ion pulse: '+foes.length+' enemy ship'+(foes.length===1?'':'s')+' lose half their shields.',u.side==='player'?'p':'e'); }
  if(a==='blink'){ const h=arg&&arg.hex?arg.hex:autoBlink(u); if(!h||!blinkHexes(u).some(x=>x.q===h.q&&x.r===h.r)) return false; const live=liveFrom(u), from={q:u.q,r:u.r}; u.q=h.q; u.r=h.r; u.vis=null; try{ if(typeof animBlink==='function') await animBlink(u,from); }catch(e){} if(!live()){ u.abCd=abilityCd(u); return false; } /* B1 (B-6): a jump whose animation stalled still lands, so it still costs the cooldown */ if(typeof fxText==='function') fxText(u,'Phase jump','#9fe3ff',-24); objAfterMove(u); } // v53: hex re-checked before the jump, live check after it (the jump itself is instant, so the hex is set before animBlink draws the arrival)
  if(a==='surge'){ for(let i=0;i<4;i++) u.sh[i]=u.shMax; if(u.st.shieldOff<99) u.st.shieldOff=0; if(typeof fxShield==='function') fxShield(u,-1); if(typeof fxText==='function') fxText(u,'Shields surge','#7fd6c8',-24); }
  if(a==='launch'){
    const h=arg&&arg.hex ? arg.hex : pick(launchHexes(u));
    const kind = arg&&arg.kind ? arg.kind : wingKind(u);
    launchWing(u,h,kind);
  }
  if(a==='nova'){
    const c=arg.hex;
    log(`${u.name} fires its nova cannon.`, u.side==='player'?'p':'e');
    const live=liveFrom(u); if(typeof animNova==='function') await animNova(u,c); if(!live()) return false; // abandoned after a stall: the blast never lands, and (B1, B-7) the cooldown is not spent
    u.abCd=abilityCd(u);
    const hitList=alive().filter(x=>hdist(x,c)<=1);
    for(const x of hitList){
      const dmg=(hdist(x,c)===0?40:20)*u.dmg*(x.isSq?1.5:1)*storyDamageMult(u);
      const quad=shieldQuad(x,u);
      const r=applyHit(u,{pierce:.3,crit:5},x,dmg,quad);
      if(r.shield&&typeof fxText==='function') fxText(x,'\u2212'+r.shield,'#7fd6c8',-18);
      if(typeof fxText==='function') fxText(x,'\u2212'+r.hull,'#ff7a6e',0);
      log(`Spinal shell hits ${x.name} for ${r.hull} hull${r.shield?` and ${r.shield} shields`:''}.`, x.side==='player'?'e':'p');
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
// v53-D: guns that already fired this round (alternating) are spent; the after-move term needs the gun to bear after a one-step turn and a clear line
function evalThreatVet(v,foes){ let tot=0; for(const p of foes){ const d=hdist(p,v); if(d>13) continue; let ls=null;
    for(const w of p.weapons){ if(w.cdLeft>1||w.off>1||!aiGunLive(p,w)) continue; if(d<=w.r&&inArc(p,v,w.arc)){ const e=expectedVs(p,w,v); tot+=e.hull+e.shield*.2; }
      else if(d<=w.r+Math.max(1,(p.speed||2)-1)&&aiArcSoon(p,v,w.arc)&&(ls==null?(ls=los(p,v)):ls)){ const e=expectedVs(p,w,v); tot+=(e.hull+e.shield*.2)*.2; } } } return tot; }
// can this gun still fire before the round ends? In alternating play a gun that fired (or a braced hull) is done until the next round; flak never fires at ships
function aiGunLive(p,w){ if(w.k==='flak') return false; if(B&&B.alt&&(w.fired||p.braced)) return false; return true; }
// would the target sit in this arc now, or after a one-step turn (if the ship has a turn)?
function aiArcSoon(p,v,arc){ if(arc==='T'||inArc(p,v,arc)) return true; if(!((p.turns||0)>0)) return false; const f=p.facing; return inArc({q:p.q,r:p.r,facing:(f+1)%6},v,arc)||inArc({q:p.q,r:p.r,facing:(f+5)%6},v,arc); }
// a position that lines up a ram for next activation
function ramSetup(v,u){ const d=DIRS[v.facing]; let q=v.q,r=v.r; for(let i=0;i<=(u.speed||2);i++){ q+=d[0]; r+=d[1]; if(!onBoard(q,r)||blocks(terr(q,r))) return 0; const o=unitAt(q,r); if(o&&o!==u){ return (o.side!==u.side&&!o.isSq&&i>=1)?ramEstimate(Object.assign(Object.create(u),{q:v.q,r:v.r,facing:v.facing}),o).dmg:0; } } return 0; }
// the fleet-wide focus target: the most valuable ship that is closest to dying
function aiFocusTarget(){ const sh=aiShooters(); let best=null,bv=0; for(const t of alive('player')){ if(t.isSq) continue; const v=aiFocusVal(t,sh); if(v>bv){bv=v;best=t;} } return best; }
// v53-D: value over effective hull, priced the way expectedVs will price it (brace, guard aura, Iron Command), and worth less when few of our guns can reach it this turn
function aiShooters(){ return caps('enemy').filter(u=>!u.transport&&u.weapons.length); }
function aiFocusVal(t,shooters){ if(!t||t.dead||t.isSq) return 0; const br=braceMul(t), take=Math.max(.15,br*guardMul(t)*cmdTaken(t));
  const ehp=t.hp/take+t.sh.reduce((a,x)=>a+x,0)*.3; let n=0;
  for(const u of shooters){ let rr=0; for(const w of u.weapons) if(w.cdLeft<=1&&w.off<=1&&w.k!=='flak'&&w.r>rr) rr=w.r; if(rr&&hdist(u,t)<=rr+(u.speed||2)) n++; }
  return ((t.t.cp||1)*12+(t.flagship||t.pflag?20:0))/Math.max(20,ehp)*(n>=2?1:n===1?.8:.4); }
// sticky fleet focus (veteran only): kept until the target dies or another is clearly (25%) better; re-checked each enemy turn and activation, never overwritten by a single ship's volley
function aiRefreshFocus(){ if(!B) return null; if(!aiVet()){ B.aiFocus=null; return null; } const sh=aiShooters(), cur=B.aiFocus&&!B.aiFocus.dead&&B.aiFocus.side==='player'&&inThisBattle(B.aiFocus)?B.aiFocus:null, cv=cur?aiFocusVal(cur,sh):0;
  let best=null,bv=0; for(const t of alive('player')){ if(t.isSq||t===cur) continue; const v=aiFocusVal(t,sh); if(v>bv){bv=v;best=t;} }
  B.aiFocus=!cur||(best&&bv>cv*1.25)?(best||cur):cur; return B.aiFocus; }
function evalOffenseVet(a,ready,targets,focus){ let tot=0;
  for(const w of ready){ let best=0; for(const t of targets){ if(!inReach(a,w,t)) continue; const e=expectedVs(a,w,t); let v=e.hull+e.shield*.3; if(e.hull>=t.hp) v+=15+t.maxHp*.1; if(t.isSq&&!w.vsSq) v*=.5; if(t===focus) v*=1.3; if(e.rear) v*=1.1; if(v>best) best=v; } tot+=best; }
  return tot; }
// alternating activations: veterans act with the ship that has the best opportunity, or the most danger, right now
function aiPickActivation(list){ if(!aiVet()||list.length<2) return list[0]; aiRefreshFocus(); const foes=alive('player'); let best=list[0],bv=-1e9;
  for(const u of list){ if(u.isSq) continue; const ready=u.weapons.filter(weaponReady); let mx=0;
    for(let f=0;f<6;f++){ const o=evalOffenseVet(Object.assign(Object.create(u),{facing:f}),ready,foes,B.aiFocus); if(o>mx) mx=o; }
    let reach=0; for(const t of foes){ const d=hdist(u,t); for(const w of ready) if(d<=w.r+(u.speed||2)) reach=Math.max(reach,w.dmg*w.shots*(t===B.aiFocus?1.3:1)); }
    const val=mx+reach*.5+evalThreat(u,foes)*.25+(u.hp<u.maxHp*.3?10:0); if(val>bv){bv=val;best=u;} }
  return best; }
function evalThreat(v, foes){
  let tot=0;
  for(const p of foes){ if(hdist(p,v)>9) continue;
    for(const w of p.weapons){ if(w.cdLeft>1||w.off>1||!aiGunLive(p,w)) continue; if(hdist(p,v)>w.r) continue; if(!inArc(p,v,w.arc)) continue; const e=expectedVs(p,w,v); tot+=e.hull+e.shield*.2; } }
  return tot;
}
// v53-D: the volley primary is re-picked before every gun from current hull and shields, with damage counted only up to the hull a target has left
// (a 2-hull wreck is not worth a full broadside); a heavy gun leaves a kill that a lighter ready gun can make to that gun and fires elsewhere
// AI polish (v54 backlog): target hysteresis. A ship keeps last activation's primary while it is still worth 85% of the best, so volleys stop hopping between near-equal targets
const AI_STICK=.85;
function aiPickPrimary(u,ws,focus){ let pv=0,primary=null,lastV=0; const last=u.aiLastT&&!u.aiLastT.dead&&u.aiLastT.side!==u.side?u.aiLastT:null;
  for(const t of alive('player')){ let sh=0,hull=0; for(const w of ws){ if(!canFire(u,w,t)) continue; const e=expectedVs(u,w,t); sh+=e.shield*.3; hull+=e.hull; } if(!sh&&!hull) continue;
    const val=(Math.min(hull,t.hp)+sh)*(t.isSq?.6:1.1)+(hull>=t.hp?25+t.maxHp*.15:0)+(t===focus?10:0)+(1-t.hp/t.maxHp)*15+nemTargetBonus(u,t); if(t===last) lastV=val; if(val>pv){pv=val;primary=t;} }
  if(last&&lastV>0&&lastV>=pv*AI_STICK) primary=last; if(primary) u.aiLastT=primary; return primary; }
// shield strippers first: the order key is the share of a gun's fire that comes off shields (ion strips more than it deals), then raw weight
function aiGunOrder(u,ws,t){ const k=new Map(); for(const w of ws){ let v=-1; if(t&&canFire(u,w,t)){ const e=expectedVs(u,w,t); v=e.raw>0?Math.round(e.shield/e.raw*4):0; } k.set(w,v); }
  return ws.slice().sort((a,b)=>k.get(b)-k.get(a)||(b.dmg*b.shots)-(a.dmg*a.shots)); }
async function aiVolley(u,live){
    const vet=aiVet(), focus=vet&&B.aiFocus&&!B.aiFocus.dead?B.aiFocus:null, tried=new Set();
    let fired=false;
    for(let g=0;g<u.weapons.length;g++){
      if(B.over) return null; if(u.dead) break;
      const ws=u.weapons.filter(w=>weaponReady(w)&&w.k!=='flak'&&!tried.has(w)); if(!ws.length) break;
      const primary=aiPickPrimary(u,ws,focus); // veterans concentrate on it; both levels use it to order the guns
      const w=aiGunOrder(u,ws,primary)[0], wi=u.weapons.indexOf(w); tried.add(w);
      let bt=null, bv=0;
      const taunt=alive('player').find(p=>!p.isSq&&p.fx&&p.fx.taunt&&hdist(p,u)<=p.fx.taunt); /* Aspect of the Bulwark: ships in its reach must fire on it */
      if(taunt&&canFire(u,w,taunt)){ bt=taunt; bv=1; }
      else if(vet&&primary&&canFire(u,w,primary)&&!(w.vsSq>1&&!primary.isSq&&alive('player').some(s=>s.isSq&&canFire(u,w,s)))){ bt=primary; bv=1;
        if(expectedVs(u,w,primary).hull>=primary.hp*2&&ws.some(x=>x!==w&&canFire(u,x,primary)&&expectedVs(u,x,primary).hull>=primary.hp)){ let av=3;
          for(const t of alive('player')){ if(t===primary||!canFire(u,w,t)) continue; const e=expectedVs(u,w,t); const v=Math.min(e.hull,t.hp)+e.shield*.3+(e.hull>=t.hp?20:0); if(v>av){av=v;bt=t;} } } }
      else for(const t of alive('player')){ if(!canFire(u,w,t)) continue; const e=expectedVs(u,w,t); let v=Math.min(e.hull,t.hp)+e.shield*.3; if(e.hull>=t.hp) v+=20; if(!t.isSq) v*=1.1; if(v>bv){bv=v;bt=t;} }
      if(bt && bv>0.5){ await fireWeapon(u,wi,bt,{called:null}); fired=true; await wait(30); if(!live()) return null; }
    }
    return fired;
}
async function aiTurn(){
  const order=alive('enemy').sort((a,b)=>(a.isSq?0:1)-(b.isSq?0:1) || b.speed-a.speed);
  for(const u of order){ if(B.over) return; if(u.dead||!u.isSq) continue; await aiUnit(u); }
  // v53-D: Classic mode picks each next ship by opportunity (aiPickActivation, veteran); standard keeps the fixed speed order
  const done=new Set(); for(let g=0;g<order.length;g++){ if(B.over) return; const left=order.filter(u=>!u.isSq&&!u.dead&&!done.has(u)); if(!left.length) break; const u=aiPickActivation(left); done.add(u); await aiUnit(u); }
}
// true travel distance (in hexes, around holes, rocks and wrecks) from every hex to the nearest of the given targets
function pathField(targets){ const D=new Map(), q=[]; for(const t of targets){ const k=hkey(t.q,t.r); if(!D.has(k)){ D.set(k,0); q.push(t); } }
  for(let i=0;i<q.length;i++){ const h=q[i], d=D.get(hkey(h.q,h.r)); for(const dd of DIRS){ const n={q:h.q+dd[0],r:h.r+dd[1]}, k=hkey(n.q,n.r); if(D.has(k)||!onBoard(n.q,n.r)||blocks(terr(n.q,n.r))) continue; D.set(k,d+1); q.push(n); } }
  return D; }
function fieldDist(D,v,fallback){ const d=D.get(hkey(v.q,v.r)); return d==null?fallback+6:d; }
// v53-D: the ability checks in one helper. 'pre' runs before moving; 'aim' re-runs the ones that depend on where the ship ended up (focus and frenzy
// only once a gun bears, reload when a spent tube now reaches a target) just before it fires; 'escape' is the phase jump away after firing when hurt
// and still under the guns. canAbility and cooldowns already stop a double use.
async function aiAbilities(u,live,mode){ const foes=alive('player'); if(!foes.length||u.dead) return live(); const pre=mode==='pre', aim=mode==='aim';
    if(pre&&u.ab==='launch' && canAbility(u)){ const hs=launchHexes(u).sort((a,b)=>Math.min(...foes.map(f=>hdist(a,f)))-Math.min(...foes.map(f=>hdist(b,f)))); await useAbility(u,{hex:hs[0]}); await wait(200); }
    const nearF=foes.filter(f=>!f.isSq).reduce((a,f)=>!a||hdist(u,f)<hdist(u,a)?f:a,null);
    /* shields: surge when the facing toward the nearest threat is under half, not when all four facings are drained */
    if(pre&&u.ab==='surge' && canAbility(u) && nearF && hdist(u,nearF)<=8 && u.sh[shieldQuad(u,nearF)]<u.shMax*.5) { await useAbility(u); await wait(200); if(!live()) return false; }
    if(aim&&(u.ab==='focus'||u.ab==='frenzy') && canAbility(u) && u.weapons.some(w=>weaponReady(w)&&foes.some(f=>canFire(u,w,f)))) await useAbility(u);
    if(pre&&(u.ab==='evasive'||u.ab==='phase') && canAbility(u) && foes.some(f=>hdist(u,f)<=5)) await useAbility(u);
    if(u.ab==='reload' && canAbility(u) && (pre?foes.some(f=>!f.isSq&&hdist(u,f)<=6+(u.speed||2)):aim&&u.weapons.some(w=>w.k==='torp'&&w.off===0&&!weaponReady(w)&&foes.some(f=>!f.isSq&&inReach(u,w,f))))) { await useAbility(u); if(!live()) return false; }
    if(pre&&u.ab==='regrow' && canAbility(u) && u.hp<u.maxHp*.6) await useAbility(u);
    if(pre&&u.ab==='reclaim' && canAbility(u) && alive('enemy').some(x=>!x.isSq&&hdist(x,u)<=3&&x.hp<x.maxHp*.6)) await useAbility(u);
    if(pre&&u.ab==='ionpulse' && canAbility(u) && foes.filter(t=>!t.isSq&&hdist(t,u)<=4).reduce((a,t)=>a+t.sh.reduce((x,y)=>x+y,0),0)>=30) await useAbility(u);
    if(pre&&u.ab==='overburn' && canAbility(u) && nearF && hdist(u,nearF)>(u.speed||2)+1) await useAbility(u);
    if(u.ab==='blink' && canAbility(u) && nearF && (pre?(u.hp<u.maxHp*.35&&evalThreat(u,foes)>u.hp*.3 || !u.weapons.some(w=>weaponReady(w)&&foes.some(f=>hdist(u,f)<=w.r+(u.speed||2)))):mode==='escape'&&u.hp<u.maxHp*.35&&evalThreat(u,foes)>u.hp*.3)) { await useAbility(u); if(!live()) return false; }
    return live(); }
// after the volley: a ram the move lined up, then the escape jump
async function aiAfterFire(u,live,runner){ if(!u.isSq&&!runner&&!u.dead) await tacticRam(u); if(B.over||u.dead||!live()) return false; if(!u.isSq&&!runner&&canFade(u)){ await fadeMove(u); if(B.over||u.dead||!live()) return false; } return await aiAbilities(u,live,'escape')&&!B.over; }
// AI polish (v54 backlog): a smooth response curve for caution as hull drops (0.32 when healthy up to 0.6 x the faction's hurt weight when crippled),
// with hysteresis: a ship that drops under 30% stays cautious until it is back above 45%, so it does not flip between charging and fleeing
function aiHurtW(u,prof){ const f=u.hp/Math.max(1,u.maxHp); if(f<.3) u.aiHurt=true; else if(f>.45) u.aiHurt=false; const k=u.aiHurt?1:clamp((.6-f)/.3,0,1), x=k*k*(3-2*k); return .32+(.6*prof.hurt-.32)*x; }
// the Ithar fade (and Slip the Net): after firing, step to the reachable hex with the least incoming fire if it cuts the threat by a quarter
async function fadeMove(u){ if(!u||u.dead||u.isSq||!u.postFire||postFireMp(u)<1) return false; const foes=alive(u.side==='player'?'enemy':'player'); if(!foes.length) return false;
  const here=evalThreat(u,foes)+torpThreat(u,u); if(here<5) return false; let best=null,bv=here; for(const s of computeReach(u).states){ if(s.q===u.q&&s.r===u.r) continue; const v=stateView(u,s), th=evalThreat(v,foes)+torpThreat(u,v); if(th<bv){ bv=th; best=s; } }
  if(!best||bv>here*.75) return false; await moveUnit(u,best); fstat(u.fac,'fade'); return true; }
function enemyPaceK(){ const n=B?B.units.filter(x=>x.side==='enemy'&&!x.isSq&&!x.dead).length:1; return Math.min(1,Math.max(PACE.bigMin,Math.sqrt(PACE.bigRef/Math.max(1,n)))); } // B2: bigger enemy fleets play their phase quicker
// veteran AI: brace instead of firing when the incoming fire is heavy, our own guns can do little and the hull is already down
function aiVetBrace(u){ if(!(aiVet()&&!u.isSq&&!u.t.boss&&canOrder(u,'brace'))) return false; const pf=alive('player'), myOff=evalOffense(u,u.weapons.filter(weaponReady),pf), thr=evalThreat(u,pf); return thr>u.hp*.45&&myOff<thr*.35&&u.hp<u.maxHp*.7; }
async function aiUnit(u){
  if(u.isSq){ if(!B.over&&!u.dead&&u.side==='enemy') await sqAct(u); return; } // squadrons follow the swarm rules
  // H17 The First Throat Opens: in Alternating mode the enemy's paired activation after the flagship is skipped once, so the player opens one more throat
  if(u.side==='enemy'&&treeSkill('firstThroat')&&B.alt!==false&&B.tr&&!B.tr.firstThroatUsed){ const fg=B.units.find(x=>x.pflag&&!x.dead); if(fg&&fg.activated){ B.tr.firstThroatUsed=1; treeFx(fg,'firstThroat','one more throat opens'); return; } }
  if(u.side==='enemy'&&!B.cmdEUsed&&B.cmdENext!=null){ await bossCmdFire(); if(B.over||u.dead) return; }
  const live=liveFrom(u);
    if(B.over||u.dead||u.side!=='enemy') return; u._calledUsed=false;
    B.aiActive=u; await wait(PACE.aiGap); if(!live()) return;
    const foes=alive('player');
    if(!foes.length) return;
    if(!await aiAbilities(u,live,'pre')) return; // abilities before moving (v53-D: one helper, re-run after the move)
    const runner=u.transport||(B.obj&&B.obj.type==='hunt'&&u.flagship);
    if(!u.isSq&&!runner) await tacticRam(u); if(B.over||u.dead||!live()) return;
    // plan movement
    const ready=u.weapons.filter(weaponReady);
    const {states}=computeReach(u);
    const minR=Math.min(...u.weapons.map(w=>w.opt));
    let best=null, bestScore=-1e9; const PF=pathField(foes.filter(f=>!f.isSq||u.isSq));
    const vet0=aiVet(), focus0=vet0?aiRefreshFocus():null; // v53-D: the sticky fleet focus, checked once per activation
    const flE=vet0&&B.obj&&B.obj.type==='flagship'&&!u.flagship&&!u.isSq?B.units.find(x=>x.flagship&&!x.dead&&x.side==='enemy'):null, escO=flE?caps('enemy').filter(x=>x!==u&&x!==flE&&!x.transport):[], escIn=flE?escO.filter(x=>hdist(x,flE)<=3).length:0; // escort spacing
    for(const s of states){
      const v=stateView(u,s);
      const vet=vet0, focus=focus0;
      const off=vet?evalOffenseVet(v,ready,foes,focus):evalOffense(v,ready,foes);
      const threat=vet?evalThreatVet(v,foes):evalThreat(v,foes);
      const prof=nemProf(u,(!u.isSq&&FACTION_AI[u.fac])||FACTION_AI.voidsworn), tw=(u.isSq?.15:!vet?.3:u.flagship?.65:aiHurtW(u,prof))*prof.tw; // AI polish: smooth caution curve with hysteresis
      let score=off-threat*tw; if(vet&&!u.isSq&&threat>=u.hp) score-=25; // v53-D death cliff: a hex where the expected fire could finish us
      if(vet&&!u.isSq&&prof.range){ const nd2=Math.min(99,...foes.filter(f=>!f.isSq).map(f=>hdist(v,f))); if(prof.range>0) score-=Math.max(0,prof.range-nd2)*prof.rw; else score-=Math.max(0,nd2+prof.range)*prof.rw; }
      if(vet&&!u.isSq&&RAM_FAC[u.fac]) score+=ramSetup(v,u)*.35;
      if(vet&&B.obj&&B.obj.type==='flagship'&&!u.flagship&&!u.isSq){ const fl=flE; if(fl){ const dv=hdist(v,fl); score-=Math.max(0,dv-3)*(escIn>=2?.6:2); if(dv<=3) for(const x of escO) if(hdist(x,v)===1) score-=1; } } // two escorts in the ring cap the pull, and escorts spread out instead of stacking
      if(off<=0){ const hd=Math.min(...foes.filter(f=>!f.isSq||u.isSq).map(f=>hdist(v,f)).concat([99])), nd=Math.max(hd,fieldDist(PF,v,hd)); score-=Math.max(0,nd-minR)*4; } // travel distance, so a hole or a rock wall between us is not a shortcut
      score-=s.cost*.05;
      if(!u.isSq){ score-=torpThreat(u,v)*.9; score-=syncPull(u,v)*(vet?2:1.2)*(u.nem&&B.nemLine?2:1); } // B3: step out of incoming torpedo lanes; Hegemony keeps formation on its anchor
      if(B.obj&&B.obj.type==='hold'&&!u.isSq&&!vet) score-=hdist(v,B.obj.hex)*1.6; // veterans: aiObjScore (two nearest, urgency)
      score+=aiObjScore(u,v); score+=aiWellScore(u,v);
      if(score>bestScore){ bestScore=score; best=s; }
    }
    let volleyP=null, braceMid=false;
    if(best && best.path.length){ const midFire=!u.isSq&&!runner&&!(u.ab==='nova'&&canAbility(u))&&!(typeof animPath==='function'&&typeof process!=='undefined'&&process.env&&process.env.NOMIDFIRE);
      // R1 (AI-1, Muse patch pack 1 as adjusted by its addendum): the veteran brace decision runs on the mid-move path too, after the boarding deferral and before
      // the volley (once a gun fires, Brace is closed); on a brace call the ship finishes its move, fires nothing and braces
      await moveUnit(u,best,midFire?{onLate:()=>{ if(boardTargets(u).length) return; if(aiVetBrace(u)){ braceMid=true; return; } volleyP=(async()=>{ if(!await aiAbilities(u,live,'aim')||u.dead) return null; return aiVolley(u,live); })(); return volleyP; }}:undefined); if(!live()) return; }
    if(braceMid){ if(!u.dead) giveOrder(u,'brace'); B.aiActive=null; u.activated=true; return; }
    if(volleyP){ const fired=await volleyP; if(!live()||B.over) return; if(!await aiAfterFire(u,live,runner)) return; if(!fired && !u.dead && u.hp<u.maxHp*.5 && canOrder(u,'brace') && evalThreat(u,alive('player'))>10){ giveOrder(u,'brace'); } B.aiActive=null; u.activated=true; return; }
    // nova
    if(u.ab==='nova' && canAbility(u)){
      let bh=null, bv=0;
      for(const h of novaTargets(u)){ let v=0; for(const x of alive()){ const d=hdist(x,h); if(d>1) continue; const dm=d===0?40:20; v+= x.side==='player'?dm:-dm*1.5; } if(v>bv){bv=v;bh=h;} }
      if(bh && bv>=40){ await useAbility(u,{hex:bh}); await wait(80); if(!live()) return; }
    }
    if(!u.isSq && !runner && await tacticBoard(u)){ if(live()){ B.aiActive=null; u.activated=true; } return; }
    if(!live()) return;
    if(aiVetBrace(u)){ giveOrder(u,'brace'); B.aiActive=null; u.activated=true; return; }
    if(!await aiAbilities(u,live,'aim')) return;
    const fired=await aiVolley(u,live); if(fired===null) return;
    if(!await aiAfterFire(u,live,runner)) return;
    if(!fired && !u.isSq && !u.dead && u.hp<u.maxHp*.5 && canOrder(u,'brace') && evalThreat(u,alive('player'))>10){ giveOrder(u,'brace'); }
    B.aiActive=null; u.activated=true;
}
