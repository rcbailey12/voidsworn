'use strict';
// Tests the file gate and its diagnostics, not game rules. All fixtures live under TEMP.
const assert = require('node:assert/strict'), fs = require('node:fs'), os = require('node:os'), path = require('node:path');
const R = require('./records'), { check } = require('./check'), { update } = require('./update');
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'saved-results-selftest-'));
const saved = path.join(root, 'saved'), scenarios = path.join(root, 'scenarios.json');
for (const d of ['out', 'golden']) fs.mkdirSync(path.join(root, d));
const scenario = { example: { seed: 7 } };
fs.writeFileSync(scenarios, JSON.stringify(scenario));
const log = path.join(root, 'worker.log'), part = path.join(root, 'part.json');
fs.writeFileSync(part, JSON.stringify(scenario));
const goodLog = `batch start example\nbatch result example exit 0\nbatch 1 battles -> ${path.join(root, 'out')}\n`;
fs.writeFileSync(log, goodLog);
const batch = { names: ['example'], workers: [{ names: ['example'], file: part, log, godot: { code: 0 } }] };
fs.writeFileSync(path.join(root, 'batches.json'), JSON.stringify(batch));
fs.writeFileSync(path.join(root, 'summary.json'), JSON.stringify({ battles: 1, failures: 0 }));
const state = { b: { round: 1 }, g: { uid: 1 }, units: [{ id: 'x01', side: 'enemy', tpl: 'hull', hp: 100 }] };
function rows(hp = 100, rng = 7) {
  const s = structuredClone(state); s.units[0].hp = hp;
  return [0, 1].map(turn => ({ turn, round: 1, actor: turn ? 'end win' : 'tick player', rng: turn ? rng : 7,
    state: JSON.stringify(s), hash: R.sha(JSON.stringify(s)) }));
}
const record = path.join(root, 'out/example.jsonl');
const write = a => fs.writeFileSync(record, a.map(r => JSON.stringify(r)).join('\n') + '\n');
write(rows());
for (const n of R.FILES) {
  const file = path.join(root, n === 'math.txt' ? 'golden' : 'out', n === 'math_verdict.txt' ? 'math.txt' : n);
  const bytes = n.startsWith('prng_') ? '7 0000000000000000\n'.repeat(10000) : n.startsWith('threat_') ?
    JSON.stringify({ 1: { '0,0': '0' }, 2: { '0,0': '0' }, 3: { '0,0': '0' } }) :
    n === 'math.txt' ? 'round 0000000000000000 0000000000000000 0000000000000000\n' : 'math 1 values, differences from Node: none\n';
  fs.writeFileSync(file, bytes);
}
const opts = { saved, scenarios, print() {} };
let count = 0;
function test(name, fn) { fn(); count++; console.log('PASS: ' + name); }
update(root, opts);
test('unchanged complete Godot evidence passes', () => assert.equal(check(root, opts).failures, 0));
test('a changed hull fails with turn, unit, field and later count', () => {
  write(rows(90)); const r = check(root, opts); assert.equal(r.changed, 1);
  const text = fs.readFileSync(path.join(root, 'changed-battles.txt'), 'utf8');
  for (const s of ['turn 0', 'x01 (enemy hull)', 'state.units[0].hp: 100 -> 90', 'later changed records: 1']) assert.ok(text.includes(s));
});
test('PRNG-only change names the exact record field', () => {
  write(rows(100, 8)); assert.equal(check(root, opts).changed, 1);
  assert.match(fs.readFileSync(path.join(root, 'changed-battles.txt'), 'utf8'), /record.rng: 7 -> 8/);
});
test('truncated battle fails', () => { write(rows().slice(0, 1)); assert.ok(check(root, opts).failures); });
test('missing battle fails by name', () => {
  fs.renameSync(record, record + '.kept'); assert.ok(check(root, opts).failures); fs.renameSync(record + '.kept', record);
});
test('forged state hash fails', () => { const a = rows(); a[0].hash = 'bad'; write(a); assert.ok(check(root, opts).failures); write(rows()); });
test('state encoding changes have a useful diagnostic', () => {
  const a = rows(); a[0].state = JSON.stringify(state, null, 1); a[0].hash = R.sha(a[0].state); write(a);
  assert.equal(check(root, opts).changed, 1);
  assert.match(fs.readFileSync(path.join(root, 'changed-battles.txt'), 'utf8'), /state encoding/); write(rows());
});
test('complete records cannot hide an unfinished batch', () => {
  fs.writeFileSync(log, goodLog.split('\n').slice(0, 2).join('\n')); assert.ok(check(root, opts).failures); fs.writeFileSync(log, goodLog);
});
test('Godot error cannot hide behind a successful exit', () => {
  fs.writeFileSync(log, goodLog + 'SCRIPT ERROR: planted\n'); assert.ok(check(root, opts).failures); fs.writeFileSync(log, goodLog);
});
test('only the exact offline Windows certificate-store error is allowed', () => {
  const certificate = 'ERROR: Failed to read the root certificate store.';
  try {
    for (const ending of ['\n', '\r\n']) {
      const offlineLog = certificate + ending + goodLog;
      fs.writeFileSync(log, offlineLog);
      assert.equal(check(root, opts).failures, 0);
      fs.writeFileSync(log, offlineLog + 'ERROR: planted worker failure' + ending);
      assert.ok(check(root, opts).failures);
      fs.writeFileSync(log, certificate + ' Extra text.' + ending + goodLog);
      assert.ok(check(root, opts).failures);
    }
  } finally {
    fs.writeFileSync(log, goodLog);
  }
});
test('changed input cannot reuse stale records', () => {
  fs.writeFileSync(part, JSON.stringify({ example: { seed: 8 } })); assert.ok(check(root, opts).failures); fs.writeFileSync(part, JSON.stringify(scenario));
});
test('damaged saved archive fails even if current hash matches', () => {
  const f = path.join(saved, 'records/example.jsonl.br'), b = fs.readFileSync(f); fs.writeFileSync(f, 'damaged');
  assert.ok(check(root, opts).failures); fs.writeFileSync(f, b);
});
test('removed battles are named', () => {
  const f = path.join(saved, 'results.json'), m = R.json(f), old = fs.readFileSync(f);
  m.battles.removed = m.battles.example; fs.writeFileSync(f, JSON.stringify(m));
  assert.ok(check(root, opts).failures);
  assert.match(fs.readFileSync(path.join(root, 'changed-battles.txt'), 'utf8'), /FAIL battle removed/);
  fs.writeFileSync(f, old);
});
test('a new battle without a saved entry is named', () => {
  const f = path.join(saved, 'results.json'), m = R.json(f), old = fs.readFileSync(f);
  delete m.battles.example; fs.writeFileSync(f, JSON.stringify(m));
  assert.equal(check(root, opts).changed, 1); fs.writeFileSync(f, old);
});
test('missing threat map fails', () => {
  const f = path.join(root, 'out/threat_s4.json'); fs.renameSync(f, f + '.kept'); assert.ok(check(root, opts).failures); fs.renameSync(f + '.kept', f);
});
test('a seed draw change fails', () => {
  const f = path.join(root, 'out/prng_7.txt'), b = fs.readFileSync(f); fs.writeFileSync(f, b.toString().replace(/^7 /, '8 '));
  assert.equal(check(root, opts).files_changed, 1); fs.writeFileSync(f, b);
});
test('failed math verification fails', () => {
  const f = path.join(root, 'out/math.txt'), b = fs.readFileSync(f); fs.writeFileSync(f, 'math 1 values, differences from Node: {round: 1}\n');
  assert.ok(check(root, opts).failures); fs.writeFileSync(f, b);
});
test('CI summary includes the report and comparison time', () => {
  const old = process.env.GITHUB_STEP_SUMMARY, f = path.join(root, 'ci-summary.md');
  process.env.GITHUB_STEP_SUMMARY = f;
  try {
    check(root, opts); const text = fs.readFileSync(f, 'utf8');
    assert.match(text, /Saved Godot results/); assert.match(text, /0 failures; [0-9.]+ s/);
  } finally {
    if (old === undefined) delete process.env.GITHUB_STEP_SUMMARY; else process.env.GITHUB_STEP_SUMMARY = old;
  }
});
test('update refuses a failed parity run', () => {
  fs.writeFileSync(path.join(root, 'summary.json'), JSON.stringify({ battles: 1, failures: 1 }));
  assert.throws(() => update(root, opts), /every original parity check passing/);
});
test('update refuses a partial parity run', () => {
  fs.writeFileSync(path.join(root, 'summary.json'), JSON.stringify({ battles: 0, failures: 0 }));
  assert.throws(() => update(root, opts), /complete run/);
});
test('explicit update accepts a baseline failure and then passes', () => {
  fs.writeFileSync(path.join(root, 'summary.json'), JSON.stringify({ battles: 1, failures: 1, parity_failures: 0 }));
  write(rows(90)); update(root, opts); assert.equal(check(root, opts).failures, 0);
});
test('repeat update is byte-identical', () => {
  const f = path.join(saved, 'results.json'), b = fs.readFileSync(f);
  const report = fs.readFileSync(path.join(saved, 'changes.txt'));
  update(root, opts); assert.deepEqual(fs.readFileSync(f), b);
  assert.deepEqual(fs.readFileSync(path.join(saved, 'changes.txt')), report);
});
console.log(`PASS: saved results self-test, ${count} cases; scratch: ${root}`);
