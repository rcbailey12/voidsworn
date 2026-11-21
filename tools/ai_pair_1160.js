// Issue 1160: paired-seed enemy AI harness (issue 1062's method, widened).
// Every row is one enemy faction, one sector and one AI level. Battle i of a row always uses the same seed and objective, so a run on
// main and a run on the branch (and the two levels) meet the same draws; the difference is the AI change, not a drifted random stream.
// The battles themselves run in sim3d.js (mode aipair): the headless player bot with the Sunward reference fleet of the sector against
// the game's own enemy generator, alternating activations, objectives rotating rout, rout, flagship, hold, intercept.
//
//   node tools/ai_pair_1160.js run <out.json> [n per row, default 200] [workers, default 4]
//   node tools/ai_pair_1160.js table <before.json> <after.json>     (markdown table, before and after)
//   EQUAL=1 in the environment gives both levels the same fleet budget (AI decisions only).
const fs = require('fs'), path = require('path'), os = require('os'), { spawn } = require('child_process');
const FACS = ['voidsworn', 'hegemony', 'corsair', 'chorus', 'ithar', 'deathless'];
const NAMES = { voidsworn: 'Sunward Crusade', hegemony: 'Hegemony Navy', corsair: 'Ashfall Hullbreakers', chorus: 'the Chorus', ithar: 'the Glasswrights', deathless: 'Eclipse' };
const LEVELS = ['standard', 'veteran'], SECTORS = [1, 2, 3];
const ROOT = path.join(__dirname, '..');

function seedOf(fac, sec, i) { return 1160000 + sec * 10000 + FACS.indexOf(fac) * 1000 + i; }
function jobs(n, facs, secs, levels) {
  const out = [];
  for (const lvl of levels) for (const sec of secs) for (const fac of facs) for (let i = 0; i < n; i++)
    out.push({ k: [lvl, sec, fac, i].join('|'), fac, sec, lvl, seed: seedOf(fac, sec, i), obj: i % 5 });
  return out;
}
function median(a) { const s = a.slice().sort((x, y) => x - y); return s.length ? (s.length % 2 ? s[(s.length - 1) / 2] : (s[s.length / 2 - 1] + s[s.length / 2]) / 2) : 0; }
function summarize(results) {
  const rows = {}, add = (key, r) => { const R = rows[key] || (rows[key] = { n: 0, wins: 0, rounds: [], past12: 0, timeouts: 0, eShips: 0, acts: 0, fired: 0, dist: 0 }); R.n++; R.acts += r.acts || 0; R.fired += r.fired || 0; R.dist += r.dist || 0; R.wins += r.win; R.rounds.push(r.rounds); if (r.rounds > 12) R.past12++; if (r.over === 'timeout') R.timeouts++; R.eShips += r.eShips; };
  for (const r of results) { const [lvl, sec, fac] = r.k.split('|'); add([lvl, sec, fac].join('|'), r); add([lvl, 'all', fac].join('|'), r); add([lvl, sec, 'all'].join('|'), r); add([lvl, 'all', 'all'].join('|'), r); }
  const o = {}; for (const [k, R] of Object.entries(rows)) o[k] = { n: R.n, win: +(R.wins / R.n * 100).toFixed(1), median: median(R.rounds), past12: R.past12, timeouts: R.timeouts, eShips: +(R.eShips / R.n).toFixed(1), firePct: +(R.fired / Math.max(1, R.acts) * 100).toFixed(1), range: +(R.dist / Math.max(1, R.acts)).toFixed(2) };
  return o;
}
function runShard(list, i) {
  return new Promise((res, rej) => {
    const f = path.join(os.tmpdir(), 'ai_pair_1160_' + process.pid + '_' + i + '.json'); fs.writeFileSync(f, JSON.stringify(list));
    const p = spawn(process.execPath, ['sim3d.js', 'aipair', f], { cwd: ROOT, env: process.env });
    let buf = ''; const out = []; p.stdout.on('data', d => { buf += d; let j; while ((j = buf.indexOf('\n')) >= 0) { const line = buf.slice(0, j); buf = buf.slice(j + 1); if (line.startsWith('{"k"')) out.push(JSON.parse(line)); } });
    p.stderr.on('data', d => process.stderr.write(d));
    p.on('close', c => { fs.unlinkSync(f); if (c) rej(new Error('shard ' + i + ' exit ' + c)); else res(out); });
  });
}
async function run(list, workers) {
  // fixed shard assignment by battle index, so a rerun groups the same battles in the same processes
  const shards = Array.from({ length: workers }, () => []); list.forEach((j, i) => shards[i % workers].push(j));
  const parts = await Promise.all(shards.map((s, i) => runShard(s, i)));
  const by = new Map([].concat(...parts).map(r => [r.k, r]));
  return list.map(j => by.get(j.k));
}
function table(A, B) {
  const L = [], pct = x => x.toFixed(1) + '%', d = (a, b) => (b - a >= 0 ? '+' : '') + (b - a).toFixed(1);
  L.push('| Level | Sector | Enemy | Battles | Player wins before | after | change | Median rounds before / after | Past round 12 before / after |');
  L.push('|---|---|---|---:|---:|---:|---:|---:|---:|');
  for (const lvl of LEVELS) for (const sec of ['all', ...SECTORS.map(String)]) for (const fac of ['all', ...FACS]) {
    const k = [lvl, sec, fac].join('|'), a = A.summary[k], b = B.summary[k]; if (!a || !b) continue;
    const lv = lvl === 'veteran' ? 'Veteran' : 'Standard', st = sec === 'all' ? 'all' : sec, fn = fac === 'all' ? 'all' : NAMES[fac];
    const bold = sec === 'all' && fac === 'all' ? '**' : '';
    L.push(`| ${bold}${lv}${bold} | ${st} | ${fn} | ${b.n} | ${pct(a.win)} | ${bold}${pct(b.win)}${bold} | ${d(a.win, b.win)} | ${a.median} / ${b.median} | ${a.past12} / ${b.past12} |`);
  }
  return L.join('\n');
}
async function main() {
  const [cmd, a1, a2, a3] = process.argv.slice(2);
  if (cmd === 'run') {
    const n = +(a2 || 200), workers = +(a3 || 4), t0 = Date.now();
    const list = jobs(n, (process.env.FACS || FACS.join(',')).split(','), (process.env.SECS || '1,2,3').split(',').map(Number), (process.env.LEVELS || LEVELS.join(',')).split(','));
    const results = await run(list, workers);
    if (results.some(r => !r)) throw new Error('missing battle results');
    const summary = summarize(results);
    fs.writeFileSync(a1, JSON.stringify({ n, equal: process.env.EQUAL === '1', results, summary }));
    for (const lvl of LEVELS) { const s = summary[lvl + '|all|all']; if (s) console.log(lvl.padEnd(9), 'battles', s.n, 'player wins', s.win + '%', 'median', s.median, 'past round 12', s.past12, 'timeouts', s.timeouts); }
    console.log('seconds', Math.round((Date.now() - t0) / 1000));
  } else if (cmd === 'table') {
    console.log(table(JSON.parse(fs.readFileSync(a1)), JSON.parse(fs.readFileSync(a2))));
  } else { console.log('usage: run <out.json> [n] [workers] | table <before.json> <after.json>'); process.exit(1); }
}
module.exports = { jobs, seedOf, summarize, median, run, table };
if (require.main === module) main().catch(e => { console.error(e); process.exit(1); });
