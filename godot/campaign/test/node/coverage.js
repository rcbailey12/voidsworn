// G3 campaign parity: what the seeded runs exercised, in plain counts (report only).
//   node coverage.js <first_seed> <last_seed>
'use strict';
const { execFileSync } = require('child_process'), fs = require('fs'), path = require('path'), os = require('os');
const a = +process.argv[2] || 1, z = +process.argv[3] || 24, tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'vscov'));
const acts = {}, ends = { victory: 0, lost: 0 }; let steps = 0, sectors = [0, 0, 0, 0];
for (let s = a; s <= z; s++) {
  const f = path.join(tmp, 'c' + s + '.jsonl'); execFileSync(process.execPath, [path.join(__dirname, 'golden_campaign.js'), String(s), f]);
  const L = fs.readFileSync(f, 'utf8').trim().split('\n').map(l => JSON.parse(l)); steps += L.length;
  let lastRun = null; for (const r of L) { acts[r.act] = (acts[r.act] || 0) + 1; if (r.act === 'battle') acts['battle:' + r.arg] = (acts['battle:' + r.arg] || 0) + 1; if (r.act === 'takeSalvage') acts['takeSalvage:' + r.arg.split(':')[1]] = (acts['takeSalvage:' + r.arg.split(':')[1]] || 0) + 1; if (r.run && r.run !== 'null') lastRun = r.run; }
  const meta = L.filter(r => r.meta).pop(); const run = lastRun ? JSON.parse(lastRun) : null; if (run) sectors[run.sector]++;
  const m = JSON.parse(meta.meta); if ((m.stats.wins || 0) > ((s % 4 >= 2) ? (s % 4) - 1 : 0)) ends.victory++; else ends.lost++;
  fs.unlinkSync(f); }
console.log('seeds ' + a + ' to ' + z + ': ' + steps + ' steps; runs won ' + ends.victory + ', lost or abandoned ' + ends.lost + '; deepest sector reached: ' + sectors.slice(1).map((n, i) => 'S' + (i + 1) + ' ' + n).join(', '));
console.log(Object.keys(acts).sort().map(k => k + ' ' + acts[k]).join(', '));
