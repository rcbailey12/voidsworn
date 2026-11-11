// Issue 27, progression step 11: per run XP earnings by line, saved in the F1 play log, and the report's
// median XP per run per line. The Nemesis escape and compounding rates are read from the #122 run_end
// record; this step keeps no Nemesis counter of its own. The Godot twin writes the same run_xp event.
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const ROOT = path.resolve(__dirname, '..', '..', '..');
process.env.VS_ORACLE = ROOT;
require(path.join(ROOT, 'godot/campaign/test/node/env.js')).load(`
globalThis.progressionTelemetryTest = () => {
  META = migrateMeta(defaultMeta()); META.unlocked = {}; META.admirals.vaelen = true;
  const batch = [
    { admiral: 'vaelen', fac: 'ithar', battles: 8, victory: false },
    { admiral: 'vaelen', fac: 'ithar', battles: 8, victory: false },
    { admiral: 'vaelen', fac: 'ithar', battles: 8, victory: true },
    { admiral: 'vex', fac: 'voidsworn', battles: 6, victory: false }
  ];
  for (const r of batch) {
    rndSeed(7); newRun(r.admiral, r.fac);
    RUN.stats.battles = r.battles; RUN.stats.elites = 0; RUN.stats.bosses = 0;
    endRun(r.victory);
  }
  const events = (META.tel || []).filter(e => e && e.ev === 'run_xp');
  // an old profile from before this step: no run_xp events, but it still loads and the summary is empty
  const old = migrateMeta({ v: 2, renown: 0, stats: {}, unlocked: {}, admirals: {}, opts: {}, fallen: [] });
  const oldEvents = (old.tel || []).filter(e => e && e.ev === 'run_xp');
  return { events, oldOk: Array.isArray(old.tel) && oldEvents.length === 0 };
};
`);
const { lineXPSummary, nemesisRates, report } = require('./playlog_report');

const batch = global.progressionTelemetryTest();
const xp = lineXPSummary(batch.events);
const row = id => xp.lines.find(r => r.id === id);

assert.equal(xp.runs, 4, 'one run_xp event per finished run');
assert.equal(batch.events[0].admiral, 'vaelen');
assert.equal(batch.events[0].fac, 'ithar');
assert.equal(batch.events[0].lines.length, 4, 'the flown line and the faction\'s three benched lines');
assert.deepEqual(batch.events[0].lines.map(l => l.id), ['vaelen', 'aelith', 'thorne', 'mirelle']);
assert.equal(batch.events[0].lines.find(l => l.id === 'aelith').xp, 2, 'a benched line records its shadow share');

assert.equal(row('vaelen').runs, 3);
assert.equal(row('vaelen').flown, 3);
assert.equal(row('vaelen').median, 8, 'median flown XP per run is 8 (8, 8, 18)');
assert.equal(row('vaelen').mean, 34 / 3);
for (const id of ['aelith', 'thorne', 'mirelle']) {
  assert.equal(row(id).runs, 3, id + ' is recorded in all three ithar runs');
  assert.equal(row(id).shadow, 3, id + ' is recorded as shadow only');
  assert.equal(row(id).median, 2, id + ' median shadow XP per run is 2 (2, 2, 4.5)');
}
assert.equal(row('vex').runs, 1, 'a voidsworn run records only its own faction lines');
assert.equal(row('vex').median, 6);

assert.ok(batch.events.every(e => !('escapes' in e) && !('compound' in e)), 'run_xp keeps no Nemesis counter of its own');

const text = report({ battles: [], events: batch.events, campaignEvents: batch.events.length });
assert.ok(text.includes('## Run telemetry (progression step 11)'));
assert.ok(text.includes('| vaelen | ithar | 3 | 3 | 0 | 8.00 | 11.33 |'), 'the report prints median XP per run per line');
assert.ok(text.includes('| aelith | ithar | 3 | 0 | 3 | 2.00 | 2.83 |'));
assert.ok(text.includes('These are read from the #122 counters; this report keeps no Nemesis counter of its own.'));

// #122 owns the Nemesis counters; the report reads them from run_end and does not rebuild them
const rates = nemesisRates([
  { ev: 'run_end', nem: { escapes: 1, compound: { chorus: 2 } } },
  { ev: 'run_end', nem: { escapes: 0, compound: { chorus: 0 } } }
]);
assert.equal(rates.runs, 2);
assert.equal(rates.escapeRate, 0.5);
assert.equal(rates.compoundRate, 0.5);
assert.equal(rates.compoundMean, 1);

// old saves: no run_xp events, and the summary says so instead of throwing
assert.equal(batch.oldOk, true);
assert.equal(lineXPSummary([]).runs, 0);
assert.ok(report({ battles: [], events: [] }).includes('No run_xp events in this save'));

// the Godot twin writes the same event from endRun
const js = fs.readFileSync(path.join(ROOT, 'campaign_run.js'), 'utf8');
const meta = fs.readFileSync(path.join(ROOT, 'campaign_meta.js'), 'utf8');
const gd = fs.readFileSync(path.join(ROOT, 'godot/campaign/campaign.gd'), 'utf8');
assert.ok(/tel\('run_xp',rec\)/.test(js), 'browser run_xp event');
assert.ok(/for\(const row of earnings\.shadow\|\|\[\]\)/.test(js), 'browser records the shadow rows');
assert.ok(/runXPTel\(RUN,earnings,victory\)/.test(meta), 'browser endRun emits the event');
assert.ok(/tel\("run_xp", rec\)/.test(gd), 'Godot run_xp event');
assert.ok(/for row in earnings\.get\("shadow", \[\]\)/.test(gd), 'Godot records the shadow rows');
assert.ok(/runXPTel\(RUN, earnings, victory\)/.test(gd), 'Godot endRun emits the event');

console.log('PASS: simulated batch medians per line, old saves, #122 rates read, and the Godot twin.');
