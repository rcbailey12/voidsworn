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
  assert.strictEqual(fleet.stageOf({ installed: true, sheets: ['S9'], concept: 'a' }), 'New build installed');
  assert.strictEqual(fleet.stageOf({ installed: false, sheets: ['C14'], concept: 'a' }), 'Build sheet made, old hull in game');
  assert.strictEqual(fleet.stageOf({ installed: false, sheets: [], concept: 'a' }), 'Concept picked, old hull in game');
  assert.strictEqual(fleet.stageOf({ installed: false, sheets: [], concept: null, keep: 'by design' }), 'Old hull kept on purpose');
  assert.strictEqual(fleet.stageOf({ installed: false, sheets: [], concept: null }), 'Old hull, no pick yet');
});
t('pick line carries the path and the ruling', () => {
  assert.strictEqual(fleet.pickLine({ concept: 'a/b.webp', ruling: 'R369', note: 'Step 3', ship: 'Prism' }), 'Approved pick: a/b.webp (R369). Step 3');
  assert.strictEqual(fleet.pickLine({ concept: null, ruling: '', note: '', ship: 'Bastion' }), 'Approved pick: none recorded for Bastion');
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
    'a|Ghost': { ship: 'Three', concept: null, job: 1 } } }));
  const got = fleet.build(tmp).problems.join('\n');
  fs.rmSync(tmp, { recursive: true, force: true });
  for (const want of ['a|Carrier (A3) is in', 'a|Ghost is in', 'concept file is missing: gone.jpg', 'old hull A1 with no job', 'new build installed but no approved concept'])
    assert.ok(got.includes(want), 'missing problem: ' + want + '\n' + got);
});

// The real repo.
const data = fleet.build(ROOT);
for (const p of data.problems) { bad++; console.log('FAIL fleet list: ' + p); }
checks++;
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
    + data.rows.filter(r => r.installed).length + ' new builds installed, every old hull has a job or a keep reason');
}
