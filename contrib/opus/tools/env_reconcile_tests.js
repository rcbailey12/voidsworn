'use strict';
// Standing checks for the environment reconciliation (#230, FINDINGS R139): contrib/opus/briefs/environment_reconciliation.md
// and nebula_motion_spec.md. Node 18+, no dependencies. Run by run_all_checks.js (every *_tests.js in this folder).
// The audit's finding was silent disagreement between documents and code; these checks fail when the shipped value
// and the document of record part ways, so whoever changes one changes the other in the same PR.
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');
const read = f => fs.readFileSync(path.join(ROOT, f), 'utf8');
let pass = 0, fail = 0;
function check(ok, what) { if (ok) pass++; else { fail++; console.log('FAIL ' + what); } }
const has = (t, s) => t.includes(s);

const liv = read('godot/world/world_living.gd');
const rocks = read('godot/world/world_rocks.gd');
const world = read('godot/world/world.gd');
const board = read('godot/render/board.gd');
const spec = read('contrib/opus/briefs/nebula_motion_spec.md');
const rec = read('contrib/opus/briefs/environment_reconciliation.md');
const kit = read('tools/blender/hs/station_kit.py');

// 1. NB8: the base drift and the layer rates (nebula_motion_spec.md sections 1 and 2)
check(has(liv, 'vec3 drift = vec3(0.012, 0.004, 0.007) * gas_time * rate;'), 'GAS_SHADER base drift is (0.012, 0.004, 0.007); change nebula_motion_spec.md section 1 with it');
check(has(liv, 'vec3 p = vW * 0.075 + drift;'), 'GAS_SHADER samples the field at 0.075 a unit (nebula_motion_spec.md section 0)');
const d = [0.012, 0.004, 0.007].map(v => v / 0.075);
const base = Math.hypot(...d);
check(Math.abs(base - 0.193) < 0.0005 && has(spec, '0.193 units a second'), `base drift rate is 0.193 u/s in code (${base.toFixed(4)}) and in the spec`);
check(has(liv, 'float rate = band < 0.5 ? 0.6 : (band < 1.5 ? 1.0 : (band < 2.5 ? 1.6 : 0.4));'), 'layer multipliers 0.6, 1.0, 1.6, 0.4 (nebula_motion_spec.md section 2)');
check(has(liv, 'rate *= band > 2.5 ? -1.7 : 1.7;'), 'storm layers 1.7 times faster, veil reversed (section 2)');
check(has(liv, 'float fine = wfbm3(p * 3.6 + vec3(w * 0.4) + drift * 2.5);'), 'filaments at 3.6 times the frequency and 2.5 times the extra drift (section 2)');
check(has(liv, 'sin(gas_time * 0.785398 + phase) * 0.025'), 'body breathing: period 8 s, amplitude 0.025 (section 3)');
check(has(liv, '0.90 + 0.10 * sin(gas_time * 3.14159 + phase)'), 'storm glow pulse: 2 s, plus or minus 10 percent (section 3)');
check(has(liv, 'uniform float flat_rates = 0.0;'), 'the flattened-rate capture variant defaults off (section 2)');
// 2. NB11: the storm flash radius, in hexes (section 4)
check(has(liv, '(1.0 - smoothstep(8.0, 12.0, length(dd))) * f.w') && has(liv, 'sheet * 0.10 + flash * 0.3'), 'flash response full within 8 u, gone at 12 u, weight 0.3; sheet glow weight 0.10 (section 4)');
check(has(liv, 'exp(-dot(dd, dd) / 500.0)'), 'sheet glow spread 500 (1/e at 22.4 u, 1.3 hexes; section 4)');
check(has(spec, '0.46 hex') && has(spec, '0.69 hex') && has(spec, '1.3 hexes'), 'nebula_motion_spec.md states the storm radii in hexes (NB11)');
check(has(liv, 'rng.randf_range(2.2, 6.5)') && has(liv, 'dt / 0.45'), 'bolt cadence 2.2 to 6.5 s and tick flare 0.45 s (section 4)');
// 3. AS14: one tumble figure of record (environment_reconciliation.md section 1)
check(/const TUMBLE_K := 0\.10\b/.test(liv) && has(liv, 'return TUMBLE_K / maxf(1.0, scale_v)'), 'TUMBLE_K is 0.10 and tumble_rate uses it (reconciliation section 1)');
check(has(liv, 'uniform float tumble_k = 0.10;') && has(liv, 'min(rate, tumble_k / max(1.0, scale_v))'), 'the wreck shader caps tumble with the same figure');
check(!/0\.10 \/ max\(1\.0, scale_v\)/.test(liv), 'no second hard-coded 0.10 tumble cap in world_living.gd');
check(has(liv, 'OS.get_environment("VS_TUMBLE") == "periods" else "cap"'), 'the terrain-periods tumble is a capture variant, off by default');
check((rocks.match(/uniform float tumble_k = 0\.0;/g) || []).length === 2 && has(rocks, 'OS.get_environment("VS_ROCK_TUMBLE") == "1" else 0.0'), 'rocks hold their seeded pose by default (rock and crystal shaders, tumble_k 0)');
check(has(rec, '0.10 / max(1, scale)'), 'environment_reconciliation.md states the figure of record');
// 4. AS18: no debris piece over 8.66 units (section 3)
const CAP = 8.66;
const living = /var s := 0\.3 \+ 2\.5 \* pow\(rng\.randf\(\), 2\.4\)/.test(liv) ? (0.3 + 2.5) * 2.0 : NaN;
const plain = /var s := 0\.35 \+ 1\.6 \* pow\(_rng\.randf\(\), 2\.2\)/.test(world) ? (0.35 + 1.6) * 2.0 : NaN;
const hero = /rng\.randf_range\(1\.3, 2\.6\) if i > 0 else rng\.randf_range\(2\.6, 3\.8\)/.test(liv) ? 3.8 * 2.0 * Math.max(...JSON.parse(read('godot/world/wreckage/kit.json')).pieces.map(p => p.radius)) : NaN;
const ext = Math.max(...JSON.parse(read('godot/world/rocks/rocks.json')).rocks.map(r => Math.max(...r.ext)));
check(ext === 2.0, `library rocks are 2.0 units long at scale 1 (got ${ext}); the AS16 table assumes it`);
for (const [name, v] of [['living debris rock', living], ['plain debris rock', plain], ['hero wreck piece', hero]])
  check(v <= CAP, `${name} largest length ${v} is within the AS18 cap ${CAP} (reconciliation section 3; if the formula changed, update this check and section 2)`);
// 5. BD16: zone tints of record (section 4)
const zt = /const ZONE_TINT := \{"neb": Color\(0\.69, 0\.49, 1\.0, ([\d.]+)\), "debris": Color\(0\.83, 0\.75, 0\.53, ([\d.]+)\), "storm": Color\(1\.0, 0\.91, 0\.4, ([\d.]+)\)\}/.exec(board);
check(zt && zt[1] === '0.075' && zt[2] === '0.065' && zt[3] === '0.065', 'ZONE_TINT alphas are 0.075, 0.065, 0.065; change reconciliation section 4 with them');
// 6. AS1 and PL8 stay until the loom turntable (section 7)
check(has(world, 'assert(angle <= BACKDROP_ROCK_ANGLE + 0.000001') && has(world, 'angle * 4.4 <= 2.0 * _planet_ang'), 'the AS1 and PL8 backdrop asserts stay until #236 picks a profile (R124)');
// 7. ST3 and ST5: reported, not asserted (section 6)
check(!/assert abs\(hi\[0\] - lo\[0\] - 46\)/.test(kit) && !/assert hi\[2\] >= 15/.test(kit), 'ST3: station length and skyline are reported, not asserted');
check(!/assert tops ==/.test(kit) && !/assert max\(v\.co\.z for v in bpy\.data\.objects\['gantry_crossbeam'\]/.test(kit) && !/assert max\(v\.co\.z for v in bpy\.data\.objects\['secondary_process_column'\]/.test(kit), 'ST3: R94 detail heights are reported, not asserted');
check(!/assert[^\n]*triangles_roundtrip[^\n]*<=/.test(kit), 'ST5: no station triangle ceiling assert (R113)');
check(has(kit, "'Disconnected parts: '") && has(kit, "'Backward gun'") && has(kit, "'R94 primitive changed'"), 'the correctness asserts and the R100 additions-only hash check stay');

console.log(`env_reconcile_tests: ${pass + fail} checks, ${pass} pass, ${fail} fail`);
process.exit(fail ? 1 : 0);
