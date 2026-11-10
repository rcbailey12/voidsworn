'use strict';
// Issue 335, finding 3: the oracle copies and the campaign tables must not fall behind the live game files.
// Hard check (a normal row in run_all_checks.js): fails when any file in godot/rules/test/oracle/ or
// godot/campaign/test/oracle/ that has a root twin differs from the root, and when
// godot/campaign/data/campaign_tables.json still carries skill text that data.js no longer has.
// Files with no root twin (the Godot-only campaign_hooks.js, fnames.js, the two README notes) are not compared.
const fs = require('fs');
const path = require('path');
const ROOT = process.env.VS_ROOT || path.resolve(__dirname, '../../..');
const DIRS = ['godot/rules/test/oracle', 'godot/campaign/test/oracle'];
const TABLES = 'godot/campaign/data/campaign_tables.json';
const fails = [];

for (const dir of DIRS) {
  const abs = path.join(ROOT, dir);
  if (!fs.existsSync(abs)) { fails.push(dir + ' is missing'); continue; }
  for (const name of fs.readdirSync(abs).sort()) {
    const twin = path.join(ROOT, name);
    if (!fs.existsSync(twin) || !fs.statSync(twin).isFile()) continue;
    const a = fs.readFileSync(path.join(abs, name));
    const b = fs.readFileSync(twin);
    if (!a.equals(b)) fails.push(dir + '/' + name + ' differs from the root ' + name);
  }
}

function collect(trees) {
  const out = new Map();
  const add = (key, skill) => out.set(key, { n: skill && skill.n, d: skill && skill.d });
  for (const id of Object.keys(trees || {})) {
    const t = trees[id] || {};
    for (const b of Object.keys(t.branches || {})) {
      (t.branches[b].tiers || []).forEach((pair, ti) => (pair || []).forEach((skill, ci) => add(id + ':' + b + ':' + ti + ':' + ci, skill)));
    }
    (t.capstones || []).forEach((skill, ci) => add(id + ':cap:' + ci, skill));
  }
  return out;
}

process.env.VS_ORACLE = ROOT;
require(path.join(ROOT, 'godot/campaign/test/node/env.js')).load('globalThis.__ROOT_TREES = LINEAGE_TREES;');
const tablesPath = path.join(ROOT, TABLES);
if (!fs.existsSync(tablesPath)) fails.push(TABLES + ' is missing');
else {
  const tables = JSON.parse(fs.readFileSync(tablesPath, 'utf8')).tables || {};
  const root = collect(global.__ROOT_TREES);
  const shipped = collect(tables.LINEAGE_TREES);
  for (const [key, skill] of shipped) {
    if (!root.has(key)) { fails.push(TABLES + ' has a tree row ' + key + ' (' + JSON.stringify(skill.n) + ') that data.js no longer has'); continue; }
    const want = root.get(key);
    if (skill.n !== want.n) fails.push(TABLES + ' skill ' + key + ' is named ' + JSON.stringify(skill.n) + ', data.js says ' + JSON.stringify(want.n));
    if (skill.d !== want.d) fails.push(TABLES + ' skill ' + key + ' (' + JSON.stringify(want.n) + ') has a description data.js no longer has');
  }
  for (const key of root.keys()) if (!shipped.has(key)) fails.push(TABLES + ' is missing the tree row ' + key + ' that data.js has');
}

if (fails.length) {
  for (const f of fails) console.log('FAIL ' + f);
  console.log('FAIL: ' + fails.length + ' oracle copy or campaign table difference(s)');
  process.exit(1);
}
console.log('PASS: every oracle copy matches its root file and campaign_tables.json carries the same tree text as data.js');
