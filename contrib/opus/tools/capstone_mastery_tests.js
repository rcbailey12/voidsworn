'use strict';
// Step 14: capstone mastery. A chosen level 8 evolution deepens at 320, 440 and 600 XP.
// The effect texts are placeholders until the tree pack carries them. No browser or third-party package is needed.
const path = require('path');
const assert = require('assert');
process.env.VS_ORACLE = path.resolve(__dirname, '../../..');
require('../../../godot/campaign/test/node/env.js').load(`
globalThis.capstoneMasteryTest = () => {
  const ok = require('assert'); let html = ''; show = h => { html = h; };
  const evo = id => { META.lineage = META.lineage || {}; META.lineage[id] = {picks: ['A:0:0', 'B:0:0', 'C:0:0'], capstone: 0, respecs: 0}; };

  // a line at 320 XP on its chosen evolution shows mastery level 1 and its effect
  META = migrateMeta(defaultMeta()); META.mastery.vaelen = 320; evo('vaelen');
  ok.equal(masteryLevel('vaelen'), 8, 'the evolution stays at tree level 8');
  ok.equal(capstoneMasteryLevel('vaelen'), 1, '320 XP is capstone mastery 1');
  ok.equal(masteryXPCap('vaelen'), 600, 'a chosen evolution opens the cap to 600');
  ok.ok(capstoneMasteryPerk(1) && capstoneMasteryPerk(1).d.length > 0, 'mastery 1 has an effect line');
  ACT.lineage('vaelen');
  ok.ok(html.includes('Capstone mastery: '), 'the lineage screen names the evolution mastery');
  ok.ok(html.includes('Mastery I (earned)'), 'the screen marks mastery 1 earned');
  ok.ok(html.includes('320 XP'), 'the screen lists the 320 threshold');
  ok.ok(html.includes('Placeholder: the mastery effect'), 'the placeholder effect is visible');
  ok.ok(masteryBar('vaelen').includes('Capstone mastery 1/3'), 'the admiral bar shows capstone mastery 1');

  // XP below 230 cannot buy mastery: no evolution, no mastery, and the line still stops at 230
  META = migrateMeta(defaultMeta()); META.mastery.vaelen = 229;
  ok.equal(lineagePick('vaelen:cap:0'), false, 'no evolution below level 8');
  ok.equal(capstoneMasteryLevel('vaelen'), 0, 'no mastery below the evolution');
  ok.equal(masteryXPCap('vaelen'), 230, 'an unmet line still caps at 230');
  META.mastery.vaelen = 320;
  ok.equal(capstoneMasteryLevel('vaelen'), 0, 'XP alone cannot buy mastery without the evolution');

  // the three thresholds
  for (const [xp, level] of [[0, 0], [319, 0], [320, 1], [439, 1], [440, 2], [599, 2], [600, 3], [900, 3]]) {
    META = migrateMeta(defaultMeta()); META.mastery.vaelen = xp; evo('vaelen');
    ok.equal(capstoneMasteryLevel('vaelen'), level, 'capstone mastery threshold ' + xp);
  }
  META = migrateMeta(defaultMeta()); META.mastery.vaelen = 320; evo('vaelen');
  ok.equal(capstoneMasteryNext('vaelen'), 440, '320 XP points at 440 next');
  META.mastery.vaelen = 600;
  ok.equal(capstoneMasteryNext('vaelen'), null, '600 XP is full mastery');

  // XP past 230 deepens the chosen evolution on a real run instead of spilling at once
  META = migrateMeta(defaultMeta()); META.mastery.vaelen = 300; evo('vaelen');
  newRun('vaelen', 'ithar'); RUN.stats.battles = 8; endRun(false);
  ok.equal(masteryXP('vaelen'), 308, 'XP past 230 deepens the chosen evolution');
  ok.equal(capstoneMasteryLevel('vaelen'), 0, '308 XP is still below mastery 1');

  // without an evolution the same run still stops at 230 and spills the rest to shadow learning
  META = migrateMeta(defaultMeta()); META.mastery.vaelen = 229;
  newRun('vaelen', 'ithar'); RUN.stats.battles = 8; endRun(false);
  ok.equal(masteryXP('vaelen'), 230, 'an unmet line stops at 230');
  ok.equal(capstoneMasteryLevel('vaelen'), 0, 'an unmet line shows no mastery');

  // save round trip
  META = migrateMeta(defaultMeta()); META.mastery.vaelen = 440; evo('vaelen');
  META = migrateMeta(JSON.parse(JSON.stringify(META)));
  ok.equal(capstoneMasteryLevel('vaelen'), 2, 'mastery survives reopening a save');

  // a respec withdraws the evolution and with it the mastery display and the raised cap
  META = migrateMeta(defaultMeta()); META.mastery.vaelen = 440; evo('vaelen'); META.renown = 100;
  ok.equal(lineageRespec('vaelen'), true);
  ok.equal(capstoneMasteryLevel('vaelen'), 0, 'a reset evolution shows no mastery');
  ok.equal(masteryXPCap('vaelen'), 230, 'a reset line caps at 230 again');
  const gain = masteryCredit('vaelen', 50);
  ok.equal(masteryXP('vaelen'), 440, 'a reset line keeps the XP it already earned');
  ok.equal(gain.overflow, 50, 'new XP past the reset cap goes to shadow learning');
  return true;
};
`);
assert.equal(global.capstoneMasteryTest(), true);
console.log('PASS: capstone mastery opens at 320, 440 and 600 XP only after the level 8 evolution, and shows its effect.');
