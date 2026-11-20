'use strict';
// Standing check for the fleet list (issue 1421): every ship the game draws has a row, every approved concept file
// exists, no old hull sits without a job, and docs/ship_pipeline/FLEET.md matches what the repo says today.
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const fleet = require('./fleet_list.js');
const ROOT = path.resolve(__dirname, '../../..');

let checks = 0, bad = 0;
function t(name, fn) {
  checks++;
  try { fn(); } catch (e) { bad++; console.log('FAIL ' + name + ': ' + e.message); }
}

// The small parts, on made-up input.
t('hull table parse', () => {
  const slots = fleet.readHullTable('const AI_HULLS := {\n\t"ithar|Cruiser": "I15_11", "obj|station": "O1_37",\n}\n');
  assert.deepStrictEqual(slots, { 'ithar|Cruiser': 'I15_11', 'obj|station': 'O1_37' });
});
t('new build is told by its parts maps', () => {
  assert.strictEqual(fleet.isNewBuild({ files: { 'X.glb': {}, 'X_parts_base.jpg': {} } }), true);
  assert.strictEqual(fleet.isNewBuild({ files: { 'X.glb': {}, 'X_damage.glb': {}, 'X_wreck.glb': {} } }), false);
  assert.strictEqual(fleet.isNewBuild(undefined), false);
});
t('stage words', () => {
  assert.strictEqual(fleet.stageOf({ installed: true, sheets: ['S9'], concept: 'a' }), 'New-format build on main');
  assert.strictEqual(fleet.stageOf({ installed: false, sheets: ['C14'], concept: 'a' }), 'Build sheet made, old hull in game');
  assert.strictEqual(fleet.stageOf({ installed: false, sheets: [], concept: 'a' }), 'Concept picked, old hull in game');
  assert.strictEqual(fleet.stageOf({ installed: false, sheets: [], concept: null, keep: 'by design' }), 'Old hull kept on purpose');
  assert.strictEqual(fleet.stageOf({ installed: false, sheets: [], concept: null }), 'Old hull, no pick yet');
});
t('pick line carries the path and the ruling', () => {
  assert.strictEqual(fleet.pickLine({ concept: 'a/b.webp', ruling: 'R369', note: 'Step 3', ship: 'Prism' }), 'Approved pick: a/b.webp (R369). Step 3');
  assert.strictEqual(fleet.pickLine({ concept: null, ruling: '', note: '', ship: 'Bastion' }), 'Approved pick: none recorded for Bastion');
});

t('a new-format row with old armour reads as pending, not accepted', () => {
  assert.strictEqual(fleet.lookOf({ installed: true, pending: 'Round G armour.', accepted: '' }), 'Pending: Round G armour.');
  assert.strictEqual(fleet.lookOf({ installed: true, pending: '', accepted: 'Ryan, Nov 20' }), 'Accepted: Ryan, Nov 20');
  assert.strictEqual(fleet.lookOf({ installed: true, pending: '', accepted: '' }), 'Not recorded');
  assert.strictEqual(fleet.lookOf({ installed: false, pending: '', accepted: '' }), '');
});

// A broken copy must be caught: a slot with no row, a missing concept file, an old hull with no job.
t('problems are found in a broken fleet', () => {
  const tmp = fs.mkdtempSync(path.join(require('os').tmpdir(), 'fleet_'));
  const put = (p, s) => { fs.mkdirSync(path.dirname(path.join(tmp, p)), { recursive: true }); fs.writeFileSync(path.join(tmp, p), s); };
  put('godot/render/hull_table.gd', 'const AI_HULLS := {\n\t"a|Frigate": "A1", "a|Cruiser": "A2", "a|Carrier": "A3",\n}\n');
  put('godot/assets/ships/manifest.json', JSON.stringify({ ships: { A1: { files: { 'A1_damage.glb': {} } }, A2: { files: { 'A2_parts_base.jpg': {} } } } }));
  put('docs/ship_pipeline/fleet.json', JSON.stringify({ slots: {
    'a|Frigate': { ship: 'One', concept: 'gone.jpg' },
    'a|Cruiser': { ship: 'Two', concept: null },
    'a|Ghost': { ship: 'Three', concept: null, job: 1 } }, other: [{ ship: 'Loose', concept: null, job: 2 }] }));
  const got = fleet.build(tmp).problems.join('\n');
  fs.rmSync(tmp, { recursive: true, force: true });
  for (const want of ['a|Carrier (A3) is in', 'a|Ghost is in', 'concept file is missing: gone.jpg', 'old hull A1 with no job', 'new build installed but no approved concept', 'no key, so --pick cannot find it'])
    assert.ok(got.includes(want), 'missing problem: ' + want + '\n' + got);
});

// The real repo.
const data = fleet.build(ROOT);
for (const p of data.problems) { bad++; console.log('FAIL fleet list: ' + p); }
checks++;
// Artoo on PR 1425: the two recovered Glasswright craft picks (R370) must resolve for a brief, and Bladeback must not read
// as done while its installed files carry the old armour.
t('the R370 craft picks resolve', () => {
  for (const [key, file] of [['ithar|fighter', 'fighter_starling_v2d.webp'], ['ithar|bomber', 'bomber_heliograph_w4b.webp']]) {
    const row = fleet.findPick(data, key);
    assert.ok(row, key + ' not found');
    const line = fleet.pickLine(row);
    assert.ok(line.includes(file) && line.includes('R370'), key + ': ' + line);
  }
  assert.ok(fleet.findPick(data, 'ithar|Cruiser') && fleet.findPick(data, 'I15_11'), 'slot key and hull code both resolve');
  assert.strictEqual(fleet.findPick(data, ''), null);
});
t('Bladeback reads as pending', () => {
  const row = fleet.findPick(data, 'chorus|Cruiser');
  assert.ok(fleet.lookOf(row).startsWith('Pending:'), fleet.lookOf(row));
});
t('FLEET.md is current', () => {
  const page = path.join(ROOT, fleet.PAGE);
  const have = fs.existsSync(page) ? fs.readFileSync(page, 'utf8').replace(/\r\n/g, '\n') : '';
  assert.ok(have === fleet.render(data), fleet.PAGE + ' is stale: run node contrib/opus/tools/fleet_list.js --write and commit it');
});

if (bad) {
  console.log('FAIL: ' + bad + ' of ' + checks + ' fleet list checks failed');
  process.exitCode = 1;
} else {
  console.log('PASS: ' + checks + ' fleet list checks; ' + data.rows.length + ' ship slots, '
    + data.rows.filter(r => r.installed).length + ' in the new build format, every old hull has a job or a keep reason');
}
