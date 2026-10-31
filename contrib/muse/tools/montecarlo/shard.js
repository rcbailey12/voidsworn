// shard.js - runs a batch of campaign runs in one process and writes JSON.
// Usage: node shard.js --out raw/x.json --n 100 --seed0 1000 --ai veteran \
//        [--fac voidsworn] [--admirals a,b] [--priceMult 0.8] [--cpDelta 4] \
//        [--credMult 1.2] [--replace campaign3d.js:::PATTERN:::REPL ...]
'use strict';
const fs = require('fs');
const { loadGame } = require('./loader_main');

const REPO = process.env.MC_REPO || require('path').join(__dirname, '..', 'voidsworn-fresh');
const args = {};
const replace = [];
for (let i = 2; i < process.argv.length; i++) {
  const a = process.argv[i];
  if (a === '--replace') { const [f, p, r] = process.argv[++i].split(':::'); replace.push({ file: f, pattern: p, repl: r }); }
  else if (a.startsWith('--')) args[a.slice(2)] = process.argv[++i];
}
const replMap = {};
for (const r of replace) { (replMap[r.file] = replMap[r.file] || []).push([r.pattern, r.repl]); }

async function main() {
  const extra = [fs.readFileSync(require('path').join(__dirname, 'bot.js'), 'utf8'), fs.readFileSync(require('path').join(__dirname, 'driver.js'), 'utf8'), fs.readFileSync(require('path').join(__dirname, 'policies.js'), 'utf8')];
  const G = loadGame(REPO, { replace: replMap, extra });
  const runOne = G.api.runOne;

  const fac = args.fac || 'voidsworn';
  const admirals = args.admirals
    ? args.admirals.split(',')
    : G.api.get(`Object.keys(ADMIRALS).filter(k=>(ADMIRALS[k].fac||'voidsworn')===${JSON.stringify(fac)})`);
  const n = parseInt(args.n || '10', 10);
  const seed0 = parseInt(args.seed0 || '1', 10);
  const ai = args.ai || 'veteran';
  const t0 = Date.now();
  const runs = [];
  const meta0 = { fac, admirals, ai, n, seed0, policy: args.policy || 'baseline', priceMult: args.priceMult || '1', cpDelta: args.cpDelta || '0', credMult: args.credMult || '1', replace };
  const writeOut = () => fs.writeFileSync(args.out, JSON.stringify({ meta: { ...meta0, done: runs.length, seconds: (Date.now() - t0) / 1000 }, runs }));
  for (let i = 0; i < n; i++) {
    const cfg = { fac, admiral: admirals[i % admirals.length], ai, seed: seed0 + i, policy: args.policy || 'baseline',
      priceMult: args.priceMult ? parseFloat(args.priceMult) : 1,
      cpDelta: args.cpDelta ? parseInt(args.cpDelta, 10) : 0,
      credMult: args.credMult ? parseFloat(args.credMult) : 1 };
    const S = await runOne(cfg);
    runs.push(S);
    if ((i + 1) % 50 === 0) writeOut();
    if ((i + 1) % 25 === 0 || i === n - 1) console.log(`[${args.out}] ${i + 1}/${n} runs, ${((Date.now() - t0) / 1000).toFixed(1)}s, wins ${runs.filter(r => r.won).length}, errors ${runs.filter(r => r.errors.length).length}`);
  }
  writeOut();
  console.log('wrote', args.out, 'in', ((Date.now() - t0) / 1000).toFixed(1) + 's');
}
main().catch(e => { console.error(e); process.exit(1); });
