// driver.js - headless campaign driver for the Monte Carlo harness.
// Appended into the game vm context by shard.js. Everything below calls the
// shipped campaign functions (newRun, genSector via newRun/afterBattle,
// startBattle, finishBattle, rewardFlow and the ACT reward chain, shipyard
// ACT handlers, nextEvent/applyOutcome, the Nemesis functions). The only
// parts written here are: (1) a replication of battleScreen's cfg assembly
// and ACT.enterNode's dispatch, minus all rendering; (2) the bot policies
// (node choice, reward picks, shipyard spending, event choices), each stated
// in the evidence report; (3) statistics recording.
// Snapshot source prices once; every run must start from the same table.
const MC_BASE_HULL_COSTS = Object.fromEntries(Object.entries(HULLS).filter(([,h]) => h.cost != null).map(([id,h]) => [id,h.cost]));
function mcFleetHpFrac(){ if(!RUN||!RUN.fleet.length) return 1; const mx=RUN.fleet.reduce((a,s)=>a+derive(s).maxHp,0); return mx?RUN.fleet.reduce((a,s)=>a+Math.max(0,s.hp),0)/mx:1; }
function mcMissing(){ return RUN.fleet.reduce((a,s)=>a+derive(s).maxHp-s.hp,0); }
function mcFxScore(fx){ if(!fx) return 0; let sc=0; for(const k in fx){ const v=fx[k]; if(!v) continue; sc+=Math.abs(v)*(k.includes('Pct')?30:2); } return sc; }
function mcPickBoon(offer){
  const kit=fleetKit();
  if(offer.every(o=>!boonUseful(o.id,kit))) return -1; // decline only when every offer is useless to this fleet
  let bi=0, bs=-1e9;
  offer.forEach((o,i)=>{ const b=BOONS[o.id]; const sc=(o.r||0)*3+mcFxScore(b.fx(RARITY[o.r||0].m))+(b.duo?2:0)+(b.leg?4:0); if(sc>bs){ bs=sc; bi=i; } });
  return bi;
}
function mcPickMod(opts){ let bm=null, bs=-1e9; for(const m of opts){ const sc=mcFxScore(MODULES[m].fx)+MODULES[m].cost/100; if(sc>bs){ bs=sc; bm=m; } } return bm; }
function mcPickRelic(ids){ let br=ids[0], bs=-1e9; for(const r of ids){ const sc=mcFxScore(RELICS[r].fx)+mcFxScore(RELICS[r].run); if(sc>bs){ bs=sc; br=r; } } return br; }
function mcPickPerk(s){ let bp=s.cap.offer[0], bs=-1e9; for(const p of s.cap.offer){ const sc=mcFxScore(PERKS[p].fx); if(sc>bs){ bs=sc; bp=p; } } return bp; }
function mcPickAspect(offer){ let ba=offer[0], bs=-1e9; for(const k of offer){ const sc=mcFxScore(ASPECTS[k].fx); if(sc>bs){ bs=sc; ba=k; } } return ba; }
function mcAutoFit(m){ const i=RUN.inventory.indexOf(m); if(i<0) return; const s=RUN.fleet.find(x=>x.mods.length<HULLS[x.tpl].slots&&(!MODULES[m].only||HULLS[x.tpl].ab===MODULES[m].only)); if(s) ACT.equip(i+':'+s.uid); }
function mcNodeScore(n){
  const dmg=1-mcFleetHpFrac(); let s=0;
  if(n.type==='elite') s=50; else if(n.type==='boss') s=45; else if(n.type==='battle') s=32;
  else if(n.type==='shipyard') s=26+(RUN.credits>180?8:0); else if(n.type==='event') s=20;
  else if(n.type==='drydock') s=14; else if(n.type==='field') s=14;
  if(dmg>.45){ if(n.type==='drydock') s+=120; else if(n.type==='field') s+=100; else if(n.type==='shipyard') s+=90; else if(n.type==='elite') s-=25; }
  if(n.rw){ if(n.rw.k==='boon') s+=(RUN.boons||[]).filter(b=>BOONS[b.id]&&BOONS[b.id].p===n.rw.p).length<2?9:4;
    else if(n.rw.k==='repair'&&dmg>.2) s+=25; else if(n.rw.k==='cred') s+=3; else if(n.rw.k==='mod') s+=5; }
  return s;
}
function mcChooseNode(avail){ let bid=avail[0], bs=-1e9; for(const id of avail){ const n=findNode(id); if(!n) continue; const sc=mcNodeScore(n); if(sc>bs){ bs=sc; bid=id; } } return bid; }
function mcMaybeVerb(S){ const V=verbFor(); if(!V||!verbCanUse()) return; const free=verbFree(V), c=V.cost||{};
  const ok=free||(!c.cred&&!c.mod&&!c.xp)||(c.cred&&RUN.credits>=300)||(c.mod&&RUN.inventory.length>=2)||(c.xp&&((flagshipOf()||RUN.fleet[0]||{cap:{xp:0}}).cap.xp>=(c.xp+30)));
  if(!ok) return; const lines=useVerb(); if(lines) S.verbUses++; }
// battleScreen's cfg assembly, replicated line for line minus rendering
// (campaign3d.js battleScreen): node seed, garrison reinforcement, encounter,
// map/deployment/objective/shape/archetype/modifier, verb, battle event, and
// prepBattle's rules part (alternating activations on, enemy turn seeded).
function mcSetupBattle(cfg){
  const sn=cfg.node&&findNode(cfg.node);
  if(sn){ nodeSeeds([sn]); if(sn.seed!=null&&cfg.seed==null){ const sd=cfg.eventRelic?((sn.seed^0x27d4eb2f)>>>0):sn.seed; cfg=Object.assign({},cfg,{seed:sd}); rndSeed((sd^0x5bd1e995)>>>0); } }
  if(RUN.fleet.length<=1&&(RUN.reinf||0)<RUN.sector){ RUN.reinf=RUN.sector; RUN.fleet.push(newShip('warden')); }
  const nd=cfg.node&&findNode(cfg.node);
  if(nd&&!nd.enc&&cfg.kind!=='boss'){ Object.assign(nd,rollEncounter(nd.type,nd.col)); if(!nd.map&&RUN.map&&RUN.map.region) nd.map=regionMap(RUN.map.region,nd.col,7); fitEncounter(nd); }
  const ro=cfg.kind==='boss'?bossEncounter():nd&&nd.enc?{enc:nd.enc,shape:nd.shape}:rollEncounter(cfg.kind,cfg.col||1);
  const c=Object.assign({map:(nd&&nd.map)||(RUN.map&&RUN.map.region&&regionMap(RUN.map.region,cfg.kind==='boss'?6:(nd?nd.col:3),7))||(cfg.kind==='boss'&&FAC_MAP[cfg.fac]?FAC_MAP[cfg.fac][0]:'random'),dep:cfg.kind==='boss'?'line':pick(['line','line','flank']),obj:ro.enc,shape:ro.shape,arch:cfg.kind!=='boss'&&nd?nd.arch:null,mod:cfg.kind!=='boss'&&nd?nd.mod:null},cfg);
  if(RUN.verbNext&&!c.verb) c.verb=RUN.verbNext;
  startBattle(c); B.campaign=true;
  B.event=c.nemesis&&NEM_FAC[c.nemesis.fac]&&NEM_FAC[c.nemesis.fac].beh.strike==='reinforce'?Object.assign(rollBattleEvent(c,'reinf_enemy'),{r:3}):rollBattleEvent(c,(sectorCond()||{}).war&&c.kind!=='boss'?(rnd()<.6?'reinf_enemy':'reinf_ally'):null);
  B.alt=true; for(const x of B.units) x.activated=false; startSideTurn('enemy');
  return c;
}
async function mcFight(cfgIn,S,isNem){
  const sec=RUN.sector;
  const nemB=isNem&&RUN.nem?{meeting:S.nem.length+1,s:sec,adaptB:RUN.nem.adapt.length,revB:RUN.nem.revealed.length,fedB:RUN.nem.fed||0}:null;
  mcSetupBattle(cfgIn);
  const rec={s:sec,kind:B.cfg.kind,fac:B.cfg.fac,nem:!!isNem,obj:B.obj?B.obj.type:null,
    pShips:B.units.filter(u=>u.side==='player'&&!u.isSq).length,pCP:B.cp0?B.cp0.player:0,eCP:B.cp0?B.cp0.enemy:0,
    tpl:B.units.filter(u=>u.side==='player'&&!u.isSq).map(u=>u.tpl)};
  const res=await mcBattleLoop();
  rec.rounds=B.round; rec.partial=!!B.partial; rec.res=res;
  rec.lost=B.units.filter(u=>u.side==='player'&&u.ship&&u.dead&&!u.exited).length;
  if(res==='timeout') S.timeouts++;
  S.battles.push(rec);
  // Timeout treatment (stated approximation): a non-boss timeout resolves as a
  // retreat, matching the shipped withdraw flow. A boss timeout resolves as a
  // loss: retreating out of the boss node would complete it and strand the run
  // on the map, a state the shipped game cannot reach (it has no round cap).
  const finRes=res==='timeout'?(B.cfg.kind==='boss'?'loss':'retreat'):res;
  try{ finishBattle(finRes); }catch(e){ S.errors.push('finishBattle: '+(e&&e.message||e)); }
  if(nemB){ nemB.res=res; if(RUN&&RUN.nem){ nemB.adaptA=RUN.nem.adapt.length; nemB.revA=RUN.nem.revealed.length; } S.nem.push(nemB); }
  if(RUN) S.econ.push({at:'postbattle',s:RUN.sector,credits:RUN.credits,ships:RUN.fleet.length,missing:mcMissing(),cp:fleetCP()});
}
function mcRewardStep(S){
  const R=RUN.reward; if(!R) return false;
  if(R.prizes&&R.prizes.length){ const plan=prizePlan(R); for(const row of plan) S.prizePicks.push({tpl:row.p.tpl,k:row.k}); ACT.prizeConfirm(); return true; }
  const ws=window._wrecks||[];
  if(R.stage==='salvage'&&ws.length){ const w=ws[0], y=w.yield; S.salvageOffers.push({tpl:w.tpl,mod:y.mod,cred:y.cred,tow:!!y.tow}); const k=y.mod?'mod':(y.tow?'tow':'cred'); S.salvagePicks.push({tpl:w.tpl,k}); ACT.takeSalvage('0:'+k); return true; }
  if(R.stage==='pick'){
    const rw=window._rw||R.rw||{};
    if(rw.k==='boon'){ ACT.rewardNext(); const off=(RUN.reward&&RUN.reward.boonOffer)||window._boonOffer||[];
      if(off.length){ S.boonOffers.push({p:rw.p,min:rw.min||0,s:RUN.sector,offer:off.map(o=>({id:o.id,r:o.r||0}))});
        const i=mcPickBoon(off); if(i<0){ S.boonDeclines++; ACT.boonDecline(); } else { S.boonPicks.push({id:off[i].id,r:off[i].r||0,p:rw.p}); ACT.takeBoon(i); } }
      return true; }
    if(rw.k==='mod'){ ACT.rewardNext(); const opts=(RUN.reward&&RUN.reward.modOffer)||window._modOffer||[];
      if(opts.length){ S.modOffers.push({offer:opts.slice(),s:RUN.sector,src:'reward'}); const m=mcPickMod(opts); if(m){ S.modPicks.push({id:m,src:'reward'}); ACT.takeMod(m); } }
      return true; }
    ACT.rewardNext(); return true; }
  if(R.stage==='relic'){ const rc=window._relicChoice||[];
    if(rc.length){ S.relicOffers.push({offer:rc.slice(),s:RUN.sector}); const r=mcPickRelic(rc); S.relicPicks.push({id:r}); ACT.takeRelic(r); }
    else relicStep();
    return true; }
  if(R.stage==='promo'){ const s=RUN.fleet.find(x=>x.cap.pending>0);
    if(!s){ promotionsStep(); return true; }
    if(!s.cap.offer) promoteModal(s.uid,promotionsStep);
    if(s.cap.offer){ const p=mcPickPerk(s); S.perkPicks.push({id:p}); ACT.takePerk(s.uid+':'+p); }
    return true; }
  ACT.rewardNext(); return true;
}
function mcShipyard(n,S){
  shipyardScreen(n);
  const st=n.stock, pm=priceMult();
  S.hullOffers.push({offer:st.hulls.slice(),s:RUN.sector});
  S.modOffers.push({offer:st.mods.slice(),s:RUN.sector,src:'yard'});
  const missing=mcMissing(), maxTot=RUN.fleet.reduce((a,s)=>a+derive(s).maxHp,0);
  const prices=[...st.hulls.map(h=>Math.round(HULLS[h].cost*pm)),...st.mods.map(m=>Math.round(MODULES[m].cost*pm)),...RUN.fleet.filter(s=>s.mk<3).map(s=>mkCost(s))].filter(x=>x>0);
  const reg={type:'shipyard',s:RUN.sector,creditsIn:RUN.credits,missing,worstMissing:RUN.fleet.reduce((a,s)=>Math.max(a,derive(s).maxHp-s.hp),0),missingFrac:maxTot?missing/maxTot:0,pm,cheapest:prices.length?Math.min(...prices):0,repairCost:Math.ceil(missing/2*pm),spendRepair:0,spendHull:0,spendMod:0,spendMk:0};
  let c0=RUN.credits; if(missing>0) ACT.repairAll(); reg.spendRepair=c0-RUN.credits;
  for(const h of st.hulls.slice().sort((a,b)=>(HULLS[b].cp||1)-(HULLS[a].cp||1))){
    const t=HULLS[h], cost=Math.round(t.cost*pm);
    if(t.unique&&RUN.fleet.some(s=>s.tpl===h)) continue;
    if(fleetCP()+(t.cp||1)>RUN.cpCap) continue;
    if(RUN.credits-cost<40) continue;
    c0=RUN.credits; ACT.buyHull(h); if(RUN.credits<c0){ reg.spendHull+=c0-RUN.credits; S.hullPicks.push({id:h,s:RUN.sector}); } }
  st.mods.forEach((m,i)=>{ if(st.sold.includes(i)) return; const cost=Math.round(MODULES[m].cost*pm); if(RUN.credits-cost<120) return;
    c0=RUN.credits; ACT.buyMod(i); if(RUN.credits<c0){ reg.spendMod+=c0-RUN.credits; S.modPicks.push({id:m,src:'yard'}); mcAutoFit(m); } });
  const order=[...RUN.fleet].sort((a,b)=>((b.uid===RUN.flagUid?1:0)-(a.uid===RUN.flagUid?1:0))||((HULLS[b.tpl].cp||1)-(HULLS[a.tpl].cp||1)));
  for(const s of order){ if(s.mk>=3) continue; const c=mkCost(s); if(RUN.credits-c<250) continue; c0=RUN.credits; ACT.upgradeMk(s.uid); if(RUN.credits<c0) reg.spendMk+=c0-RUN.credits; }
  reg.creditsOut=RUN.credits; reg.missingOut=mcMissing();
  S.regroups.push(reg);
  ACT.leaveYard();
}
function mcEvent(n,S){
  const ev=nextEvent(); const cur=Object.assign({},ev,(ev.v&&ev.v[RUN.fac])||{});
  const rec={id:ev.id,s:RUN.sector,total:cur.o.length,enabled:0,choice:-1};
  const opts=cur.o.map((o,i)=>({o,i})).filter(x=>eventOptOk(x.o)); rec.enabled=opts.length; S.events.push(rec);
  if(!opts.length){ completeNode(); return {}; }
  const missFrac=1-mcFleetHpFrac();
  const score=x=>{ const r=x.o.r||{}; let v=0;
    v+=(r.cred||0)+(r.xp||0)*2+(r.xpLow||0)+(r.xpTop||0);
    v+=(r.healAll||0)*300*missFrac+(r.repairOne?80*missFrac:0);
    v+=(r.relic?120:0)+((r.mod||r.modId)?60:0)+((r.ship||r.shipRaw)?150:0)+(r.upgradeOne?100:0)+(r.nemIntel?40:0);
    v-=(r.cost||0)+(r.dmgAll||0)*400+(r.dmgOne||0)*150+(r.dmgBig||0)*200+(r.payRelic?130:0)+(r.payXp?50:0)+(r.payMod?60:0)+(r.loseMod?70:0)+(r.gamble?10:0);
    if(r.fight) v+=mcFleetHpFrac()>=.7?60:-200;
    return v; };
  let bx=opts[0], bv=-1e18; for(const x of opts){ const v=score(x); if(v>bv){ bv=v; bx=x; } }
  const o=bx.o; rec.choice=bx.i; eventFlags(cur,o,bx.i);
  if(o.r&&o.r.fight) return {battle:{kind:'elite',fac:o.r.fight,col:n.col+1,node:n.id,eventRelic:true}};
  applyOutcome(o.r||{}); completeNode(); return {};
}
function mcEnterNode(id,S){
  const n=findNode(id); RUN.pos=id; RUN.curNode=id;
  if(n.type==='battle'||n.type==='elite'||n.type==='boss'){
    let kind=n.type, fac=nodeFaction(n);
    if(nemNodeIs(n)){ ensureNemesis(); const fa=nemBeh().fleet; return {battle:Object.assign({kind:'elite',fac:RUN.nem.fac,col:n.col,node:id,nemesis:nemBattleCfg()},ARCHETYPES[fa]?{arch:fa}:{}),nemesis:true}; }
    if(RUN.ambush&&kind==='battle'){ kind='elite'; fac=RUN.fac==='hegemony'?RUN.map.fac:'hegemony'; RUN.ambush=false; }
    return {battle:{kind,fac,col:n.col,node:id}};
  }
  if(n.type==='event') return mcEvent(n,S);
  if(n.type==='shipyard'){ mcShipyard(n,S); return {}; }
  if(n.type==='drydock'){ const cr=RUN.credits, mi=mcMissing(); drydockScreen(n); S.regroups.push({type:'drydock',s:RUN.sector,creditsIn:cr,missing:mi,missingOut:mcMissing()}); return {}; }
  if(n.type==='field'){ fieldRepairs(n); return {}; }
  return {};
}
function mcFreshStats(cfg){ return {fac:cfg.fac,admiral:cfg.admiral,ai:cfg.ai,seed:cfg.seed,won:false,sectorReached:1,timeouts:0,verbUses:0,
  battles:[],nem:[],econ:[],regroups:[],boonOffers:[],boonPicks:[],boonDeclines:0,modOffers:[],modPicks:[],relicOffers:[],relicPicks:[],
  hullOffers:[],hullPicks:[],prizePicks:[],salvageOffers:[],salvagePicks:[],events:[],perkPicks:[],patrons:[],gift:null,finalFleet:[],finalBoons:[],errors:[]}; }
async function mcRunOne(cfg){
  const S=mcFreshStats(cfg);
  try{
    META=defaultMeta(); AI_LEVEL=cfg.ai; SPEED=0;
    for (const [id,cost] of Object.entries(MC_BASE_HULL_COSTS)) HULLS[id].cost = cost;
    if(cfg.priceMult&&cfg.priceMult!==1) for(const id of Object.keys(HULLS)){ const h=HULLS[id]; if(h.cost!=null&&factionOfTpl(id)===cfg.fac) h.cost=Math.max(5,Math.round(h.cost*cfg.priceMult/5)*5); }
    rndSeed(cfg.seed>>>0);
    newRun(cfg.admiral,cfg.fac,{});
    if(cfg.cpDelta) RUN.cpCap+=cfg.cpDelta;
    if(cfg.credMult&&cfg.credMult!==1) RUN.credits=Math.round(RUN.credits*cfg.credMult);
    aspectScreen(); const asp=mcPickAspect(window._aspOffer||[]); if(asp) ACT.pickAspect(asp);
    S.patrons=RUN.patrons.slice(); S.gift=RUN.giftBoon||null;
    S.econ.push({at:'start',s:1,credits:RUN.credits,ships:RUN.fleet.length,missing:0,cp:fleetCP()});
    const wins0=META.stats.wins||0;
    let prevSector=1, guard=0;
    while(RUN&&!RUN.over&&guard++<800){
      if(RUN.sector>prevSector){ const pb=[...S.econ].reverse().find(e=>e.at==='postbattle');
        S.regroups.push({type:'transit',s:prevSector,creditsIn:pb?pb.credits:RUN.credits,missing:pb?pb.missing:0,missingOut:mcMissing(),creditsOut:RUN.credits});
        prevSector=RUN.sector; }
      S.sectorReached=Math.max(S.sectorReached,RUN.sector);
      if(RUN.reward){ mcRewardStep(S); continue; }
      mcMaybeVerb(S);
      const avail=availableNodes();
      if(!avail.length){ S.errors.push('no available nodes, sector '+RUN.sector); break; }
      const step=mcEnterNode(mcChooseNode(avail),S);
      if(step&&step.battle) await mcFight(step.battle,S,step.nemesis);
    }
    if(guard>=800) S.errors.push('run guard exhausted');
    S.won=(META.stats.wins||0)>wins0;
    if(RUN){ S.finalFleet=RUN.fleet.map(s=>s.tpl); S.finalBoons=(RUN.boons||[]).map(b=>b.id); }
    else { const last=[...S.battles].reverse().find(b=>b); S.finalFleet=[]; }
  }catch(e){ S.errors.push('run: '+(e&&e.message||e)); }
  return S;
}
// Direct offer sampler for the boon rarity grid: real rollBoonOffer calls on a
// scaffold run with controlled sector, favour and held boons.
function mcSampleBoons(cfg){
  META=defaultMeta(); SPEED=0;
  rndSeed(cfg.seed>>>0);
  newRun(cfg.admiral||'vex',cfg.fac||'voidsworn',{});
  RUN.sector=cfg.sector; RUN.patrons=[cfg.patron,...Object.keys(PATRONS).filter(p=>p!==cfg.patron).slice(0,3)];
  META.favour={}; META.favour[cfg.patron]=cfg.favourPts||0;
  RUN.boons=[];
  if(cfg.holds==='duo'){ const partner=Object.keys(BOONS).map(id=>BOONS[id]).find(b=>b.duo&&b.duo.includes(cfg.patron));
    if(partner){ const q=partner.duo.find(x=>x!==cfg.patron); const qb=Object.keys(BOONS).find(id=>BOONS[id].p===q&&!BOONS[id].leg); if(qb) RUN.boons.push({id:qb,r:0}); if(!RUN.patrons.includes(q)) RUN.patrons[1]=q; } }
  if(cfg.holds==='two'){ const mine=Object.keys(BOONS).filter(id=>BOONS[id].p===cfg.patron&&!BOONS[id].leg).slice(0,2); for(const id of mine) RUN.boons.push({id,r:0}); }
  const out={patron:{0:0,1:0,2:0,3:0},backfill:{0:0,1:0,2:0,3:0},duo:0,leg:0,offers:0,slots:0};
  for(let i=0;i<cfg.n;i++){ const off=rollBoonOffer(cfg.patron,cfg.minR||0); out.offers++; out.slots+=off.length;
    for(const o of off){ const b=BOONS[o.id]; if(b.duo) out.duo++; else if(b.leg) out.leg++; else if(b.p===cfg.patron) out.patron[o.r||0]++; else out.backfill[o.r||0]++; } }
  return out;
}
var MC={runOne:mcRunOne,sampleBoons:mcSampleBoons};
