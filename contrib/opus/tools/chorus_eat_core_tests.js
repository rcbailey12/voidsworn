'use strict';
// Issue 42 (R78 Q15): the Chorus eats one core in sector 3. Covers the offer, eating, refusing, the save round trip and
// a run of another faction never seeing the offer. Uses the real root game files through the campaign harness.
const path = require('path');
process.env.VS_ORACLE = path.resolve(__dirname, '../../..');
require('../../../godot/campaign/test/node/env.js').load(`
globalThis.chorusEatSuite = () => {
  const ok = require('assert');
  const iron = Object.keys(BOONS).find(id => BOONS[id].p === 'iron' && !BOONS[id].leg);
  const storm = Object.keys(BOONS).find(id => BOONS[id].p === 'storm' && !BOONS[id].leg);
  const ironDuo = Object.keys(BOONS).find(id => BOONS[id].duo && BOONS[id].duo.includes('iron'));
  const otherDuo = Object.keys(BOONS).find(id => BOONS[id].duo && !BOONS[id].duo.includes('iron'));
  let html = '';
  show = h => { html = String(h); }; modal = h => { html = String(h); }; closeModal = () => {}; toast = () => {};

  const reset = (admiral, fac) => {
    META = migrateMeta(defaultMeta()); rndSeed(11); newRun(admiral, fac);
    ok.ok(RUN, 'a run starts as ' + fac);
    RUN.sector = 3; RUN.patrons = ['iron', 'storm', 'hunger', 'rook']; RUN.flags = {}; RUN.boons = []; RUN.reward = null;
    META.favour = { iron: 0, storm: 6, hunger: 11, star: 15, rook: 0, ember: 0 };
    return RUN;
  };
  const hulls = () => RUN.fleet.map(s => ({ uid: s.uid, tpl: s.tpl, hp: s.hp, max: derive(s).maxHp }));

  // the offer: title, one button per eligible core, refuse, and the Synced core left out
  reset('matriarch', 'chorus');
  ok.equal(coreEatDue(), true, 'a Chorus run at sector 3 is offered the choice');
  ok.ok(showCoreEat(), 'the offer is shown');
  ok.ok(html.includes('The swarm hungers.'), 'the offer title');
  for (const p of coreEatEligible()) ok.ok(html.includes('Eat ' + esc(PATRONS[p].n)), 'a button for ' + PATRONS[p].n);
  ok.ok(html.includes('data-act="refuseCoreEat"'), 'a Refuse button');
  ok.ok(!coreEatEligible().includes('star'), 'a Synced core is not eligible');
  reset('matriarch', 'chorus'); RUN.sector = 2;
  ok.equal(coreEatDue(), false, 'sector 2 is not offered');
  reset('matriarch', 'chorus'); META.favour = Object.fromEntries(Object.keys(PATRONS).map(id => [id, 12]));
  ok.equal(coreEatDue(), false, 'no offer when every core is Synced');
  reset('vex', 'voidsworn');
  ok.equal(coreEatEligible().length, 0, 'another faction has no eligible cores');
  ok.equal(coreEatDue(), false, 'another faction is never offered');
  html = ''; ok.equal(showCoreEat(), false, 'another faction never sees the screen'); ok.equal(html, '');

  // eat: hull grows on every Chorus ship and on new ships, not on a non-Chorus ship; current hull rises with it
  reset('matriarch', 'chorus');
  const ally = newShip('penitent'); ally.hp = derive(ally).maxHp; RUN.fleet.push(ally);
  const before = hulls();
  ok.equal(eatCore('star'), false, 'a Synced core cannot be eaten');
  ok.ok(eatCore('hunger'), 'a core below Synced can be eaten');
  ok.equal(RUN.eatenCore, 'hunger'); ok.equal(RUN.eatCoreSeen, true);
  for (const old of before) {
    const s = RUN.fleet.find(x => x.uid === old.uid); const now = derive(s).maxHp;
    if (factionOfTpl(s.tpl) === 'chorus') {
      ok.ok(now > old.max, 'a Chorus ship gains max hull');
      ok.equal(s.hp, Math.min(now, old.hp + (now - old.max)), 'its current hull rises by the same amount');
    } else {
      ok.equal(now, old.max, 'a non-Chorus ship keeps its max hull');
      ok.equal(s.hp, old.hp, 'a non-Chorus ship keeps its hull');
    }
  }
  const plain = (() => { reset('matriarch', 'chorus'); return derive(newShip('b_drone')).maxHp; })();
  reset('matriarch', 'chorus'); eatCore('hunger'); const grown = derive(newShip('b_drone')).maxHp;
  ok.ok(grown > plain, 'a ship built after the meal gets the growth');
  ok.equal(eatCore('iron'), false, 'the offer can only be taken once');
  ok.equal(showCoreEat(), false, 'a taken offer never shows again');

  // protocols: the eaten core's boons and its duos are lost, other boons stay, and its pool is gone for the run
  reset('matriarch', 'chorus');
  RUN.boons = [{ id: iron, r: 0 }, { id: storm, r: 0 }, { id: ironDuo, r: 0 }, { id: otherDuo, r: 0 }];
  ok.ok(eatCore('iron'), 'eat a core that has protocols held');
  ok.ok(!RUN.boons.some(b => b.id === iron), 'the eaten core protocol is lost');
  ok.ok(!RUN.boons.some(b => b.id === ironDuo), 'a duo including the eaten core is lost');
  ok.ok(RUN.boons.some(b => b.id === storm) && RUN.boons.some(b => b.id === otherDuo), 'other protocols stay');
  for (const o of rollBoonOffer('iron', 1)) {
    const b = BOONS[o.id];
    ok.ok(b.p !== 'iron' && !(b.duo && b.duo.includes('iron')), 'the eaten core is never offered again');
  }

  // refuse: nothing changes, the offer is marked seen
  reset('matriarch', 'chorus');
  const refused = hulls();
  ok.ok(showCoreEat(), 'the offer is shown before refusing');
  ok.ok(refuseCoreEat(), 'refusing is accepted');
  ok.equal(RUN.eatenCore, null); ok.equal(RUN.eatCoreSeen, true);
  for (const old of refused) {
    const s = RUN.fleet.find(x => x.uid === old.uid);
    ok.equal(derive(s).maxHp, old.max, 'refusing changes no max hull');
    ok.equal(s.hp, old.hp, 'refusing changes no current hull');
  }
  ok.equal(coreEatDue(), false, 'a refused offer never shows again');

  // save round trip: the eaten core, the seen mark and the grown hull survive
  reset('matriarch', 'chorus');
  ok.ok(eatCore('hunger'), 'eat before saving');
  saveRun();
  const saved = JSON.parse(JSON.stringify({ meta: META, run: SAVED_RUN }));
  META = migrateMeta(saved.meta); RUN = migrateRun(saved.run); SAVED_RUN = saved.run;
  ok.equal(RUN.eatenCore, 'hunger'); ok.equal(RUN.eatCoreSeen, true);
  const reloaded = RUN.fleet.find(s => factionOfTpl(s.tpl) === 'chorus');
  ok.ok(derive(reloaded).maxHp > HULLS[reloaded.tpl].hp, 'the grown hull survives the reload');
  ok.equal(coreEatDue(), false, 'the save does not offer it a second time');
  // an older save with neither field loads as not yet offered
  const old = JSON.parse(JSON.stringify(RUN)); delete old.eatenCore; delete old.eatCoreSeen;
  RUN = migrateRun(old);
  ok.equal(RUN.eatenCore, null); ok.equal(RUN.eatCoreSeen, false);
  ok.equal(coreEatDue(), true, 'a missing field means not offered yet');
};
`);
global.chorusEatSuite();
console.log('PASS: Chorus core eat offer, eat, refuse, save round trip and non-Chorus runs match R78 Q15.');
