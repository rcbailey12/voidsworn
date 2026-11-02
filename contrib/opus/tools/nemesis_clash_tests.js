// Progression step 6: prove Q4 on the live browser code, with optional Godot fixtures.
// node contrib/opus/tools/nemesis_clash_tests.js [fixtures.json]
'use strict';
const assert = require('assert/strict');
const fs = require('fs'), path = require('path');
const root = path.resolve(__dirname, '../../..');
process.env.VS_ORACLE = root;
require(path.join(root, 'godot/campaign/test/node/env.js')).load(`
globalThis.NemTest = { nemAdapt, rndSeed, rnd, NEM_ADAPT, NEM_ADAPT_FAC,
  setRun(r){ RUN=r; }, rng(){ return RNG_S >>> 0; } };
`);
const T = globalThis.NemTest;
const copy = v => JSON.parse(JSON.stringify(v));
const fixtures = [];
const kinds = Object.keys(T.NEM_ADAPT);
function check(name, run, force, want) {
  const before = copy(run), seed = fixtures.length + 1;
  T.setRun(run); T.rndSeed(seed);
  const pick = T.nemAdapt(force), n = run.nem;
  const blocked = [];
  if (before.nem.revealed.includes('ion')) blocked.push('shields');
  if (before.nem.revealed.includes('torp')) blocked.push('pd');
  assert.ok(!blocked.includes(pick), name + ': never counter a revealed weakness');
  assert.deepEqual(n.revealed, before.nem.revealed, name + ': scouting stays known');
  assert.equal(T.rng(), seed, name + ': adaptation does not draw random numbers');
  if (pick === null) assert.deepEqual(run, before, name + ': no choice leaves state intact');
  else {
    assert.ok(!before.nem.adapt.includes(pick), name + ': no duplicate');
    assert.ok(kinds.includes(pick) || pick === T.NEM_ADAPT_FAC[n.fac].special.id, name + ': valid adaptation');
    assert.deepEqual(n.adapt, [...before.nem.adapt, pick], name + ': append only the choice');
    assert.deepEqual(n.seen, {}, name + ': clear observations after adapting');
  }
  if (force) {
    const remaining = [...kinds, T.NEM_ADAPT_FAC[n.fac].special.id]
      .filter(k => !blocked.includes(k) && !before.nem.adapt.includes(k));
    assert.equal(pick !== null, remaining.length > 0, name + ': force bypasses cap, never the clash check');
  }
  if (want !== undefined) assert.equal(pick, want, name);
  fixtures.push({ name, seed, run: before, force,
    expected: { pick, adapt: copy(n.adapt), seen: copy(n.seen), revealed: copy(n.revealed), rng: T.rng() } });
}
function run(fac, revealed, adapt, seen, sector = 3, beaten = 0, scars = 0) {
  return { sector, nem: { fac, weak: ['ion', 'torp'], revealed: [...revealed], adapt: [...adapt],
    seen: { ...seen }, beaten, scars, dead: false } };
}
for (const fac of Object.keys(T.NEM_ADAPT_FAC)) {
  const special = T.NEM_ADAPT_FAC[fac].special.id;
  // Controls prove the forbidden choices really can win before scouting reveals them.
  check(fac + ' unknown emitters', run(fac, [], [], { ion: 100 }), false, 'shields');
  check(fac + ' unknown point defense', run(fac, [], [], { torp: 100 }), false, 'pd');
  check(fac + ' hidden weaknesses allow shields fallback', run(fac, [], [special], {}), false, 'shields');
  check(fac + ' both known prefer special', run(fac, ['ion', 'torp'], [], {}), false, special);
  check(fac + ' both known fallback', run(fac, ['ion', 'torp'], [special], {}), false, 'armor');
  check(fac + ' safe pool exhausted', run(fac, ['ion', 'torp'], ['armor', 'evasion', 'aim', special], {}), true, null);
  check(fac + ' sector one cap', run(fac, ['ion', 'torp'], [], { ion: 100, torp: 100 }, 1), false, null);
  const options = [...kinds, special];
  for (const revealed of [[], ['ion'], ['torp'], ['ion', 'torp']]) {
    for (let mask = 0; mask < 64; mask++) {
      const adapt = options.filter((_, i) => mask & (1 << i));
      // nemAdapt is deterministic. Vary observations and prior picks instead of rerolling identical state.
      T.rndSeed(1000 + mask);
      const randomSeen = Object.fromEntries(['lance', 'ion', 'torp', 'sq', 'ram', 'board', 'battery', 'broad', 'evaded']
        .map(k => [k, Math.floor(T.rnd() * 50)]));
      for (const [i, seen] of [{}, { lance: 100, ion: 100 }, { torp: 100, sq: 100 }, randomSeen].entries()) {
        for (const force of [false, true]) check(
          [fac, revealed.join('+') || 'hidden', mask, i, force].join('/'),
          run(fac, revealed, adapt, seen, 1 + mask % 3, mask % 2, mask % 3), force);
      }
    }
  }
}
if (process.argv[2]) fs.writeFileSync(process.argv[2], JSON.stringify(fixtures));
console.log('PASS: ' + fixtures.length + ' Nemesis adaptation cases, all six factions, scored and fallback choices, caps and forced exhaustion.');
