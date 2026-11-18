'use strict';
// Issue 1019 follow-up: a smoke run must never replace the saved 200-sim dataset.
// This runs the README's documented smoke command exactly (--only today_standard
// --sims 5 --out <temp file>) and proves the six saved raw files stay byte for
// byte identical afterwards. Before the fix, sim_map_pace.js wrote
// raw_<setup>.json beside itself whatever --out said, so that same command
// replaced raw_today_standard.json with five rows.
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const dir = __dirname;
const root = path.resolve(dir, '..', '..', '..');
const sim = path.join(dir, 'sim_map_pace.js');

const source = fs.readFileSync(sim, 'utf8');
const block = /const SETUPS = \[([\s\S]*?)\n\];/.exec(source);
assert(block, 'SETUPS block not found in sim_map_pace.js');
const ids = [];
for (const m of block[1].matchAll(/id:\s*'([a-z0-9_]+)'/g)) ids.push(m[1]);
assert.equal(ids.length, 6, 'expected six setups, found ' + ids.join(', '));
assert(ids.includes('today_standard'), 'today_standard setup is missing');

const saved = new Map();
for (const id of ids) {
  const f = path.join(dir, 'raw_' + id + '.json');
  assert(fs.existsSync(f), 'missing saved data ' + f);
  saved.set(id, fs.readFileSync(f));
}

const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'map_pace_smoke_'));
try {
  const outCsv = path.join(temp, 'pace_check.csv');
  const run = spawnSync(process.execPath, [sim, '--only', 'today_standard', '--sims', '5', '--out', outCsv], {
    cwd: root, encoding: 'utf8', timeout: 180000, windowsHide: true,
  });
  assert.equal(run.status, 0, 'smoke command failed:\n' + (run.stdout || '') + (run.stderr || ''));
  assert(fs.existsSync(outCsv), 'smoke run did not write the CSV at --out');
  const tempRaw = path.join(temp, 'raw_today_standard.json');
  assert(fs.existsSync(tempRaw), 'smoke raw file was not written beside --out');
  assert.equal(JSON.parse(fs.readFileSync(tempRaw, 'utf8')).length, 5, 'smoke raw file should hold the five smoke rows');
  console.log('PASS smoke run writes the raw rows beside the chosen --out folder');

  for (const id of ids) {
    const now = fs.readFileSync(path.join(dir, 'raw_' + id + '.json'));
    assert(now.equals(saved.get(id)), 'saved data changed: raw_' + id + '.json');
  }
  console.log('PASS the six saved raw files are unchanged byte for byte after the smoke run');

  const extra = fs.readdirSync(dir).filter((n) => /^raw_.*\.json$/.test(n) && !ids.includes(n.slice(4, -5)));
  assert.equal(extra.length, 0, 'stray raw file(s) in the script folder: ' + extra.join(', '));
  console.log('PASS no stray raw files appeared in the script folder');
} finally {
  fs.rmSync(temp, { recursive: true, force: true });
}

console.log('PASS map pace smoke safety (' + ids.length + ' saved files held)');
