// ======================= CORE =======================
// v41: seeded rules randomness (mulberry32). Each battle reseeds from B.seed, so a seed plus the same moves replays a fight;
// the simulator takes SEED from the environment so whole runs repeat exactly. Cosmetic effects keep Math.random.
let RNG_S=(Math.random()*4294967296)>>>0;
function rndSeed(s){ RNG_S=(s>>>0); }
function rnd(){ RNG_S=(RNG_S+0x6D2B79F5)|0; let t=Math.imul(RNG_S^(RNG_S>>>15),1|RNG_S); t=(t+Math.imul(t^(t>>>7),61|t))^t; return ((t^(t>>>14))>>>0)/4294967296; }
const ri = (a,b) => a + Math.floor(rnd()*(b-a+1));
const pick = a => a[Math.floor(rnd()*a.length)];
const shuffle = a => { for(let i=a.length-1;i>0;i--){const j=Math.floor(rnd()*(i+1));[a[i],a[j]]=[a[j],a[i]];} return a; };
const clamp = (v,a,b) => Math.max(a,Math.min(b,v));
const esc = s => String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let SPEED = 1;
const wait = ms => new Promise(r=>setTimeout(r, ms*SPEED));
let UID = 1;
const newId = () => 'x'+Date.now().toString(36)+(UID++);

// ---------- hex math (pointy-top, axial) ----------
const DIRS = [[1,0],[0,1],[-1,1],[-1,0],[0,-1],[1,-1]]; // facing i -> angle i*60deg on screen
const hkey = (q,r) => q+','+r;
function hdist(a,b){const dq=a.q-b.q, dr=a.r-b.r; return (Math.abs(dq)+Math.abs(dr)+Math.abs(dq+dr))/2;}
function axPx(q,r){return {x:Math.sqrt(3)*(q+r/2), y:1.5*r};}
function angTo(a,b){const pa=axPx(a.q,a.r), pb=axPx(b.q,b.r); return Math.atan2(pb.y-pa.y,pb.x-pa.x)*180/Math.PI;}
function relAng(u,t){let d=angTo(u,t)-u.facing*60; d=((d%360)+540)%360-180; return d;}
function inArc(u,t,arc){
  if(arc==='T') return true;
  const a=relAng(u,t), A=Math.abs(a);
  if(arc==='F') return A<=60.5;
  if(arc==='R') return A>=119.5;
  if(arc==='S') return a>=29.5 && a<=150.5;
  if(arc==='P') return a<=-29.5 && a>=-150.5;
  return false;
}
function shieldQuad(t,att){const b=relAng(t,att), A=Math.abs(b); if(A<50) return 0; if(A>130) return 2; return b>0?1:3;}
const QUAD_NAME = ['prow','starboard','rear','port'];
function cubeRound(x,z){let y=-x-z, rx=Math.round(x), rz=Math.round(z), ry=Math.round(y);
  const dx=Math.abs(rx-x), dy=Math.abs(ry-y), dz=Math.abs(rz-z);
  if(dx>dy&&dx>dz) rx=-ry-rz; else if(dy<=dz) rz=-rx-ry;
  return {q:rx,r:rz};}
function hexLine(a,b){const N=hdist(a,b), out=[]; for(let i=0;i<=N;i++){const t=N?i/N:0;
  out.push(cubeRound(a.q+(b.q-a.q)*t+1e-6, a.r+(b.r-a.r)*t+1e-6));} return out;}
function faceToward(a,b){const ang=angTo(a,b); return ((Math.round(ang/60)%6)+6)%6;}

// ---------- persistence ----------
const STORE_KEY='voidsworn.v1';
const SAVE_VERSION=2;
function defaultMeta(){return {v:SAVE_VERSION,renown:0,unlocked:{},admirals:{vex:true},fallen:[],stats:{runs:0,best:0,wins:0},opts:{},tel:[],updated:0,mastery:{},favour:{},variants:{},heatBest:{}};}
// older saves get the fields newer code expects
function migrateMeta(m){ if(!m.v||m.v<2){ m.opts=m.opts||{}; m.tel=m.tel||[]; m.v=2; } m.mastery=m.mastery||{}; m.favour=m.favour||{}; m.variants=m.variants||{}; m.heatBest=m.heatBest||{};
  // first load after progression arrived: credit the runs already played (from the run log) to mastery and favour
  if(!m.backfilled){ m.backfilled=1; try{ let adm=null; for(const e of (m.tel||[])){
      if(e.ev==='run_start'&&e.admiral) adm=e.admiral;
      else if(e.ev==='battle_end'&&adm&&e.result==='win') m.mastery[adm]=(m.mastery[adm]||0)+(e.kind==='boss'?5:e.kind==='elite'?2:1);
      else if(e.ev==='run_end'){ if(adm&&e.victory) m.mastery[adm]=(m.mastery[adm]||0)+10; adm=null; const st=e.stats||{}; m._back=(m._back||0)+(st.battles||0)*2+(st.elites||0)*4+(st.bosses||0)*15+Math.floor((st.kills||0)/4)+((e.sector||1)-1)*5; }
      else if(e.ev==='boon_pick'&&e.id&&typeof BOONS!=='undefined'&&BOONS[e.id]){ const ps=BOONS[e.id].p?[BOONS[e.id].p]:(BOONS[e.id].duo||[]); for(const p of ps) m.favour[p]=(m.favour[p]||0)+1+(e.r||0); } } m.renown=(m.renown||0)+Math.min(60,m._back||0); delete m._back; /* a capped credit for runs already flown, so there is something to unlock right away */ }catch(err){} }
  // v41: older builds logged run_end without a faction, so early victories never reached wonFacs; recover them from the run's run_start
  if(!m.wonFix41){ m.wonFix41=1; try{ let fac=null; const won=new Set((m.stats&&m.stats.wonFacs)||[]); for(const e of (m.tel||[])){ if(e.ev==='run_start'&&e.fac) fac=e.fac; else if(e.ev==='run_end'){ if(e.victory&&(e.fac||fac)) won.add(e.fac||fac); fac=null; } } if(m.stats) m.stats.wonFacs=[...won]; }catch(e){} }
  return m; }
function migrateRun(r){ if(r&&!r.fac) r.fac='voidsworn';
  if(r&&(!r.v||r.v<2)){ r.v=2; r.stats=r.stats||{battles:0,elites:0,bosses:0,kills:0}; r.fallen=r.fallen||[]; } return r; }
let META = defaultMeta();
let SAVED_RUN = null;
let onPersistLoaded = ()=>{};
const Persist = {
  db:null, uid:null, writing:false, pending:false,
  loadLocal(){ let s=null, o=null; try{ s=localStorage.getItem(STORE_KEY); }catch(e){} try{ if(s) o=JSON.parse(s); }catch(e){ o=null; } // v41: a damaged save falls back to the backup copy
    if(s&&(!o||typeof o!=='object')){ try{ const b=localStorage.getItem(STORE_KEY+'.bak'); if(b){ o=JSON.parse(b); this.recovered=true; } }catch(e){ o=null; } }
    try{ if(o&&typeof o==='object'){
      if(o.meta){ META=migrateMeta(Object.assign(defaultMeta(),o.meta)); if(typeof mergeLocalTel==='function') mergeLocalTel(); } SAVED_RUN=migrateRun((o.run&&!o.run.none)?o.run:null); } }catch(e){} },
  saveLocal(){ const data=JSON.stringify({meta:META, run:SAVED_RUN});
    try{ const prev=localStorage.getItem(STORE_KEY); if(prev&&prev!==data){ try{ JSON.parse(prev); localStorage.setItem(STORE_KEY+'.bak',prev); }catch(e){} } }catch(e){} // v41: keep the last good save one step behind
    try{ localStorage.setItem(STORE_KEY, data); this.failed=false; }
    catch(e){ if(!this.failed&&typeof toast==='function') toast('This device could not save locally (storage full?). Your cloud save still updates.'); this.failed=true; } },
  async connect(){
    try{
      if(!window.claude || typeof window.claude.use!=='function') return;
      const [db,user] = await Promise.all([window.claude.use('db'), window.claude.use('user')]);
      if(!db || !user) return;
      const id = await user.id(); if(!id) return;
      this.db=db; this.uid=id;
      const snap = await db.doc('data/users/'+id+'/save').get();
      if(snap.exists){
        const d = JSON.parse(JSON.stringify(snap.data()||{}));
        const rm = d.meta||{};
        if((rm.updated||0) > (META.updated||0)){
          META = migrateMeta(Object.assign(defaultMeta(), rm)); if(typeof mergeLocalTel==='function') mergeLocalTel();
          SAVED_RUN = migrateRun((d.run && !d.run.none) ? d.run : null);
          this.saveLocal(); onPersistLoaded();
        } else if((META.updated||0) > (rm.updated||0)) this.push();
      } else if(META.updated) this.push();
    }catch(e){ console.warn('Cloud save unavailable', e); this.db=null; }
  },
  async push(){
    if(!this.db) return;
    if(this.writing){ this.pending=true; return; }
    this.writing=true;
    try{ await this.db.doc('data/users/'+this.uid+'/save').set({meta:META, run:SAVED_RUN||{none:true}}); }
    catch(e){ console.warn('Cloud save failed', e); }
    this.writing=false;
    if(this.pending){ this.pending=false; this.push(); }
  },
  save(){ META.updated=Date.now(); this.saveLocal(); this.push(); }
};

// ---------- run state ----------
let RUN = null;
function capName(fac){ const C=CAPTAINS[fac]||CAPTAINS.voidsworn; const used=new Set((typeof RUN!=='undefined'&&RUN&&RUN.fleet?RUN.fleet:[]).map(s=>s.cap&&s.cap.name.split(' ')[0])); let n='';
  for(let i=0;i<8;i++){ n=C.names?pick(C.names)+(C.epithets?' '+pick(C.epithets):''):pick(C.first)+' '+pick(C.last); if(!used.has(n.split(' ')[0])) break; } return n; } // avoid repeating a first name within the fleet
function rankName(c){ const R=((CAPTAINS[(c&&c.fac)||'voidsworn'])||CAPTAINS.voidsworn).ranks; return R[Math.max(0,Math.min(R.length-1,(c&&c.rank)||0))]; }
function factionOfTpl(tpl){ const h=HULLS[tpl]; if(h&&h.fac) return h.fac; for(const [f,F2] of Object.entries(FACTIONS)) if((F2.roster||[]).includes(tpl)||F2.boss===tpl) return f; return 'voidsworn'; }
function shipName(fac){ const used=new Set((RUN?RUN.fleet:[]).map(s=>s.name)); const base=!fac||fac==='voidsworn'?SHIP_NAMES:[...((typeof FNAMES!=='undefined'&&FNAMES[fac])||[]),...(MORE_SHIP_NAMES[fac]||[])]; const pool=(base.length?base:SHIP_NAMES).filter(n=>!used.has(n)); return pick(pool.length?pool:SHIP_NAMES); }
function newCaptain(vet,fac){ const c={fac:fac||'voidsworn',name:capName(fac), xp:0, rank:0, perks:[], pending:0};
  if(vet){ c.xp=RANK_XP[1]; c.rank=1; c.perks=[pick(Object.keys(PERKS))]; } return c; }
function newShip(tpl, vet){ const fac=factionOfTpl(tpl); const s={uid:newId(), tpl, name:shipName(fac), mk:1, hp:0, mods:[], cap:newCaptain(vet,fac)}; s.hp=derive(s).maxHp; return s; }

function sumFx(list){const o={}; for(const fx of list){ if(!fx) continue; for(const k in fx) o[k]=(o[k]||0)+fx[k]; } return o;}
function fleetFxList(){ const l=[]; if(RUN){ for(const r of RUN.relics) if(RELICS[r].fx) l.push(RELICS[r].fx); if(ADMIRALS[RUN.admiral]) l.push(ADMIRALS[RUN.admiral].fx); for(const b of (RUN.boons||[])) if(BOONS[b.id]) l.push(BOONS[b.id].fx(RARITY[b.r||0].m)); } return l; }
// ---------- patrons and boons ----------
function ensurePatrons(){ if(!RUN) return; if(!RUN.patrons||!RUN.patrons.length) RUN.patrons=shuffle(Object.keys(PATRONS)).slice(0,4); if(!RUN.boons) RUN.boons=[]; }
function hasBoon(id){ return !!(RUN&&RUN.boons&&RUN.boons.some(b=>b.id===id)); }
function boonPatrons(){ return new Set((RUN&&RUN.boons||[]).map(b=>BOONS[b.id]&&BOONS[b.id].p).filter(Boolean)); }
function rollRarity(minR,s,p){ const ft=p?favourTier(p):0, x=rnd(), rare=.24+.06*((s||1)-1)+(ft>=1?.12:0), epic=.06+.03*((s||1)-1)+(ft>=1?.03:0); let r=x<epic?2:x<epic+rare?1:0; if(ft>=3) r=Math.max(r,1); return Math.max(minR||0,r); }
// three boons from one patron; a duo boon can take a slot once you hold boons from both of its patrons
function fleetKit(){ const k={}; for(const sh of (RUN&&RUN.fleet)||[]){ const d=derive(sh); for(const w of d.weapons){ if(w.k==='torp') k.torp=1; if(w.k==='lance') k.lance=1; if(w.k==='battery') k.batt=1; if(w.k==='flak') k.flak=1; if(w.arc==='P'||w.arc==='S') k.broad=1; if(w.arc==='P'||w.arc==='S'||w.k==='battery') k.still=1; } if((HULLS[sh.tpl].sh||0)>0) k.shields=1; if(HULLS[sh.tpl].hangar) k.carrier=1; if(d.hangar) k.sq=1; } return k; }
function boonUseful(id,kit){ const n=BOON_NEED[id]; return !n||!!kit[n]; }
function rollBoonOffer(p,minR){ ensurePatrons(); const s=(RUN&&RUN.sector)||1, have=boonPatrons(), kit=fleetKit();
  let pool=Object.keys(BOONS).filter(id=>BOONS[id].p===p&&!hasBoon(id)); pool=shuffle(pool); const junk=pool.filter(id=>!boonUseful(id,kit)); pool=pool.filter(id=>boonUseful(id,kit));
  const duos=Object.keys(BOONS).filter(id=>{ const b=BOONS[id]; return b.duo&&!hasBoon(id)&&boonUseful(id,kit)&&b.duo.includes(p)&&b.duo.every(q=>have.has(q)||q===p)&&b.duo.some(q=>q!==p&&have.has(q)); });
  const out=pool.slice(0,3).map(id=>({id,r:rollRarity(minR,s,p)}));
  if(duos.length&&(out.length<3||rnd()<.45)){ const d={id:pick(duos),r:0}; if(out.length>=3) out[2]=d; else out.push(d); }
  if(out.length<3){ const extra=shuffle(Object.keys(BOONS).filter(id=>BOONS[id].p&&BOONS[id].p!==p&&RUN.patrons.includes(BOONS[id].p)&&!hasBoon(id)&&boonUseful(id,kit)&&!out.some(o=>o.id===id))); while(out.length<3&&extra.length) out.push({id:extra.pop(),r:rollRarity(minR,s)}); while(out.length<3&&junk.length) out.push({id:junk.pop(),r:rollRarity(minR,s)}); }
  return out; }
// what a map node pays out: usually a patron's boon (its sigil shows on the map), sometimes a refit, credits or repairs
function rollNodeReward(type){ ensurePatrons(); const p=pick(RUN.patrons); if(type==='elite'||type==='boss') return {k:'boon',p,min:1}; const x=rnd(); return x<.62?{k:'boon',p}:x<.78?{k:'mod'}:x<.9?{k:'cred'}:{k:'repair'}; }
function flagshipOf(){ return RUN&&RUN.fleet&&RUN.fleet.find(s=>s.uid===RUN.flagUid); }
function ensureFlagship(){ if(!RUN||!RUN.fleet||!RUN.fleet.length) return null; if(!flagshipOf()){ const f=[...RUN.fleet].sort((a,b)=>(HULLS[b.tpl].cp||1)-(HULLS[a.tpl].cp||1)||derive(b).maxHp-derive(a).maxHp)[0]; RUN.flagUid=f.uid; return f; } return flagshipOf(); }
function runFx(){ const o={}; if(RUN) for(const r of RUN.relics){ const x=RELICS[r].run; if(x) for(const k in x) o[k]=(o[k]||0)+x[k]; } if(RUN && META.unlocked.salvagers) o.credPct=(o.credPct||0)+.2; return o; }
function mkWeapon(id,arc,fx){ const b=W[id]; const w=Object.assign({id,arc},b); w.cd=b.cd||0;
  if(b.k==='battery'&&fx.battShots) w.shots+=fx.battShots;
  if(b.k==='flak'&&fx.flakPlus){ w.shots+=2*fx.flakPlus; w.r+=fx.flakPlus; w.opt+=fx.flakPlus; }
  if(b.k==='torp'&&fx.torpCd) w.cd=Math.max(1,w.cd-fx.torpCd);
  if(arc==='F'&&fx.prowRange){ w.r+=fx.prowRange; w.opt+=fx.prowRange; }
  return w; }
function derive(ship){
  const t=HULLS[ship.tpl];
  const asp=RUN&&RUN.aspect&&ship.uid===RUN.flagUid&&ASPECTS[RUN.aspect]?[ASPECTS[RUN.aspect].fx]:[];
  const fx=sumFx([...fleetFxList(), ...ship.mods.map(m=>MODULES[m].fx), ...ship.cap.perks.map(p=>PERKS[p].fx), ...asp]);
  const mk=ship.mk||1, mm=1+.2*(mk-1);
  const maxHp=Math.round(t.hp*mm*(1+(fx.hpPct||0)));
  return {
    maxHp, shMax:Math.round(t.sh*mm*(1+(fx.shPct||0))), regen:Math.round(t.rg*mm*(1+(fx.regenPct||0))),
    armor:Math.min(.6,t.ar+(fx.armor||0)), speed:t.sp+(fx.speed||0), turns:t.tn+(fx.turns||0), ev:t.ev+(fx.ev||0),
    aim:fx.aim||0, crit:fx.crit||0, dmg:1+.15*(mk-1)+(fx.dmgPct||0), fx,
    hangar:t.hangar?t.hangar+(fx.hangar||0)+(fx.hive||0):(fx.hive||0),
    hullRegen:(fx.hullRegen||0)+Math.round((fx.hullRegenPct||0)*maxHp)+Math.round((t.regen||0)*mm),
    weapons:t.w.map(([id,arc])=>mkWeapon(id,arc,fx)),
  };
}
function changeShip(ship, fn){ const before=derive(ship).maxHp; fn(ship); const after=derive(ship).maxHp; ship.hp=clamp(ship.hp+(after-before),1,after); }
function changeFleet(fn){ const b=RUN.fleet.map(s=>derive(s).maxHp); fn(); RUN.fleet.forEach((s,i)=>{ const a=derive(s).maxHp; s.hp=clamp(s.hp+(a-b[i]),1,a); }); }
function fleetCP(){ return RUN.fleet.reduce((a,s)=>a+HULLS[s.tpl].cp,0); }
function priceMult(){ return (META.unlocked.wrights?.85:1)*(heatOn('h_coffers')?1.25:1); }
function heatOn(k){ return !!(typeof RUN!=='undefined'&&RUN&&RUN.heat&&RUN.heat.includes(k)); }
function repairMult(){ return heatOn('h_repair')?.5:1; }
function mkCost(s){ return Math.round((40*HULLS[s.tpl].cp*s.mk+30)*priceMult()); }
function addXp(ship, n){ const c=ship.cap; c.xp+=Math.round(n*(1+(runFx().xpPct||0)));
  while(c.rank<RANKS.length-1 && c.xp>=RANK_XP[c.rank+1]){ c.rank++; c.pending++; } }
// refits your fleet can actually use: no lance crystals for a fleet without lances, no shield parts for a shieldless one
function modulePool(){ const kit=fleetKit(), all=Object.keys(MODULES), ok=all.filter(m=>!MOD_NEED[m]||kit[MOD_NEED[m]]); return ok.length>=3?ok:all; }
function randomModule(){ return pick(modulePool()); }
function modName(m){ const f=(typeof RUN!=='undefined'&&RUN&&RUN.fac)||'voidsworn'; return (MOD_NAMES[f]&&MOD_NAMES[f][m])||MODULES[m].n; }
function relicName(r){ const f=(typeof RUN!=='undefined'&&RUN&&RUN.fac)||'voidsworn'; return (RELIC_NAMES[f]&&RELIC_NAMES[f][r])||RELICS[r].n; }
function runWord(fac){ return RUN_WORD[fac||(typeof RUN!=='undefined'&&RUN&&RUN.fac)||'voidsworn']||'run'; }
function relicUseful(r){ return !(r==='lattice'&&!fleetKit().shields); } // no shield relic for a shieldless fleet
function randomRelic(){ const pool=Object.keys(RELICS).filter(r=>!RUN.relics.includes(r)&&relicUseful(r)); return pool.length?pick(pool):null; }

// ---------- factions in a campaign ----------
const RUN_FACTIONS=['voidsworn','hegemony','corsair','chorus','ithar','deathless'];
// the hull in a faction's roster closest in strength to a Voidsworn hull; carriers map to carriers
function equivHull(tpl,fac){ if(!fac||fac==='voidsworn'||HULLS[tpl].fac===fac) return tpl; const T=HULLS[tpl]; const ros=((FACTIONS[fac]&&FACTIONS[fac].roster)||[]).filter(h=>HULLS[h]&&!HULLS[h].boss);
  if(!ros.length) return tpl; let pool=T.ab==='launch'?ros.filter(h=>HULLS[h].ab==='launch'):ros; if(!pool.length) pool=ros;
  return pool.reduce((a,h)=>{ const dh=Math.abs(HULLS[h].cp-T.cp), da=Math.abs(HULLS[a].cp-T.cp); return dh<da||(dh===da&&HULLS[h].cp>HULLS[a].cp)?h:a; },pool[0]); } // ties go to the stronger hull
// about one ordinary fight in five comes from a rival faction outside the sector's main enemy
function nodeFaction(n){ const main=RUN.map.fac; if(!RUN.foes||n.type!=='battle') return main; let h=0; for(const ch of String(n.id)+RUN.sector) h=(h*31+ch.charCodeAt(0))>>>0; return h%5===0?RUN.foes[3+(h>>3)%2]:main; }
// ---------- sector map generation ----------
function genSector(s){
  const fac = (RUN&&RUN.foes&&RUN.foes[s-1]) || pick(SECTOR_POOL[s-1]);
  const cols=[]; const COLS=7;
  for(let c=0;c<COLS;c++){
    let n = c===0||c===COLS-1 ? 1 : ri(2,4);
    const col=[];
    for(let i=0;i<n;i++){
      let type;
      if(c===0) type=s>=2?'shipyard':'battle'; /* after a sector boss the fleet docks before its next fight */
      else if(c===COLS-1) type='boss';
      else if(c===COLS-2) type=pick(['shipyard','drydock','field']); // always a rest stop before the boss
      else { const x=rnd(); type = x<.48?'battle':x<.61?'elite':x<.78?'event':x<.9?'shipyard':'drydock'; if(c===1&&(type==='elite'||type==='drydock')) type='battle'; }
      col.push({id:c+'-'+i, col:c, row:i, n, y:(i+.5)/n, type, done:false});
    }
    cols.push(col);
  }
  // the column before the rest stop always offers an elite: a step up before the flagship, for those who want it
  { const c4=cols[COLS-3]; if(!c4.some(n=>n.type==='elite')){ const b=c4.find(n=>n.type==='battle')||c4.find(n=>n.type==='event'); if(b) b.type='elite'; } }
  // guarantee a shipyard in the middle and a rest stop before the boss
  if(!cols[3].some(n=>n.type==='shipyard')) pick(cols[3]).type='shipyard';
  if(!cols[COLS-2].some(n=>n.type==='drydock'||n.type==='shipyard')) cols[COLS-2][0].type='drydock';
  // node budgets: every column before the boss holds a fight, rest stops stay scarce and drydocks only sit before the boss
  for(let c2=1;c2<COLS-2;c2++){ const col=cols[c2];
    if(c2<COLS-2) for(const n of col) if(n.type==='drydock') n.type=rnd()<.5?'battle':'event';
    let rests=col.filter(n=>n.type==='shipyard'||n.type==='drydock'); while(rests.length>1){ rests.pop().type='battle'; rests=col.filter(n=>n.type==='shipyard'||n.type==='drydock'); }
    if(!col.some(n=>n.type==='battle'||n.type==='elite')){ const cand=col.filter(n=>n.type!=='shipyard'&&n.type!=='drydock'); (cand.length?pick(cand):col[col.length-1]).type='battle'; } }
  { const c3=ri(2,COLS-3), col=cols[c3], fights=col.filter(n=>n.type==='battle'||n.type==='elite'); const cand=col.filter(n=>n.type==='event'||(n.type==='battle'&&fights.length>1)); if(cand.length) pick(cand).type='field'; }
  for(const col of cols) for(const n of col) if(n.type==='battle'||n.type==='elite') Object.assign(n,rollEncounter(n.type,n.col)); // shown on the map
  if(typeof RUN!=='undefined'&&RUN) for(const col of cols) for(const n of col) if(n.type==='battle'||n.type==='elite'||n.type==='boss') n.rw=rollNodeReward(n.type);
  // every column after the first offers at least one fight that isn't a plain Engagement, and no two neighbours share a fight type
  for(let c2=1;c2<COLS-1;c2++){ const f=cols[c2].filter(n=>n.type==='battle'||n.type==='elite'); if(f.length&&!f.some(n=>ENC_SPECIAL.includes(n.enc))){ const n=pick(f), e=pick(ENC_SPECIAL); n.enc=e; n.shape=pick(ENCOUNTERS[e].shapes); }
    for(let i=1;i<f.length;i++) if(f[i].enc===f[i-1].enc){ const e=pick(ENC_POOL.filter(x=>x!==f[i].enc)); f[i].enc=e; f[i].shape=pick(ENCOUNTERS[e].shapes); } }
  const edges=[];
  for(let c=0;c<COLS-1;c++){
    const A=cols[c], B=cols[c+1];
    for(const a of A){ const near=[...B].sort((x,y)=>Math.abs(x.y-a.y)-Math.abs(y.y-a.y));
      edges.push([a.id,near[0].id]); if(near[1] && rnd()<.45 && Math.abs(near[1].y-a.y)<.5) edges.push([a.id,near[1].id]); }
    for(const b of B){ if(!edges.some(e=>e[1]===b.id)){ const near=[...A].sort((x,y)=>Math.abs(x.y-b.y)-Math.abs(y.y-b.y))[0]; edges.push([near.id,b.id]); } }
  }
  return {fac, cols, edges};
}

// ---------- progression helpers ----------
function masteryXP(id){ return (META.mastery&&META.mastery[id])||0; }
function masteryLevel(id){ const x=masteryXP(id); let l=0; for(let i=1;i<MASTERY_XP.length;i++) if(x>=MASTERY_XP[i]) l=i; return l; }
function favourOf(p){ return (META.favour&&META.favour[p])||0; }
function favourTier(p){ const f=favourOf(p); let t=0; FAVOUR_TIERS.forEach((x,i)=>{ if(f>=x.at) t=i; }); return t; }
function heatLevel(list){ return (list||[]).reduce((a,k)=>a+((HEAT[k]&&HEAT[k].w)||0),0); }
// an admiral's alternate fleet: split the biggest hull into two mid-size ones, or merge the two smallest into one larger hull
// v41: the alternate fleet keeps the same command points and never loses a carrier (a carrier admiral's passive and Command need one)
function altFleetPlan(admiralId,fac){ const base=ADMIRALS[admiralId].start.map(t=>equivHull(t,fac)), ros=FACTIONS[fac].roster.filter(h=>HULLS[h]&&!HULLS[h].boss&&!HULLS[h].unique);
  const cp=t=>HULLS[t].cp||1, car=t=>HULLS[t].ab==='launch', sum=l=>l.reduce((s,t)=>s+cp(t),0), key=l=>l.slice().sort().join(','), by=c=>ros.filter(h=>!car(h)&&cp(h)===c)[0];
  const need=base.filter(car).length, total=sum(base), nc=base.filter(t=>!car(t)).sort((x,y)=>cp(y)-cp(x)), splits=[], merges=[];
  for(const L of nc){ const c=cp(L); for(let x=Math.ceil(c/2);x<c;x++){ const A=by(x), Bh=by(c-x); if(A&&Bh){ const out=base.slice(); out.splice(out.indexOf(L),1,A,Bh); splits.push(out); } } }
  const sm=nc.slice().reverse(); for(let i=0;i+1<sm.length;i++){ const H=by(cp(sm[i])+cp(sm[i+1])); if(H){ const out=base.slice(); out.splice(out.indexOf(sm[i]),1); out.splice(out.indexOf(sm[i+1]),1,H); merges.push(out); } }
  const big=nc.length&&cp(nc[0])>=4, cands=big?[...splits,...merges]:[...merges,...splits];
  const ok=cands.find(o=>sum(o)===total&&o.filter(car).length>=need&&key(o)!==key(base));
  if(ok) return {fleet:ok,mod:null};
  // nothing to reshuffle (a carrier plus one escort): the carrier gets a hangar expansion instead
  return {fleet:base,mod:need&&MODULES.hangar?'hangar':null}; }
function altFleet(admiralId,fac){ return altFleetPlan(admiralId,fac).fleet; }
// a second Command: the next distinct Command among this faction's admirals
function altCommand(admiralId){ const a=ADMIRALS[admiralId], fac=a.fac||'voidsworn', ids=Object.keys(ADMIRALS).filter(k=>(ADMIRALS[k].fac||'voidsworn')===fac), i=ids.indexOf(admiralId);
  for(let k=1;k<ids.length;k++){ const c=ADMIRALS[ids[(i+k)%ids.length]].cmd; if(c&&a.cmd&&c.id!==a.cmd.id) return c; } return null; }
function newRun(admiralId,fac,opt){
  opt=opt||{}; const adm=ADMIRALS[admiralId]; fac=RUN_FACTIONS.includes(fac)?fac:'voidsworn';
  RUN = {fac, foes:shuffle(RUN_FACTIONS.filter(f=>f!==fac)), admiral:admiralId, credits:120, cpCap:10, sector:1, relics:[], inventory:[], fleet:[], pos:null,
    stats:{battles:0,elites:0,bosses:0,kills:0,lost:0}, t0:Date.now(), fallen:[], ambush:false, over:false, boons:[], patrons:shuffle(Object.keys(PATRONS)).slice(0,4), aspect:null, flagUid:null};
  if(META.unlocked.chest1) RUN.credits+=75; if(META.unlocked.chest2) RUN.credits+=75; if(META.unlocked.chest3) RUN.credits+=75;
  if(META.unlocked.cmd1) RUN.cpCap+=2; if(META.unlocked.cmd2) RUN.cpCap+=2;
  if(META.unlocked.founder){ const r=randomRelic(); if(r) RUN.relics.push(r); }
  RUN.heat=(opt.heat||[]).filter(k=>HEAT[k]); RUN.mastery=masteryLevel(admiralId);
  const plan=opt.alt&&RUN.mastery>=1?altFleetPlan(admiralId,fac):null, start=plan?plan.fleet:adm.start.map(t=>equivHull(t,fac)); RUN.altFleet=!!plan;
  for(const t of start) RUN.fleet.push(newShip(t, !!META.unlocked.vets));
  if(plan&&plan.mod){ const c=RUN.fleet.find(s=>HULLS[s.tpl].ab==='launch'); if(c){ c.mods.push(plan.mod); c.hp=derive(c).maxHp; } }
  if(opt.cmdAlt&&RUN.mastery>=3){ const c=altCommand(admiralId); if(c) RUN.cmdOverride=c; }
  RUN.cpCap=Math.max(RUN.cpCap, fleetCP()+3); ensureFlagship();
  if(RUN.mastery>=4){ const f=flagshipOf(); if(f){ f.mk=Math.max(f.mk||1,2); f.cap.rank=Math.max(f.cap.rank,2); f.cap.xp=Math.max(f.cap.xp,RANK_XP[2]); if(f.cap.perks.length<2) f.cap.perks.push(pick(Object.keys(PERKS).filter(p=>!f.cap.perks.includes(p)))); f.hp=derive(f).maxHp; } }
  // a Devoted patron sends a gift: one common boon from the first devoted patron watching this run
  { const dev=RUN.patrons.find(p=>favourTier(p)>=2); if(dev){ const pool=Object.keys(BOONS).filter(id=>BOONS[id].p===dev&&boonUseful(id,fleetKit())); if(pool.length){ const id=pick(pool); RUN.boons.push({id,r:favourTier(dev)>=3?1:0}); RUN.giftBoon=id; } } }
  RUN.map=genSector(1);
  META.stats.runs++;
  saveRun();
}
function saveRun(){ SAVED_RUN = RUN && !RUN.over ? JSON.parse(JSON.stringify(RUN)) : null; Persist.save(); }
function availableNodes(){
  const m=RUN.map;
  if(!RUN.pos) return m.cols[0].map(n=>n.id);
  return m.edges.filter(e=>e[0]===RUN.pos).map(e=>e[1]);
}
function findNode(id){ for(const c of RUN.map.cols) for(const n of c) if(n.id===id) return n; return null; }
