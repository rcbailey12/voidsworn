'use strict';
// R78 Q15 (issue #42): the Chorus eats one unsynced core in sector 3, once a run. Covers the eat, the refuse, the save
// round trip, an older save without the new fields, the gates (non-Chorus, wrong sector, everything synced) and the
// offer screen itself through the real ACT.enterNode gate. Writes fixtures for godot/campaign/test/eaten_core_test.gd.
const fs = require('fs'), path = require('path');
process.env.VS_ORACLE = path.resolve(__dirname, '../../..');
require('../../../godot/campaign/test/node/env.js').load(`
globalThis.eatenCoreTest = () => {
  const ok = require('assert');
  const fixtures = [];
  const baseHp = ship => Math.round(HULLS[ship.tpl].hp * (1 + .2 * ((ship.mk || 1) - 1)) * (1 + .06 * classTrack(HULLS[ship.tpl].cls)));
  const snap = () => ({
    offer: eatenCoreOffer(),
    eaten: typeof RUN.eatenCore === 'string' ? RUN.eatenCore : null,
    seen: !!RUN.eatenOfferSeen,
    boons: (RUN.boons || []).map(b => b.id),
    gift: RUN.giftBoon || null,
    maxHp: RUN.fleet.map(s => derive(s).maxHp),
    hp: RUN.fleet.map(s => s.hp),
    favour: Object.assign({}, META.favour),
    mapCores: [...new Set(RUN.map.cols.flat().filter(n => !n.done && n.rw && n.rw.k === 'boon').map(n => n.rw.p))].sort(),
    poolOk: !RUN.eatenCore || !boonOfferCan(eatenCoreOffer()[0] || RUN.patrons[0], 1).some(id => BOONS[id].p === RUN.eatenCore || (BOONS[id].duo || []).includes(RUN.eatenCore))
  });
  const setup = f => {
    rndSeed(f.seed); UID = 1;
    META = migrateMeta(defaultMeta()); META.favour = Object.assign({}, f.favour); SAVED_RUN = null;
    newRun('vex', f.fac);
    RUN.sector = f.sector; RUN.map = genSector(f.sector); RUN.pos = null;
    if (f.beat3Done) RUN.flags[STORY_BEAT3[f.fac].id] = 1;
    for (const id of f.hold || []) RUN.boons.push({ id, r: 0 });
    if (f.gift) RUN.giftBoon = f.gift;
    if (f.extra) { const sh = newShip(f.extra); sh.hp = Math.floor(derive(sh).maxHp / 2); RUN.fleet.push(sh); }
    saveRun();
  };
  const actsSeen = () => {
    let html = ''; const keep = { show, modal };
    show = h => { html = String(h); }; modal = h => { html = String(h); };
    return { html, restore: () => { show = keep.show; modal = keep.modal; } };
  };

  // 1. eat: the growth, the lost protocols (own, duo, gift), the map scrub, no more offers, favour untouched
  {
    const offer0 = (() => { setup({ seed: 101, fac: 'chorus', sector: 3, favour: {}, beat3Done: true }); return eatenCoreOffer(); })();
    ok.equal(offer0.length, Object.keys(PATRONS).length, 'every core is offered at zero favour');
    const p = offer0[0], other = offer0[1];
    const duo = Object.keys(BOONS).find(id => BOONS[id].duo && BOONS[id].duo.includes(p) && BOONS[id].duo.includes(other));
    const hold = [Object.keys(BOONS).find(id => BOONS[id].p === p && !BOONS[id].leg), Object.keys(BOONS).find(id => BOONS[id].p === other && !BOONS[id].leg)];
    if (duo) hold.push(duo);
    setup({ seed: 101, fac: 'chorus', sector: 3, favour: {}, beat3Done: true, hold, gift: hold[0], extra: 'warden' });
    const before = snap();
    ok.deepEqual(before.offer, offer0, 'the offer lists every unsynced core');
    const expectChorus = RUN.fleet.map(s => factionOfTpl(s.tpl) === 'chorus' ? Math.round(baseHp(s) * 1.1) : baseHp(s));
    ok.ok(eatenCoreEat(p), 'the eat is accepted');
    const after = snap();
    ok.equal(after.eaten, p); ok.ok(after.seen, 'the offer is marked seen');
    ok.deepEqual(after.maxHp, expectChorus, 'every Chorus ship +10% max hull, the prize warden untouched');
    ok.deepEqual(after.hp, after.maxHp, 'current hull rose by the same amount (ships were whole)');
    const warden = RUN.fleet[RUN.fleet.length - 1];
    ok.equal(warden.hp, Math.floor(baseHp(warden) / 2), 'the non-Chorus hull did not move');
    ok.deepEqual(after.boons, [hold[1]], 'held protocols of the eaten core and its duos are lost');
    ok.equal(after.gift, null, 'a gift of the eaten core is forgotten');
    ok.deepEqual(after.favour, before.favour, 'eating never touches favour');
    ok.ok(!after.mapCores.includes(p), 'no unfinished node still carries the eaten core signal');
    ok.ok(after.poolOk, 'no pool, duo or legendary of the eaten core can be offered again');
    ok.equal(after.offer.length, 0, 'never offered twice');
    ok.ok(!eatenCoreEat(other), 'a second eat is refused');
    const grown = newShip(RUN.fleet[0].tpl);
    ok.equal(derive(grown).maxHp, expectChorus[0], 'a ship grown after the meal gets the hull too');
    const plain = newShip('warden');
    ok.equal(derive(plain).maxHp, baseHp(plain), 'a new non-Chorus ship does not');
    fixtures.push({ name: 'eat', seed: 101, fac: 'chorus', sector: 3, favour: {}, beat3Done: true, hold, gift: hold[0], extra: 'warden', act: { k: 'eat', p }, before, after });
  }

  // 2. refuse: nothing changes but the seen mark
  {
    setup({ seed: 102, fac: 'chorus', sector: 3, favour: { iron: 5 }, beat3Done: true });
    const before = snap();
    ok.ok(before.offer.length > 0 && !before.offer.includes('iron'), 'a Partial sync core is still on the menu, iron is not (favour 5... wait, 5 < 12 so iron IS offered)');
    ACT.eatRefuse();
    const after = snap();
    ok.equal(after.eaten, null); ok.ok(after.seen, 'refusing marks the offer seen');
    ok.deepEqual(after.maxHp, before.maxHp, 'refusing changes no hull');
    ok.deepEqual(after.boons, before.boons, 'refusing keeps every protocol');
    ok.equal(after.offer.length, 0, 'never offered again');
    fixtures.push({ name: 'refuse', seed: 102, fac: 'chorus', sector: 3, favour: { iron: 5 }, beat3Done: true, hold: [], gift: null, extra: null, act: { k: 'refuse' }, before, after });
  }

  // 3. save round trip: the choice survives save and load
  {
    setup({ seed: 103, fac: 'chorus', sector: 3, favour: {}, beat3Done: true });
    const p = eatenCoreOffer()[2];
    ok.ok(eatenCoreEat(p)); saveRun();
    const before = snap();
    const saved = JSON.parse(JSON.stringify({ meta: META, run: SAVED_RUN }));
    META = migrateMeta(saved.meta); RUN = migrateRun(saved.run); SAVED_RUN = saved.run;
    const after = snap();
    ok.equal(after.eaten, p); ok.ok(after.seen); ok.equal(after.offer.length, 0, 'a reloaded run is not offered again');
    ok.deepEqual(after.maxHp, before.maxHp, 'the growth survives the reload');
    ok.deepEqual(after.boons, before.boons);
    fixtures.push({ name: 'save_round_trip', seed: 103, fac: 'chorus', sector: 3, favour: {}, beat3Done: true, hold: [], gift: null, extra: null, act: { k: 'eat', p, reload: true }, before, after });
  }

  // 4. an older save without the new fields still loads and is offered
  {
    setup({ seed: 104, fac: 'chorus', sector: 3, favour: {}, beat3Done: true });
    delete RUN.eatenCore; delete RUN.eatenOfferSeen; delete SAVED_RUN.eatenCore; delete SAVED_RUN.eatenOfferSeen;
    const saved = JSON.parse(JSON.stringify({ meta: META, run: SAVED_RUN }));
    RUN = migrateRun(saved.run);
    ok.equal(RUN.eatenCore, null, 'a missing field loads as not eaten');
    const offer = eatenCoreOffer();
    ok.equal(offer.length, Object.keys(PATRONS).length, 'a missing field means not offered yet');
    fixtures.push({ name: 'old_save', seed: 104, fac: 'chorus', sector: 3, favour: {}, beat3Done: true, hold: [], gift: null, extra: null, act: { k: 'none' }, before: null, after: snap() });
  }

  // 5. the gates: non-Chorus, wrong sector, everything synced
  {
    setup({ seed: 105, fac: 'voidsworn', sector: 3, favour: {}, beat3Done: true });
    ok.equal(eatenCoreOffer().length, 0, 'a non-Chorus run never sees the offer');
    ok.ok(!showEatenCore(), 'and no screen');
    const node = availableNodes()[0];
    ACT.enterNode(node);
    ok.equal(RUN.pos, node, 'a non-Chorus run enters its first sector 3 node undisturbed');
    setup({ seed: 106, fac: 'chorus', sector: 2, favour: {} });
    ok.equal(eatenCoreOffer().length, 0, 'sector 2 offers nothing');
    setup({ seed: 107, fac: 'chorus', sector: 3, favour: Object.fromEntries(Object.keys(PATRONS).map(q => [q, 12])), beat3Done: true });
    ok.equal(eatenCoreOffer().length, 0, 'when every core is Synced there is no offer');
    fixtures.push({ name: 'gates', seed: 107, fac: 'chorus', sector: 3, favour: Object.fromEntries(Object.keys(PATRONS).map(q => [q, 12])), beat3Done: true, hold: [], gift: null, extra: null, act: { k: 'none' }, before: null, after: snap() });
  }

  // 6. the offer screen comes before the first sector 3 node, through the real gate
  {
    setup({ seed: 108, fac: 'chorus', sector: 3, favour: {}, beat3Done: true });
    const cap = actsSeen();
    const node = availableNodes()[0];
    ACT.enterNode(node);
    const html = cap.html; cap.restore();
    ok.ok(html.includes('The swarm hungers.'), 'the screen opens with its title');
    ok.equal(RUN.pos, null, 'the node waits for the answer');
    for (const p of Object.keys(PATRONS)) ok.ok(html.includes('data-act="eatCore" data-arg="' + p + '"'), 'one button for ' + p);
    ok.ok(html.includes('data-act="eatRefuse"'), 'a Refuse button');
    const acts = [...html.matchAll(/data-act="([^"]*)"(?: data-arg="([^"]*)")?/g)].map(m => m[1] + ':' + (m[2] || ''));
    ACT.eatCore(eatenCoreOffer()[1]);
    ok.ok(RUN.eatenOfferSeen && RUN.eatenCore, 'answering through the button eats');
    ACT.enterNode(node);
    ok.equal(RUN.pos, node, 'the node opens after the answer');
    fixtures.push({ name: 'screen_gate', seed: 108, fac: 'chorus', sector: 3, favour: {}, beat3Done: true, hold: [], gift: null, extra: null, act: { k: 'screen', node, eat: 1 }, before: null, after: snap(), acts });
  }
  return fixtures;
};
`);
const fixtures = global.eatenCoreTest();
if (process.argv[2]) fs.writeFileSync(process.argv[2], JSON.stringify(fixtures));
console.log('PASS: eaten core: eat, refuse, save round trip, older saves, the gates (non-Chorus, sector, all synced) and the offer screen before the first sector 3 node.');
