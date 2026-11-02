// Full campaign measure. Uses Muse's unmodified baseline driver and current rules.
// Usage: node contrib/opus/tools/run_montecarlo.js --runs 50 --seed 1
// Optional: --faction ID --admiral ID --out report.md
// Runs are per faction, rotating through its admirals in game-table order.
'use strict';
const fs = require('fs');
const path = require('path');
const Module = require('module');
const root = path.resolve(__dirname, '../../..');
const source = path.join(root, 'contrib/muse/tools/montecarlo');

function readSource(name) {
  const text = fs.readFileSync(path.join(source, name), 'utf8').replace(/^\uFEFF/, '');
  const compact = text.replace(/\s/g, '');
  if (compact.length && compact.length % 4 === 0 && /^[A-Za-z0-9+/]+={0,2}$/.test(compact)) {
    return { text: Buffer.from(compact, 'base64').toString('utf8'), encoded: true };
  }
  return { text, encoded: false };
}
function parse() {
  const opts = { runs: 50, seed: 1 };
  for (let i = 2; i < process.argv.length; i++) {
    const key = process.argv[i];
    if (key === '--help') {
      console.log('Usage: node contrib/opus/tools/run_montecarlo.js [--runs N] [--seed UINT32] [--faction ID] [--admiral ID] [--out file]\nDefault: 50 runs per faction, seed 1, all six factions, rotating all admirals.');
      return null;
    }
    if (!['--runs', '--seed', '--faction', '--admiral', '--out'].includes(key)) throw Error('Unknown argument: ' + key);
    const value = process.argv[++i];
    if (!value || value.startsWith('--')) throw Error('Missing value for ' + key);
    opts[key.slice(2)] = value;
  }
  for (const key of ['runs', 'seed']) {
    if (!/^\d+$/.test(String(opts[key]))) throw Error('--' + key + ' must be an integer');
    opts[key] = Number(opts[key]);
    if (!Number.isSafeInteger(opts[key]) || opts[key] < (key === 'runs' ? 1 : 0)) throw Error('Invalid --' + key);
  }
  if (opts.seed + opts.runs - 1 > 0xffffffff) throw Error('Seed range exceeds UINT32');
  if (opts.out) {
    opts.out = path.resolve(opts.out);
    const rel = path.relative(root, opts.out);
    if (!rel || rel.startsWith('..') || path.isAbsolute(rel)) throw Error('--out must be inside the repo folder');
    // Never overwrite a source file or an existing report accidentally.
    if (fs.existsSync(opts.out)) throw Error('--out already exists: ' + opts.out);
    if (!fs.statSync(path.dirname(opts.out)).isDirectory()) throw Error('Output directory does not exist');
  }
  return opts;
}
function interval(k, n) {
  const z = 1.96, p = k / n, d = 1 + z*z/n;
  const c = p + z*z/(2*n), m = z*Math.sqrt(p*(1-p)/n + z*z/(4*n*n));
  return [Math.max(0, (c-m)/d), Math.min(1, (c+m)/d)];
}
const pct = n => (100*n).toFixed(1) + '%';
const ascii = s => String(s).replace(/[^\x20-\x7e\r\n]/g, '?');
function row(label, runs) {
  if (!runs.length) return `| ${ascii(label)} | 0 | n/a | n/a | 0 | 0 | 0 | 0 | n/a |`;
  const wins = runs.filter(r => r.won).length;
  const sectors = [1,2,3].map(s => runs.filter(r => !r.won && r.sectorReached === s).length);
  return `| ${ascii(label)} | ${runs.length} | ${pct(wins/runs.length)} | ${interval(wins,runs.length).map(pct).join(' to ')} | ${sectors.join(' | ')} | ${wins} | ${(runs.reduce((s,r)=>s+r.battles.length,0)/runs.length).toFixed(2)} |`;
}
async function main() {
  const opts = parse(); if (!opts) return;
  const started = Date.now();
  let temp;
  try {
    const loader = readSource('loader_main.js');
    let loaderPath = path.join(source, 'loader_main.js');
    if (loader.encoded) {
      temp = fs.mkdtempSync(path.join(root, '.montecarlo-temp-'));
      loaderPath = path.join(temp, 'loader_main.js');
      fs.writeFileSync(loaderPath, loader.text);
    }
    const mod = new Module(loaderPath, module);
    mod.filename = loaderPath; mod.paths = Module._nodeModulePaths(path.dirname(loaderPath));
    mod._compile(loader.text, loaderPath);
    const extra = ['bot.js', 'driver.js', 'policies.js'].map(name => {
      const data = readSource(name);
      if (data.encoded) {
        if (!temp) temp = fs.mkdtempSync(path.join(root, '.montecarlo-temp-'));
        fs.writeFileSync(path.join(temp, name), data.text);
      }
      return data.text;
    });
    const game = mod.exports.loadGame(root, { extra });
    const factions = game.api.get('RUN_FACTIONS.slice()');
    const admirals = game.api.get('ADMIRALS');
    const names = game.api.get('FACTIONS');
    if (opts.faction && !factions.includes(opts.faction)) throw Error('Unknown faction. Choose: ' + factions.join(', '));
    if (opts.admiral && !Object.hasOwn(admirals, opts.admiral)) throw Error('Unknown admiral. Choose: ' + Object.keys(admirals).join(', '));
    const admFac = opts.admiral && (admirals[opts.admiral].fac || 'voidsworn');
    if (opts.faction && admFac && opts.faction !== admFac) throw Error('Admiral belongs to ' + admFac);
    const selected = opts.faction ? [opts.faction] : admFac ? [admFac] : factions;
    const all = [], groups = [];
    for (const fac of selected) {
      const ids = opts.admiral ? [opts.admiral] : Object.keys(admirals).filter(id => (admirals[id].fac || 'voidsworn') === fac);
      if (!ids.length) throw Error('No admirals for ' + fac);
      const runs = [];
      for (let i = 0; i < opts.runs; i++) {
        const r = await game.api.runOne({ fac, admiral: ids[i % ids.length], ai: 'veteran', seed: opts.seed+i, policy: 'baseline', priceMult: 1, cpDelta: 0, credMult: 1 });
        runs.push(r); all.push(r);
        if ((i+1)%10 === 0 || i+1 === opts.runs) console.error(`${fac}: ${i+1}/${opts.runs}, ${((Date.now()-started)/1000).toFixed(1)}s elapsed`);
      }
      groups.push({ fac, ids, runs });
    }
    const lines = ['# Campaign Monte Carlo', '',
      `Seed: ${opts.seed} through ${opts.seed+opts.runs-1} per faction. Runs per faction: ${opts.runs}. AI: veteran. Policy: baseline. No tuning overrides.`, '',
      'Playtest everything unlocked state: NOT enabled. The browser has no such switch. The driver calls defaultMeta() before every run: renown 0, unlocked {}, admirals {vex:true}, mastery {}, favour {}, variants {}, heatBest {}, no previous wins. It directly selects any requested admiral, bypassing ownership selection. Standard starting fleet, default Command, Heat 0; progression earned within a run applies, but does not carry into the next run.', '',
      'Admirals rotate in game-table order. --admiral alone selects its faction. The same seed range is reused for each faction. These are bot rates, not player win rates.', '',
      'S1/S2/S3 are mutually exclusive counts of non-winning runs ending in that sector (including errors). Won is the full-run victory count.', '',
      '| Faction / admiral (ID) | Runs | Full-run win | Binomial 95% CI | S1 | S2 | S3 | Won | Avg battles |',
      '| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: |'];
    for (const {fac,ids,runs} of groups) {
      lines.push(row(`${names[fac].n} (${fac})`, runs));
      for (const id of ids) lines.push(row(`  ${admirals[id].n} (${id})`, runs.filter(r=>r.admiral===id)));
    }
    lines.push(row('Overall', all), '',
      'Noise: Wilson binomial 95% intervals describe sampling uncertainty under this bot. Small admiral samples are noisy. Fixed seeds reproduce the sample; factions sharing seeds are not independent, and the pooled interval is descriptive.',
      `Driver errors: ${all.filter(r=>r.errors.length).length} runs. Battle timeouts: ${all.reduce((s,r)=>s+r.timeouts,0)}.`);
    for (const r of all.filter(r=>r.errors.length)) lines.push(ascii(`- ${r.fac}/${r.admiral}, seed ${r.seed}: ${r.errors.join('; ')}`));
    lines.push(`Run time: ${((Date.now()-started)/1000).toFixed(2)} seconds.`, '');
    const report = lines.map(ascii).join('\n');
    if (opts.out) fs.writeFileSync(opts.out, report, { flag: 'wx' });
    process.stdout.write(report);
    if (all.some(r=>r.errors.length)) process.exitCode = 1;
  } finally {
    if (temp) {
      const rel = path.relative(root, path.resolve(temp));
      if (!rel.startsWith('.montecarlo-temp-') || rel.includes(path.sep)) throw Error('Unexpected temporary path');
      fs.rmSync(temp, { recursive: true, force: true });
    }
  }
}
main().catch(e => { console.error(ascii(e.stack || e)); process.exitCode = 1; });
