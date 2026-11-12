'use strict';
// Issue 361: one generated walk over LINEAGE_TREES.
// Every skill row must either have a TREE_FX entry and reach B.tree through the real campaign and battle functions
// (lineagePick, newRun, startBattle), or sit on the dated waiting list below. The check never types a run, a battle, a
// pick list or a page state by hand: it builds them with the game's own functions, one row at a time.
// The choice of pick is generated from the tree shape: a branch row is reached by its own branch tiers, a capstone by
// one tier-0 row from each branch. That is presence, not behaviour: this check proves the row is wired, not that the
// number in its text is right. Behaviour checks stay the rule for new and changed rows only.
const path = require('path');

// Dated waiting rows: text but no TREE_FX effect. A row may only wait with a date and a one-line reason, and the list
// can only shrink: WAITING_AT_FREEZE is the set that was allowed to wait on LIST_FROZEN. A row that gains an effect
// must be removed from WAITING (the check fails until it is), and a row may not join the list after the freeze.
const LIST_FROZEN = '2026-11-10';
const WAITING = {
  // empty since issue 529 (Nov 11 2026): the last seven rows (the four Chorus roles, Spawned Before the Strike,
  // The Brood Does Not Stop, Scent in the Dark) now work in battle
};
// The rows that were allowed to wait on LIST_FROZEN. Keep this literal: a row may leave WAITING when its effect lands,
// but a row that joins the list must also join this literal, which is what a reviewer sees. The list only shrinks.
const WAITING_AT_FREEZE = [
  'matriarch:A:1:1', 'matriarch:cap:1', 'razormaw:A:1:1',
  'matriarch:B:0:0', 'razormaw:B:0:0', 'mending:B:0:0', 'voice:B:0:0'
];

function run() {
  process.env.VS_ORACLE = path.resolve(__dirname, '../../..');
  const data = JSON.stringify({ WAITING, WAITING_AT_FREEZE, LIST_FROZEN });
  require('../../../godot/campaign/test/node/env.js').load(`
globalThis.__TREE_WALK_DATA__ = ${data};
globalThis.treeTableWalk = () => {
  const D = globalThis.__TREE_WALK_DATA__;
  const fails = [], lines = [];
  const rows = [];
  for (const id of Object.keys(LINEAGE_TREES)) {
    const tree = LINEAGE_TREES[id];
    for (const b of Object.keys(tree.branches)) {
      tree.branches[b].tiers.forEach((pair, t) => pair.forEach((skill, c) => {
        rows.push({ key: id + ':' + b + ':' + t + ':' + c, id, b, t });
      }));
    }
    tree.capstones.forEach((skill, c) => rows.push({ key: id + ':cap:' + c, id, b: 'cap', t: 0 }));
  }
  const rowSet = new Set(rows.map(r => r.key));
  const waiting = D.WAITING;
  for (const key of Object.keys(waiting)) {
    const w = waiting[key] || {};
    if (!rowSet.has(key)) fails.push('FAIL ' + key + ': the waiting list names a row that is not in LINEAGE_TREES');
    if (!/^\\d{4}-\\d{2}-\\d{2}$/.test(String(w.date || ''))) fails.push('FAIL ' + key + ': a waiting row needs a date (YYYY-MM-DD)');
    else if (String(w.date) > D.LIST_FROZEN) fails.push('FAIL ' + key + ': dated after ' + D.LIST_FROZEN + '; the waiting list can only shrink');
    if (!w.reason || !String(w.reason).trim()) fails.push('FAIL ' + key + ': a waiting row needs a one-line reason');
    if (TREE_FX[key]) fails.push('FAIL ' + key + ': now has a TREE_FX entry; remove it from the waiting list');
    if (!D.WAITING_AT_FREEZE.includes(key)) fails.push('FAIL ' + key + ': joined the waiting list after ' + D.LIST_FROZEN + '; the list can only shrink');
  }
  const prereq = r => {
    if (r.b === 'cap') return [r.id + ':A:0:0', r.id + ':B:0:0', r.id + ':C:0:0'];
    const out = [];
    for (let t = 0; t < r.t; t++) out.push(r.id + ':' + r.b + ':' + t + ':0');
    return out;
  };
  let tested = 0;
  for (const r of rows) {
    const fx = TREE_FX[r.key];
    if (!fx) {
      if (!waiting[r.key]) fails.push('FAIL ' + r.key + ': has no TREE_FX entry and is not on the dated waiting list');
      continue;
    }
    RUN = null; SAVED_RUN = null;   // picks are made between runs, as the game allows
    META = migrateMeta(defaultMeta());
    META.admirals[r.id] = true;     // the harness owns the admiral it flies
    META.mastery[r.id] = 230;       // level 8: three branch picks and a capstone are earned
    let refused = false;
    for (const k of prereq(r)) {
      if (lineagePick(k) !== true) { fails.push('FAIL ' + r.key + ': lineagePick(' + k + ') was refused'); refused = true; break; }
    }
    if (refused) continue;
    if (lineagePick(r.key) !== true) { fails.push('FAIL ' + r.key + ': lineagePick was refused'); continue; }
    newRun(r.id, ADMIRALS[r.id].fac);
    if (!RUN || !RUN.lineage || RUN.lineage.id !== r.id) { fails.push('FAIL ' + r.key + ': newRun did not snapshot the admiral tree'); continue; }
    startBattle({kind: 'battle', fac: 'hegemony', col: 1, seed: 7, obj: 'rout', shape: 'open', map: 'belt', enemies: [{tpl: 'h_picket'}]});
    const got = {};
    for (const s of (B && B.tree) || []) got[s.k] = s.key;
    if (got[fx.k] !== r.key) {
      fails.push('FAIL ' + r.key + ': ' + fx.k + ' did not reach B.tree under its own key (got ' + JSON.stringify(got[fx.k]) + ')');
      continue;
    }
    tested++;
  }
  for (const key of Object.keys(waiting)) lines.push('  waiting ' + key + ' ' + waiting[key].date + ': ' + waiting[key].reason);
  return { fails, lines, tested, rows: rows.length, waiting: Object.keys(waiting).length };
};
`);
  const out = global.treeTableWalk();
  if (out.fails.length) {
    for (const f of out.fails) console.log(f);
    console.log('FAIL: ' + out.fails.length + ' tree table row(s) failed the walk');
    process.exitCode = 1;
  } else {
    for (const line of out.lines) console.log(line);
    console.log('PASS: ' + out.tested + ' effect rows reach B.tree through lineagePick, newRun and startBattle; ' + out.waiting + ' dated waiting rows make no promise; ' + out.rows + ' rows walked');
  }
}

module.exports = { WAITING, WAITING_AT_FREEZE, LIST_FROZEN };
if (require.main === module) run();
