// Issue 1177 run 2 economy measure: paired seeds, one game tree per call.
// Usage: node contrib/opus/tools/issue1177/econ_1177.js <repo root> <runs per faction> <first seed> <out.json> [ai]
// Uses Muse's unmodified Monte Carlo driver. On a tree with the new repair-stop
// choice (repairStopOptions), the driver's drydockScreen/fieldRepairs calls are
// routed to a bot pick: take the full service when the extra hull it gives is
// worth more than the credits at the paid repair price (half a credit per hull
// point, times priceMult), or when the fleet or the flagship is below half hull.
'use strict';
const fs = require('fs'), path = require('path'), Module = require('module');
const [root, runsArg, seedArg, out, aiArg] = process.argv.slice(2);
const RUNS = Number(runsArg), SEED = Number(seedArg), AI = aiArg || 'standard';
const src = path.join(__dirname, '../../../muse/tools/montecarlo');
const read = n => fs.readFileSync(path.join(src, n), 'utf8');
const shim = `
var MC_STOP_PICKS=[];
if(typeof repairStopOptions==='function'){
  drydockScreen=function(n){ mcStopPick(n); };
  fieldRepairs=function(n){ mcStopPick(n); };
} else {
  const _d=drydockScreen, _f=fieldRepairs;
  drydockScreen=function(n){ MC_STOP_PICKS.push({type:'drydock',pick:'auto',s:RUN.sector}); return _d(n); };
  fieldRepairs=function(n){ MC_STOP_PICKS.push({type:'field',pick:'auto',s:RUN.sector}); return _f(n); };
}
function mcStopPick(n){
  RUN.curNode=n.id;
  const o=repairStopOptions(n.type), pm=priceMult();
  const extra=o[0].hp-o[1].hp, worth=extra/2*pm;
  const fl=(typeof flagshipOf==='function'&&flagshipOf())||null;
  const flFrac=fl?Math.max(0,fl.hp)/derive(fl).maxHp:1;
  const pick=(worth>o[1].credits||mcFleetHpFrac()<.5||flFrac<.5)?'service':'stipend';
  MC_STOP_PICKS.push({type:n.type,pick,s:RUN.sector});
  ACT.repairStop(pick);
}
var _mcRun1177=MC.runOne;
MC.runOne=async function(c){ MC_STOP_PICKS=[]; const S=await _mcRun1177(c); S.stopPicks=MC_STOP_PICKS.slice(); return S; };
`;
const loaderPath = path.join(src, 'loader_main.js');
const mod = new Module(loaderPath, module); mod.filename = loaderPath; mod.paths = Module._nodeModulePaths(src);
mod._compile(read('loader_main.js'), loaderPath);
const game = mod.exports.loadGame(path.resolve(root), { extra: ['bot.js', 'driver.js', 'policies.js'].map(read).concat([shim]) });
(async () => {
  const facs = game.api.get('RUN_FACTIONS.slice()'), adm = game.api.get('ADMIRALS');
  const rows = [];
  for (const fac of facs) {
    const ids = Object.keys(adm).filter(id => (adm[id].fac || 'voidsworn') === fac);
    for (let i = 0; i < RUNS; i++) {
      const r = await game.api.runOne({ fac, admiral: ids[i % ids.length], ai: AI, seed: SEED + i, policy: 'baseline', priceMult: 1, cpDelta: 0, credMult: 1 });
      const t = r.regroups.find(g => g.type === 'transit' && g.s === 2);
      rows.push({ fac, admiral: r.admiral, seed: r.seed, won: r.won, sector: r.sectorReached, s3credits: t ? t.creditsOut : null,
        timeouts: r.timeouts, errors: r.errors, stops: r.stopPicks || [], dryOld: r.regroups.filter(g => g.type === 'drydock').length });
    }
    console.error(fac, 'done');
  }
  fs.writeFileSync(out, JSON.stringify(rows));
})().catch(e => { console.error(e.stack || e); process.exitCode = 1; });
