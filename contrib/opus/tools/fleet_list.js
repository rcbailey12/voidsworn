'use strict';
// The fleet list (issue 1421). Node 18+, no dependencies.
//
// Why: approved concepts kept getting skipped (the Nov 16 Glasswright picks, twice on Nov 20) because nothing listed, per
// ship, what Ryan picked and how far the build has got. docs/ship_pipeline/fleet.json holds the hand-kept part (approved
// concept, ruling, job, note). This file reads the rest from the repo and joins them:
//   hull code        godot/render/hull_table.gd AI_HULLS (what the game draws for that faction and class)
//   build sheet      tools/recipe/ships/*.json, the recipe whose game_code is that hull
//   build format     godot/assets/ships/manifest.json: a new build has *_parts_* maps, a Nov 1 hull does not. That is
//                    the file layout only. Whether the approved look is in those files is the hand-kept 'accepted' and
//                    'pending' text; proving the model the game renders is issue 1410's guard, not this list.
//
//   node contrib/opus/tools/fleet_list.js            print the problems, exit 1 on any
//   node contrib/opus/tools/fleet_list.js --write    also rewrite docs/ship_pipeline/FLEET.md
//   node contrib/opus/tools/fleet_list.js --pick "ithar|Cruiser"   print the Approved pick line for a brief
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');
const FLEET = 'docs/ship_pipeline/fleet.json';
const PAGE = 'docs/ship_pipeline/FLEET.md';
const HULL_TABLE = 'godot/render/hull_table.gd';
const MANIFEST = 'godot/assets/ships/manifest.json';
const RECIPES = 'tools/recipe/ships';

const FACTION_NAMES = { voidsworn: 'Sunward Crusade', hegemony: 'Hegemony Navy', corsair: 'Ashfall Hullbreakers',
  chorus: 'The Chorus', ithar: 'The Glasswrights', deathless: 'Eclipse', craft: 'Strike craft (old shared hulls)',
  obj: 'Objectives' };

function readHullTable(text) {
  const block = text.match(/const AI_HULLS\s*:=\s*\{([\s\S]*?)\n\}/);
  if (!block) throw new Error(HULL_TABLE + ': AI_HULLS not found');
  const slots = {};
  const re = /"([^"|]+\|[^"]+)"\s*:\s*"([^"]+)"/g;
  let m;
  while ((m = re.exec(block[1]))) slots[m[1]] = m[2];
  return slots;
}

function readRecipes(root) {
  const byHull = {};
  const dir = path.join(root, RECIPES);
  if (!fs.existsSync(dir)) return byHull;
  for (const f of fs.readdirSync(dir).filter(n => n.endsWith('.json')).sort()) {
    let j;
    try { j = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')); } catch (e) { continue; }
    if (j && typeof j.game_code === 'string') (byHull[j.game_code] = byHull[j.game_code] || []).push(path.basename(f, '.json'));
  }
  return byHull;
}

// A new recipe build ships *_parts_* maps; the Nov 1 (A4) hulls ship *_damage.glb and *_wreck.glb instead (issue 1410).
function isNewBuild(entry) {
  return !!entry && Object.keys(entry.files || {}).some(n => n.includes('_parts_'));
}

function stageOf(row) {
  if (row.installed) return 'New-format build on main';
  if (row.sheets.length) return 'Build sheet made, old hull in game';
  if (row.concept || row.picked) return 'Concept picked, old hull in game';
  if (row.keep) return 'Old hull kept on purpose';
  return 'Old hull, no pick yet';
}

function build(root = ROOT) {
  const read = p => fs.readFileSync(path.join(root, p), 'utf8');
  const fleet = JSON.parse(read(FLEET));
  const hulls = readHullTable(read(HULL_TABLE));
  const manifest = JSON.parse(read(MANIFEST)).ships || {};
  const recipes = readRecipes(root);
  const problems = [];
  const rows = [];

  for (const slot of Object.keys(hulls)) {
    if (!fleet.slots[slot]) problems.push(slot + ' (' + hulls[slot] + ') is in ' + HULL_TABLE + ' but has no row in ' + FLEET);
  }
  for (const slot of Object.keys(fleet.slots)) {
    const r = fleet.slots[slot];
    if (!(slot in hulls)) { problems.push(slot + ' is in ' + FLEET + ' but not in ' + HULL_TABLE + ' AI_HULLS'); continue; }
    const hull = hulls[slot];
    const row = { slot, faction: slot.split('|')[0], cls: slot.split('|')[1], hull, ship: r.ship || '', concept: r.concept || null,
      ruling: r.ruling || '', job: r.job || null, note: r.note || '', keep: r.keep || '', picked: !!r.picked, accepted: r.accepted || '', pending: r.pending || '',
      sheets: recipes[hull] || [], installed: isNewBuild(manifest[hull]), inManifest: !!manifest[hull] };
    row.stage = stageOf(row);
    if (!row.ship) problems.push(slot + ': the row has no ship name');
    if (row.concept && !fs.existsSync(path.join(root, row.concept))) problems.push(slot + ': concept file is missing: ' + row.concept);
    if (!row.inManifest) problems.push(slot + ': hull ' + hull + ' has no entry in ' + MANIFEST);
    // Nothing may sit untracked: an old hull with no installed build needs an open job or a stated reason to stay.
    if (!row.installed && !row.job && !row.keep) problems.push(slot + ' (' + row.ship + '): old hull ' + hull + ' with no job and no keep reason');
    // An installed new build with no recorded concept means a pick was never written down.
    if (row.installed && !row.concept) problems.push(slot + ' (' + row.ship + '): new build installed but no approved concept recorded');
    rows.push(row);
  }
  const other = (fleet.other || []).map((r, i) => {
    if (!r.ship) problems.push('other[' + i + ']: no ship name');
    if (r.concept && !fs.existsSync(path.join(root, r.concept))) problems.push('other[' + i + '] (' + r.ship + '): concept file is missing: ' + r.concept);
    if (!r.job && !r.keep) problems.push('other[' + i + '] (' + r.ship + '): no job and no keep reason');
    if (!r.key) problems.push('other[' + i + '] (' + r.ship + '): no key, so --pick cannot find it');
    if (r.key && (r.key in fleet.slots)) problems.push('other[' + i + ']: key ' + r.key + ' is also a slot');
    return { slot: r.key || '', hull: '', ship: r.ship || '', concept: r.concept || null, ruling: r.ruling || '', job: r.job || null, note: r.note || '', keep: r.keep || '' };
  });
  return { rows, other, problems };
}

// The line a brief carries (AGENTS.md job block, docs/playbooks/ships.md section 7).
function pickLine(row) {
  if (row.concept) return 'Approved pick: ' + row.concept + (row.ruling ? ' (' + row.ruling + ')' : '') + (row.note ? '. ' + row.note : '');
  return 'Approved pick: none recorded for ' + row.ship + (row.note ? '. ' + row.note : '');
}

// A brief asks by slot key ("ithar|Cruiser"), by hull code, or by an 'other' key ("ithar|fighter").
function findPick(data, want) {
  return data.rows.concat(data.other).find(r => want && (r.slot === want || r.hull === want)) || null;
}

function lookOf(r) {
  if (r.pending) return 'Pending: ' + r.pending + (r.accepted ? ' Accepted before that: ' + r.accepted + '.' : '');
  if (r.accepted) return 'Accepted: ' + r.accepted;
  return r.installed ? 'Not recorded' : '';
}

function link(p) { return p ? '[' + path.basename(p) + '](../../' + p.split(path.sep).join('/') + ')' : 'none'; }
function cell(s) { return String(s || '').replace(/\|/g, '/').replace(/\r?\n/g, ' '); }

function render(data) {
  const { rows, other } = data;
  const count = s => rows.filter(r => r.stage === s).length;
  const out = [];
  out.push('# The fleet list');
  out.push('');
  out.push('GENERATED by contrib/opus/tools/fleet_list.js from docs/ship_pipeline/fleet.json, godot/render/hull_table.gd,');
  out.push('godot/assets/ships/manifest.json and tools/recipe/ships. Do not edit by hand: change fleet.json, then run');
  out.push('`node contrib/opus/tools/fleet_list.js --write`. The standing check fleet_list_tests fails when this page is stale.');
  out.push('');
  out.push('One row per ship the game draws. "Approved concept" is the picture Ryan picked; a build or concept brief copies it');
  out.push('into its "Approved pick" line. "New-format build on main" means only that main\'s ship manifest row for that hull code');
  out.push('has the new recipe file layout. It does not prove the approved look is in those files: the "Approved look in game"');
  out.push('column says what Ryan accepted and what is still pending, and issue 1410 checks the model the game renders. None');
  out.push('of this is the playable exe (that is a separate snapshot).');
  out.push('');
  out.push('**Totals:** ' + rows.length + ' ship slots. ' + count('New-format build on main') + ' new builds installed, '
    + count('Build sheet made, old hull in game') + ' with a build sheet but the old hull in game, '
    + count('Concept picked, old hull in game') + ' with a picked concept only, '
    + count('Old hull, no pick yet') + ' old with no pick yet, ' + count('Old hull kept on purpose') + ' kept on purpose.');
  let fac = '';
  for (const r of rows) {
    if (r.faction !== fac) {
      fac = r.faction;
      out.push('');
      out.push('## ' + (FACTION_NAMES[fac] || fac) + (FACTION_NAMES[fac] && !['craft', 'obj'].includes(fac) ? ' (`' + fac + '`)' : ''));
      out.push('');
      out.push('| Ship | Class | Hull code | Stage | Approved look in game | Approved concept | Ruling | Build sheet | Job | Note |');
      out.push('|---|---|---|---|---|---|---|---|---|---|');
    }
    out.push('| ' + [cell(r.ship), cell(r.cls), '`' + r.hull + '`', r.stage, cell(lookOf(r)), link(r.concept), cell(r.ruling) || '', r.sheets.join(', '),
      r.job ? '#' + r.job : '', cell(r.keep || r.note)].join(' | ') + ' |');
  }
  if (other.length) {
    out.push('');
    out.push('## Not a slot yet');
    out.push('');
    out.push('Picked or ruled things that have no hull code of their own in hull_table.gd.');
    out.push('');
    out.push('| What | Pick key | Approved concept | Ruling | Job | Note |');
    out.push('|---|---|---|---|---|---|');
    for (const r of other) out.push('| ' + [cell(r.ship), '`' + r.slot + '`', link(r.concept), cell(r.ruling), r.job ? '#' + r.job : '', cell(r.keep || r.note)].join(' | ') + ' |');
  }
  out.push('');
  return out.join('\n');
}

function main() {
  const args = process.argv.slice(2);
  const data = build();
  const pickAt = args.indexOf('--pick');
  if (pickAt >= 0) {
    const row = findPick(data, args[pickAt + 1]);
    if (!row) { console.error('No slot or hull code "' + args[pickAt + 1] + '" in ' + FLEET); process.exit(1); }
    console.log(pickLine(row));
    return;
  }
  if (args.includes('--write')) {
    fs.writeFileSync(path.join(ROOT, PAGE), render(data));
    console.log('wrote ' + PAGE);
  }
  for (const p of data.problems) console.log('PROBLEM: ' + p);
  if (data.problems.length) { console.log('FAIL: ' + data.problems.length + ' fleet list problem(s)'); process.exit(1); }
  console.log('PASS: ' + data.rows.length + ' ship slots listed, ' + data.rows.filter(r => r.installed).length + ' in the new build format');
}

if (require.main === module) main();

module.exports = { build, render, pickLine, findPick, lookOf, readHullTable, isNewBuild, stageOf, FLEET, PAGE };
