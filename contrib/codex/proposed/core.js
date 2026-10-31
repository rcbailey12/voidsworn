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
// B2 (faster battles): one table for presentation pace, read by the game and by sim3d.js's timing model, so the model cannot drift from the game.
// Only animation time changes; rules order and outcomes do not. Lower is faster (a multiplier on SPEED-scaled durations).
const PACE={move:.66, rot:.6, enemy:.5, tail:.38, swarm:.5, skip:.18, banner:380, aiGap:60, aiEnd:90, volley:.5, bigRef:4.5, bigMin:.5};
// volley: a ship's second and later weapons in the same activation play quicker; bigRef/bigMin: enemy pace scales by sqrt(bigRef / enemy ships on board), never below bigMin, so 20-ship fights keep a readable but bounded enemy phase
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
function migrateMeta(m){ { const d=defaultMeta(); for(const k in d) if(k!=='v'&&m[k]==null) m[k]=d[k]; if(typeof m.stats!=='object'||Array.isArray(m.stats)) m.stats=d.stats; for(const k in d.stats) if(typeof m.stats[k]!=='number') m.stats[k]=d.stats[k]||0; } // B1: a null stats or opts in an old save crashed the title screen
  if(!m.v||m.v<2){ m.opts=m.opts||{}; m.tel=m.tel||[]; m.v=2; } m.mastery=m.mastery||{}; m.favour=m.favour||{}; m.variants=m.variants||{}; m.heatBest=m.heatBest||{};
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
  if(r&&(!r.v||r.v<2)){ r.v=2; r.stats=r.stats||{battles:0,elites:0,bosses:0,kills:0}; r.fallen=r.fallen||[]; } return normalizeRun(r); }
// v53: the one place that knows every field a RUN carries. newRun sets the real starting values; this fills anything an older or partial save lacks
function runDefaults(){ return {fac:'voidsworn',foes:null,admiral:'vex',credits:0,cpCap:10,sector:1,relics:[],inventory:[],fleet:[],pos:null,stats:{battles:0,elites:0,bosses:0,kills:0,lost:0},t0:0,fallen:[],ambush:false,over:false,boons:[],patrons:[],aspect:null,flagUid:null,
  heat:[],mastery:0,ransoms:0,altFleet:false,cmdOverride:null,giftBoon:null,reserve:[],seenEvents:[],regionsUsed:[],condsUsed:[],curNode:null,reinf:0,flags:{},nem:null,verbUsed:0,verbNext:null,classTrack:{},boonRerolls:0}; } // B4: event flags, the Nemesis, the faction verb
function normalizeRun(r){ if(!r||typeof r!=='object') return r; const d=runDefaults(); for(const k in d) if(r[k]==null) r[k]=d[k];
  for(const k of ['relics','inventory','fleet','fallen','boons','patrons','heat','reserve','seenEvents','regionsUsed','condsUsed']) if(!Array.isArray(r[k])) r[k]=[];
  if(typeof r.stats!=='object'||Array.isArray(r.stats)) r.stats={}; for(const k in d.stats) if(typeof r.stats[k]!=='number') r.stats[k]=0;
  r.fleet=r.fleet.filter(s=>s&&typeof s==='object'); for(const s of r.fleet){ if(!Array.isArray(s.mods)) s.mods=[]; if(!s.mk) s.mk=1; if(!s.cap||typeof s.cap!=='object') s.cap={fac:r.fac,name:'Captain',xp:0,rank:0,perks:[],pending:0}; if(!Array.isArray(s.cap.perks)) s.cap.perks=[]; }
  return repairRunIds(r); }
// B1 (save-brick class): every id a saved run points at is checked against today's tables. A renamed or removed id is dropped
// or reset to a safe default instead of crashing the map, the fleet screen or the run summary. Each repair is listed in r._repairs
// so the player is told on Continue, and a dropped ship keeps a raw copy of the old save (STORE_KEY+'.repaired').
function repairRunIds(r){ if(!r||typeof r!=='object'||r.none) return r; const rep=[], has=(T,k)=>typeof T!=='undefined'&&k!=null&&Object.prototype.hasOwnProperty.call(T,k);
  const keep=(arr,T,kind,get)=>arr.filter(x=>{ const id=get?get(x):x; if(has(T,id)) return true; unknownId(kind,id); rep.push(kind+' '+String(id).slice(0,40)); return false; });
  if(!has(FACTIONS,r.fac)){ rep.push('faction '+r.fac); r.fac='voidsworn'; }
  if(!has(ADMIRALS,r.admiral)){ const a=Object.keys(ADMIRALS).find(k=>(ADMIRALS[k].fac||'voidsworn')===r.fac)||'vex'; rep.push('admiral '+String(r.admiral).slice(0,40)); unknownId('admiral',r.admiral); r.admiral=a; }
  if(r.foes!=null&&!Array.isArray(r.foes)) r.foes=null; if(Array.isArray(r.foes)&&r.foes.some(f=>!has(FACTIONS,f))){ rep.push('sector foes'); r.foes=null; }
  r.relics=keep(r.relics,RELICS,'relic'); r.inventory=keep(r.inventory,MODULES,'refit'); r.heat=keep(r.heat,HEAT,'heat');
  r.boons=keep(r.boons.filter(b=>b&&typeof b==='object'),BOONS,'boon',b=>b.id); r.patrons=keep(r.patrons,PATRONS,'patron');
  if(r.aspect!=null&&!has(ASPECTS,r.aspect)){ rep.push('aspect '+r.aspect); unknownId('aspect',r.aspect); r.aspect=null; }
  if(r.giftBoon!=null&&!has(BOONS,r.giftBoon)){ unknownId('boon',r.giftBoon); r.giftBoon=null; }
  const capFix=c=>{ if(!c||typeof c!=='object') return {fac:r.fac,name:'Captain',xp:0,rank:0,perks:[],pending:0}; if(typeof c.name!=='string'||!c.name.trim()) c.name='Captain';
    if(!Array.isArray(c.perks)) c.perks=[]; c.perks=keep(c.perks,PERKS,'perk'); if(typeof c.xp!=='number') c.xp=0; if(typeof c.rank!=='number') c.rank=0; if(typeof c.pending!=='number') c.pending=0; if(!c.fac) c.fac=r.fac; return c; };
  const before=r.fleet.length; r.fleet=keep(r.fleet,HULLS,'ship hull',s=>s.tpl);
  for(const s of r.fleet){ s.cap=capFix(s.cap); s.mods=keep(s.mods,MODULES,'refit'); if(typeof s.name!=='string') s.name=HULLS[s.tpl].n; if(typeof s.hp!=='number'||!(s.hp>0)) s.hp=1; }
  r.reserve=r.reserve.filter(x=>x&&typeof x==='object').map(x=>(x.cap=capFix(x.cap),x)); r.fallen=r.fallen.filter(f=>f&&typeof f==='object'&&typeof f.name==='string');
  if(r.flagUid!=null&&!r.fleet.some(s=>s.uid===r.flagUid)) r.flagUid=null;
  if(!Number.isFinite(r.credits)){ rep.push('credits'); r.credits=0; } // B1 (B-5): a save whose credits went NaN from selling a captured flagship
  if(r.reward!=null){ const R=r.reward; if(typeof R!=='object'||Array.isArray(R)) r.reward=null; else { // B1: a pending reward chain from an older save is checked like the rest
    if(!['prize','salvage','pick','relic','promo'].includes(R.stage)) R.stage='promo'; R.prizes=Array.isArray(R.prizes)?R.prizes.filter(p=>p&&typeof p==='object'&&has(HULLS,p.tpl)):[]; if(!R.rw||typeof R.rw!=='object') R.rw={};
    R.relics=Array.isArray(R.relics)?keep(R.relics,RELICS,'relic'):[]; R.wrecks=Array.isArray(R.wrecks)?R.wrecks.filter(w=>w&&typeof w==='object'&&w.yield&&typeof w.yield==='object'):[];
    for(const w of R.wrecks){ if(w.yield.mod!=null&&!has(MODULES,w.yield.mod)) w.yield.mod=null; if(!has(HULLS,w.tpl)) w.yield.tow=false; }
    if(R.boonOffer!=null&&(!Array.isArray(R.boonOffer)||R.boonOffer.some(o=>!o||!has(BOONS,o.id)))) R.boonOffer=null;
    if(R.modOffer!=null&&(!Array.isArray(R.modOffer)||R.modOffer.some(m=>!has(MODULES,m)))) R.modOffer=null; } }
  if(r.fleet.length<before) r._shipsDropped=(r._shipsDropped||0)+(before-r.fleet.length);
  if(rep.length) r._repairs=(Array.isArray(r._repairs)?r._repairs:[]).concat(rep).slice(-20);
  return r; }
// v53: a save is only trusted when its run has a fleet array and a map, and its meta is a plain object with the expected containers
function saneMeta(m){ if(!m||typeof m!=='object'||Array.isArray(m)) return false; for(const k of ['unlocked','admirals','stats','opts','mastery','favour','variants','heatBest']) if(m[k]!=null&&(typeof m[k]!=='object'||Array.isArray(m[k]))) return false; for(const k of ['tel','fallen']) if(m[k]!=null&&!Array.isArray(m[k])) return false; return m.renown==null||typeof m.renown==='number'; }
function saneRun(r){ return r==null||!!r.none||(typeof r==='object'&&Array.isArray(r.fleet)&&!!r.map&&Array.isArray(r.map.cols)); }
function saneSave(o){ return !!o&&typeof o==='object'&&!Array.isArray(o)&&(o.meta==null||saneMeta(o.meta))&&saneRun(o.run); }
// a renamed module, perk or relic id in an old save is logged once and skipped instead of throwing
const UNKNOWN_IDS=new Set(); function unknownId(kind,id){ const k=kind+':'+id; if(!UNKNOWN_IDS.has(k)){ UNKNOWN_IDS.add(k); try{ console.warn('Unknown '+kind+' id skipped:',id); if(typeof tel==='function') tel('unknown_id',{kind,id:String(id).slice(0,40)}); }catch(e){} } return null; }
let META = defaultMeta();
let SAVED_RUN = null;
let onPersistLoaded = ()=>{};
const Persist = {
  db:null, uid:null, writing:false, pending:false,
  loadLocal(){ let s=null, o=null; try{ s=localStorage.getItem(STORE_KEY); }catch(e){} try{ if(s) o=JSON.parse(s); }catch(e){ o=null; } // v41: a damaged save falls back to the backup copy
    if(s&&!saneSave(o)){ try{ const b=localStorage.getItem(STORE_KEY+'.bak'), ob=b?JSON.parse(b):null; if(saneSave(ob)){ o=ob; this.recovered=true; } }catch(e){} } // v53: a save that parses but is malformed (fleet not an array, broken meta) also falls back
    if(o&&typeof o==='object'&&!saneSave(o)){ if(!saneRun(o.run)) o.run=null; if(o.meta!=null&&!saneMeta(o.meta)) o.meta=null; } // no good backup either: keep whichever half is sound
    try{ if(o&&typeof o==='object'){
      if(o.meta){ META=migrateMeta(Object.assign(defaultMeta(),o.meta)); if(typeof mergeLocalTel==='function') mergeLocalTel(); } SAVED_RUN=migrateRun((o.run&&!o.run.none)?o.run:null);
      if(SAVED_RUN&&SAVED_RUN._repairs&&s){ try{ if(!localStorage.getItem(STORE_KEY+'.repaired')) localStorage.setItem(STORE_KEY+'.repaired',s); }catch(e){} } } }catch(e){ try{ if(s&&!localStorage.getItem(STORE_KEY+'.repaired')) localStorage.setItem(STORE_KEY+'.repaired',s); }catch(_){} console.warn('Save could not be loaded; raw copy kept as '+STORE_KEY+'.repaired',e); } }, // B1: an old save that needed repairs, or failed to load, is kept raw, never silently lost
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
        if(!saneSave(d)){ console.warn('Cloud save malformed; keeping this device\'s save'); if(META.updated) this.push(); return; }
        // v53: meta (unlocks, renown, settings) and the run resolve on separate stamps, so a purchase or a report on one device never rolls back a newer run from another
        const rm = d.meta||{}, lRunAt=META.runAt||META.updated||0, rRunAt=rm.runAt||rm.updated||0, lRun=SAVED_RUN;
        const takeMeta=(rm.updated||0) > (META.updated||0), takeRun=rRunAt > lRunAt;
        if(takeMeta||takeRun){
          if(takeMeta){ META = migrateMeta(Object.assign(defaultMeta(), rm)); if(typeof mergeLocalTel==='function') mergeLocalTel(); }
          if(takeRun){ SAVED_RUN = migrateRun((d.run && !d.run.none) ? d.run : null); META.runAt=rRunAt; } else { SAVED_RUN=lRun; META.runAt=lRunAt; }
          this.saveLocal(); onPersistLoaded();
        }
        if((!takeMeta&&(META.updated||0) > (rm.updated||0)) || (!takeRun&&lRunAt > rRunAt)) this.push();
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
  // v53: a run write stamps both meta and run; {meta:true} (purchases, problem reports) stamps meta only. Telemetry, error and stall paths call saveLocal() and stamp nothing
  save(opt){ const now=Date.now(); META.updated=now; if(!(opt&&opt.meta)) META.runAt=now; this.saveLocal(); this.push(); }
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
// reserved (customization, schema only): a ship's fit, {pod, module, trim} or null; nothing applies it yet
function shipFit(ship){ return (ship&&ship.fit)||null; }
function newShip(tpl, vet){ const fac=factionOfTpl(tpl); const s={uid:newId(), tpl, name:shipName(fac), mk:1, hp:0, mods:[], cap:newCaptain(vet,fac)}; s.hp=derive(s).maxHp; return s; }

function sumFx(list){const o={}; for(const fx of list){ if(!fx) continue; for(const k in fx) o[k]=(o[k]||0)+fx[k]; } return o;}
function fleetFxList(){ const l=[]; if(RUN){ for(const r of RUN.relics) if(RELICS[r]?RELICS[r].fx:unknownId('relic',r)) l.push(RELICS[r].fx); if(ADMIRALS[RUN.admiral]) l.push(ADMIRALS[RUN.admiral].fx); for(const b of (RUN.boons||[])) if(BOONS[b.id]) l.push(BOONS[b.id].fx(RARITY[b.r||0].m)); } return l; }
// ---------- patrons and boons ----------
function ensurePatrons(){ if(!RUN) return; if(!RUN.patrons||!RUN.patrons.length) RUN.patrons=shuffle(Object.keys(PATRONS)).slice(0,4); if(!RUN.boons) RUN.boons=[]; }
function hasBoon(id){ return !!(RUN&&RUN.boons&&RUN.boons.some(b=>b.id===id)); }
function boonPatrons(){ return new Set((RUN&&RUN.boons||[]).map(b=>BOONS[b.id]&&BOONS[b.id].p).filter(Boolean)); }
function rollRarity(minR,s,p){ const ft=p?favourTier(p):0, x=rnd(), rare=.24+.06*((s||1)-1)+(ft>=1?.12:0), epic=.06+.03*((s||1)-1)+(ft>=1?.03:0); let r=x<epic?2:x<epic+rare?1:0; if(ft>=3) r=Math.max(r,1); return Math.max(minR||0,r); }
// three boons from one patron; a duo boon can take a slot once you hold boons from both of its patrons
function fleetKit(){ const k={}; for(const sh of (RUN&&RUN.fleet)||[]){ const d=derive(sh); for(const w of d.weapons){ if(w.k==='torp') k.torp=1; if(w.k==='lance') k.lance=1; if(w.k==='battery') k.batt=1; if(w.k==='flak') k.flak=1; if(w.arc==='P'||w.arc==='S') k.broad=1; if(w.arc==='P'||w.arc==='S'||w.k==='battery') k.still=1; } if((HULLS[sh.tpl].sh||0)>0) k.shields=1; if(HULLS[sh.tpl].hangar) k.carrier=1; if(d.hangar) k.sq=1; } return k; }
function boonUseful(id,kit){ const n=BOON_NEED[id]; return !n||!!kit[n]; }
function rollBoonOffer(p,minR){ ensurePatrons(); const s=(RUN&&RUN.sector)||1, have=boonPatrons(), kit=fleetKit();
  let pool=Object.keys(BOONS).filter(id=>BOONS[id].p===p&&!BOONS[id].leg&&!hasBoon(id)); pool=shuffle(pool); const junk=pool.filter(id=>!boonUseful(id,kit)); pool=pool.filter(id=>boonUseful(id,kit));
  const duos=Object.keys(BOONS).filter(id=>{ const b=BOONS[id]; return b.duo&&!hasBoon(id)&&boonUseful(id,kit)&&b.duo.includes(p)&&b.duo.every(q=>have.has(q)||q===p)&&b.duo.some(q=>q!==p&&have.has(q)); });
  const out=pool.slice(0,3).map(id=>({id,r:rollRarity(minR,s,p)}));
  if(duos.length&&(out.length<3||rnd()<.45)){ const d={id:pick(duos),r:0}; if(out.length>=3) out[2]=d; else out.push(d); }
  if(out.length<3){ const extra=shuffle(Object.keys(BOONS).filter(id=>BOONS[id].p&&!BOONS[id].leg&&BOONS[id].p!==p&&RUN.patrons.includes(BOONS[id].p)&&!hasBoon(id)&&boonUseful(id,kit)&&!out.some(o=>o.id===id))); while(out.length<3&&extra.length) out.push({id:extra.pop(),r:rollRarity(minR,s)}); while(out.length<3&&junk.length) out.push({id:junk.pop(),r:rollRarity(minR,s)}); }
  { const L=legendaryFor(p,minR); if(L){ if(out.length>=3) out[2]={id:L,r:3}; else out.push({id:L,r:3}); } } // B4 step 3: the patron's legendary, at elite and flagship rewards, once you hold two of its boons
  return out; }
function legendaryFor(p,minR){ if(!(minR>=1)) return null; const L=Object.keys(BOONS).find(id=>BOONS[id].leg&&BOONS[id].p===p); if(!L||hasBoon(L)||!boonUseful(L,fleetKit())) return null; const n=(RUN.boons||[]).filter(b=>BOONS[b.id]&&BOONS[b.id].p===p&&!BOONS[b.id].leg).length; return n>=2?L:null; }
// what a map node pays out: usually a patron's boon (its sigil shows on the map), sometimes a refit, credits or repairs
function rollNodeReward(type){ ensurePatrons(); const p=pick(RUN.patrons); if(type==='elite'||type==='boss') return {k:'boon',p,min:1}; const x=rnd(); return x<.62?{k:'boon',p}:x<.78?{k:'mod'}:x<.9?{k:'cred'}:{k:'repair'}; }
function flagshipOf(){ return RUN&&RUN.fleet&&RUN.fleet.find(s=>s.uid===RUN.flagUid); }
function shipValue(tpl){ const H=HULLS[tpl]; return H&&Number.isFinite(H.cost)?H.cost:40*((H&&H.cp)||1); } // B1: hulls with no shop price (bosses, variants) still have a value, so selling never makes credits NaN
function prizeScrap(tpl){ return Math.round(shipValue(tpl)*.35); }
function ensureFlagship(){ if(!RUN||!RUN.fleet||!RUN.fleet.length) return null; if(!flagshipOf()){ const f=[...RUN.fleet].sort((a,b)=>(HULLS[b.tpl].cp||1)-(HULLS[a.tpl].cp||1)||derive(b).maxHp-derive(a).maxHp)[0]; RUN.flagUid=f.uid; return f; } return flagshipOf(); }
function runFx(){ const o={}; if(RUN) for(const r of RUN.relics){ const x=RELICS[r]?RELICS[r].run:unknownId('relic',r); if(x) for(const k in x) o[k]=(o[k]||0)+x[k]; } if(RUN && META.unlocked.salvagers) o.credPct=(o.credPct||0)+.2; return o; }
function mkWeapon(id,arc,fx){ const b=W[id]; const w=Object.assign({id,arc},b); w.cd=b.cd||0;
  if(b.k==='battery'&&fx.battShots) w.shots+=fx.battShots;
  if(b.k==='flak'&&fx.flakPlus){ w.shots+=2*fx.flakPlus; w.r+=fx.flakPlus; w.opt+=fx.flakPlus; }
  if(b.k==='torp'&&fx.torpCd) w.cd=Math.max(1,w.cd-fx.torpCd);
  if(arc==='F'&&fx.prowRange){ w.r+=fx.prowRange; w.opt+=fx.prowRange; }
  if(b.k==='lance'&&fx.lanceRange){ w.r+=fx.lanceRange; w.opt+=fx.lanceRange; } // Long Silence, Epic
  return w; }
function derive(ship){
  const t=HULLS[ship.tpl];
  const asp=RUN&&RUN.aspect&&ship.uid===RUN.flagUid&&ASPECTS[RUN.aspect]?[ASPECTS[RUN.aspect].fx]:[];
  const fx=sumFx([...fleetFxList(), ...ship.mods.map(m=>MODULES[m]?MODULES[m].fx:unknownId('module',m)), ...ship.cap.perks.map(p=>PERKS[p]?PERKS[p].fx:unknownId('perk',p)), ...asp]);
  const mk=ship.mk||1, mm=1+.2*(mk-1), tr=classTrack(t.cls); // B4 step 3: the shared class refit track adds 6% hull and 6% damage per level
  const maxHp=Math.round(t.hp*mm*(1+(fx.hpPct||0)+.06*tr));
  return {
    maxHp, shMax:Math.round(t.sh*mm*(1+(fx.shPct||0))), regen:Math.round(t.rg*mm*(1+(fx.regenPct||0))),
    armor:Math.min(.6,t.ar+(fx.armor||0)), speed:t.sp+(fx.speed||0), turns:t.tn+(fx.turns||0), ev:t.ev+(fx.ev||0),
    aim:fx.aim||0, crit:fx.crit||0, dmg:1+.15*(mk-1)+(fx.dmgPct||0)+.06*tr, fx,
    hangar:t.hangar?t.hangar+(fx.hangar||0)+(fx.hive||0):(fx.hive||0),
    hullRegen:(fx.hullRegen||0)+Math.round((fx.hullRegenPct||0)*maxHp)+Math.round((t.regen||0)*mm),
    weapons:nameWeapons(t.fac,t.w.map(([id,arc])=>mkWeapon(id,arc,fx))),
  };
}
// B4 step 3: shared refit tracks per class, bought at shipyards; every ship of that class gains, now and later (RUN.classTrack[cls] 0..3)
const CLASS_TRACK_MAX=3;
function classTrack(cls){ return (typeof RUN!=='undefined'&&RUN&&RUN.classTrack&&RUN.classTrack[cls])||0; }
function classTrackCost(cls){ return Math.round((60+50*classTrack(cls))*priceMult()); }
function buyClassTrack(cls){ if(!RUN||classTrack(cls)>=CLASS_TRACK_MAX) return false; const c=classTrackCost(cls); if(RUN.credits<c) return false; RUN.credits-=c; changeFleet(()=>{ RUN.classTrack=RUN.classTrack||{}; RUN.classTrack[cls]=classTrack(cls)+1; }); return true; }
function changeShip(ship, fn){ const before=derive(ship).maxHp; fn(ship); const after=derive(ship).maxHp; ship.hp=clamp(ship.hp+(after-before),1,after); }
function changeFleet(fn){ const b=RUN.fleet.map(s=>derive(s).maxHp); fn(); RUN.fleet.forEach((s,i)=>{ const a=derive(s).maxHp; s.hp=clamp(s.hp+(a-b[i]),1,a); }); }
function fleetCP(){ return RUN.fleet.reduce((a,s)=>a+HULLS[s.tpl].cp,0); }
function priceMult(){ const c=sectorCond(); return (META.unlocked.wrights?.85:1)*(heatOn('h_coffers')?1.25:1)*((c&&c.price)||1); }
function heatOn(k){ return !!(typeof RUN!=='undefined'&&RUN&&RUN.heat&&RUN.heat.includes(k)); }
function repairMult(){ const c=sectorCond(); return (heatOn('h_repair')?.5:1)*((c&&c.repair)||1); }
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
  { const c4=cols[COLS-3]; if(!c4.some(n=>n.type==='elite')){ const b=c4.find(n=>n.type==='battle')||c4.find(n=>n.type==='event')||c4.find(n=>n.type==='shipyard'||n.type==='drydock'); if(b) b.type='elite'; } }
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
  // fleet archetypes and node modifiers on ordinary fights (bosses keep their own escort)
  for(const col of cols) for(const n of col) if(n.type==='battle'||n.type==='elite'){ const x=rnd(); n.arch=x<.25?'swarm':x<.47?'heavy':x<.62?'carrier':null; const y=rnd(); n.mod=n.col>=2&&y<.14?'bounty':n.col>=2&&n.type==='battle'&&y<.26?'veteran':null; }
  // one condition per sector, never the same twice in a run
  let cond=null; try{ const used=(RUN&&RUN.condsUsed)||[], pool=Object.keys(SECTOR_CONDS).filter(k=>!used.includes(k)); cond=pick(pool.length?pool:Object.keys(SECTOR_CONDS)); if(RUN){ RUN.condsUsed=used.concat(cond); } }catch(e){ cond=null; }
  let region=null; try{ region=pickRegion(fac); for(const col of cols) for(const n of col){ n.map=regionMap(region,n.col,COLS); fitEncounter(n); } }catch(e){ region=null; }
  let biome=null; try{ biome=rollBiome(region); }catch(e){}
  return {fac, cols, edges, cond, region, biome};
}
function sectorCond(){ try{ const k=typeof RUN!=='undefined'&&RUN&&RUN.map&&RUN.map.cond; return k&&SECTOR_CONDS[k]?SECTOR_CONDS[k]:null; }catch(e){ return null; } }

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
  { const dev=RUN.patrons.find(p=>favourTier(p)>=2); if(dev){ const pool=Object.keys(BOONS).filter(id=>BOONS[id].p===dev&&!BOONS[id].leg&&boonUseful(id,fleetKit())); if(pool.length){ const id=pick(pool); RUN.boons.push({id,r:favourTier(dev)>=3?1:0}); RUN.giftBoon=id; } } }
  RUN.map=genSector(1);
  RUN.flags={}; if(typeof newNemesis==='function') RUN.nem=newNemesis(); // B4: one named enemy commander per run
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
