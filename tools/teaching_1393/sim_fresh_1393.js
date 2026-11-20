// Issue 1393 (R366): fresh-profile Sunward sim for the first-run teaching battles. Same Monte Carlo driver as
// tools/late_run_1178/sim_1178.js, plus what a brand-new profile gets in the shipped game: the run starts with the teaching gate
// on (main3d.js newRun), and every battle config goes through teachingBattle() as campaign3d.js battleScreen does before
// startBattle. Records, per run, the result of the second fight (teaching Battle 2) and its layout.
// Usage: node tools/teaching_1393/sim_fresh_1393.js <repo root> <ai: standard|veteran> <runs> <first seed> <out.json>
'use strict';
const fs = require('fs'), path = require('path'), Module = require('module');
const [root, AI, runsArg, seedArg, out] = process.argv.slice(2);
const RUNS = Number(runsArg), SEED = Number(seedArg);
const src = path.join(__dirname, '../../contrib/muse/tools/montecarlo');
const read = n => fs.readFileSync(path.join(src, n), 'utf8');
const shim = `
var T1393=[];
if(typeof repairStopOptions==='function'){   // the repair-stop pick from sim_1178.js (issue 1177), so stops resolve the same way
  drydockScreen=function(n){ t1393StopPick(n); };
  fieldRepairs=function(n){ t1393StopPick(n); };
}
function t1393StopPick(n){
  RUN.curNode=n.id;
  const o=repairStopOptions(n.type), pm=priceMult();
  const fl=(typeof flagshipOf==='function'&&flagshipOf())||null;
  const flFrac=fl?Math.max(0,fl.hp)/derive(fl).maxHp:1;
  ACT.repairStop(((o[0].hp-o[1].hp)/2*pm>o[1].credits||mcFleetHpFrac()<.5||flFrac<.5)?'service':'stipend');
}
const _t1393NewRun=newRun;
newRun=function(a,f,o){ return _t1393NewRun(a,f,Object.assign({},o,{teachingGate:true})); };
const _t1393Start=startBattle;
startBattle=function(c){ if(RUN&&RUN.teachingGate===true&&c&&typeof teachingBattle==='function') Object.assign(c,teachingBattle(c)); return _t1393Start.apply(this,arguments); };
const _t1393Loop=mcBattleLoop;
mcBattleLoop=async function(){ T1393.push({tb:(B&&B.cfg&&B.cfg.teachingBattle)||null,shape:(B&&(B.shape||B.cfg&&B.cfg.shape))||null,arena:(B&&B.cfg&&B.cfg.arena)||null,ev:B&&B.event?B.event.k:null,evR:B&&B.event?B.event.r:null,fac:B&&B.cfg?B.cfg.fac:null});
  return _t1393Loop.apply(this,arguments); };
const _t1393Run=MC.runOne;
MC.runOne=async function(c){ T1393=[]; const S=await _t1393Run(c); S.t1393=T1393.slice(); return S; };
`;
const loaderPath = path.join(src, 'loader_main.js');
const mod = new Module(loaderPath, module); mod.filename = loaderPath; mod.paths = Module._nodeModulePaths(src);
mod._compile(read('loader_main.js'), loaderPath);
const game = mod.exports.loadGame(path.resolve(root), { extra: ['bot.js', 'driver.js', 'policies.js'].map(read).concat([shim]) });
(async () => {
  const adm = game.api.get('ADMIRALS'), ids = Object.keys(adm).filter(id => (adm[id].fac || 'voidsworn') === 'voidsworn');
  const rows = [];
  for (let i = 0; i < RUNS; i++) {
    const r = await game.api.runOne({ fac: 'voidsworn', admiral: ids[i % ids.length], ai: AI, seed: SEED + i, policy: 'baseline', priceMult: 1, cpDelta: 0, credMult: 1 });
    const b2 = r.battles[1] ? Object.assign({}, r.battles[1], r.t1393[1] || {}) : null;
    rows.push({ seed: r.seed, admiral: r.admiral, won: r.won, battles: r.battles.length,
      b2: b2 && { res: b2.res, tb: b2.tb, shape: b2.shape, arena: b2.arena, ev: b2.ev, evR: b2.evR, fac: b2.fac, lost: b2.lost, rounds: b2.rounds },
      diedAtB2: !r.won && r.battles.length === 2, errors: r.errors });
  }
  fs.writeFileSync(out, JSON.stringify(rows));
  const n = rows.length, b2loss = rows.filter(x => x.b2 && x.b2.res !== 'win').length, dead = rows.filter(x => x.diedAtB2).length;
  console.log(JSON.stringify({ runs: n, wins: rows.filter(x => x.won).length, b2NotWon: b2loss, runEndedAtB2: dead,
    b2ShipsLost: rows.reduce((a, x) => a + ((x.b2 && x.b2.lost) || 0), 0), seed121: rows.find(x => x.seed === 121) || null,
    errors: rows.reduce((a, x) => a + x.errors.length, 0) }));
})();
