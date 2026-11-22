// Issue 1484: paired campaign sim for Chorus biomass buying refits, class refit tracks, protocol rerolls and the late market.
// Usage: node tools/late_run_1484/sim_1484.js <repo root> <ai: standard|veteran> <runs per faction> <first seed> <out.json>
//        (FAC=<id> runs one faction)
// Built on tools/late_run_1178/sim_1178.js (same Muse Monte Carlo driver, same repair-stop pick, Sector 3 routing and late
// shop pick) with Artoo's issue 1484 changes, so a flat win rate cannot hide purchases the bot never makes:
//  - one decision policy in every tree. Each purchase kind reads the //    the source: a sink written with hullPay pays hullKey(), otherwise credits), so the same rule spends credits on main and
//    biomass on the branch for a Chorus run;
//  - the bot also buys class refit tracks (purse minus price at least 250) and rerolls a protocol offer it would decline
//    (purse minus price at least 100), every faction, both arms;
//  - every purchase is checked by its effect (the module is in the hold and fitted, the track level rose, the relic or
//    command point arrived, the offer was replaced), and the run records per kind: opportunities (the bot's rule is met by the
//    larger of the run's credits and biomass), attempts (met by the purse the tree charges), successes, and the biomass and
//    credits actually debited;
//  The Muse bot and loader it runs were brought up to the current game in issue 1632 (it had stopped at the first battle since Nov 20).
'use strict';
const fs = require('fs'), path = require('path'), Module = require('module');
const [root, AI, runsArg, seedArg, out] = process.argv.slice(2);
const RUNS = Number(runsArg), SEED = Number(seedArg);
const src = path.join(__dirname, '../../contrib/muse/tools/montecarlo');
const read = n => fs.readFileSync(path.join(src, n), 'utf8');
const shim = `
var MC78={}, MC84={};
// which purse each sink charges in this tree
function mc84Pays(fn){ const s=String(fn); return s.includes('shopPay(')?'shop':s.includes('hullPay(')?'hull':'credits'; }
const MC84PAY={ mod:mc84Pays(ACT.buyMod), track:mc84Pays(buyClassTrack), late:mc84Pays(ACT.lateBuy), reroll:mc84Pays(boonReroll) };
function mc84Key(k,c){ return MC84PAY[k]==='shop'?shopKey(c):MC84PAY[k]==='hull'?hullKey():'credits'; }
function mc84Purse(k,c){ return RUN[mc84Key(k,c)]||0; }
function mc84Best(){ return Math.max(RUN.credits||0,RUN.bio||0); }
function mc84Rec(k){ return MC84[k]=MC84[k]||{opp:0,try:0,ok:0,bio:0,cred:0,fit:0}; }
function mc84Do(k,fn,took){ const r=mc84Rec(k), b=RUN.bio||0, c=RUN.credits||0; r.try++; fn(); const ok=!!took(); if(ok) r.ok++; r.bio+=b-(RUN.bio||0); r.cred+=c-(RUN.credits||0); return ok; }
if(typeof repairStopOptions==='function'){
  drydockScreen=function(n){ mc78StopPick(n); };
  fieldRepairs=function(n){ mc78StopPick(n); };
}
function mc78StopPick(n){
  RUN.curNode=n.id;
  const o=repairStopOptions(n.type), pm=priceMult();
  const fl=(typeof flagshipOf==='function'&&flagshipOf())||null;
  const flFrac=fl?Math.max(0,fl.hp)/derive(fl).maxHp:1;
  const pick=((o[0].hp-o[1].hp)/2*pm>o[1].credits||mcFleetHpFrac()<.5||flFrac<.5)?'service':'stipend';
  ACT.repairStop(pick);
}
const _mc78Fight=mcFight;
mcFight=async function(cfg,S,isNem){
  if(cfg&&cfg.kind==='boss'&&RUN&&RUN.sector===3&&MC78.bossCredits==null){ MC78.bossCredits=RUN.credits; MC78.bossBio=RUN.bio||0; MC78.bossShips=RUN.fleet.length; MC78.bossMaxHp=RUN.fleet.reduce((a,s)=>a+derive(s).maxHp,0); }
  return _mc78Fight(cfg,S,isNem);
};
if(typeof factionWinEcon==='function'){ const _f78=factionWinEcon; factionWinEcon=function(c,sm){ const o=_f78(c,sm);
  MC78.bio=(MC78.bio||0)+(o.bio||0); MC78.cullet=(MC78.cullet||0)+(o.cullet||0); if(o.core) MC78.cores=(MC78.cores||0)+1; return o; }; }
// refit modules: the driver's rule (purse minus price at least 120), on the purse the tree charges, checked by effect
function mc84Mods(n,S){ const st=n.stock, pm=priceMult();
  st.mods.forEach((m,i)=>{ if(st.sold.includes(i)) return; const cost=Math.round(MODULES[m].cost*pm);
    if(mc84Best()-cost>=120) mc84Rec('mod').opp++;
    if(mc84Purse('mod',cost)-cost<120) return;
    const inv=RUN.inventory.length;
    if(mc84Do('mod',()=>ACT.buyMod(i),()=>st.sold.includes(i)&&RUN.inventory.length===inv+1)){ S.modPicks.push({id:m,src:'yard'}); const f=RUN.fleet.reduce((a,s)=>a+s.mods.length,0); mcAutoFit(m); if(RUN.fleet.reduce((a,s)=>a+s.mods.length,0)>f) mc84Rec('mod').fit++; } }); }
// class refit tracks: the most common class first, purse minus price at least 250
function mc84Tracks(){ if(typeof buyClassTrack!=='function') return; const cnt={};
  for(const s of RUN.fleet){ const c=HULLS[s.tpl].cls; cnt[c]=(cnt[c]||0)+1; }
  for(const cls of Object.keys(cnt).sort((a,b)=>cnt[b]-cnt[a]||(a<b?-1:1))){ const lv=classTrack(cls); if(lv>=CLASS_TRACK_MAX) continue; const c=classTrackCost(cls);
    if(mc84Best()-c>=250) mc84Rec('track').opp++;
    if(mc84Purse('track',c)-c<250) continue;
    mc84Do('track',()=>ACT.buyTrack(cls),()=>classTrack(cls)===lv+1); } }
{
  // the driver's yard pass with module buying taken out (mc84Mods does it on the right purse); the Chorus pass runs hull work
  // on biomass, as sim_1178 does
  const _drv=mcShipyard;
  mcShipyard=function(n,S){
    const bm=ACT.buyMod, lv=ACT.leaveYard; ACT.buyMod=()=>{}; ACT.leaveYard=()=>{};
    try{
      if(RUN.fac==='chorus'&&typeof hullKey==='function'&&hullKey()==='bio'){ const hk=hullKey, c=RUN.credits;
        RUN.credits=RUN.bio||0; hullKey=()=>'credits';
        try{ _drv(n,S); } finally { RUN.bio=RUN.credits; RUN.credits=c; hullKey=hk; } }
      else _drv(n,S);
    } finally { ACT.buyMod=bm; ACT.leaveYard=lv; }
    mc84Mods(n,S); mc84Tracks();
  };
}
{
  // a fleet with money to spend goes shopping in Sector 3 (the late market's purse)
  const _mc78Score=mcNodeScore;
  mcNodeScore=function(n){ let sc=_mc78Score(n); if(n.type==='shipyard'&&RUN.sector>=3&&mc84Purse('late',300)>=300) sc+=40; return sc; };
}
if(typeof lateShopOffers==='function'){
  const _mc78Yard=mcShipyard;
  mcShipyard=function(n,S){
    _mc78Yard(n,S);
    try{ if(!RUN||RUN.over){ ACT.leaveYard(); return; } let guard=0;
      yardNode=n;
      for(let i=(RUN.cores||[]).length-1;i>=0;i--){ const tpl=RUN.cores[i]; if(RUN.credits>=coreCost(tpl)&&fleetCP()+(HULLS[tpl].cp||1)<=RUN.cpCap){ MC78.coreRestores=(MC78.coreRestores||0)+1; ACT.restoreCore(i); } }
      while(guard++<4){ const all=(yardNode&&yardNode.stock&&yardNode.stock.late)?lateShopOffers():[]; if(!all.length) break;
        // the repair reserve only binds when the late market and repairs share a purse
        const resv=Math.ceil(mcMissing()/2*priceMult()), reserve=c=>mc84Key('late',c)===hullKey()?resv:0;
        const open=all.filter(o=>!o.done&&!o.full&&!(o.kind==='relic'&&RUN.relics.includes(o.r))).sort((a,b)=>b.value-a.value);
        const opp=open.find(o=>mc84Best()-o.cost>=reserve(o.cost)); if(opp&&guard===1) mc84Rec('late').opp++;
        const o=open.find(o=>o.ok&&mc84Purse('late',o.cost)-o.cost>=reserve(o.cost)); if(!o) break;
        const rl=RUN.relics.length, cap=RUN.cpCap;
        if(!mc84Do('late',()=>ACT.lateBuy(o.id),()=>o.kind==='relic'?RUN.relics.length===rl+1:RUN.cpCap===cap+1)) break;
        MC78.lateBuys=(MC78.lateBuys||0)+1; MC78.lateSpent=(MC78.lateSpent||0)+o.cost; (MC78.lateIds=MC78.lateIds||[]).push(o.id); }
    }catch(e){ S.errors.push('lateShop: '+(e&&e.message||e)); }
    ACT.leaveYard();
  };
} else { const _y=mcShipyard; mcShipyard=function(n,S){ _y(n,S); ACT.leaveYard(); }; }
// protocol rerolls: an offer the bot would decline is rerolled once when the purse minus the price is at least 100
{
  const _pick=mcPickBoon;
  mcPickBoon=function(offer){ let i=_pick(offer); const R=RUN.reward, rw=(R&&(window._rw||R.rw))||{};
    if(i>=0||!R||R.rerolled||typeof boonReroll!=='function'||rw.k!=='boon') return i;
    const c=boonRerollCost(); if(mc84Best()-c>=100) mc84Rec('reroll').opp++;
    if(mc84Purse('reroll',c)-c<100) return i;
    // the live offer comes from boonStep, which hands an eaten core's offer to another patron; the reroll button carries that patron
    const bp=(RUN.eatenCore&&RUN.eatenCore===rw.p)?((RUN.patrons||[]).find(q=>q!==rw.p)||rw.p):rw.p;
    const old=(R.boonOffer||offer).map(o=>o.id).join();
    if(mc84Do('reroll',()=>boonReroll(bp,rw.min||0),()=>RUN.reward&&RUN.reward.rerolled&&(RUN.reward.boonOffer||[]).map(o=>o.id).join()!==old)){
      const nw=RUN.reward.boonOffer||[]; offer.length=0; for(const o of nw) offer.push(o); i=_pick(offer); }
    return i; };
}
const _mc78Run=MC.runOne;
MC.runOne=async function(c){ MC78={}; MC84={}; const S=await _mc78Run(c);
  S.m78=Object.assign({},MC78); S.m84=JSON.parse(JSON.stringify(MC84)); S.pays=Object.assign({},MC84PAY);
  S.m78.creditsEnd=(typeof RUN!=='undefined'&&RUN)?RUN.credits:null; S.m78.bioEnd=(typeof RUN!=='undefined'&&RUN)?(RUN.bio||0):null; return S; };
`;
const loaderPath = path.join(src, 'loader_main.js');
const mod = new Module(loaderPath, module); mod.filename = loaderPath; mod.paths = Module._nodeModulePaths(src);
mod._compile(read('loader_main.js'), loaderPath);
const game = mod.exports.loadGame(path.resolve(root), { extra: ['bot.js', 'driver.js', 'policies.js'].map(read).concat([shim]) });
(async () => {
  const facs = game.api.get('RUN_FACTIONS.slice()'), adm = game.api.get('ADMIRALS');
  const rows = [];
  for (const fac of facs.filter(f => !process.env.FAC || f === process.env.FAC)) {
    const ids = Object.keys(adm).filter(id => (adm[id].fac || 'voidsworn') === fac);
    for (let i = 0; i < RUNS; i++) {
      const r = await game.api.runOne({ fac, admiral: ids[i % ids.length], ai: AI, seed: SEED + i, policy: 'baseline', priceMult: 1, cpDelta: 0, credMult: 1 });
      const last = r.battles[r.battles.length - 1];
      rows.push({ fac, admiral: r.admiral, seed: r.seed, won: r.won, sector: r.sectorReached,
        lossSector: r.won ? null : (last ? last.s : r.sectorReached), bossCredits: r.m78.bossCredits ?? null, bossBio: r.m78.bossBio ?? null,
        creditsEnd: r.m78.creditsEnd, bioEnd: r.m78.bioEnd, lateBuys: r.m78.lateBuys || 0, lateSpent: r.m78.lateSpent || 0, lateIds: r.m78.lateIds || [],
        bio: r.m78.bio || 0, buys: r.m84, pays: r.pays, battles: r.battles.length, timeouts: r.timeouts, errors: r.errors });
    }
    console.error(AI, fac, 'done');
  }
  fs.writeFileSync(out, JSON.stringify(rows));
})().catch(e => { console.error(e.stack || e); process.exitCode = 1; });
