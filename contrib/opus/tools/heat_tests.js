'use strict';
// Step 10: Heat opens after the first loss and pays the ruled XP.
// No browser, Godot or third-party package is needed for this standing check.
const path = require('path');
const assert = require('assert');
process.env.VS_ORACLE = path.resolve(__dirname, '../../..');
require('../../../godot/campaign/test/node/env.js').load(`
globalThis.heatTest = () => {
  const ok = require('assert');
  META = migrateMeta(defaultMeta()); runOpt.heat = [];
  ok.equal(heatUnlocked(), false, 'a fresh profile has Heat closed');
  ok.ok(!runOptionsHtml().includes('data-act="optHeat"'), 'a fresh profile sees no Heat control');
  ok.ok(runOptionsHtml().includes('Lose a run to unlock Heat'), 'the locked card says how Heat opens');

  newRun('vaelen', 'ithar'); RUN.stats.battles = 0; endRun(false);
  ok.equal(META.stats.losses, 1, 'a lost run is recorded');
  ok.equal(heatUnlocked(), true, 'one loss opens Heat');
  ok.ok(runOptionsHtml().includes('data-act="optHeat"'), 'one loss shows the Heat control');

  META = migrateMeta(defaultMeta()); newRun('vaelen', 'ithar'); endRun(false, true);
  ok.equal(META.stats.losses || 0, 0, 'an abandoned run is not a recorded loss');
  ok.equal(heatUnlocked(), false, 'an abandoned run does not open Heat');

  META = migrateMeta(Object.assign(defaultMeta(), { tel: [
    { ev: 'run_end', victory: false, abandoned: false },
    { ev: 'run_end', victory: false },
    { ev: 'run_end', victory: false, abandoned: true },
    { ev: 'run_end', victory: true, abandoned: false }
  ] }));
  ok.equal(META.stats.losses, 2, 'a profile from before the Heat gate back-fills its recorded losses from the run log');
  ok.equal(heatUnlocked(), true, 'the back-filled losses open Heat on the next load');

  META = migrateMeta(Object.assign(defaultMeta(), { tel: [
    { ev: 'run_end', victory: false, abandoned: true },
    { ev: 'run_end', victory: true, abandoned: false }
  ] }));
  ok.ok(!('losses' in META.stats), 'a log with no real loss leaves the count absent so old fixtures stay unchanged');

  META = migrateMeta(defaultMeta()); META.stats.losses = 1; runOpt.heat = [];
  newRun('vaelen', 'ithar', {heat: ['h_hunted']});
  ok.equal(heatLevel(RUN.heat), 2, 'h_hunted is two Heat points');
  RUN.stats.battles = 0; endRun(false);
  ok.equal(masteryXP('vaelen'), 4, 'the flown line gets 2 XP per Heat point');
  ok.equal(masteryXP('aelith'), 0, 'the Heat payout is not split to benched lines');
  ok.equal(META.shadowPool.ithar, 2, 'the faction shadow pool gets 1 XP per Heat point');
  ok.equal(META.stats.losses, 2, 'the paid run also records its loss');

  META = migrateMeta(defaultMeta()); META.stats.losses = 1; META.mastery.vaelen = 229;
  newRun('vaelen', 'ithar', {heat: ['h_flag']}); RUN.stats.battles = 0; endRun(false);
  ok.equal(masteryXP('vaelen'), 230, 'Heat XP respects the line cap');
  ok.equal(META.shadowPool.ithar, 2, 'cap overflow joins the shadow pool with the pool point');

  META = migrateMeta(defaultMeta()); META.stats.wins = 1;
  ok.equal(heatUnlocked(), true, 'an older winner keeps Heat open');

  META = migrateMeta(defaultMeta()); META.admirals.vaelen = true; pickedAdmiral = 'vaelen'; pickedFaction = 'ithar'; runOpt.heat = ['h_flag'];
  ACT.startRun();
  ok.deepEqual(RUN.heat, [], 'a fresh profile cannot launch with Heat');
  META.stats.losses = 1; ACT.startRun();
  ok.deepEqual(RUN.heat, ['h_flag'], 'a profile with one loss can launch with Heat');
  RUN = null;
  return true;
};
`);
assert.equal(global.heatTest(), true);
console.log('PASS: Heat opens after the first loss and pays 2 XP per point to the flown line and 1 to the shadow pool.');
