'use strict';
// Issue 354: every baked picture fx_death spawns records its spawn with fx.record_spawn, and the death vent is rooted
// on the real plating by the hull ray used since PR 327.
//
// This is the always-runnable guard: it checks the wiring in godot/fx/fx_death.gd so a later edit cannot silently drop
// the record calls again. When a Godot binary is available it also runs the behaviour check
// godot/fx/test/death_spawn_check.gd on the PC-built hulls (a real Eclipse cruiser, a hull that does not fill its box);
// where Godot or the built hulls are missing (GitHub's standing-checks job) it prints SKIP and keeps the static result.
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const ROOT = path.resolve(__dirname, '../../..');

const fails = [];
const ok = (cond, msg) => { if (!cond) fails.push(msg); };

const deathPath = path.join(ROOT, 'godot/fx/fx_death.gd');
const checkPath = path.join(ROOT, 'godot/fx/test/death_spawn_check.gd');
ok(fs.existsSync(deathPath), 'missing godot/fx/fx_death.gd');
ok(fs.existsSync(checkPath), 'missing godot/fx/test/death_spawn_check.gd');
const src = fs.existsSync(deathPath) ? fs.readFileSync(deathPath, 'utf8') : '';

ok(/const VENT_ROOT_FRAC := 0\.40/.test(src), 'VENT_ROOT_FRAC is not the measured 0.40 of the vent picture');
ok(/s\.hull\.ray\(lp \+ ln \* s\.hull\.L, -ln\)/.test(src), 'the death vent does not root on the hull with the PR 327 ray');
ok(/fx\.record_spawn\(src, mi\.get_meta\("gas_root"\)\)/.test(src), 'flipbook does not record the gas root');

const calls = src.split(/\r?\n/).filter(l => /flipbook\(/.test(l) && !/static func flipbook\(/.test(l));
ok(calls.length >= 4, 'expected at least four fx_death flipbook calls, found ' + calls.length);
for (const line of calls) {
  ok(/,\s*(src|s)\b/.test(line), 'a flipbook call does not pass its source ship: ' + line.trim());
}
ok(calls.some(l => /,\s*s,\s*true\)/.test(l)), 'the vent flipbook call is not rooted on the surface');
ok(calls.filter(l => /atlas_band\(R \/ 0\.16\), src\)/.test(l)).length === 2, 'the flash and cool core pictures do not both record');
ok(calls.some(l => /atlas_band\(L\), src\)/.test(l)), "a released section's cool picture does not record");

function findGodot() {
  const candidates = [process.env.GODOT,
    'C:/Users/rcbai/Downloads/voidsworn_test/godot/Godot_v4.7.2-stable_win64_console.exe'];
  for (const c of candidates) if (c && fs.existsSync(c)) return c;
  const onPath = spawnSync('godot', ['--version'], { encoding: 'utf8', windowsHide: true });
  return onPath.status === 0 ? 'godot' : null;
}

if (fails.length) {
  for (const f of fails) console.log('FAIL ' + f);
  console.log('FAIL: ' + fails.length + ' death spawn wiring check(s) failed');
  process.exit(1);
}
console.log('PASS: every fx_death picture records its spawn and the vent uses the hull ray');

const godot = findGodot();
if (!godot) {
  console.log('SKIP: behaviour check needs Godot (run godot/fx/test/death_spawn_check.gd on the PC)');
  process.exit(0);
}
const run = spawnSync(godot, ['--headless', '--path', 'godot', '--script', 'res://fx/test/death_spawn_check.gd'],
  { cwd: ROOT, encoding: 'utf8', windowsHide: true, timeout: 300000, maxBuffer: 16 * 1024 * 1024 });
const out = (run.stdout || '') + (run.stderr || '');
for (const line of out.trim().split(/\r?\n/)) {
  const t = line.trim();
  if (/DEATH_SPAWN|^PASS|^FAIL|vent atlas root|^WARN|placeholder/.test(t)) console.log('  ' + t);
}
if (/placeholder hull/.test(out)) {
  console.log('SKIP: behaviour check needs the PC-built hulls in godot/gen');
  process.exit(0);
}
if (run.status !== 0) {
  console.log('FAIL: the death spawn behaviour check failed');
  process.exit(1);
}
console.log('PASS: the death spawn behaviour check passed on the real hull');
