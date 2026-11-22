// Issue 1178: paired campaign sim for the late game (Sector 3 difficulty, late shop sinks, faction economies).
// Usage: node tools/late_run_1178/sim_1178.js <repo root> <ai: standard|veteran> <runs per faction> <first seed> <out.json>
// Loads <repo root>'s game files with Muse's unmodified Monte Carlo driver (contrib/muse/tools/montecarlo) and adds:
//  - the repair-stop pick from issue 1177 (full service when its extra hull is worth more than the credits at the paid
//    repair price, or when the fleet or flagship is below half hull);
//  - in Sector 3 with 300 or more credits, a preference for shipyard stops (every tree, so both arms route alike);
//  - the late shop pick when the tree has late shop sinks (lateShopOffers): buy the best offer it can afford while
//    keeping a repair reserve;
//  - per-run records: sector of the loss, credits on entering the final boss, faction economy counters.
'use strict';
const fs = require('fs'), path = require('path'), Module = require('module');
const [root, AI, runsArg, seedArg, out] = process.argv.slice(2);
const RUNS = Number(runsArg), SEED = Number(seedArg);
const src = path.join(__dirname, '../../contrib/muse/tools/montecarlo');
const read = n => fs.readFileSync(path.join(src, n), 'utf8');
const shim = `
var MC78={};
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
  if(cfg&&cfg.kind==='boss'&&RUN&&RUN.sector===3&&MC78.bossCredits==null){ MC78.bossCredits=RUN.credits; MC78.bossShips=RUN.fleet.length; MC78.bossMaxHp=RUN.fleet.reduce((a,s)=>a+derive(s).maxHp,0); }
  return _mc78Fight(cfg,S,isNem);
};
if(typeof factionWinEcon==='function'){ const _f78=factionWinEcon; factionWinEcon=function(c,sm){ const o=_f78(c,sm);
  MC78.bio=(MC78.bio||0)+(o.bio||0); MC78.cullet=(MC78.cullet||0)+(o.cullet||0); if(o.core) MC78.cores=(MC78.cores||0)+1; return o; }; }
if(typeof hullKey==='function'){
  // Chorus: the bot's shipyard pass runs twice, first on biomass for hull work (repairs, hulls, Marks), then on credits for refits.
  const _mc78Chorus=mcShipyard;
  mcShipyard=function(n,S){
    if(RUN.fac!=='chorus'||hullKey()!=='bio') return _mc78Chorus(n,S);
    const hk=hullKey, lv=ACT.leaveYard, bm=ACT.buyMod, c=RUN.credits;
    RUN.credits=RUN.bio||0; hullKey=()=>'credits'; ACT.leaveYard=()=>{}; ACT.buyMod=()=>{};
    try{ _mc78Chorus(n,S); } finally { RUN.bio=RUN.credits; RUN.credits=c; hullKey=hk; ACT.leaveYard=lv; ACT.buyMod=bm; }
    const ra=ACT.repairAll, bh=ACT.buyHull, um=ACT.upgradeMk;
    ACT.repairAll=()=>{}; ACT.buyHull=()=>{}; ACT.upgradeMk=()=>{};
    try{ _mc78Chorus(n,S); } finally { ACT.repairAll=ra; ACT.buyHull=bh; ACT.upgradeMk=um; }
  };
}
{
  // A fleet with money to spend goes shopping in Sector 3. One routing policy on every tree (main too), so the before and after
  // arms differ only by the game (Artoo on PR 1276).
  const _mc78Score=mcNodeScore;
  mcNodeScore=function(n){ let sc=_mc78Score(n); if(n.type==='shipyard'&&RUN.sector>=3&&RUN.credits>=300) sc+=40; return sc; };
}
if(typeof lateShopOffers==='function'){
  const _mc78Yard=mcShipyard;
  mcShipyard=function(n,S){
    const r=_mc78Yard(n,S);
    try{ if(!RUN||RUN.over) return r; let guard=0;
      yardNode=n;
      for(let i=(RUN.cores||[]).length-1;i>=0;i--){ const tpl=RUN.cores[i]; if(RUN.credits>=coreCost(tpl)&&fleetCP()+(HULLS[tpl].cp||1)<=RUN.cpCap){ MC78.coreRestores=(MC78.coreRestores||0)+1; ACT.restoreCore(i); } }
      while(guard++<4){ const offs=lateShopOffers().filter(o=>o.ok); if(!offs.length) break;
        const reserve=Math.ceil(mcMissing()/2*priceMult());
        const o=offs.sort((a,b)=>b.value-a.value).find(o=>RUN.credits-o.cost>=reserve); if(!o) break;
        ACT.lateBuy(o.id); MC78.lateBuys=(MC78.lateBuys||0)+1; MC78.lateSpent=(MC78.lateSpent||0)+o.cost; (MC78.lateIds=MC78.lateIds||[]).push(o.id); }
    }catch(e){ S.errors.push('lateShop: '+(e&&e.message||e)); }
    return r;
  };
}
const _mc78Run=MC.runOne;
MC.runOne=async function(c){ MC78={}; const S=await _mc78Run(c);
  S.m78=Object.assign({},MC78); if(typeof RUN!=='undefined'&&RUN&&RUN.econ78) S.m78.econ=Object.assign({},RUN.econ78);
  S.m78.creditsEnd=(typeof RUN!=='undefined'&&RUN)?RUN.credits:null; return S; };
`;
const loaderPath = path.join(src, 'loader_main.js');
const mod = new Module(loaderPath, module); mod.filename = loaderPath; mod.paths = Module._nodeModulePaths(src);
mod._compile(read('loader_main.js'), loaderPath);
const game = mod.exports.loadGame(path.resolve(root), { extra: ['bot.js', 'driver.js', 'policies.js'].map(read).concat([shim]) });
(async () => {
  const facs = game.api.get('RUN_FACTIONS.slice()'), adm = game.api.get('ADMIRALS');
  const rows = [];
  for (const fac of facs.filter(f => !process.env.FAC || f === process.env.FAC)) {   // FAC=<id> runs one faction
    const ids = Object.keys(adm).filter(id => (adm[id].fac || 'voidsworn') === fac);
    for (let i = 0; i < RUNS; i++) {
      const r = await game.api.runOne({ fac, admiral: ids[i % ids.length], ai: AI, seed: SEED + i, policy: 'baseline', priceMult: 1, cpDelta: 0, credMult: 1 });
      const last = r.battles[r.battles.length - 1];
      rows.push({ fac, admiral: r.admiral, seed: r.seed, won: r.won, sector: r.sectorReached,
        lossSector: r.won ? null : (last ? last.s : r.sectorReached), bossCredits: r.m78.bossCredits ?? null,
        bossShips: r.m78.bossShips ?? null, bossMaxHp: r.m78.bossMaxHp ?? null, creditsEnd: r.m78.creditsEnd, lateBuys: r.m78.lateBuys || 0,
        lateSpent: r.m78.lateSpent || 0, lateIds: r.m78.lateIds || [], bio: r.m78.bio || 0, cullet: r.m78.cullet || 0, cores: r.m78.cores || 0, coreRestores: r.m78.coreRestores || 0,
        battles: r.battles.map(b => [b.s, b.kind, b.res, b.pCP, b.eCP, b.lost]), timeouts: r.timeouts, errors: r.errors });
    }
    console.error(AI, fac, 'done');
  }
  fs.writeFileSync(out, JSON.stringify(rows));
})().catch(e => { console.error(e.stack || e); process.exitCode = 1; });
