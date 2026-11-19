// driver_ge.js - headless campaign driver for issue 1086.
// Glasswright (ithar) and Eclipse (deathless) economy ideas measured against
// today's credits economy. The shipped game files are loaded read only by
// loader_main.js; every economy change below lives in memory in this file and
// is never written back to disk.
//
// Copied from the issue 1085 Chorus harness (contrib/deepseek/chorus_biomass_1118)
// so the same campaign bot, the same node policies and the same measures apply.
// The biomass layer is removed; a Glasswright / Eclipse patch layer is added.
//
// WC_GE flags (all off in a "today" setup):
//   kiln        G-A simplest form: at a shipyard (a kiln) each ship's first
//               15 percent of max hull of missing hull is repaired free; the
//               rest pays today's shipyard price (1 credit per 2 hull).
//   cullet      G-B simplest form: on a win, the fleet's own lost Glasswright
//               hulls pay a fixed-by-class credit refund, capped per battle.
//   commission  G-C simplest form: a hull bought at a shipyard is paid up front
//               and arrives one completed node later, one commission at a time.
//               The one-order limit is enforced at the purchase point by
//               mcCommissionCanOrder (sim/commission_policy.js), not only by the
//               shipyard loop's earlier commBusy check.
//   slots       E-A simplest form: Archive slots bought with credits at a
//               shipyard (Archive node) for a flat 45 credits, capped at two in
//               the fleet. A ship that held a slot and was destroyed returns at
//               the next Archive node as a fresh standard hull of its class at
//               Mk 1, no refits, for a rebuild price of 40 percent of its shop
//               value. The copy is cheap, the body costs.
//   core        E-B simplest form: a win that cost ships banks one core (one
//               per battle) and one un-slotted lost hull; at the next Archive
//               node a core plus a rebuild price of 20 percent of its shop
//               value restores that hull at Mk 1, no refits. A loss or retreat
//               recovers no core.
//
// Everything else (rewardFlow, drydock, field repairs, the post-win patch, the
// in-battle Archive restore, the faction verbs, the price ladder) is the
// shipped code, untouched.
const MC_BASE_HULL_COSTS = {};
for (const id of Object.keys(HULLS)) MC_BASE_HULL_COSTS[id] = HULLS[id].cost;
function mcRestoreBaseHullCosts(){ for (const id of Object.keys(HULLS)) { if (id in MC_BASE_HULL_COSTS) HULLS[id].cost = MC_BASE_HULL_COSTS[id]; } }

var MC_SETUP='baseline', MC_LAST_INCOME=null, MC_NODE_TICK=0;
var MC_GE={kiln:false,cullet:false,commission:false,slots:false,core:false};
var MC_GE_CONST={
  hairlinePct:0.15,
  culletRate:{Frigate:15,Destroyer:30,Cruiser:45,Carrier:50,Battleship:60,default:20},
  culletCap:60,
  slotFlat:45,
  slotRestorePct:0.4,
  slotCap:2,
  corePct:0.2,
};
function mcGeReset(cfg){
  MC_GE=Object.assign({kiln:false,cullet:false,commission:false,slots:false,core:false},(cfg&&cfg.ge)||{});
  MC_GE_CONST=Object.assign({},MC_GE_CONST,(cfg&&cfg.geConst)||{});
}
function mcCanField(tpl){ const t=HULLS[tpl]; if(!t) return false; return fleetCP()+(t.cp||1)<=RUN.cpCap; }

// ---- income recording: the shipped rewardFlow, observed only ----
const _mcOrigRewardFlow = rewardFlow;
rewardFlow = function(summary){
  const cfg=summary.cfg, s=RUN.sector, rf=runFx(), scnd=sectorCond();
  const kindMult=cfg.kind==='boss'?3:cfg.kind==='elite'?1.6:1;
  let flat=Math.round((25+12*s+3*(cfg.col||0))*kindMult*(1+(rf.credPct||0)+((scnd&&scnd.cred)||0)));
  if(cfg.mod==='bounty') flat=Math.round(flat*1.5);
  if(summary.partial) flat=Math.round(flat/2);
  _mcOrigRewardFlow(summary);
  MC_LAST_INCOME={flat:flat,total:flat,kills:summary.kills||0,partial:!!summary.partial,kind:cfg.kind,sector:s,currency:'credits'};
};

// ---- final snapshot: endRun clears RUN at the very end ----
var MC_END_SNAPSHOT=null;
const _mcOrigEndRun = endRun;
endRun = function(victory, abandoned){
  if(RUN && !RUN.over){ const wp=mcWorstPair(RUN.fleet); MC_END_SNAPSHOT={sector:RUN.sector,ships:RUN.fleet.length,
    hull:RUN.fleet.reduce((a,s)=>a+Math.max(0,s.hp),0),maxHull:RUN.fleet.reduce((a,s)=>a+derive(s).maxHp,0),
    worst:wp.worst,worstMax:wp.worstMax,credits:RUN.credits,fleet:RUN.fleet.map(s=>s.tpl)}; }
  return _mcOrigEndRun(victory, abandoned);
};

// ---- node tick: one jump is one completed node ----
const _mcOrigCompleteNode = completeNode;
completeNode = function(){
  _mcOrigCompleteNode();
  MC_NODE_TICK++;
  mcDeliverCommissions();
};
function mcDeliverCommissions(){
  if(!RUN||RUN.over) return;
  const q=RUN.commQueue||[];
  for(let i=0;i<q.length;){
    const c=q[i];
    if(MC_NODE_TICK>=c.arriveAt && mcCanField(c.tpl)){
      RUN.fleet.push(newShip(c.tpl));
      q.splice(i,1);
      ensureFlagship();
    } else i++;
  }
}

// ---- Glasswright G-C: a bought hull arrives after one jump ----
function mcGeBuyHull(h,S){
  const t=HULLS[h]; if(!t) return false;
  const cost=Math.round(t.cost*priceMult());
  if(MC_GE.commission&&!mcCommissionCanOrder((RUN.commQueue||[]).length,RUN.credits,cost,fleetCP(),(t.cp||1),RUN.cpCap)) return false;
  if(RUN.credits<cost||!mcCanField(h)) return false;
  RUN.credits-=cost;
  if(MC_GE.commission){
    RUN.commQueue=RUN.commQueue||[];
    RUN.commQueue.push({tpl:h,arriveAt:MC_NODE_TICK+2});
    if(S) S.commissionsStarted=(S.commissionsStarted||0)+1;
  } else {
    RUN.fleet.push(newShip(h));
    if(S) S.hullsBought=(S.hullsBought||0)+1;
  }
  return true;
}

// ---- Glasswright G-A: kiln repair with a free hairline floor ----
function mcKilnRepairAll(reg,pm){
  let total=0;
  for(const s of RUN.fleet){
    const d=derive(s), miss=d.maxHp-s.hp;
    if(miss<=0) continue;
    const free=Math.floor(d.maxHp*MC_GE_CONST.hairlinePct);
    const paid=Math.max(0,miss-free);
    total+=Math.ceil(paid/2*pm);
  }
  const c0=RUN.credits;
  if(RUN.credits>=total){ RUN.credits-=total; RUN.fleet.forEach(s=>{ s.hp=derive(s).maxHp; }); }
  if(reg) reg.spendRepair=c0-RUN.credits;
}

// ---- Glasswright G-B: cullet refund from your own losses on a win ----
function mcCulletValue(tpl){
  const H=HULLS[tpl]; const cls=H&&H.cls; const R=MC_GE_CONST.culletRate;
  return (cls&&R[cls])||R.default||0;
}
function mcRefundCullet(lost,S){
  let sum=0;
  for(const l of lost) sum+=mcCulletValue(l.tpl);
  const v=Math.min(MC_GE_CONST.culletCap,sum);
  if(v>0){ RUN.credits+=v; if(S) S.culletEarned=(S.culletEarned||0)+v; }
}

// ---- Eclipse E-A / E-B: queue the dead, restore at the next Archive stop ----
function mcQueueRestores(lost,finRes,ended,S){
  if(ended||!RUN) return;
  const win=finRes==='win';
  if(MC_GE.cullet&&RUN.fac==='ithar'&&win&&lost.length) mcRefundCullet(lost,S);
  if(MC_GE.slots&&RUN.fac==='deathless'){
    for(const l of lost){
      if(!l.archiveSlot) continue;
      RUN.pendingRestore=RUN.pendingRestore||[];
      RUN.pendingRestore.push({tpl:l.tpl,kind:'slot'});
      if(S) S.slotRestoresQueued=(S.slotRestoresQueued||0)+1;
    }
  }
  if(MC_GE.core&&RUN.fac==='deathless'&&win){
    const un=lost.filter(l=>!l.archiveSlot);
    if(un.length){
      RUN.cores=(RUN.cores||0)+1;
      RUN.coreBodies=RUN.coreBodies||[];
      un.sort((a,b)=>shipValue(b.tpl)-shipValue(a.tpl));
      RUN.coreBodies.push(un[0].tpl);
      if(S) S.coresEarned=(S.coresEarned||0)+1;
    }
  }
}
function mcArchiveStep(S){
  if(!RUN||RUN.over) return;
  if(MC_GE.slots&&RUN.fac==='deathless'){
    const pend=RUN.pendingRestore||[];
    for(let i=0;i<pend.length;){
      const r=pend[i];
      const price=Math.round(shipValue(r.tpl)*MC_GE_CONST.slotRestorePct/5)*5;
      if(mcCanField(r.tpl)&&RUN.credits>=price){
        RUN.credits-=price; RUN.fleet.push(newShip(r.tpl)); pend.splice(i,1); ensureFlagship();
        if(S){ S.slotRestored=(S.slotRestored||0)+1; S.slotRestoreSpend=(S.slotRestoreSpend||0)+price; }
      } else i++;
    }
  }
  if(MC_GE.core&&RUN.fac==='deathless'){
    const bodies=RUN.coreBodies||[];
    while((RUN.cores||0)>0&&bodies.length){
      const tpl=bodies[0], price=Math.round(shipValue(tpl)*MC_GE_CONST.corePct/5)*5;
      if(RUN.credits>=price&&mcCanField(tpl)){
        RUN.credits-=price; RUN.cores--; bodies.shift(); RUN.fleet.push(newShip(tpl)); ensureFlagship();
        if(S) S.coreRestored=(S.coreRestored||0)+1;
      } else break;
    }
  }
  if(MC_GE.slots&&RUN.fac==='deathless'){
    const cap=MC_GE_CONST.slotCap||2;
    let used=RUN.fleet.filter(s=>s.archiveSlot).length+(RUN.pendingRestore||[]).length;
    if(used<cap){
      const order=[...RUN.fleet].sort((a,b)=>((b.uid===RUN.flagUid?1:0)-(a.uid===RUN.flagUid?1:0))||((shipValue(b.tpl))-(shipValue(a.tpl))));
      let bought=0;
      for(const s of order){
        if(used>=cap||bought>=2) break;
        if(s.archiveSlot) continue;
        const price=MC_GE_CONST.slotFlat||45;
        if(RUN.credits-price<150) continue;
        RUN.credits-=price; s.archiveSlot=true; used++; bought++;
        if(S) S.slotsBought=(S.slotsBought||0)+1;
      }
    }
  }
}

// ---- driver helpers (unchanged from the issue 1085 harness) ----
function mcFleetHpFrac(){ if(!RUN||!RUN.fleet.length) return 1; const mx=RUN.fleet.reduce((a,s)=>a+derive(s).maxHp,0); return mx?RUN.fleet.reduce((a,s)=>a+Math.max(0,s.hp),0)/mx:1; }
function mcMissing(){ return RUN.fleet.reduce((a,s)=>a+derive(s).maxHp-s.hp,0); }
// The worst damaged ship's missing hull and its own maximum hull. The shared
// spiral test needs both: it prices a quarter of the maximum, capped at what is
// missing (contrib/deepseek/chorus_biomass_1118/sim/spiral.js).
function mcWorstPair(fleet){ let worst=0,worstMax=0; for(const s of (fleet||[])){ const d=derive(s), m=d.maxHp-s.hp; if(m>worst){ worst=m; worstMax=d.maxHp; } } return {worst,worstMax}; }
function mcCheapestHull(){ const pm=priceMult(); let best=Infinity;
  for(const id of (FACTIONS[RUN.fac]&&FACTIONS[RUN.fac].roster)||[]){ const H=HULLS[id]; if(!H||H.sq||H.boss) continue; const c=Math.round((H.cost||0)*pm); if(c>0&&c<best) best=c; }
  return isFinite(best)?best:0; }
function mcFxScore(fx){ if(!fx) return 0; let sc=0; for(const k in fx){ const v=fx[k]; if(!v) continue; sc+=Math.abs(v)*(k.includes('Pct')?30:2); } return sc; }
function mcPickBoon(offer){
  const kit=fleetKit();
  if(offer.every(o=>!boonUseful(o.id,kit))) return -1;
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
  // capture the player ships that died before finishBattle removes them
  const preLost=B.units.filter(u=>u.side==='player'&&u.ship&&u.dead&&!u.exited).map(u=>({tpl:u.ship.tpl,mk:u.ship.mk,archiveSlot:!!u.ship.archiveSlot}));
  rec.rounds=B.round; rec.partial=!!B.partial; rec.res=res;
  rec.lost=B.units.filter(u=>u.side==='player'&&u.ship&&u.dead&&!u.exited).length;
  if(res==='timeout') S.timeouts++;
  S.battles.push(rec);
  const finRes=res==='timeout'?(B.cfg.kind==='boss'?'loss':'retreat'):res;
  const preCheapest=mcCheapestHull(), prePm=priceMult();
  MC_LAST_INCOME=null; MC_END_SNAPSHOT=null;
  try{ finishBattle(finRes); }catch(e){ S.errors.push('finishBattle: '+(e&&e.message||e)); }
  const ended=(!RUN||RUN.over);
  const effective=finRes==='loss'?(ended?'loss':'retreat'):finRes;
  rec.result=effective;
  if(!ended){ try{ if(S){S.recoverCalls=(S.recoverCalls||0)+1;S.preLostTotal=(S.preLostTotal||0)+preLost.length;} mcQueueRestores(preLost,finRes,ended,S); }catch(e){ S.errors.push('recovery: '+(e&&e.message||e)); } }
  rec.income=MC_LAST_INCOME?MC_LAST_INCOME.total:0;
  rec.incomeDetail=MC_LAST_INCOME;
  if(MC_LAST_INCOME) S.incomes.push(MC_LAST_INCOME.total);
  const wp=RUN?mcWorstPair(RUN.fleet):null;
  const st=RUN?{sector:RUN.sector,credits:RUN.credits,ships:RUN.fleet.length,missing:mcMissing(),cp:fleetCP(),
      hull:RUN.fleet.reduce((a,s)=>a+Math.max(0,s.hp),0),maxHull:RUN.fleet.reduce((a,s)=>a+derive(s).maxHp,0),
      worst:wp.worst,worstMax:wp.worstMax,fleet:RUN.fleet.map(s=>s.tpl)}:MC_END_SNAPSHOT;
  // Loss spiral bookkeeping, the issue 1085 definition: a "loss" is a battle
  // not won, a "setback" is a loss or a win that cost ships. The spiral is two
  // losses in a row where, at the second, the credits cannot pay the shared
  // test's 25 percent repair of the worst ship (capped at what is missing), or
  // the cheapest hull the faction can field. Starvation is the same test on two
  // setbacks in a row. An empty fleet is no recovery.
  // spiralFull and starveFull keep run 1's full-repair pricing on the same runs,
  // so the two definitions can be compared the way issue 1085 did.
  { const loss=effective!=='win', setback=loss||rec.lost>0;
    const alive=!!st&&st.ships>0;
    const worst=st?(st.worst||0):0, worstMax=st?(st.worstMax||0):0;
    const money=st?st.credits:0;
    const repairHull=mcRepairHull(worst,worstMax), repairCost=mcRepairCost(worst,worstMax,prePm);
    const fullCost=Math.ceil(Math.max(worst,1)/2*prePm);
    const unrec=st?mcUnrecoverable(worst,worstMax,money,prePm,preCheapest,alive):false;
    const unrecFull=!st?false:(!alive||(worst>0&&money<fullCost&&money<preCheapest));
    if(st) S.recovery.push({s:st.sector,res:effective,lost:rec.lost,worst:Math.round(worst*10)/10,worstMax:Math.round(worstMax*10)/10,money,pm:prePm,repairHull,repairCost,fullCost,cheapest:preCheapest,unrec:unrec?1:0,unrecFull:unrecFull?1:0});
    if(loss){ S.lossStreak=(S.lossStreak||0)+1; if(S.lossStreak>=2){ S.twoLosses=true; if(!S.spiral&&unrec) S.spiral=true; if(!S.spiralFull&&unrecFull) S.spiralFull=true; } } else S.lossStreak=0;
    if(setback){ S.setbackStreak=(S.setbackStreak||0)+1; if(S.setbackStreak>=2){ S.twoSetbacks=true; if(!S.starve&&unrec) S.starve=true; if(!S.starveFull&&unrecFull) S.starveFull=true; } } else S.setbackStreak=0;
  }
  if(nemB){ nemB.res=res; if(RUN&&RUN.nem){ nemB.adaptA=RUN.nem.adapt.length; nemB.revA=RUN.nem.revealed.length; } S.nem.push(nemB); }
  if(st) S.econ.push({at:'postbattle',s:st.sector,credits:st.credits,ships:st.ships,missing:st.missing,cp:st.cp,hull:st.hull,maxHull:st.maxHull,fleet:st.fleet});
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
  try{ mcArchiveStep(S); }catch(e){ S.errors.push('archive: '+(e&&e.message||e)); }
  const st=n.stock, pm=priceMult();
  S.hullOffers.push({offer:st.hulls.slice(),s:RUN.sector});
  S.modOffers.push({offer:st.mods.slice(),s:RUN.sector,src:'yard'});
  const missing=mcMissing(), maxTot=RUN.fleet.reduce((a,s)=>a+derive(s).maxHp,0);
  const prices=[...st.hulls.map(h=>Math.round(HULLS[h].cost*pm)),...st.mods.map(m=>Math.round(MODULES[m].cost*pm)),...RUN.fleet.filter(s=>s.mk<3).map(s=>mkCost(s))].filter(x=>x>0);
  const reg={type:'shipyard',s:RUN.sector,creditsIn:RUN.credits,missing,worstMissing:RUN.fleet.reduce((a,s)=>Math.max(a,derive(s).maxHp-s.hp),0),missingFrac:maxTot?missing/maxTot:0,pm,cheapest:prices.length?Math.min(...prices):0,repairCost:Math.ceil(missing/2*pm),spendRepair:0,spendHull:0,spendMod:0,spendMk:0};
  if(missing>0){
    if(MC_GE.kiln&&RUN.fac==='ithar') mcKilnRepairAll(reg,pm);
    else { const c0=RUN.credits; ACT.repairAll(); reg.spendRepair=c0-RUN.credits; }
  }
  const commBusy=MC_GE.commission&&(RUN.commQueue||[]).length>=1;
  if(!commBusy){
    for(const h of st.hulls.slice().sort((a,b)=>(HULLS[b].cp||1)-(HULLS[a].cp||1))){
      const t=HULLS[h];
      if(t.unique&&RUN.fleet.some(s=>s.tpl===h)) continue;
      if(fleetCP()+(t.cp||1)>RUN.cpCap) continue;
      const cost=Math.round(t.cost*pm);
      if(RUN.credits-cost<40) continue;
      const c0=RUN.credits;
      if(MC_GE.commission){ if(mcGeBuyHull(h,S)){ reg.spendHull+=c0-RUN.credits; S.hullPicks.push({id:h,s:RUN.sector}); } }
      else { ACT.buyHull(h); if(RUN.credits<c0){ reg.spendHull+=c0-RUN.credits; S.hullPicks.push({id:h,s:RUN.sector}); } }
    }
  }
  st.mods.forEach((m,i)=>{ if(st.sold.includes(i)) return; const cost=Math.round(MODULES[m].cost*pm); if(RUN.credits-cost<120) return;
    const c0=RUN.credits; ACT.buyMod(i); if(RUN.credits<c0){ reg.spendMod+=c0-RUN.credits; S.modPicks.push({id:m,src:'yard'}); mcAutoFit(m); } });
  const order=[...RUN.fleet].sort((a,b)=>((b.uid===RUN.flagUid?1:0)-(a.uid===RUN.flagUid?1:0))||((HULLS[b.tpl].cp||1)-(HULLS[a.tpl].cp||1)));
  for(const s of order){ if(s.mk>=3) continue; const c=mkCost(s); if(RUN.credits-c<250) continue; const c0=RUN.credits; ACT.upgradeMk(s.uid); if(RUN.credits<c0) reg.spendMk+=c0-RUN.credits; }
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
function mcFreshStats(cfg){ return {fac:cfg.fac,admiral:cfg.admiral,ai:cfg.ai,seed:cfg.seed,setup:cfg.setup||'baseline',ge:cfg.ge||{},won:false,sectorReached:1,timeouts:0,verbUses:0,
  battles:[],nem:[],econ:[],regroups:[],boonOffers:[],boonPicks:[],boonDeclines:0,modOffers:[],modPicks:[],relicOffers:[],relicPicks:[],
  hullOffers:[],hullPicks:[],prizePicks:[],salvageOffers:[],salvagePicks:[],events:[],perkPicks:[],patrons:[],gift:null,finalFleet:[],finalBoons:[],errors:[],
  incomes:[],recovery:[],lossStreak:0,setbackStreak:0,twoLosses:false,twoSetbacks:false,spiral:false,starve:false,spiralFull:false,starveFull:false,
  culletEarned:0,slotsBought:0,slotRestoresQueued:0,slotRestored:0,coresEarned:0,coreRestored:0,commissionsStarted:0,hullsBought:0}; }
async function mcRunOne(cfg){
  const S=mcFreshStats(cfg);
  try{
    MC_SETUP=cfg.setup||'baseline'; MC_LAST_INCOME=null; MC_NODE_TICK=0; MC_END_SNAPSHOT=null; mcGeReset(cfg);
    META=defaultMeta(); if(cfg.admiral) META.admirals[cfg.admiral]=true; AI_LEVEL=cfg.ai; SPEED=0;
    mcRestoreBaseHullCosts();
    if(cfg.priceMult&&cfg.priceMult!==1) for(const id of Object.keys(HULLS)){ const h=HULLS[id]; if(h.cost!=null&&factionOfTpl(id)===cfg.fac) h.cost=Math.max(5,Math.round(h.cost*cfg.priceMult/5)*5); }
    rndSeed(cfg.seed>>>0);
    newRun(cfg.admiral,cfg.fac,{});
    if(!RUN){ S.errors.push('newRun returned no run'); return S; }
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
    if(RUN){ S.finalFleet=RUN.fleet.map(s=>s.tpl); S.finalBoons=(RUN.boons||[]).map(b=>b.id); S.creditsFinal=RUN.credits; }
    else { const snap=MC_END_SNAPSHOT||[...S.econ].reverse().find(e=>e.at==='postbattle'); S.finalFleet=snap&&snap.fleet?snap.fleet:[]; S.creditsFinal=snap?snap.credits||0:0; }
  }catch(e){ S.errors.push('run: '+(e&&e.message||e)); }
  return S;
}
var MC={runOne:mcRunOne};
