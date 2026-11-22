'use strict';
// Issue 1632: the Muse Monte Carlo bot (contrib/muse/tools/montecarlo) must still play the game. Issue 1379 removed torpThreat
// from battle.js, the bot kept calling it, and from Nov 20 every sim run ended at its first move with a caught "not defined"
// error and 0 battles, while the sims went on printing rates. One seeded run per faction: each must fight battles, end
// without a run error, and leave no timer error behind.
const fs = require('fs'), path = require('path'), Module = require('module');
const ROOT = path.resolve(__dirname, '../../..');
const src = path.join(ROOT, 'contrib/muse/tools/montecarlo');
const read = n => fs.readFileSync(path.join(src, n), 'utf8');
const loaderPath = path.join(src, 'loader_main.js');
const mod = new Module(loaderPath, module); mod.filename = loaderPath; mod.paths = Module._nodeModulePaths(src);
mod._compile(read('loader_main.js'), loaderPath);
const game = mod.exports.loadGame(ROOT, { extra: ['bot.js', 'driver.js', 'policies.js'].map(read) });
(async () => {
  const facs = game.api.get('RUN_FACTIONS.slice()'), adm = game.api.get('ADMIRALS');
  let fail = 0;
  for (const fac of facs) {
    const admiral = Object.keys(adm).find(id => (adm[id].fac || 'voidsworn') === fac);
    const r = await game.api.runOne({ fac, admiral, ai: 'standard', seed: 1632, policy: 'baseline', priceMult: 1, cpDelta: 0, credMult: 1 });
    const ok = r.battles.length > 0 && !r.errors.length;
    if (!ok) fail++;
    console.log(`${ok ? 'ok  ' : 'FAIL'}  ${fac}: ${r.battles.length} battles, ${r.won ? 'won' : 'lost'} in sector ${r.sectorReached}${r.errors.length ? ', errors: ' + r.errors.join(' | ') : ''}`);
  }
  await new Promise(res => setTimeout(res, 2500));   // let delayed screen timers fire
  if (globalThis.__timerErrors) console.log(`note: ${globalThis.__timerErrors} delayed screen timer(s) threw after their run and were dropped`);
  if (fail) { console.log(`FAIL: ${fail} of ${facs.length} bot runs did not play through`); process.exitCode = 1; }
  else console.log(`PASS: the Monte Carlo bot plays a seeded run for each of ${facs.length} factions without errors`);
})().catch(e => { console.log('FAIL: ' + (e.stack || e)); process.exitCode = 1; });
