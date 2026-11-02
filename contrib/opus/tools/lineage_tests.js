'use strict';
// Step 2: the real campaign earns XP across runs, records choices and resets a line.
// No browser, Godot or third-party package is needed for this standing check.
const path = require('path');
const assert = require('assert');
process.env.VS_ORACLE = path.resolve(__dirname, '../../..');
require('../../../godot/campaign/test/node/env.js').load(`
globalThis.lineageTest = () => {
  const ok = require('assert');
  META = migrateMeta(defaultMeta()); META.admirals.vaelen = true;
  for (let run = 0; run < 5; run++) {
    newRun('vaelen', 'ithar');
    RUN.stats.battles = 15;
    endRun(false);
  }
  ok.equal(masteryXP('vaelen'), 75);
  ok.equal(masteryLevel('vaelen'), 5);
  ok.equal(lineagePick('vaelen:A:1:0'), false, 'cannot skip a tier');
  ok.equal(lineagePick('vaelen:cap:0'), false, 'cannot take a capstone early');
  ACT.lineage('vaelen'); ACT.offerLineage('vaelen:A:0:0');
  ok.deepEqual(lineageBuild('vaelen').picks, [], 'preview does not spend the pick');
  ACT.closeModal();
  ACT.confirmLineage('vaelen:A:0:0');
  ok.equal(lineageNodes('vaelen').find(n => n.key === 'vaelen:A:0:1').state, 'locked');
  ok.equal(lineagePick('vaelen:B:0:0'), false, 'only one pick at level 5');
  META.mastery.vaelen = 110;
  ok.equal(lineagePick('vaelen:B:0:1'), true, 'branches advance independently');
  META.mastery.vaelen = 160;
  ok.equal(lineagePick('vaelen:A:1:0'), true);
  ok.equal(lineagePick('vaelen:A:2:0'), false, 'only three branch picks');
  META.mastery.vaelen = 230;
  ok.equal(lineagePick('vaelen:cap:1'), true);
  ok.equal(lineageNodes('vaelen').find(n => n.key === 'vaelen:cap:0').state, 'locked');
  ok.equal(lineagePick('vaelen:cap:0'), false);
  const saved = JSON.stringify(META);
  META = migrateMeta(JSON.parse(saved));
  ok.equal(lineageBuild('vaelen').capstone, 1, 'choices survive reopening');
  ok.equal(lineageRespecCost('vaelen'), 25);
  META.renown = 24;
  ok.equal(lineageRespec('vaelen'), false, 'cannot reset without renown');
  META.renown = 25;
  newRun('vaelen', 'ithar');
  ok.equal(lineageRespec('vaelen'), false, 'cannot reset during a run');
  RUN = null;
  ok.equal(lineageRespec('vaelen'), false, 'cannot reset while a saved run exists');
  SAVED_RUN = null;
  ACT.offerRespec('vaelen'); ACT.closeModal();
  ok.equal(META.renown, 25, 'cancel does not charge');
  ACT.confirmRespec('vaelen');
  ok.equal(META.renown, 0);
  ok.deepEqual(lineageBuild('vaelen'), {picks: [], capstone: null, respecs: 1});
  ok.equal(masteryXP('vaelen'), 230, 'reset keeps XP');
  ok.equal(lineageRespecCost('vaelen'), 35);
  ok.equal(lineageRespecCost('aelith'), 25, 'price belongs to the line');
  ok.equal(lineagePick('vaelen:A:0:1'), true, 'locked partner becomes available after reset');
  ok.equal(lineagePick('vaelen:A:1:1'), true);
  ok.equal(lineagePick('vaelen:A:2:1'), true, 'one branch may reach tier 3');
  ok.equal(lineagePick('vaelen:cap:0'), true);
  META.renown = 100;
  ok.equal(lineageRespec('vaelen'), true);
  ok.equal(META.renown, 65);
  ok.equal(lineageRespecCost('vaelen'), 45);
  ok.equal(lineageRespec('vaelen'), false, 'empty resets cannot charge');
  for (const id of Object.keys(ADMIRALS)) {
    META.mastery[id] = 230;
    if (ADMIRALS[id].fac !== 'ithar') {
      ok.equal(masteryLevel(id), 4);
      ok.deepEqual(lineageNodes(id), []);
      ok.equal(lineageRespec(id), false);
    } else {
      ok.equal(masteryLevel(id), 8);
      ok.equal(lineagePick(id + ':B:0:0'), true);
      ok.equal(lineagePick(id + ':C:0:0'), true);
      ok.equal(lineagePick(id + ':A:0:0'), true);
      ok.equal(lineagePick(id + ':cap:0'), true);
    }
  }
  for (const [xp, level] of [[0,0],[6,1],[16,2],[30,3],[50,4],[74,4],[75,5],[109,5],[110,6],[159,6],[160,7],[229,7],[230,8]]) {
    META.mastery.vaelen = xp; ok.equal(masteryLevel('vaelen'), level);
  }
  const old = defaultMeta(); delete old.lineage;
  META = migrateMeta(old); ok.deepEqual(lineageBuild('vaelen'), {picks: [], capstone: null, respecs: 0}, 'old profiles start with no choices');
  return true;
};
`);
assert.equal(global.lineageTest(), true);
console.log('PASS: Glasswright XP, tiers, locks, capstones, saves and per-line resets; other factions unchanged.');
