'use strict';
// Issue 238 reporting checks. Report rows only: they prove the five audit artifacts exist and still say what the
// reports say. They do not run a bake, a battle, or a Monte Carlo on CI; those numbers are in the dated JSON files.
// The scripts themselves are covered by their exported data functions here.

const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');
const DIR = path.join(ROOT, 'docs/shots/reporting_2026_11');
function read(name) { return JSON.parse(fs.readFileSync(path.join(DIR, name), 'utf8')); }

const env = require('./env_batch_audit.js');
const star = require('./star_count_report.js');
const sound = require('./sound_defer_report.js');

let total = 0, failed = 0;
function t(id, fn) {
  total++;
  try { fn(); console.log('PASS ' + id); }
  catch (e) { failed++; console.log('FAIL ' + id + ': ' + e.message); }
}
function ok(v, m) { if (!v) throw Error(m || 'expected truthy'); }

t('ST4 station counts', () => {
  const j = read('station_audit.json');
  ok(j.variants.fleet.triangles_roundtrip === 11636, 'fleet triangle count changed: ' + j.variants.fleet.triangles_roundtrip);
  ok(j.variants.refinery.triangles_roundtrip === 6656, 'refinery triangle count changed: ' + j.variants.refinery.triangles_roundtrip);
  ok(j.variants.fleet.triangles_roundtrip < 20000 && j.variants.refinery.triangles_roundtrip < 20000, 'a station is over the 20k target');
});

t('ST4 station timing', () => {
  const j = read('station_audit.json');
  for (const k of ['fleet', 'refinery']) {
    const d = j.variants[k].median_delta_ms;
    ok(typeof d === 'number' && d < j.ceiling_ms, k + ' timing delta is not under the 1.0 ms ceiling');
  }
});

t('PL12 cold planet bakes', () => {
  const j = read('planet_bake_timings.json');
  ok(j.rows.length === 8, 'expected 8 seeds, found ' + j.rows.length);
  ok(j.rows.every(r => r.pass_a_ok && r.pass_b_ok), 'a planet pass did not return an image');
  const max = Math.max(...j.rows.map(r => r.total_ms));
  ok(max > 0 && max < j.wait_cap_ms, 'a cold bake is over the 20000 ms wait cap: ' + max);
  ok(j.cache_max === 24, 'cache max changed: ' + j.cache_max);
});

t('BD2 sky march steps', () => {
  const s = env.skySteps();
  ok(s, 'could not read the sky step values');
  ok(s.loader_steps.max === 48 && s.loader_steps.high === 40 && s.loader_steps.low === 26, 'loader steps changed');
  ok(s.shader_default === 40 && s.loop_cap === 64, 'shader default or loop cap changed');
  ok(s.all_within_loop_cap, 'a tier asks for more steps than the loop cap');
});

t('BD6 star count', () => {
  const j = read('star_count.json');
  ok(j.layers.length === 3, 'expected three star layers');
  ok(j.regions.length === 6, 'expected six regions');
  for (const r of j.regions) {
    ok(r.stars_total > 0 && r.stars_per_sr > 0, r.region + ' has no stars');
    ok(r.relaxed_total > r.stars_total, r.region + ' relaxed thresholds did not add stars');
  }
  ok(star.shell(120).length > 0, 'the cell enumerator found no cells');
});

t('S8 rule and S9 defect', () => {
  const js = sound.table(sound.jsCues());
  const gd = sound.table(sound.godotCues());
  const jsV = sound.verdict(js), gdV = sound.verdict(gd);
  ok(jsV.fail25.includes('gun_sq'), 'gun_sq no longer fails the 2.5x rule in sfx.js');
  ok(jsV.dropWorst.length > 0, 'sfx.js no longer drops voices in a full salvo');
  ok(gdV.fail25.length === 0, 'the port now fails the 2.5x rule: ' + gdV.fail25.join(', '));
  ok(gdV.dropWorst.length === 0, 'the port now drops salvo voices: ' + gdV.dropWorst.join('; '));
});

t('S8 full salvo arithmetic', () => {
  const js = sound.table(sound.jsCues());
  ok(js.some(r => r.starts_worst < r.starts_wanted), 'no sfx.js cue drops a voice in the worst-case salvo');
  ok(js.every(r => r.starts_worst <= r.starts_wanted), 'a simulated cue started more voices than requested');
});

t('HD6 battle log soak', () => {
  const j = read('soak.json');
  ok(j.rules_log_entries === j.hud_log_entries, 'the rules log and the HUD log disagree: ' + j.rules_log_entries + ' vs ' + j.hud_log_entries);
  ok(j.hud_log_entries > j.js_cap, 'the soak did not pass the JS 200-entry cap: ' + j.hud_log_entries);
  ok(j.hud_display_lines >= j.hud_log_entries, 'display lines are below entries');
  ok(fs.existsSync(path.join(DIR, 'hd6_battle_log_soak.png')), 'the soak capture is missing');
});

t('MP8 danger bands', () => {
  const j = read('danger_bands.json');
  ok(j.fights > 0, 'no fights measured');
  ok(j.bands.length === 4, 'expected four bands');
  ok(j.logistic_fit && typeof j.logistic_fit.B === 'number', 'missing logistic fit');
  ok(j.logistic_fit.B < 0, 'the fitted win probability does not fall as danger rises');
  ok(j.bands.find(b => b.band === 'Easy').win_rate > j.bands.find(b => b.band === 'Deadly').win_rate, 'Easy does not win more often than Deadly');
});

console.log(`${total} tests, ${total - failed} pass, ${failed} fail`);
process.exitCode = failed ? 1 : 0;
