'use strict';
// Issue 238, MP8: report only. Monte Carlo of the Godot campaign map's danger bands against measured bot outcomes.
// The band estimate is copied line for line from godot/ui/campaign/map_intel.gd danger(), evaluated on the campaign
// state just before each fight the existing campaign sim harness plays. Then, per band, the script reports how often the
// bot actually won, and fits a logistic curve P(win) = sigmoid(a + b * ratio) so the cut points can be re-ruled from
// data instead of by hand (the Flash fit option, UI audit synthesis section 5.2).
//
//   node contrib/opus/tools/danger_bands_montecarlo.js [--runs 12] [--seed 1] [--faction ID] [--out FILE.json]
//
// Runs are per faction, rotating that faction's admirals in table order, as run_montecarlo.js does. No tuning overrides.

const fs = require('fs');
const path = require('path');
const Module = require('module');
const ROOT = path.resolve(__dirname, '../../..');
const SOURCE = path.join(ROOT, 'contrib/muse/tools/montecarlo');
const BANDS = [[0.8, 'Easy'], [1.05, 'Even'], [1.4, 'Hard'], [99.0, 'Deadly']];

function readSource(name) {
  const text = fs.readFileSync(path.join(SOURCE, name), 'utf8').replace(/^\uFEFF/, '');
  const compact = text.replace(/\s/g, '');
  if (compact.length && compact.length % 4 === 0 && /^[A-Za-z0-9+/]+={0,2}$/.test(compact)) return { text: Buffer.from(compact, 'base64').toString('utf8'), encoded: true };
  return { text, encoded: false };
}

function parse() {
  const opts = { runs: 12, seed: 1 };
  for (let i = 2; i < process.argv.length; i++) {
    const key = process.argv[i];
    if (key === '--help') {
      console.log('Usage: node danger_bands_montecarlo.js [--runs N] [--seed UINT32] [--faction ID] [--out FILE.json]');
      return null;
    }
    if (!['--runs', '--seed', '--faction', '--out'].includes(key)) throw Error('Unknown argument: ' + key);
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
    const rel = path.relative(ROOT, opts.out);
    if (!rel || rel.startsWith('..') || path.isAbsolute(rel)) throw Error('--out must be inside the repo folder');
    if (!fs.statSync(path.dirname(opts.out)).isDirectory()) throw Error('Output directory does not exist');
  }
  return opts;
}

// The extra source appended after the harness driver. It replaces mcFight with the same function plus one danger
// record per fight, evaluated before the battle starts. Nothing else in the driver changes.
const EXTRA = `
const MC_BANDS = ${JSON.stringify(BANDS)};
function mcBand(ratio) { for (const b of MC_BANDS) if (ratio < b[0]) return b[1]; return 'Deadly'; }
function mcDangerFor(cfg, isNem) {
  const n = cfg && cfg.node ? findNode(cfg.node) : null;
  const s = RUN.sector;
  const col = Number(cfg && cfg.col != null ? cfg.col : (n ? n.col : 1));
  let kind = String((cfg && cfg.kind) || 'battle');
  if (isNem) kind = 'elite';
  const R = RAMP;
  let budget = ([0, 4.2, 9.5, 14][s] + col * (s === 1 ? 0.9 : (s === 2 ? 1 : 1.1))) * Number(R.grow[s]);
  if (kind === 'elite') budget *= 1.05;
  const P = fleetPower();
  let bossPart = 0;
  if (kind === 'boss') {
    budget *= Number(R.boss[s]);
    const fac = RUN.map.fac;
    const btpl = FACTIONS[fac] && FACTIONS[fac].boss;
    const bcp = btpl != null && HULLS[btpl] ? Number(HULLS[btpl].cp || 6) : 6;
    const fit = Math.max(0.55, Math.min(1, P / [0, 6, 9, 12][s]));
    bossPart = bcp * Number(BOSS_SCALE[s]) * fit * Number(BOSS_FAC[fac] != null ? BOSS_FAC[fac] : 1) * Number(BOSS_DMG[s]) * (heatOn('h_flag') ? 1.2 : 1) * 1.6;
  }
  budget *= Math.max(Number(R.pwMin), Math.min(Number(R.pwMax), Math.pow(Math.max(0.5, P) / Number(R.refP[s]), Number(R.pw))));
  if (typeof AI_LEVEL !== 'undefined' && AI_LEVEL === 'standard') budget *= Number(R.std);
  if (heatOn('h_hunted')) budget *= 1.15;
  if (n && n.mod === 'bounty') budget *= 1.1;
  const tough = (1 + 0.12 * (s - 1)) * (1 + 0.08 * (s - 1)) * Number(R.thin[s]) * (kind === 'boss' ? Number(R.escort) : 1);
  let threat = budget * tough + bossPart;
  if (kind === 'elite') threat *= 1.25;
  if (n && n.mod === 'veteran') threat *= 1.08;
  if (heatOn('h_elite')) threat *= 1.08;
  if (isNem && RUN.nem) {
    const N = RUN.nem;
    const sc = Number(N.scars || 0), ad = (N.adapt || []).length;
    if (sc > 0) threat *= 1 + 0.1 * sc;
    if (ad > 0) threat *= 1 + 0.06 * ad;
    const tr = N.traits || [];
    let k = 1; for (const x of tr) k *= x === 'veterans' ? 1.12 : 1.05;
    threat *= k;
    threat *= 1 + Math.min(0.32, 0.04 * Number(N.fed || 0));
    threat *= 1 + 0.06 * Math.min(3, Number(N.honed || 0));
    let beh = null; try { beh = nemBeh(N); } catch (e) {}
    const raid = beh && beh.strike === 'raid';
    const rich = (raid ? Number(N.riches || 0) : 0) + ((N.adapt || []).includes('riches') ? 1 : 0);
    if (rich > 0) threat += rich * 1.2 * tough;
  }
  const ratio = threat / Math.max(0.5, P);
  return { ratio, band: mcBand(ratio), threat, power: P, kind, sector: s, col, node: cfg ? cfg.node : null, nem: !!isNem };
}
const MC_ORIG_FIGHT = mcFight;
mcFight = async function(cfg, S, isNem) {
  const d = mcDangerFor(cfg, isNem);
  const r = await MC_ORIG_FIGHT(cfg, S, isNem);
  const rec = S.battles[S.battles.length - 1] || {};
  d.res = rec.res || ''; d.rounds = rec.rounds || 0; d.lost = rec.lost || 0;
  d.won = d.res === 'win';
  if (!S.danger) S.danger = [];
  S.danger.push(d);
  return r;
};
`;

function interval(k, n) {
  const z = 1.96, p = k / n, d = 1 + z * z / n;
  const c = p + z * z / (2 * n), m = z * Math.sqrt(p * (1 - p) / n + z * z / (4 * n * n));
  return [Math.max(0, (c - m) / d), Math.min(1, (c + m) / d)];
}
const pct = n => (100 * n).toFixed(1) + '%';
const ascii = s => String(s).replace(/[^\x20-\x7e\r\n]/g, '?');

function fitLogistic(rows) {
  const xs = rows.map(r => r.ratio), ys = rows.map(r => (r.won ? 1 : 0));
  const n = xs.length;
  if (!n) return null;
  const mean = xs.reduce((a, b) => a + b, 0) / n;
  const sd = Math.sqrt(xs.reduce((a, b) => a + (b - mean) * (b - mean), 0) / n) || 1;
  let a = 0, b = 0;
  const lr = 0.5;
  for (let step = 0; step < 40000; step++) {
    let ga = 0, gb = 0;
    for (let i = 0; i < n; i++) {
      const z = a + b * ((xs[i] - mean) / sd);
      const p = 1 / (1 + Math.exp(-z));
      const e = p - ys[i];
      ga += e; gb += e * ((xs[i] - mean) / sd);
    }
    ga /= n; gb /= n;
    a -= lr * ga; b -= lr * gb;
    if (Math.abs(ga) + Math.abs(gb) < 1e-10) break;
  }
  // P(win) = sigmoid(A + B * ratio)
  const A = a - b * mean / sd, B = b / sd;
  const prob = r => 1 / (1 + Math.exp(-(A + B * r)));
  const ratioAt = p => (Math.log(p / (1 - p)) - A) / B;
  return { A, B, mean, sd, prob, ratioAt };
}

function auc(rows) {
  // score is -ratio, so a higher score means the band model says the fight is easier; AUC 0.5 is no separation.
  const pos = rows.filter(r => r.won), neg = rows.filter(r => !r.won);
  let sum = 0;
  for (const p of pos) for (const q of neg) sum += -p.ratio > -q.ratio ? 1 : (-p.ratio === -q.ratio ? 0.5 : 0);
  return pos.length && neg.length ? sum / (pos.length * neg.length) : null;
}

async function main() {
  const opts = parse(); if (!opts) return;
  const started = Date.now();
  let temp;
  try {
    const loader = readSource('loader_main.js');
    let loaderPath = path.join(SOURCE, 'loader_main.js');
    if (loader.encoded) {
      temp = fs.mkdtempSync(path.join(ROOT, '.danger-temp-'));
      loaderPath = path.join(temp, 'loader_main.js');
      fs.writeFileSync(loaderPath, loader.text);
    }
    const mod = new Module(loaderPath, module);
    mod.filename = loaderPath; mod.paths = Module._nodeModulePaths(path.dirname(loaderPath));
    mod._compile(loader.text, loaderPath);
    const extra = ['bot.js', 'driver.js', 'policies.js'].map(name => {
      const data = readSource(name);
      if (data.encoded) {
        if (!temp) temp = fs.mkdtempSync(path.join(ROOT, '.danger-temp-'));
        fs.writeFileSync(path.join(temp, name), data.text);
      }
      return data.text;
    });
    extra.push(EXTRA);
    const game = mod.exports.loadGame(ROOT, { extra });
    const factions = game.api.get('RUN_FACTIONS.slice()');
    const admirals = game.api.get('ADMIRALS');
    if (opts.faction && !factions.includes(opts.faction)) throw Error('Unknown faction. Choose: ' + factions.join(', '));
    const all = [];
    for (const fac of (opts.faction ? [opts.faction] : factions)) {
      const ids = Object.keys(admirals).filter(id => (admirals[id].fac || 'voidsworn') === fac);
      if (!ids.length) throw Error('No admirals for ' + fac);
      for (let i = 0; i < opts.runs; i++) {
        const r = await game.api.runOne({ fac, admiral: ids[i % ids.length], ai: 'veteran', seed: opts.seed + i, policy: 'baseline', priceMult: 1, cpDelta: 0, credMult: 1 });
        for (const d of (r.danger || [])) all.push(d);
        if ((i + 1) % 5 === 0 || i + 1 === opts.runs) console.error(`${fac}: ${i + 1}/${opts.runs}, ${all.length} fights, ${((Date.now() - started) / 1000).toFixed(1)}s elapsed`);
      }
    }
    const fights = all.filter(d => d.res !== 'timeout');
    const byKind = {};
    for (const d of fights) byKind[d.kind] = (byKind[d.kind] || 0) + 1;
    function bandRows(set) {
      const byBand = {};
      for (const [lo, name] of BANDS) byBand[name] = { band: name, lower: lo, fights: 0, wins: 0, losses: 0, retreats: 0 };
      for (const d of set) {
        const b = byBand[d.band]; if (!b) continue;
        b.fights++;
        if (d.won) b.wins++; else b.losses++;
        if (d.res === 'retreat') b.retreats++;
      }
      return Object.values(byBand).map(b => ({ ...b, win_rate: b.fights ? b.wins / b.fights : null,
        ci: b.fights ? interval(b.wins, b.fights) : null }));
    }
    function fitOutFor(set) {
      const fit = fitLogistic(set);
      return fit ? {
        A: fit.A, B: fit.B, auc: auc(set), fights: set.length,
        probabilities_at_old_cut_points: [0.8, 1.05, 1.4].map(x => ({ ratio: x, p: fit.prob(x) })),
        ratio_at_probability: [0.9, 0.75, 0.6, 0.5, 0.4, 0.25, 0.1].map(p => ({ p, ratio: fit.ratioAt(p) })),
      } : null;
    }
    const fightsNonBoss = fights.filter(d => d.kind !== 'boss');
    const rows = bandRows(fights);
    const report = {
      item: 'MP8 danger bands against measured bot outcomes', seed: opts.seed, runs_per_faction: opts.runs,
      factions: opts.faction ? [opts.faction] : factions, fights: fights.length, fights_by_kind: byKind,
      ai: 'veteran', policy: 'baseline', bands_source: 'godot/ui/campaign/map_intel.gd BANDS',
      bands: rows,
      logistic_fit: fitOutFor(fights),
      bands_non_boss: bandRows(fightsNonBoss),
      logistic_fit_non_boss: fitOutFor(fightsNonBoss),
      note: 'Retreats count as not won. Timeouts are left out (the sim maps a non-boss timeout to a retreat). Boss fights are one per run; the non-boss block leaves them out.',
      elapsed_s: (Date.now() - started) / 1000,
    };
    if (opts.out) fs.writeFileSync(opts.out, JSON.stringify(report, null, 2) + '\n');
    console.log('MP8 danger bands: ' + fights.length + ' fights (' + JSON.stringify(byKind) + ')');
    for (const r of rows) console.log(`  ${r.band}: ${r.fights} fights, ${r.wins} won (${r.fights ? pct(r.win_rate) : 'n/a'})${r.ci ? ', 95% ' + r.ci.map(pct).join(' to ') : ''}, retreats ${r.retreats}`);
    const fo = report.logistic_fit;
    if (fo) {
      console.log(`  logistic P(win)=sigmoid(${fo.A.toFixed(3)} + ${fo.B.toFixed(3)} * ratio), AUC ${fo.auc == null ? 'n/a' : fo.auc.toFixed(3)}`);
      console.log('  P(win) at old cut points: ' + fo.probabilities_at_old_cut_points.map(x => `${x.ratio}:${pct(x.p)}`).join(', '));
      console.log('  ratio at P(win): ' + fo.ratio_at_probability.map(x => `${x.p}:${x.ratio.toFixed(3)}`).join(', '));
    }
    console.log('MP8 non-boss only: ' + fightsNonBoss.length + ' fights');
    for (const r of report.bands_non_boss) console.log(`  ${r.band}: ${r.fights} fights, ${r.wins} won (${r.fights ? pct(r.win_rate) : 'n/a'})${r.ci ? ', 95% ' + r.ci.map(pct).join(' to ') : ''}`);
    const fon = report.logistic_fit_non_boss;
    if (fon) {
      console.log(`  logistic P(win)=sigmoid(${fon.A.toFixed(3)} + ${fon.B.toFixed(3)} * ratio), AUC ${fon.auc == null ? 'n/a' : fon.auc.toFixed(3)}`);
      console.log('  P(win) at old cut points: ' + fon.probabilities_at_old_cut_points.map(x => `${x.ratio}:${pct(x.p)}`).join(', '));
      console.log('  ratio at P(win): ' + fon.ratio_at_probability.map(x => `${x.p}:${x.ratio.toFixed(3)}`).join(', '));
    }
    console.log('PASS: report only, MP8 Monte Carlo ran');
  } finally {
    if (temp) {
      const rel = path.relative(ROOT, path.resolve(temp));
      if (!rel.startsWith('.danger-temp-') || rel.includes(path.sep)) throw Error('Unexpected temporary path');
      fs.rmSync(temp, { recursive: true, force: true });
    }
  }
}
main().catch(e => { console.error(ascii(e.stack || e)); process.exitCode = 1; });
