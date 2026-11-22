'use strict';
// Standing check for the fleet list (issue 1421): every ship the game draws has a row, every approved concept file
// exists, no old hull sits without a job, and docs/ship_pipeline/FLEET.md matches what the repo says today.
const fs = require('fs');
const os = require('os');
const path = require('path');
const assert = require('assert');
const { spawnSync } = require('child_process');
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
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'fleet_'));
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

t('different factions merge cleanly and CI distinguishes branch staleness from merge drift', () => {
  const tempRoot = fs.realpathSync.native(os.tmpdir());
  const tmp = fs.mkdtempSync(path.join(tempRoot, 'fleet-merge-'));
  const manifest = 'godot/assets/ships/manifest.json';
  const hullTable = 'godot/render/hull_table.gd';
  const generator = 'contrib/opus/tools/fleet_list.js';
  const run = (command, args) => spawnSync(command, args, { cwd: tmp, encoding: 'utf8' });
  const git = (...args) => {
    const result = run('git', ['-c', 'core.autocrlf=false', ...args]);
    assert.strictEqual(result.status, 0, result.error || result.stdout + result.stderr);
    return result.stdout.trim();
  };
  const fleetCli = (option, status = 0) => {
    const result = run(process.execPath, [generator, option]);
    assert.strictEqual(result.status, status, result.error || result.stdout + result.stderr);
    return result.stdout;
  };
  const put = (file, content) => {
    const target = path.join(tmp, file);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, content);
  };
  const save = (tree, ...parents) => git('-c', 'user.name=Fleet test', '-c', 'user.email=fleet@example.test',
    'commit-tree', tree, ...parents.flatMap(parent => ['-p', parent]), '-m', 'Fleet test snapshot');
  const snapshot = (...parents) => {
    git('add', '--all');
    return save(git('write-tree'), ...parents);
  };
  const table = hull => `const AI_HULLS := {\n  "voidsworn|Frigate": "${hull}",\n  "corsair|Frigate": "A1",\n}\n`;
  const source = `{
  "slots": {
    "voidsworn|Frigate": {"ship": "Warden", "job": 1},

    "corsair|Frigate": {"ship": "Raider", "job": 2}
  }
}\n`;
  try {
    git('init', '-q', '-b', 'main');
    put(generator, fs.readFileSync(path.join(ROOT, generator)));
    put('concept.txt', 'Fixture concept\n');
    put(hullTable, table('V1'));
    put(manifest, '{"ships":{"V1":{},"V2":{},"A1":{}}}\n');
    put(fleet.FLEET, source);
    assert.match(fleetCli('--write'), /^Totals: 2 ship slots\./m);
    assert.doesNotMatch(fs.readFileSync(path.join(tmp, fleet.PAGE), 'utf8'), /^\*\*Totals:\*\*/m);
    const base = snapshot();

    put(fleet.FLEET, source.replace('"job": 1', '"job": 1, "concept": "concept.txt"'));
    assert.match(fleetCli('--check-page', 1), /FLEET\.md is stale/);
    fleetCli('--write');
    fleetCli('--check-page');
    const sunward = snapshot(base);

    git('read-tree', '--reset', '-u', base);
    put(fleet.FLEET, source.replace('"job": 2', '"job": 2, "keep": "Kept by design"'));
    fleetCli('--write');
    fleetCli('--check-page');
    git('update-ref', 'refs/heads/hullbreakers', snapshot(base));

    // The first branch fast-forwards main. Git's three-way merge must then take the second branch cleanly.
    git('update-ref', 'refs/heads/main', sunward);
    const merged = git('merge-tree', '--write-tree', 'main', 'hullbreakers');
    git('update-ref', 'refs/heads/main', save(merged, 'main', 'hullbreakers'));
    git('read-tree', '--reset', '-u', 'main');
    const combined = fs.readFileSync(path.join(tmp, fleet.PAGE), 'utf8');
    assert.match(combined, /^\| Warden .*Concept picked, old hull in game/m);
    assert.match(combined, /^\| Raider .*Old hull kept on purpose/m);
    fleetCli('--check-page');

    // A branch switches to V2 while main installs V2. Both pages were current before Git combined their inputs.
    const beforeDrift = git('rev-parse', 'main');
    put(hullTable, table('V2'));
    fleetCli('--write');
    fleetCli('--check-page');
    const switchHull = snapshot(beforeDrift);
    git('read-tree', '--reset', '-u', beforeDrift);
    put(manifest, '{"ships":{"V1":{},"V2":{"files":{"V2_parts_base.jpg":{}}},"A1":{}}}\n');
    fleetCli('--check-page');
    git('update-ref', 'refs/heads/main', snapshot(beforeDrift));
    git('read-tree', '--reset', '-u', git('merge-tree', '--write-tree', switchHull, 'main'));
    assert.match(fleetCli('--check-page', 1), /FLEET\.md is stale/);
    fleetCli('--write');
    fleetCli('--check-page');
    assert.match(fs.readFileSync(path.join(tmp, fleet.PAGE), 'utf8'), /^\| Warden .*`V2` \| New-format build on main/m);
  } finally {
    const resolved = fs.realpathSync.native(tmp);
    assert.strictEqual(path.dirname(resolved), tempRoot);
    fs.rmSync(resolved, { recursive: true, force: true });
  }
});

// The real repo.
const data = fleet.build(ROOT);
for (const p of data.problems) { bad++; console.log('FAIL fleet list: ' + p); }
checks++;
// Artoo on PR 1425: the two recovered Glasswright craft picks (R370) must resolve for a brief, and Bladeback must not read
// as done while its installed files carry the old armour (until its run D publish, Nov 20).
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
// Nov 20: Bladeback's run D (armour almost everywhere, R374) is published, so it now reads as accepted with that ruling.
t('Bladeback reads as accepted after run D', () => {
  const row = fleet.findPick(data, 'chorus|Cruiser');
  const look = fleet.lookOf(row);
  assert.ok(look.startsWith('Accepted:') && look.includes('R374'), look);
});
t('FLEET.md is current', () => {
  const problem = fleet.pageProblem(data);
  assert.ok(!problem, problem);
});

if (bad) {
  console.log('FAIL: ' + bad + ' of ' + checks + ' fleet list checks failed');
  process.exitCode = 1;
} else {
  console.log('PASS: ' + checks + ' fleet list checks; ' + data.rows.length + ' ship slots, '
    + data.rows.filter(r => r.installed).length + ' in the new build format, every old hull has a job or a keep reason');
}
