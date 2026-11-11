'use strict';
// Paid end screens must describe the profile they actually created.
const fs = require('fs');
const path = require('path');
process.env.VS_ORACLE = path.resolve(__dirname, '../../..');
require('../../../godot/campaign/test/node/env.js').load(`
globalThis.inheritanceTest = () => {
  const ok = require('assert'), fixtures = [];
  let html = ''; show = h => { html = h; };
  const storage = {}; localStorage.setItem = (key,value) => { storage[key] = value; };
  for (const name of ['loss', 'victory', 'abandon', 'trunk', 'capstone', 'all capped', 'empty']) {
    META = migrateMeta(defaultMeta()); SAVED_RUN = null;
    const flown = name === 'empty' ? 'vex' : 'vaelen';
    META.admirals[flown] = true;
    const fac = ADMIRALS[flown].fac || 'voidsworn';
    META.renown = name === 'empty' ? 0 : 18;
    META.unlocked.chest1 = name !== 'empty';
    const variant = Object.keys(HULL_VARIANTS).find(id => !HULL_VARIANTS[id].arc);
    if (name !== 'empty') META.variants[variant] = true;
    META.mastery[flown] = name === 'capstone' ? 229 : name === 'all capped' ? 230 : ['trunk','empty'].includes(name) ? 0 : 69;
    if (name === 'capstone') META.lineage = {[flown]:{picks:['A:0:0','A:1:0','A:2:0'],capstone:null,respecs:0}};
    const ids = shadowAdmirals(fac, flown); META.heirs[fac] = ids[0];
    if (name === 'all capped') for (const id of ids) META.mastery[id] = 230;
    const meta = JSON.parse(JSON.stringify(META));
    newRun(flown, fac); const run = RUN;
    run.stats.battles = name === 'empty' ? 0 : 8;
    run.stats.elites = name === 'victory' ? 2 : 0;
    run.stats.bosses = name === 'victory' ? 3 : 0;
    run.sector = name === 'victory' ? 3 : 1;
    const stats = {...run.stats}, victory = name === 'victory', abandoned = name === 'abandon';
    endRun(victory, abandoned);
    const cy = run.carry, receipt = cy.inheritance;
    const saved = JSON.parse(storage[STORE_KEY]); ok.deepEqual(saved.meta, META); ok.equal(saved.run, null);
    ok.equal(receipt.balance, META.renown);
    ok.equal(receipt.balance - meta.renown, cy.ren);
    ok.equal(receipt.flown.xp, masteryXP(flown));
    ok.equal(receipt.flown.level, masteryLevel(flown));
    ok.equal(receipt.flown.xp - meta.mastery[flown], cy.mxGain);
    for (const row of receipt.shadow) {
      ok.equal(row.total, masteryXP(row.id));
      ok.equal(row.total - (meta.mastery[row.id] || 0), row.xp);
      ok.equal(row.level, masteryLevel(row.id));
    }
    const expected = [
      ...Object.keys(LEGACY).filter(id => !META.unlocked[id] && (!LEGACY[id].req || META.unlocked[LEGACY[id].req]) && LEGACY[id].cost <= META.renown),
      ...Object.keys(HULL_VARIANTS).filter(id => !HULL_VARIANTS[id].arc && !META.variants[id] && HULL_VARIANTS[id].cost <= META.renown)
    ];
    ok.deepEqual(receipt.affordable.map(u => u.id), expected);
    for (const u of receipt.affordable) {
      ok.equal(u.fresh, u.cost > meta.renown);
      ok.ok(html.includes(esc(u.n)), 'affordable reward is visible');
    }
    ok.ok(html.includes('Your inheritance') && html.includes('Affordable now') && html.includes('View admiral line'));
    if (name === 'loss') ok.equal(receipt.flown.pending, 1, 'level 5 offers a branch pick');
    if (name === 'trunk') { ok.equal(receipt.flown.earned[0].n, 'Alternate fleet'); ok.ok(html.includes('Alternate fleet earned')); }
    if (name === 'capstone') { ok.equal(receipt.flown.capstoneReady, true); ok.equal(receipt.flown.chosen.length, 3); }
    if (name === 'empty') ok.ok(html.includes('No unowned doctrine or hull reward is affordable yet'));
    const before = JSON.stringify(META); endRun(victory, abandoned); ok.equal(JSON.stringify(META), before);
    fixtures.push({name,meta,flown,fac,stats,sector:run.sector,victory,abandoned,carry:JSON.parse(JSON.stringify(cy)),expected:JSON.parse(JSON.stringify(META))});
  }
  return fixtures;
};
`);
const fixtures = global.inheritanceTest();
if (process.argv[2]) fs.writeFileSync(process.argv[2], JSON.stringify(fixtures));
console.log('PASS: paid inheritance matches win, loss and abandon profiles, affordability, tree progress and capped shadow XP.');
