// run_sim.js - issue 1085 Chorus biomass economy sim.
// Loads the shipped game files read only (repo root) with an in memory patch
// layer (driver_biomass.js) and runs the existing campaign bot on a seed block.
// Usage:
//   node run_sim.js --setup baseline|biomass|biomass_kill --n 240 --seed0 7000 --out raw/x.json
//     [--ai veteran] [--fac chorus] [--killRate 2] [--killCap 12] [--priceMult 1]
// All game files are read from MC_REPO (default: the repo root four folders up).
'use strict';
const fs = require('fs');
const path = require('path');
const { loadGame } = require('./loader_main');

const REPO = process.env.MC_REPO || path.resolve(__dirname, '..', '..', '..', '..');

const args = {};
for (let i = 2; i < process.argv.length; i++) {
  const a = process.argv[i];
  if (a.startsWith('--')) args[a.slice(2)] = process.argv[++i];
}

async function main() {
  const setup = args.setup || 'baseline';
  const fac = args.fac || 'chorus';
  const ai = args.ai || 'veteran';
  const n = parseInt(args.n || '240', 10);
  const seed0 = parseInt(args.seed0 || '7000', 10);
  const killRate = parseFloat(args.killRate || '2');
  const killCap = parseFloat(args.killCap || '12');
  const priceMult = args.priceMult ? parseFloat(args.priceMult) : 1;
  const out = args.out || path.join(__dirname, 'raw', setup + '.json');

  const extra = [
    fs.readFileSync(path.join(__dirname, 'bot.js'), 'utf8'),
    fs.readFileSync(path.join(__dirname, 'spiral.js'), 'utf8'),
    fs.readFileSync(path.join(__dirname, 'driver_biomass.js'), 'utf8'),
  ];
  const G = loadGame(REPO, { extra });

  const admirals = G.api.get(`Object.keys(ADMIRALS).filter(k=>(ADMIRALS[k].fac||'voidsworn')===${JSON.stringify(fac)})`);
  const t0 = Date.now();
  const runs = [];
  const meta = { setup, fac, admirals, ai, n, seed0, priceMult, killRate: setup === 'biomass_kill' ? killRate : 0, killCap: setup === 'biomass_kill' ? killCap : 0, repo: REPO };
  const writeOut = () => fs.writeFileSync(out, JSON.stringify({ meta: { ...meta, done: runs.length, seconds: (Date.now() - t0) / 1000 }, runs }));

  for (let i = 0; i < n; i++) {
    const cfg = {
      fac, admiral: admirals[i % admirals.length], ai, setup,
      seed: seed0 + i, priceMult,
      killRate: setup === 'biomass_kill' ? killRate : 0,
      killCap: setup === 'biomass_kill' ? killCap : 0,
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
