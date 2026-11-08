'use strict';
// Step 10: Heat opens after a real loss and pays +2 XP to the flown line and +1 XP to shadow.
const fs = require('fs');
const path = require('path');
process.env.VS_ORACLE = path.resolve(__dirname, '../../..');
require('../../../godot/campaign/test/node/env.js').load(`
globalThis.heatTest = () => {
  const ok = require('assert'), fixtures = [];
  let html = ''; show = h => { html = h; };
  function reset(meta) {
    META = migrateMeta(meta || defaultMeta()); SAVED_RUN = null; RUN = null; B = null;
    pickedAdmiral = 'vex'; pickedFaction = 'voidsworn'; runOpt.alt = false; runOpt.cmdAlt = false; runOpt.heat = [];
    heirDebrief = null;
  }
  function lossMeta() { const m = defaultMeta(); m.stats.losses = 1; return m; }
  function finish(name, meta, heat, abandoned = false, battles = 8) {
    reset(meta);
    const before = JSON.parse(JSON.stringify(META));
    newRun('vex', 'voidsworn', {heat}); RUN.stats.battles = battles;
    const run = RUN, stats = {...RUN.stats};
    endRun(false, abandoned);
    const result = {name, meta:before, flown:'vex', fac:'voidsworn', heat:[...heat], stats, sector:1,
      victory:false, abandoned, carry:JSON.parse(JSON.stringify(run.carry)),
      expected:{mastery:JSON.parse(JSON.stringify(META.mastery)),shadowPool:JSON.parse(JSON.stringify(META.shadowPool)),stats:JSON.parse(JSON.stringify(META.stats))}, html};
    fixtures.push(result); return result;
  }
  function shadowTotal(result) {
    const mastery = Object.entries(result.expected.mastery).filter(([id]) => id !== 'vex').reduce((n,[,xp]) => n+xp,0);
    const bank = Object.values(result.expected.shadowPool).reduce((n,xp) => n+xp,0);
    return mastery + bank;
  }

  reset();
  ok.equal(heatAvailable(), false, 'fresh profile cannot use Heat');
  ok.ok(!runOptionsHtml().includes('data-act="optHeat"'), 'fresh profile has no Heat control');
  runOpt.heat = ['h_hunted']; ACT.optHeat('h_cmd');
  ok.deepEqual(runOpt.heat, ['h_hunted'], 'locked Heat action is ignored');
  ACT.startRun(); ok.deepEqual(RUN.heat, [], 'launch strips Heat on a fresh profile');

  const first = finish('first_loss', defaultMeta(), []);
  ok.equal(first.expected.stats.losses, 1, 'a defeat records one loss');
  ok.equal(heatAvailable(), true, 'one loss opens Heat');
  ok.ok(runOptionsHtml().includes('data-act="optHeat"'), 'one-loss profile has Heat controls');
  runOpt.heat = ['h_hunted','h_cmd']; ACT.startRun();
  ok.equal(heatLevel(RUN.heat), 3, 'one-loss profile launches its selected Heat');

  const abandoned = finish('abandon', defaultMeta(), [], true);
  ok.equal(abandoned.expected.stats.losses||0, 0, 'abandoning is not a recorded loss');
  ok.equal(heatAvailable(), false, 'abandoning does not open Heat');

  const winner = defaultMeta(); winner.stats.wins = 1; reset(winner);
  ok.equal(heatAvailable(), true, 'existing winners keep Heat access');
  ok.ok(runOptionsHtml().includes('data-act="optHeat"'), 'existing winner still has Heat controls');

  const old = defaultMeta(); delete old.stats.losses;
  old.tel = [{ev:'run_end',victory:false,abandoned:false},{ev:'run_end',victory:false,abandoned:true}]; reset(old);
  ok.equal(META.stats.losses, 1, 'migration recovers a recorded defeat but not an abandon');

  const plain = finish('heat_0', lossMeta(), []);
  const heated = finish('heat_3', lossMeta(), ['h_hunted','h_cmd']);
  ok.equal(heated.carry.hl, 3, 'fixture uses three Heat points');
  ok.equal((heated.expected.mastery.vex||0)-(plain.expected.mastery.vex||0), 6, 'Heat 3 adds exactly 6 XP to the flown admiral');
  ok.equal(shadowTotal(heated)-shadowTotal(plain), 3, 'Heat 3 adds exactly 3 XP to shadow learning');
  ok.ok(heated.html.includes('Heat 3 paid 6 XP to ') && heated.html.includes('3 XP to the faction shadow pool.'), 'debrief states the ruled Heat payout');

  const cap = lossMeta(); cap.mastery.vex = masteryThresholds('vex').slice(-1)[0]-1;
  for (const id of shadowAdmirals('voidsworn','vex')) cap.mastery[id] = masteryThresholds(id).slice(-1)[0];
  const capped = finish('heat_cap', cap, ['h_hunted','h_cmd'], false, 0);
  ok.equal(capped.carry.mxGain, 1, 'only one flown XP fits below the cap');
  ok.equal(capped.carry.mxOverflow, 5, 'five flown Heat XP overflow at the cap');
  ok.equal(capped.carry.shadowBank, 8, 'cap overflow and the three direct shadow XP are preserved');

  return fixtures;
};
`);
const fixtures = global.heatTest();
if (process.argv[2]) fs.writeFileSync(process.argv[2], JSON.stringify(fixtures));
console.log('PASS: fresh and one-loss Heat controls, real loss tracking, +2/+1 XP payouts, migration and cap overflow.');
