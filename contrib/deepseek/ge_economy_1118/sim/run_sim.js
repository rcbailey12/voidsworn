// run_sim.js - issue 1086 Glasswright and Eclipse economy sim.
// Loads the shipped game files read only (repo root) with the in memory patch
// layer (driver_ge.js) and runs the existing campaign bot on a seed block.
// Usage:
//   node run_sim.js --setup ithar_today --n 240 --seed0 7000 --out raw/x.json
//   node run_sim.js --setup deathless_rec --n 240 --seed0 7000 --out raw/x.json
//     [--ai veteran] [--priceMult 1]
// Setups (see driver_ge.js header for the exact simplest forms):
//   ithar_today, ithar_kiln, ithar_cullet, ithar_commission, ithar_rec
//   deathless_today, deathless_slots, deathless_core, deathless_rec
'use strict';
const fs = require('fs');
const path = require('path');
const { loadGame } = require('./loader_main');

const REPO = process.env.MC_REPO || path.resolve(__dirname, '..', '..', '..', '..');

const SETUPS = {
  ithar_today: { fac: 'ithar', ge: {} },
  ithar_kiln: { fac: 'ithar', ge: { kiln: true } },
  ithar_cullet: { fac: 'ithar', ge: { cullet: true } },
  ithar_commission: { fac: 'ithar', ge: { commission: true } },
  ithar_rec: { fac: 'ithar', ge: { kiln: true, cullet: true, commission: true } },
  deathless_today: { fac: 'deathless', ge: {} },
  deathless_slots: { fac: 'deathless', ge: { slots: true } },
  deathless_core: { fac: 'deathless', ge: { core: true } },
  deathless_rec: { fac: 'deathless', ge: { slots: true, core: true } },
};

const args = {};
for (let i = 2; i < process.argv.length; i++) {
  const a = process.argv[i];
  if (a.startsWith('--')) args[a.slice(2)] = process.argv[++i];
}

async function main() {
  const setup = args.setup || 'ithar_today';
  const def = SETUPS[setup];
  if (!def) throw new Error('unknown setup: ' + setup);
  const fac = def.fac;
  const ai = args.ai || 'veteran';
  const n = parseInt(args.n || '240', 10);
  const seed0 = parseInt(args.seed0 || '7000', 10);
  const priceMult = args.priceMult ? parseFloat(args.priceMult) : 1;
  const out = args.out || path.join(__dirname, 'raw', setup + '.json');

  // The spiral test is the shared issue 1085 one (25 percent repair, capped at
  // what is missing), not run 1's full-repair copy. commission_policy.js holds
  // the one-order-at-a-time gate used at the purchase point.
  const spiralPath = path.join(REPO, 'contrib', 'deepseek', 'chorus_biomass_1118', 'sim', 'spiral.js');
  const extra = [
    fs.readFileSync(path.join(__dirname, 'bot.js'), 'utf8'),
    fs.readFileSync(spiralPath, 'utf8'),
    fs.readFileSync(path.join(__dirname, 'commission_policy.js'), 'utf8'),
    fs.readFileSync(path.join(__dirname, 'driver_ge.js'), 'utf8'),
  ];
  const G = loadGame(REPO, { extra });

  const admirals = G.api.get(`Object.keys(ADMIRALS).filter(k=>(ADMIRALS[k].fac||'voidsworn')===${JSON.stringify(fac)})`);
  if (!admirals.length) throw new Error('no admirals for ' + fac);
  const t0 = Date.now();
  const runs = [];
  const meta = { setup, fac, ge: def.ge, admirals, ai, n, seed0, priceMult, repo: REPO };
  const writeOut = () => fs.writeFileSync(out, JSON.stringify({ meta: { ...meta, done: runs.length, seconds: (Date.now() - t0) / 1000 }, runs }));

  for (let i = 0; i < n; i++) {
    const cfg = {
      fac, admiral: admirals[i % admirals.length], ai, setup, seed: seed0 + i,
      priceMult, ge: def.ge,
    };
    const S = await G.api.runOne(cfg);
    runs.push(S);
    if ((i + 1) % 50 === 0) writeOut();
    if ((i + 1) % 20 === 0 || i === n - 1) {
      const wins = runs.filter(r => r.won).length, errs = runs.filter(r => r.errors.length).length;
      console.log(`[${setup}] ${i + 1}/${n} runs, ${((Date.now() - t0) / 1000).toFixed(1)}s, wins ${wins}, errors ${errs}`);
    }
  }
  writeOut();
  console.log('wrote', out, 'in', ((Date.now() - t0) / 1000).toFixed(1) + 's');
}
main().catch(e => { console.error(e); process.exit(1); });
