'use strict';
// Standing checks for the consolidated UI specification (contrib/opus/briefs/ui_spec.md, issue #231, FINDINGS R134).
// Node 18+, no dependencies. Run by run_all_checks.js (every *_tests.js in this folder).
// These are code-structure checks, not numeric gates: they keep the one scale law one law, keep the battle focus ring
// visible, and keep text at or above the stated floor. The values themselves are provisional until the U-A captures.
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');
const diff = require('./ui_constants_diff.js');
const read = f => fs.readFileSync(path.join(ROOT, f), 'utf8');
let pass = 0, fail = 0;
function check(ok, what) { if (ok) pass++; else { fail++; console.log('FAIL ' + what); } }

const LAW = 'godot/ui/ui_scale.gd';
const law = read(LAW);
const K_MAX = +(/const K_MAX := ([\d.]+)/.exec(law) || [])[1];
const K_MIN = +(/const K_MIN := ([\d.]+)/.exec(law) || [])[1];
const MIN_TEXT = +(/const MIN_TEXT := (\d+)/.exec(law) || [])[1];
check(/const DESIGN_HEIGHT := 1080\.0/.test(law), 'ui_scale.gd keeps the 1080 design height');
check(K_MIN === 0.6 && K_MAX === 2.2, `ui_scale.gd floor and ceiling are the spec's provisional 0.6 and 2.2 (got ${K_MIN}, ${K_MAX}); change ui_spec.md 4.1 with them`);
check(MIN_TEXT === 12, `ui_scale.gd text floor is the spec's 12 (got ${MIN_TEXT}); change ui_spec.md 4.3 with it`);

// 1. one law: no screen keeps its own height / 1080 clamp
const files = diff.godotFiles();
for (const f of files) {
  if (f === LAW) continue;
  const t = read(f);
  const own = /(?:size\.y|vs\.y|\.y)\s*\/\s*1080(?:\.0)?/.test(t) && /clamp/.test(t);
  check(!own, `${f} has its own window-height scale law; use ui_scale.gd k_for() (ui_spec.md 4.1)`);
}
// 2. every screen that sizes text reads the shared law
const USERS = ['godot/ui/battle/hud.gd', 'godot/main/title.gd', 'godot/ui/campaign/campaign_ui.gd', 'godot/main/campaign_fallback_ui.gd',
  'godot/ui/career/career_screen.gd', 'godot/ui/career/rename_dialog.gd', 'godot/main/load_screen.gd'];
for (const f of USERS) check(/ui\/ui_scale\.gd/.test(read(f)) && /k_for\(/.test(read(f)), `${f} reads the shared scale law (ui_scale.gd k_for)`);
check(!/clamp\(ui\.k/.test(read('godot/ui/campaign/map3d.gd')), 'map3d.gd labels follow ui.k without a second clamp');
check(/set_player\(settings\.get\("ui_scale", 1\.0\)\)/.test(read('godot/main/main.gd')), 'main.gd hands the player UI scale to ui_scale.gd, a missing key reading 1.0 (ui_spec.md 4.4)');

// 3. AC5: the battle theme draws a visible focus ring, and the menu and end card take keyboard focus
const hud = read('godot/ui/battle/hud.gd');
check(!/set_stylebox\("focus", "Button", StyleBoxEmpty/.test(hud), 'battle theme focus stylebox is not empty (AC5, ui_spec.md 6.2)');
check(/set_stylebox\("focus", "Button", sf\)/.test(hud) && /sf\.draw_center = false/.test(hud) && /sf\.border_color = BONE/.test(hud), 'battle theme focus ring is the title screen ring: no fill, bone border');
check(/func _button\([^)]*keys := false\)/.test(hud) && /Control\.FOCUS_ALL if keys else Control\.FOCUS_NONE/.test(hud), 'battle buttons take focus only when asked (keys)');
check(/_button\(str\(it\[0\]\), str\(it\[1\]\), it\[2\] if it\.size\(\) > 2 else null, it == items\[0\], true\)/.test(hud), 'battle menu buttons take keyboard focus');
check(/_button\("Continue", "continue", null, true, true\)/.test(hud) && /_button\("Fight again", "restart", null, true, true\)/.test(hud), 'end card buttons take keyboard focus');
const t = read('godot/main/title.gd');
check(/sf\.draw_center = false/.test(t) && /sf\.border_color = HUD\.BONE/.test(t), 'title screen focus ring unchanged (the source of the battle ring)');

// 4. TY6: no port text under the floor (a one-glyph ornament, like the side panel's gilt diamond, is not text)
const low = diff.godotSizes(files).filter(r => r.v < MIN_TEXT && !(r.text && /^"[^\w\s]"$/.test(r.text)));
for (const r of low) check(false, `text size ${r.v} under the ${MIN_TEXT} floor at ${r.at} (ui_spec.md 4.3)`);
check(true, 'text floor scan ran');

// 5. HD9: one hull-low line in the port
check(/HULL_LOW if f < 0\.35 else HULL/.test(hud) && /BLOOD if f < 0\.35 else/.test(read('godot/ui/campaign/campaign_ui.gd')), 'hull-low line is 0.35 in the battle roster and the campaign bars (HD9)');

// 6. the diff script still reads every named pair (a pattern that stopped matching is reported, not failed)
const r = diff.build();
const stale = r.pairs.filter(p => /NOT FOUND/.test(p.a.v + p.b.v));
if (stale.length) console.log('NOTE ui_constants_diff pairs no longer found: ' + stale.map(p => p.id + ' ' + p.what).join('; ') + ' (update PAIRS in ui_constants_diff.js)');
check(typeof r.text === 'string' && r.text.length > 1000, 'ui_constants_diff builds its table');

console.log(`ui_spec_tests: ${pass + fail} checks, ${pass} pass, ${fail} fail`);
process.exitCode = fail ? 1 : 0;
