'use strict';
// Step 3: real run payouts and debrief actions, plus exact overflow fixtures
// consumed by godot/campaign/test/shadow_xp_test.gd.
const fs = require('fs');
const path = require('path');
process.env.VS_ORACLE = path.resolve(__dirname, '../../..');
require('../../../godot/campaign/test/node/env.js').load(`
globalThis.shadowXPTest = () => {
  const ok = require('assert'), fixtures = [];
  META = migrateMeta(defaultMeta());
  newRun('vaelen', 'ithar'); RUN.stats.battles = 8; endRun(false);
  ok.equal(masteryXP('vaelen'), 8);
  ok.equal(masteryXP('aelith'), 2, 'benched same faction earns a quarter');
  ok.equal(masteryXP('vex'), 0, 'another faction earns nothing');
  ACT.nameHeir('vex'); ACT.nameHeir('vaelen');
  ok.deepEqual(META.heirs, {}, 'only a benched line of this faction is eligible');
  META.runAt = 123; ACT.nameHeir('aelith');
  ok.equal(META.runAt, 123, 'heir naming saves meta without changing the run timestamp');
  ok.equal(masteryXP('aelith'), 2, 'naming is not retroactive');
  META = migrateMeta(JSON.parse(JSON.stringify(META)));
  ok.equal(META.heirs.ithar, 'aelith', 'heir survives reload');
  newRun('vaelen', 'ithar'); RUN.stats.battles = 8; endRun(true);
  ok.equal(masteryXP('aelith'), 11, 'heir earns half of the next paid victory');
  ok.equal(masteryXP('vaelen'), 26, 'flown line keeps its full payout');
  const before = JSON.stringify(META); endRun(true);
  ok.equal(JSON.stringify(META), before, 'duplicate ending cannot pay twice');
  const other = shadowAdmirals('ithar', 'vaelen').find(id => id !== 'aelith');
  ACT.nameHeir(other); ok.equal(META.heirs.ithar, other, 'one heir replaces the previous heir');
  ACT.title(); ACT.nameHeir('aelith'); ok.equal(META.heirs.ithar, other, 'naming only on the debrief');
  newRun('vex', 'voidsworn'); RUN.stats.battles = 4; endRun(false, true);
  const crusade = shadowAdmirals('voidsworn', 'vex')[0]; ACT.nameHeir(crusade);
  ok.equal(META.heirs.ithar, other, 'each faction keeps its heir');
  ok.equal(META.heirs.voidsworn, crusade, 'abandon debrief also offers an heir');
  for (const name of ['fractional', 'active cap', 'bench cap', 'all capped', 'saved balance', 'old excess', 'fixed cap']) {
    META = migrateMeta(defaultMeta());
    const fac = name === 'fixed cap' ? 'voidsworn' : 'ithar', flown = name === 'fixed cap' ? 'vex' : 'vaelen';
    const ids = shadowAdmirals(fac, flown);
    if (name !== 'fractional') META.heirs[fac] = ids[0];
    if (name === 'fixed cap') { META.mastery.vex = 49; META.mastery[ids[0]] = 49; }
    if (['active cap', 'all capped', 'saved balance'].includes(name)) META.mastery.vaelen = 229;
    if (name === 'bench cap') META.mastery[ids[0]] = 229;
    if (['all capped', 'saved balance'].includes(name)) for (const id of ids) META.mastery[id] = 230;
    if (name === 'saved balance') { META.shadowPool.ithar = 20; META.mastery[ids[1]] = 200; }
    if (name === 'old excess') META.mastery.vaelen = 250;
    const meta = JSON.parse(JSON.stringify(META)), xp = name === 'fractional' ? 1 : 8;
    const prior = Object.values(META.mastery).reduce((a,b)=>a+b,0)+(META.shadowPool[fac]||0);
    const earned = xp + ids.reduce((n,id)=>n+xp*shadowRate(id),0);
    const result = awardLineageXP(flown, fac, xp);
    const after = Object.values(META.mastery).reduce((a,b)=>a+b,0)+META.shadowPool[fac];
    ok.ok(Math.abs(after-prior-earned)<1e-9, name + ': no XP vanishes');
    for (const id of [flown, ...ids]) ok.ok(masteryXP(id)<=masteryThresholds(id).slice(-1)[0], name + ': respects caps');
    if (name === 'fractional') ok.equal(masteryXP(ids[0]), .25, 'keep fractional earnings');
    if (name === 'all capped') ok.equal(META.shadowPool.ithar, 15, 'save all overflow');
    fixtures.push({name, meta, xp, flown, fac, result, expected:JSON.parse(JSON.stringify(META))});
  }
  META = migrateMeta(JSON.parse(JSON.stringify(META))); ok.ok(META.shadowPool, 'shadow balance survives reload');
  ok.equal(saneSave({meta:{heirs:'oops'},run:null}), false, 'a non-object heirs field fails the save sanity check');
  ok.equal(saneSave({meta:{shadowPool:42},run:null}), false, 'a non-object shadowPool field fails the save sanity check');
  ok.equal(saneSave({meta:{heirs:{},shadowPool:{}},run:null}), true, 'well-formed heirs and shadowPool pass the save sanity check');
  const old = defaultMeta(); delete old.heirs; delete old.shadowPool;
  META = migrateMeta(old); ok.deepEqual(META.heirs, {}); ok.deepEqual(META.shadowPool, {});
  return fixtures;
};
`);
const fixtures = global.shadowXPTest();
if (process.argv[2]) fs.writeFileSync(process.argv[2], JSON.stringify(fixtures));
console.log('PASS: quarter and heir half rates, both debriefs, saves, faction scope and lossless capped XP.');
