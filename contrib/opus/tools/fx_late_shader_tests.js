'use strict';
// Issue 376: after the effects warm-up ends, any shader first built later names itself once with its frame and time, and
// a counter the tests read moves with it. The warm-up list is hand kept, so this is the signal that names a miss.
//
// This is the always-runnable guard: it checks the wiring in godot/fx/fx.gd, godot/fx/fx_hull.gd and
// godot/fx/fx_death.gd and the two benches that print the count, so a later edit cannot silently drop it. When a Godot
// binary is available it also runs the behaviour check godot/fx/test/late_shader_check.gd (headless: it builds shaders
// with the real helpers, not on a GPU). Where Godot is missing (GitHub's standing-checks job) it prints SKIP and keeps
// the static result. The parity and game jobs run other things; this file is the standing-checks row.
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const ROOT = path.resolve(__dirname, '../../..');

const fails = [];
const ok = (cond, msg) => { if (!cond) fails.push(msg); };

const fxPath = path.join(ROOT, 'godot/fx/fx.gd');
const hullPath = path.join(ROOT, 'godot/fx/fx_hull.gd');
const deathPath = path.join(ROOT, 'godot/fx/fx_death.gd');
const checkPath = path.join(ROOT, 'godot/fx/test/late_shader_check.gd');
const lookPath = path.join(ROOT, 'godot/bench/look_bench.gd');
const gatePath = path.join(ROOT, 'godot/bench/scene_gate.gd');
for (const p of [fxPath, hullPath, deathPath, checkPath, lookPath, gatePath]) ok(fs.existsSync(p), 'missing ' + path.relative(ROOT, p).replace(/\\/g, '/'));
const fx = fs.existsSync(fxPath) ? fs.readFileSync(fxPath, 'utf8') : '';
const hull = fs.existsSync(hullPath) ? fs.readFileSync(hullPath, 'utf8') : '';
const death = fs.existsSync(deathPath) ? fs.readFileSync(deathPath, 'utf8') : '';
const look = fs.existsSync(lookPath) ? fs.readFileSync(lookPath, 'utf8') : '';
const gate = fs.existsSync(gatePath) ? fs.readFileSync(gatePath, 'utf8') : '';

// The flag: off during a warm-up (a bench may warm more than once), on when it ends.
ok(/static var late_watch := false/.test(hull), 'fx_hull has no late watch flag');
ok(/static func start_late_watch\(\)/.test(hull) && /static func pause_late_watch\(\)/.test(hull), 'fx_hull has no start or pause for the late watch');
ok(/static func late_shader_count\(\)/.test(hull) && /static func late_shader_names\(\)/.test(hull), 'fx_hull has no counter or name list for tests to read');
ok(/if not late_watch or _late\.has\(name\):/.test(hull), 'the late log is not once per name');
ok(/print\("\[fx\] late shader: " \+ line\)/.test(hull), 'the late log does not print its line');
ok(/Engine\.get_process_frames\(\)/.test(hull) && /Time\.get_ticks_usec\(\)/.test(hull), 'the late line carries no frame and time');

// _mat names a new shader (a caller's label wins, else the fx_shaders constant name or a hash).
ok(/func _mat\(code: String, prio := 0, defines := "", label := ""\)/.test(fx), '_mat does not take a label');
ok(/name = "mat " \+ _shader_name\(code\)/.test(fx), '_mat does not name its shader');
ok(/s = HULL\.shared_shader\(code, name\)/.test(fx), '_mat does not pass its name to the shader cache');
ok(/func late_shader_count\(\) -> int:\s*\n\s*return HULL\.late_shader_count\(\)/.test(fx), 'the effects system does not expose the late counter');

// The warm-up turns the watch off while it runs and on when it ends.
const warm = fx.indexOf('func warmup(');
const warmBody = warm >= 0 ? fx.slice(warm, fx.indexOf('\nfunc ', warm + 10)) : '';
ok(/HULL\.pause_late_watch\(\)/.test(warmBody), 'the warm-up does not pause the late watch');
ok(/tmp\.queue_free\(\)\n\tHULL\.start_late_watch\(\)/.test(warmBody), 'the warm-up does not start the late watch when it ends');

// The hull and death helpers name their own materials.
ok(/static func shared_shader\(code: String, label := ""\)/.test(hull), 'the shared shader cache takes no label');
ok(/note_late\(label if label != "" else/.test(hull), 'the shared shader cache does not note a late build');
ok(/shared_shader\(dmg, "damage " \+ str\(dmg\.hash\(\)\)\)/.test(hull), 'the hull damage helper does not name its shader');
ok(/HULL\.note_late\("death debris body"\)/.test(death), 'the death debris shader is not named');
ok(/fx\.mat\(SH\.DEATH_FLIPBOOK, 2, .*"flipbook " \+ band \+ "\/" \+ kind\)/.test(death), 'the death flipbook helper does not name its shader');
ok(/fx\.mat\(code, 2, .*"route " \+ rel\)/.test(death), 'the death route helper does not name its shader');

// The benches print it.
ok(/HULL\.reset_late\(\)/.test(look) && /late_shaders_after_warmup/.test(look) && /late shaders after warm-up \(issue 376\)/.test(look), 'the look bench does not reset and print the late count');
ok(/HULL\.reset_late\(\)/.test(gate) && /"late_shaders": late\.size\(\)/.test(gate) && /late shaders after warm-up \(issue 376\)/.test(gate), 'the scene gate does not reset and print the late count');

if (fails.length) {
  for (const f of fails) console.log('FAIL ' + f);
  console.log('FAIL: ' + fails.length + ' late shader wiring check(s) failed');
  process.exit(1);
}
console.log('PASS: the late shader flag, log, counter and the two bench prints are wired');

function findGodot() {
  const candidates = [process.env.GODOT,
    'C:/Users/rcbai/Downloads/voidsworn_test/godot/Godot_v4.7.2-stable_win64_console.exe'];
  for (const c of candidates) if (c && fs.existsSync(c)) return c;
  const onPath = spawnSync('godot', ['--version'], { encoding: 'utf8', windowsHide: true });
  return onPath.status === 0 ? 'godot' : null;
}

const godot = findGodot();
if (!godot) {
  console.log('SKIP: behaviour check needs Godot (run godot/fx/test/late_shader_check.gd on the PC)');
  process.exit(0);
}
const run = spawnSync(godot, ['--headless', '--path', 'godot', '--script', 'res://fx/test/late_shader_check.gd'],
  { cwd: ROOT, encoding: 'utf8', windowsHide: true, timeout: 300000, maxBuffer: 16 * 1024 * 1024 });
const out = (run.stdout || '') + (run.stderr || '');
for (const line of out.trim().split(/\r?\n/)) {
  const t = line.trim();
  if (/LATE_SHADER|late shader|SCRIPT ERROR|Parse Error/.test(t)) console.log('  ' + t);
}
if (run.status !== 0) {
  console.log('FAIL: the late shader behaviour check failed');
  process.exit(1);
}
console.log('PASS: the late shader behaviour check passed');
