// Issue 371: a rules change (the R246 shield pool) changes every seeded battle, so some tree fixtures stop firing their pick.
// For each named fixture this tries seeds with the golden harness (the same run tree_effects_test.js makes) until the pick fires,
// then writes the first seed that works into godot/rules/test/scenarios.json. Rules parity must run after this on the final file.
//   node contrib/opus/tools/issue371/reseed_fixtures.js <fixture>=<tree key> [...]   (first seed tried: 37100, then upward)
const fs = require('fs'), os = require('os'), path = require('path'), { spawnSync } = require('child_process');
const ROOT = path.resolve(__dirname, '../../../..');
const GOLDEN = path.join(ROOT, 'godot/rules/test/node/golden.js'), SCEN = path.join(ROOT, 'godot/rules/test/scenarios.json');
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'reseed371-'));
const found = {};
for (const arg of process.argv.slice(2)) {
  const [name, key] = arg.split('=');
  for (let seed = 37100; seed < 37400; seed++) {
    const out = path.join(tmp, name + '.jsonl');
    const r = spawnSync(process.execPath, [GOLDEN, 'scenario', name, out, String(seed)], { cwd: ROOT, encoding: 'utf8' });
    if (r.status !== 0) continue;
    const lines = fs.readFileSync(out, 'utf8').trim().split('\n');
    const stats = JSON.parse(JSON.parse(lines[lines.length - 1]).state).b.treeStats || {};
    if (stats[key] >= 1) { found[name] = seed; console.log(name + ': seed ' + seed + ' fires ' + key); break; }
  }
  if (!found[name]) console.log('FAIL ' + name + ': no seed in 37100 to 37399 fires ' + key);
}
// edit only the seed lines, so the file keeps its layout
let text = fs.readFileSync(SCEN, 'utf8');
const data = JSON.parse(text);
for (const [name, seed] of Object.entries(found)) {
  const start = text.indexOf('\n "' + name + '": {'); if (start < 0) throw new Error('cannot find ' + name);
  const end = text.indexOf('\n }', start);
  const block = text.slice(start, end), old = '"seed": ' + data[name].seed + ',';
  if (!block.includes(old)) throw new Error('no seed line in ' + name);
  text = text.slice(0, start) + block.replace(old, '"seed": ' + seed + ',') + text.slice(end);
}
JSON.parse(text); fs.writeFileSync(SCEN, text);
fs.rmSync(tmp, { recursive: true, force: true });
process.exitCode = Object.keys(found).length === process.argv.length - 2 ? 0 : 1;
