// Progression step 1. Optional output: node effect_caps_tests.js <fixtures.json>
// The Godot fixture test reads the same inputs and browser results for both ports.
'use strict';
const assert = require('assert/strict');
const fs = require('fs'), path = require('path'), vm = require('vm');
const root = path.resolve(__dirname, '../../..');
const ctx = vm.createContext({ window: {}, performance: { now: () => 0 } });
vm.runInContext(['data.js', 'core.js'].map(f => fs.readFileSync(path.join(root, f), 'utf8')).join('\n') + `
globalThis.T = { FX_CAPS, sumFx, derive, HULLS, MODULES, PERKS, RELICS, ADMIRALS, ASPECTS, BOONS, RARITY,
  setRun(r){ RUN=r; } };`, ctx);
const T = ctx.T, plain = v => JSON.parse(JSON.stringify(v));
const sums = [];
function sum(name, list, expected) {
  const got = plain(T.sumFx(list));
  assert.deepEqual(got, expected, name);
  sums.push({ name, list, expected });
}
for (const [kind, cap] of Object.entries(T.FX_CAPS)) {
  assert.ok(Number.isFinite(cap) && cap > 0, kind + ' has a finite positive cap');
  sum(kind + ' above cap', [{ [kind]: cap }, { [kind]: cap }], { [kind]: cap });
  sum(kind + ' below cap', [{ [kind]: cap / 4 }, { [kind]: cap / 4 }], { [kind]: cap / 2 });
  sum(kind + ' at cap', [{ [kind]: cap }], { [kind]: cap });
}
sum('penalty after excess', [{ dmgPct: 3 }, { dmgPct: -2 }], { dmgPct: 1 });
sum('penalty before excess', [{ dmgPct: -2 }, { dmgPct: 3 }], { dmgPct: 1 });
sum('negative totals stay negative', [{ dmgPct: -.25 }, { dmgPct: -.25 }], { dmgPct: -.5 });
sum('empty list', [], {});
sum('null entries, zero, mixed kinds and unknown keys', [null, {}, { dmgPct: 3, speed: 1, aim: 0, futureKind: 7 }, { speed: 1 }],
  { dmgPct: 2, speed: 2, aim: 0, futureKind: 7 });
const effects = [T.MODULES, T.PERKS, T.RELICS, T.ADMIRALS, T.ASPECTS]
  .flatMap(table => Object.values(table).map(x => x.fx).filter(Boolean))
  .concat(Object.values(T.BOONS).flatMap(b => T.RARITY.map(r => b.fx(r.m))));
for (const fx of effects) {
  for (const kind of Object.keys(fx)) assert.ok(Object.hasOwn(T.FX_CAPS, kind), 'missing cap: ' + kind);
  assert.deepEqual(plain(T.sumFx([fx])), plain(fx), 'each single effect stays intact');
}
const derives = [];
function derive(name, run, ship, speedBonus) {
  T.setRun(run);
  const got = T.derive(ship);
  assert.equal(got.speed, T.HULLS[ship.tpl].sp + speedBonus, name);
  derives.push({ name, run, ship, expected: { speed: got.speed, fx: plain(got.fx) } });
}
const ship = { uid: 'cap_test', tpl: 'warden', mk: 1, mods: ['drive'], cap: { perks: ['helm'] } };
const run = { relics: ['compass'], admiral: 'grax', boons: [{ id: 'r_burn', r: 2 }], aspect: 'ram', flagUid: ship.uid };
derive('all sources share the speed ceiling', run, ship, 4);
derive('below ceiling keeps the full bonus', { ...run, boons: [], aspect: null }, { ...ship, cap: { perks: [] } }, 3);
derive('aspect applies only to the flagship', { ...run, relics: [], admiral: 'vex', boons: [] },
  { ...ship, uid: 'other_ship', mods: [], cap: { perks: [] } }, 0);
derive('no effects', { relics: [], admiral: '', boons: [] }, { ...ship, mods: [], cap: { perks: [] } }, 0);
// Preserve exact doubles through Godot's JSON parser, like the table exporters.
function encode(v) {
  if (typeof v === 'number' && !Number.isInteger(v)) {
    const b = Buffer.alloc(8); b.writeDoubleBE(v); return '#d:' + b.toString('hex');
  }
  if (Array.isArray(v)) return v.map(encode);
  if (v && typeof v === 'object') return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, encode(x)]));
  return v;
}
if (process.argv[2]) fs.writeFileSync(process.argv[2], JSON.stringify(encode({ sums, derives })));
console.log('PASS: ' + sums.length + ' sum fixtures, ' + derives.length + ' derive fixtures, all effect kinds covered and single effects unchanged.');
