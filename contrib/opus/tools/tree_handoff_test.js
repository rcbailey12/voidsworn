'use strict';
// Issue 335: a tree pick made through the campaign must reach the battle.
// One admiral per faction takes three branch picks and a capstone through lineagePick, then newRun, then startBattle
// the normal way. Nothing here types RUN.lineage by hand: the run snapshot must come from the real campaign functions.
// Before the fix the campaign stores short picks ("A:0:0") and treeBuild looked only for the long keys in TREE_FX,
// so only the capstone reached the battle. This check fails with three skills back and passes with four.
const path = require('path');
process.env.VS_ORACLE = path.resolve(__dirname, '../../..');
require('../../../godot/campaign/test/node/env.js').load(`
globalThis.treeHandoffTest = () => {
  const fails = [];
  const ok = (cond, msg) => { if (!cond) fails.push(msg); };
  // one admiral per faction, with three branch rows and a capstone that all carry a TREE_FX effect
  const CASES = {
    voidsworn: ['malek', ['malek:A:0:0', 'malek:B:0:0', 'malek:C:0:0', 'malek:cap:1']],
    hegemony: ['kassar', ['kassar:A:0:0', 'kassar:B:0:0', 'kassar:C:0:0', 'kassar:cap:0']],
    corsair: ['grax', ['grax:A:0:0', 'grax:B:0:0', 'grax:C:0:0', 'grax:cap:0']],
    chorus: ['razormaw', ['razormaw:A:0:0', 'razormaw:B:0:1', 'razormaw:C:0:0', 'razormaw:cap:0']],
    ithar: ['vaelen', ['vaelen:A:0:0', 'vaelen:B:0:0', 'vaelen:C:0:0', 'vaelen:cap:1']],
    deathless: ['nekhet', ['nekhet:A:0:0', 'nekhet:B:0:1', 'nekhet:C:0:0', 'nekhet:cap:0']]
  };
  META = migrateMeta(defaultMeta());
  const lines = [];
  for (const fac of Object.keys(CASES)) {
    const [id, keys] = CASES[fac];
    RUN = null; SAVED_RUN = null;   // picks are made between runs, as the game allows
    META.mastery[id] = 230;         // level 8: three branch picks and a capstone are earned
    for (const key of keys) ok(lineagePick(key) === true, fac + ': lineagePick(' + key + ') was refused');
    newRun(id, fac);
    ok(RUN && RUN.lineage && RUN.lineage.id === id, fac + ': newRun did not snapshot the admiral tree');
    RUN = JSON.parse(JSON.stringify(RUN));   // what saveRun plus a load does: the short-pick snapshot an old save holds
    startBattle({kind: 'battle', fac: 'hegemony', col: 1, seed: 7, obj: 'rout', shape: 'open', map: 'belt', enemies: [{tpl: 'h_picket'}]});
    ok(typeof B !== 'undefined' && B && Array.isArray(B.tree), fac + ': startBattle did not build a battle tree');
    const got = {};
    for (const s of (B && B.tree) || []) got[s.k] = s.key;
    const names = [];
    for (const key of keys) {
      const fx = TREE_FX[key];
      ok(!!fx, fac + ': ' + key + ' has no TREE_FX row (the check needs an effect to look for)');
      if (!fx) continue;
      names.push(fx.k);
      ok(!!got[fx.k], fac + ': ' + key + ' (' + fx.k + ') did not reach B.tree (got ' + JSON.stringify(Object.keys(got)) + ')');
      ok(got[fx.k] === key, fac + ': ' + fx.k + ' reached B.tree under key ' + JSON.stringify(got[fx.k]) + ', not ' + JSON.stringify(key));
    }
    lines.push(fac + ' ' + id + ': ' + names.join(', '));
  }
  return {fails, lines};
};
`);
const out = global.treeHandoffTest();
if (out.fails.length) {
  for (const f of out.fails) console.log('FAIL ' + f);
  console.log('FAIL: ' + out.fails.length + ' tree hand-off check(s) failed');
  process.exit(1);
}
console.log('PASS: real campaign picks reach the battle for all six factions (four skills each):');
for (const line of out.lines) console.log('  ' + line);
