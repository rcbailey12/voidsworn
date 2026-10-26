// Sweep summary: node sweep_check.js <file.json> <golden dir> <godot dir>
// Compares every battle in the sweep file record by record (compare.js) and prints one line per failure and a total.
'use strict';
const fs = require('fs'), path = require('path'), { spawnSync } = require('child_process');
const [file, gd, od] = process.argv.slice(2);
const L = JSON.parse(fs.readFileSync(file, 'utf8')); let ok = 0, bad = 0, recs = 0; const res = {};
for (const name of Object.keys(L)) {
  const a = path.join(gd, name + '.jsonl'), b = path.join(od, name + '.jsonl');
  if (!fs.existsSync(a) || !fs.existsSync(b)) { bad++; console.log(`  ${name}: FAIL (no ${fs.existsSync(a) ? 'Godot' : 'Node'} records)`); continue; }
  const r = spawnSync(process.execPath, [path.join(__dirname, 'compare.js'), 'scenario', a, b], { encoding: 'utf8' });
  if (r.status === 0) { ok++; const last = fs.readFileSync(a, 'utf8').trim().split('\n'); recs += last.length; const end = JSON.parse(last[last.length - 1]).actor; res[end] = (res[end] || 0) + 1; }
  else { bad++; const S = L[name]; console.log(`  ${name}: FAIL (${S.obj} ${S.shape} ${S.map}, ${S.fac_player} vs ${S.fac}, sector ${S.sector} ${S.kind}${S.alt === false ? ', Classic' : ''})\n    ` + r.stdout.trim().split('\n').slice(0, -1).join('\n    ')); }
}
console.log(`sweep: ${ok + bad} battles, ${ok} identical at every record (${recs} records), ${bad} differ; endings: ${Object.entries(res).map(([k, v]) => k.replace('end ', '') + ' ' + v).join(', ')}`);
console.log(bad ? 'FAIL' : 'PASS'); process.exit(bad ? 1 : 0);
